#!/bin/bash
set -euo pipefail

# ============================================================
# E.6 Orchestrator — Tier 1: Bash Sequencer
# ============================================================
# Pure sequencing, zero judgment, no LLM for Proofmark.
# Pre-loop: spawns setup agent to derive Proofmark configs.
# Per-date: spawns coordinator for ETL jobs, runs Proofmark
# via queue service (bash-native), spawns triage/build on failure.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/e6-results"
WORK_QUEUE="$RESULTS_DIR/work-queue.jsonl"
RETRY_FILE="$RESULTS_DIR/retries.json"
CURRENT_FILE="$RESULTS_DIR/current.json"
LOG_FILE="$RESULTS_DIR/sequencer.log"
COMPARISON_MANIFEST="$RESULTS_DIR/comparison-manifest.json"
PROOFMARK_CONFIGS_DIR="$RESULTS_DIR/proofmark-configs"

AGENT_DIR="$SCRIPT_DIR/Agents"
COORDINATOR_PROMPT="$AGENT_DIR/date-coordinator-prompt.md"
PROOFMARK_SETUP_PROMPT="$AGENT_DIR/proofmark-setup-prompt.md"
TRIAGE_PROMPT="$AGENT_DIR/triage-analyst-prompt.md"
BUILD_PROMPT="$AGENT_DIR/build-engineer-prompt.md"

PSQL="PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -tAc"

MAX_RETRIES=5
DEFAULT_START="2024-10-01"
DEFAULT_END="2024-12-31"
ETL_SERVICE_PID=""
PROOFMARK_SERVICE_PID=""

# Parse command-line overrides
START_DATE="$DEFAULT_START"
END_DATE="$DEFAULT_END"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --start-date) START_DATE="$2"; shift 2 ;;
        --end-date)   END_DATE="$2";   shift 2 ;;
        --clean)
            echo "Cleaning e6-results directory..."
            rm -rf "$RESULTS_DIR"
            echo "Done. Run again without --clean to start fresh."
            exit 0
            ;;
        *)
            echo "Usage: $0 [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [--clean]"
            exit 1
            ;;
    esac
done

# ============================================================
# Logging
# ============================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

log_separator() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# Database Helper
# ============================================================

run_sql() {
    PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -tAc "$1"
}

# ============================================================
# Service Management
# ============================================================

ensure_services() {
    # ETL queue service
    if ! pgrep -f "JobExecutor.*--service" > /dev/null 2>&1; then
        log "Starting ETL queue service..."
        cd /workspace/MockEtlFramework \
            && dotnet run --project JobExecutor -- --service >> "$RESULTS_DIR/etl-service.log" 2>&1 &
        ETL_SERVICE_PID=$!
        sleep 5

        if ! kill -0 "$ETL_SERVICE_PID" 2>/dev/null; then
            log "ERROR: ETL queue service failed to start. Check $RESULTS_DIR/etl-service.log"
            return 1
        fi
        log "ETL queue service started (PID: $ETL_SERVICE_PID)"
    fi

    # Proofmark queue service
    if ! pgrep -f "proofmark serve" > /dev/null 2>&1; then
        log "Starting Proofmark queue service..."
        export PATH="$PATH:/home/sandbox/.local/bin"
        cd /workspace/MockEtlFramework \
            && python3 -m proofmark serve \
                --db "host=172.18.0.1 dbname=atc user=claude password=claude" \
                --table control.proofmark_test_queue \
                --workers 5 \
                --poll-interval 5 \
                >> "$RESULTS_DIR/proofmark-service.log" 2>&1 &
        PROOFMARK_SERVICE_PID=$!
        sleep 2

        if ! kill -0 "$PROOFMARK_SERVICE_PID" 2>/dev/null; then
            log "ERROR: Proofmark service failed to start. Check $RESULTS_DIR/proofmark-service.log"
            return 1
        fi
        log "Proofmark queue service started (PID: $PROOFMARK_SERVICE_PID)"
    fi
}

stop_services() {
    if [[ -n "$ETL_SERVICE_PID" ]] && kill -0 "$ETL_SERVICE_PID" 2>/dev/null; then
        log "Stopping ETL queue service (PID: $ETL_SERVICE_PID)..."
        kill "$ETL_SERVICE_PID" 2>/dev/null || true
        wait "$ETL_SERVICE_PID" 2>/dev/null || true
    fi
    if [[ -n "$PROOFMARK_SERVICE_PID" ]] && kill -0 "$PROOFMARK_SERVICE_PID" 2>/dev/null; then
        log "Stopping Proofmark service (PID: $PROOFMARK_SERVICE_PID)..."
        kill "$PROOFMARK_SERVICE_PID" 2>/dev/null || true
        wait "$PROOFMARK_SERVICE_PID" 2>/dev/null || true
    fi
}

# ============================================================
# Pre-Loop: Proofmark Setup
# ============================================================

run_proofmark_setup() {
    if [[ -f "$COMPARISON_MANIFEST" ]]; then
        log "Comparison manifest exists — skipping Proofmark setup"
        return 0
    fi

    log "Running Proofmark setup agent (one-time config derivation)..."

    if [[ ! -f "$PROOFMARK_SETUP_PROMPT" ]]; then
        log "ERROR: Proofmark setup prompt not found at $PROOFMARK_SETUP_PROMPT"
        return 1
    fi

    local agent_exit=0
    env -u CLAUDECODE claude -p \
        --dangerously-skip-permissions \
        --model sonnet \
        --allowedTools "Bash Read Write Glob Grep" \
        --system-prompt "$(cat "$PROOFMARK_SETUP_PROMPT")" \
        "Derive Proofmark configs for all 5 V1/V4 job pairs. Write config YAMLs to POC4/Artifacts/{JobName}/ as durable artifacts. Write the comparison manifest to: $COMPARISON_MANIFEST" \
        > "$RESULTS_DIR/proofmark-setup-stdout.txt" 2>&1 \
        || agent_exit=$?

    if [[ $agent_exit -ne 0 ]]; then
        log "ERROR: Proofmark setup agent exited with code $agent_exit"
        return 1
    fi

    if [[ ! -f "$COMPARISON_MANIFEST" ]]; then
        log "ERROR: Proofmark setup agent produced no comparison manifest"
        return 1
    fi

    local count
    count=$(jq '.comparisons | length' "$COMPARISON_MANIFEST")
    log "Proofmark setup complete: $count comparisons configured"
}

# ============================================================
# Work Queue Operations
# ============================================================

init_queue() {
    if [[ -f "$WORK_QUEUE" ]]; then
        log "Resuming from existing work queue ($(wc -l < "$WORK_QUEUE") items)"
        return 0
    fi

    log "Initializing work queue: $START_DATE through $END_DATE"
    local current="$START_DATE"
    while [[ "$current" < "$END_DATE" || "$current" == "$END_DATE" ]]; do
        echo "{\"date\":\"$current\",\"jobs\":\"all\"}" >> "$WORK_QUEUE"
        current=$(date -d "$current + 1 day" +%Y-%m-%d)
    done
    log "Queued $(wc -l < "$WORK_QUEUE") dates"
}

pop_work() {
    if [[ -f "$CURRENT_FILE" ]]; then
        cat "$CURRENT_FILE"
        return 0
    fi

    if [[ ! -s "$WORK_QUEUE" ]]; then
        return 1
    fi

    local item
    item=$(head -1 "$WORK_QUEUE")
    sed -i '1d' "$WORK_QUEUE"
    echo "$item" > "$CURRENT_FILE"
    echo "$item"
}

finish_work() {
    rm -f "$CURRENT_FILE"
}

inject_reruns() {
    local triage_file="$1"
    local temp
    temp=$(mktemp)
    local injected=0

    while IFS= read -r entry; do
        local job
        job=$(echo "$entry" | jq -r '.job')

        while IFS= read -r rerun_date; do
            local retry_key="${job}:${rerun_date}"
            local current_count
            current_count=$(jq -r --arg k "$retry_key" '.[$k] // 0' "$RETRY_FILE")

            if [[ "$current_count" -ge "$MAX_RETRIES" ]]; then
                log "FLAGGED: $retry_key has hit $MAX_RETRIES retries — skipping"
                continue
            fi

            jq --arg k "$retry_key" '.[$k] = ((.[$k] // 0) + 1)' "$RETRY_FILE" > "${RETRY_FILE}.tmp"
            mv "${RETRY_FILE}.tmp" "$RETRY_FILE"

            echo "{\"date\":\"$rerun_date\",\"jobs\":[\"$job\"]}" >> "$temp"
            injected=$((injected + 1))
        done < <(echo "$entry" | jq -r '.dates[]')
    done < <(jq -c '.rerun[]' "$triage_file")

    if [[ "$injected" -gt 0 ]]; then
        sort -t'"' -k4 "$temp" > "${temp}.sorted"

        if [[ -s "$WORK_QUEUE" ]]; then
            cat "${temp}.sorted" "$WORK_QUEUE" > "${WORK_QUEUE}.tmp"
            mv "${WORK_QUEUE}.tmp" "$WORK_QUEUE"
        else
            mv "${temp}.sorted" "$WORK_QUEUE"
        fi

        log "Injected $injected re-run items at front of queue"
    fi

    rm -f "$temp" "${temp}.sorted"
}

# ============================================================
# Agent Invocation
# ============================================================

run_coordinator() {
    local date="$1"
    local jobs="$2"

    local date_dir="$RESULTS_DIR/$date"
    mkdir -p "$date_dir"

    echo "{\"date\":\"$date\",\"jobs\":$jobs}" > "$date_dir/worker-input.json"

    log "Spawning date coordinator for $date (jobs: $jobs)"

    if [[ ! -f "$COORDINATOR_PROMPT" ]]; then
        log "ERROR: Coordinator prompt missing"
        return 1
    fi

    local agent_exit=0
    env -u CLAUDECODE claude -p \
        --dangerously-skip-permissions \
        --model sonnet \
        --allowedTools "Bash Read Write Glob Grep" \
        --system-prompt "$(cat "$COORDINATOR_PROMPT")" \
        "Process date $date. Input file: $date_dir/worker-input.json. Write results to: $date_dir/coordinator-result.json" \
        > "$date_dir/coordinator-stdout.txt" 2>&1 \
        || agent_exit=$?

    if [[ $agent_exit -ne 0 ]]; then
        log "ERROR: Coordinator for $date exited with code $agent_exit"
        return 1
    fi

    if [[ ! -f "$date_dir/coordinator-result.json" ]]; then
        log "ERROR: Coordinator for $date produced no result file"
        return 1
    fi

    log "Coordinator for $date completed"
}

run_triage_analyst() {
    local date="$1"
    local date_dir="$RESULTS_DIR/$date"

    log "Spawning triage analyst for $date"

    if [[ ! -f "$TRIAGE_PROMPT" ]]; then
        log "ERROR: Triage analyst prompt not found"
        return 1
    fi

    local agent_exit=0
    env -u CLAUDECODE claude -p \
        --dangerously-skip-permissions \
        --model opus \
        --allowedTools "Bash Read Write Glob Grep" \
        --system-prompt "$(cat "$TRIAGE_PROMPT")" \
        "Triage failures for date $date. Date result: $date_dir/date-result.json. Write triage result to: $date_dir/triage-result.json. Errata log: /workspace/AtcStrategy/POC4/Errata/raw-errata-log.md. Curated errata: /workspace/AtcStrategy/POC4/Errata/curated/" \
        > "$date_dir/triage-stdout.txt" 2>&1 \
        || agent_exit=$?

    if [[ $agent_exit -ne 0 ]]; then
        log "ERROR: Triage analyst for $date exited with code $agent_exit"
        return 1
    fi

    if [[ ! -f "$date_dir/triage-result.json" ]]; then
        log "ERROR: Triage analyst for $date produced no result file"
        return 1
    fi

    log "Triage analyst for $date completed"
}

run_build_engineer() {
    local date="$1"
    local date_dir="$RESULTS_DIR/$date"

    log "Spawning build engineer for $date"

    if [[ ! -f "$BUILD_PROMPT" ]]; then
        log "ERROR: Build engineer prompt not found"
        return 1
    fi

    local agent_exit=0
    env -u CLAUDECODE claude -p \
        --dangerously-skip-permissions \
        --model sonnet \
        --allowedTools "Bash Read Write Edit Glob Grep" \
        --system-prompt "$(cat "$BUILD_PROMPT")" \
        "Apply fixes for date $date. Triage result: $date_dir/triage-result.json. Write build result to: $date_dir/build-result.json. Anti-patterns: /workspace/AtcStrategy/POC4/Governance/anti-patterns.md" \
        > "$date_dir/build-stdout.txt" 2>&1 \
        || agent_exit=$?

    if [[ $agent_exit -ne 0 ]]; then
        log "ERROR: Build engineer for $date exited with code $agent_exit"
        return 1
    fi

    if [[ ! -f "$date_dir/build-result.json" ]]; then
        log "ERROR: Build engineer for $date produced no result file"
        return 1
    fi

    local build_status
    build_status=$(jq -r '.status' "$date_dir/build-result.json")

    if [[ "$build_status" != "success" ]]; then
        log "Build engineer reported failure: $(jq -r '.reason // "unknown"' "$date_dir/build-result.json")"
        return 1
    fi

    log "Build engineer for $date completed successfully"
}

# ============================================================
# Proofmark — Bash-Native Queue + Poll
# ============================================================

run_proofmark() {
    local date="$1"
    local jobs="$2"    # "all" or JSON array of V4 job names
    local date_dir="$RESULTS_DIR/$date"

    # Determine which comparisons to run
    local comparisons
    comparisons=$(jq -c '.comparisons[]' "$COMPARISON_MANIFEST")

    # Read coordinator result to know which jobs succeeded
    local coord_result="$date_dir/coordinator-result.json"
    local succeeded
    succeeded=$(jq -r '.succeeded[]' "$coord_result")

    local queued=0
    local pairs_to_check=()

    while IFS= read -r comp; do
        local job_key v1_job v4_job lhs_template rhs_template config_path
        job_key=$(echo "$comp" | jq -r '.job_key')
        config_path=$(echo "$comp" | jq -r '.config_path')
        lhs_template=$(echo "$comp" | jq -r '.lhs_template')
        rhs_template=$(echo "$comp" | jq -r '.rhs_template')

        # Derive V1 and V4 job names from job_key
        # job_key might be "PeakTransactionTimes" or "DansTransactionSpecial_details"
        # V1 name is the base (before underscore suffix for multi-output)
        v1_job=$(echo "$job_key" | sed 's/_details$//' | sed 's/_by_state$//')
        v4_job="${v1_job}V4"

        # For targeted re-runs, only run comparisons for specified jobs
        if [[ "$jobs" != '"all"' ]]; then
            if ! echo "$jobs" | jq -e "index(\"$v4_job\")" > /dev/null 2>&1; then
                continue
            fi
        fi

        # Check that both V1 and V4 jobs succeeded
        local v1_ok=false v4_ok=false
        echo "$succeeded" | grep -qx "$v1_job" && v1_ok=true
        echo "$succeeded" | grep -qx "$v4_job" && v4_ok=true

        # For targeted re-runs, V1 wasn't re-queued — check output exists on disk
        if [[ "$jobs" != '"all"' ]]; then
            local lhs_path="${lhs_template//\{date\}/$date}"
            if [[ -f "$lhs_path" ]]; then
                v1_ok=true
            fi
        fi

        if [[ "$v1_ok" != "true" ]] || [[ "$v4_ok" != "true" ]]; then
            continue
        fi

        # Substitute date into paths
        local lhs_path="${lhs_template//\{date\}/$date}"
        local rhs_path="${rhs_template//\{date\}/$date}"

        # Verify files exist
        if [[ ! -f "$lhs_path" ]]; then
            log "  WARNING: V1 output missing: $lhs_path"
            continue
        fi
        if [[ ! -f "$rhs_path" ]]; then
            log "  WARNING: V4 output missing: $rhs_path"
            continue
        fi

        # INSERT into proofmark queue
        run_sql "INSERT INTO control.proofmark_test_queue (config_path, lhs_path, rhs_path, job_key, date_key) VALUES ('$config_path', '$lhs_path', '$rhs_path', '$job_key', '$date');"
        queued=$((queued + 1))
        pairs_to_check+=("$job_key")

    done <<< "$comparisons"

    if [[ $queued -eq 0 ]]; then
        log "  No Proofmark comparisons to run for $date"
        return 0
    fi

    log "  Queued $queued Proofmark comparisons for $date"

    # Poll until all comparisons complete
    local pending=$queued
    while [[ $pending -gt 0 ]]; do
        sleep 5
        pending=$(run_sql "SELECT count(*) FROM control.proofmark_test_queue WHERE date_key = '$date' AND status NOT IN ('Succeeded', 'Failed');")
        pending=${pending:-0}
    done

    log "  All Proofmark comparisons complete for $date"
}

evaluate_proofmark() {
    local date="$1"
    local jobs="$2"
    local date_dir="$RESULTS_DIR/$date"
    local coord_result="$date_dir/coordinator-result.json"

    # Collect Proofmark results
    local pm_results
    pm_results=$(run_sql "SELECT json_agg(json_build_object('job_key', job_key, 'status', status, 'result', result, 'error_message', error_message, 'result_json', result_json)) FROM control.proofmark_test_queue WHERE date_key = '$date';")

    # Save raw proofmark results
    echo "$pm_results" > "$date_dir/proofmark-results.json"

    # Build date-result.json
    local passed_jobs=()
    local failed_jobs=()
    local skipped_jobs=()

    # Check for matched failures (both V1 and V4 failed)
    local coord_failed
    coord_failed=$(jq -r '.failed[].job' "$coord_result" 2>/dev/null || true)

    # Get unique V1 job names we're evaluating
    local v1_jobs
    if [[ "$jobs" == '"all"' ]]; then
        v1_jobs=("PeakTransactionTimes" "DailyBalanceMovement" "CreditScoreDelta" "BranchVisitsByCustomerCsvAppendTrailer" "DansTransactionSpecial")
    else
        # For targeted re-runs, derive V1 names from V4 names
        v1_jobs=()
        while IFS= read -r v4; do
            v1_jobs+=("${v4%V4}")
        done < <(echo "$jobs" | jq -r '.[]')
    fi

    for v1_job in "${v1_jobs[@]}"; do
        local v4_job="${v1_job}V4"

        # Check if both failed (matched failure = skip)
        local v1_failed=false v4_failed=false
        echo "$coord_failed" | grep -qx "$v1_job" 2>/dev/null && v1_failed=true
        echo "$coord_failed" | grep -qx "$v4_job" 2>/dev/null && v4_failed=true

        if [[ "$v1_failed" == "true" ]] && [[ "$v4_failed" == "true" ]]; then
            skipped_jobs+=("{\"job\":\"$v1_job\",\"reason\":\"Both V1 and V4 failed\"}")
            continue
        fi

        if [[ "$v1_failed" == "true" ]] || [[ "$v4_failed" == "true" ]]; then
            local which_failed="$v1_job"
            [[ "$v4_failed" == "true" ]] && which_failed="$v4_job"
            local err_msg
            err_msg=$(jq -r --arg j "$which_failed" '.failed[] | select(.job == $j) | .error' "$coord_result" 2>/dev/null || echo "unknown")
            failed_jobs+=("{\"job\":\"$v1_job\",\"reason\":\"$which_failed failed: $err_msg\"}")
            continue
        fi

        # Check Proofmark results for this job
        # Multi-output jobs (DansTransactionSpecial) have multiple entries
        local job_pm_results
        job_pm_results=$(echo "$pm_results" | jq -c --arg jk "$v1_job" '[.[] | select(.job_key | startswith($jk))]')
        local pm_count
        pm_count=$(echo "$job_pm_results" | jq 'length')

        if [[ "$pm_count" -eq 0 ]]; then
            # No proofmark results — might mean files were missing
            failed_jobs+=("{\"job\":\"$v1_job\",\"reason\":\"No Proofmark comparison results found\"}")
            continue
        fi

        local all_pass=true
        local fail_reasons=""
        while IFS= read -r pm_entry; do
            local pm_result pm_status pm_job_key pm_error
            pm_result=$(echo "$pm_entry" | jq -r '.result // "null"')
            pm_status=$(echo "$pm_entry" | jq -r '.status')
            pm_job_key=$(echo "$pm_entry" | jq -r '.job_key')

            if [[ "$pm_status" == "Failed" ]]; then
                all_pass=false
                pm_error=$(echo "$pm_entry" | jq -r '.error_message // "unknown error"')
                fail_reasons+="$pm_job_key: Proofmark error — $pm_error; "
            elif [[ "$pm_result" == "FAIL" ]]; then
                all_pass=false
                # Extract key mismatch info from result_json
                local mismatch_summary
                mismatch_summary=$(echo "$pm_entry" | jq -r '.result_json.summary | "rows: \(.row_count_lhs) vs \(.row_count_rhs), mismatches: \(.mismatch_count)"' 2>/dev/null || echo "details unavailable")
                fail_reasons+="$pm_job_key: FAIL — $mismatch_summary; "
            fi
        done < <(echo "$job_pm_results" | jq -c '.[]')

        if [[ "$all_pass" == "true" ]]; then
            passed_jobs+=("\"$v1_job\"")
        else
            failed_jobs+=("{\"job\":\"$v1_job\",\"reason\":\"${fail_reasons%;*}\"}")
        fi
    done

    # Determine overall status
    local overall_status="passed"
    [[ ${#failed_jobs[@]} -gt 0 ]] && overall_status="failed"

    # Write date-result.json
    local passed_json="[$(IFS=,; echo "${passed_jobs[*]:-}")]"
    local failed_json="[$(IFS=,; echo "${failed_jobs[*]:-}")]"
    local skipped_json="[$(IFS=,; echo "${skipped_jobs[*]:-}")]"

    cat > "$date_dir/date-result.json" <<RESULTJSON
{
  "date": "$date",
  "status": "$overall_status",
  "passed": $passed_json,
  "failed": $failed_json,
  "skipped": $skipped_json
}
RESULTJSON

    log "  Proofmark evaluation: ${#passed_jobs[@]} passed, ${#failed_jobs[@]} failed, ${#skipped_jobs[@]} skipped"
    return 0
}

# ============================================================
# Progress Tracking
# ============================================================

update_progress() {
    local date="$1"
    local status="$2"

    echo "{\"date\":\"$date\",\"status\":\"$status\",\"timestamp\":\"$(date -Iseconds)\"}" \
        >> "$RESULTS_DIR/progress.jsonl"
}

# ============================================================
# Main Loop
# ============================================================

main() {
    mkdir -p "$RESULTS_DIR"

    if [[ ! -f "$RETRY_FILE" ]]; then
        echo '{}' > "$RETRY_FILE"
    fi

    log_separator
    log "E.6 SEQUENCER STARTING"
    log_separator

    # ── Pre-loop: Proofmark setup ─────────────────────────────
    if ! run_proofmark_setup; then
        log "FATAL: Proofmark setup failed. Cannot proceed."
        exit 1
    fi

    # ── Pre-loop: Start services ──────────────────────────────
    if ! ensure_services; then
        log "FATAL: Cannot start services. Aborting."
        exit 1
    fi

    init_queue

    local processed=0
    local passed=0
    local failed=0
    local triaged=0
    local built=0
    local errors=0

    trap 'log "Sequencer interrupted."; stop_services; exit 130' INT TERM

    while true; do
        local work
        work=$(pop_work) || break

        local date jobs
        date=$(echo "$work" | jq -r '.date')
        jobs=$(echo "$work" | jq -c '.jobs')

        log_separator
        local remaining=0
        [[ -s "$WORK_QUEUE" ]] && remaining=$(wc -l < "$WORK_QUEUE")
        log "DATE: $date | JOBS: $jobs | QUEUE: $remaining remaining"
        log_separator

        # Ensure services are alive
        if ! ensure_services; then
            log "FATAL: Cannot start services. Aborting."
            finish_work
            break
        fi

        # ── Stage 1: Coordinator (queue ETL jobs, poll) ───────
        if ! run_coordinator "$date" "$jobs"; then
            errors=$((errors + 1))
            update_progress "$date" "error"
            finish_work
            continue
        fi

        # ── Stage 2: Proofmark (bash-native, queue service) ──
        run_proofmark "$date" "$jobs"
        evaluate_proofmark "$date" "$jobs"

        local result_file="$RESULTS_DIR/$date/date-result.json"
        local status
        status=$(jq -r '.status' "$result_file")
        processed=$((processed + 1))

        if [[ "$status" == "passed" ]]; then
            log "PASSED: $date"
            passed=$((passed + 1))
            update_progress "$date" "passed"
            finish_work
            continue
        fi

        # ── Stage 3: Triage Analyst ──────────────────────────
        log "FAILED: $date"
        log "  Failures: $(jq -c '.failed' "$result_file")"
        failed=$((failed + 1))

        if ! run_triage_analyst "$date"; then
            log "Triage analyst crashed for $date — manual intervention needed"
            errors=$((errors + 1))
            update_progress "$date" "triage_error"
            finish_work
            continue
        fi

        triaged=$((triaged + 1))
        local triage_file="$RESULTS_DIR/$date/triage-result.json"

        # ── Stage 4: Build Engineer (only if fixes needed) ───
        local fixes_required
        fixes_required=$(jq -r '.fixes_required' "$triage_file")

        if [[ "$fixes_required" == "true" ]]; then
            if ! run_build_engineer "$date"; then
                log "Build engineer failed for $date — re-runs NOT injected"
                errors=$((errors + 1))
                update_progress "$date" "build_error"
                finish_work
                continue
            fi
            built=$((built + 1))
        else
            log "Triage analyst says no fixes required for $date"
        fi

        # ── Stage 5: Inject re-runs ─────────────────────────
        if jq -e '.rerun | length > 0' "$triage_file" > /dev/null 2>&1; then
            inject_reruns "$triage_file"
        else
            log "No re-runs needed for $date"
        fi

        update_progress "$date" "triaged"
        finish_work
    done

    log_separator
    log "E.6 SEQUENCER COMPLETE"
    log "  Processed: $processed"
    log "  Passed:    $passed"
    log "  Failed:    $failed"
    log "  Triaged:   $triaged"
    log "  Built:     $built"
    log "  Errors:    $errors"
    log_separator

    local flagged
    flagged=$(jq -r "to_entries[] | select(.value >= $MAX_RETRIES) | .key" "$RETRY_FILE" 2>/dev/null || true)
    if [[ -n "$flagged" ]]; then
        log ""
        log "FLAGGED (hit $MAX_RETRIES retries):"
        while IFS= read -r entry; do
            log "  ✗ $entry"
        done <<< "$flagged"
    fi

    stop_services
    log "Done."
}

main "$@"
