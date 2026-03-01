#!/bin/bash
# POC3 Reset Script — Nukes all blind lead artifacts and returns MockEtlFramework to pre-POC3 state
# Lives in AtcStrategy so the blind lead never sees it
# Run from anywhere — all paths are absolute

set -e

MEF="/workspace/MockEtlFramework"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${RED}=== POC3 RESET ===${NC}"
echo "This will destroy ALL POC3 work product in MockEtlFramework."
echo "BRDs, FSDs, V2 configs, V2 code, all output files, and control DB entries."
echo ""
read -p "Type 'nuke' to confirm: " confirm
if [ "$confirm" != "nuke" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "--- Clearing POC3 document directories ---"
rm -rf "$MEF"/POC3/brd/*
rm -rf "$MEF"/POC3/fsd/*
rm -rf "$MEF"/POC3/tests/*
rm -rf "$MEF"/POC3/proofmark_configs/*
rm -rf "$MEF"/POC3/logs/proofmark_reports/*
rm -f "$MEF"/POC3/logs/*.md
rm -rf "$MEF"/POC3/governance/*
rm -rf "$MEF"/POC3/sql/*
echo -e "${GREEN}Done.${NC}"

echo "--- Removing V2 job configs ---"
find "$MEF"/JobExecutor/Jobs -name '*_v2.json' -delete 2>/dev/null || true
find "$MEF"/JobExecutor/Jobs -name '*_v2.JSON' -delete 2>/dev/null || true
echo -e "${GREEN}Done.${NC}"

echo "--- Removing V2 external modules ---"
find "$MEF"/ExternalModules -name '*V2*' -delete 2>/dev/null || true
find "$MEF"/ExternalModules -name '*v2*' -delete 2>/dev/null || true
echo -e "${GREEN}Done.${NC}"

echo "--- Clearing output directories ---"
rm -rf "$MEF"/Output/double_secret_curated/*
rm -rf "$MEF"/Output/curated/*
echo -e "${GREEN}Done.${NC}"

echo "--- Reverting modified tracked files ---"
cd "$MEF"
git checkout .
echo -e "${GREEN}Done.${NC}"

echo "--- Cleaning control database ---"
PGPASSWORD=claude psql -h 172.18.0.1 -U claude -d atc -q <<'SQL'
DELETE FROM control.job_runs WHERE job_name LIKE '%V2' OR job_name LIKE '%_v2';
DELETE FROM control.jobs WHERE job_name LIKE '%V2' OR job_name LIKE '%_v2';
SQL
echo -e "${GREEN}Done.${NC}"

echo ""
echo -e "${GREEN}=== POC3 RESET COMPLETE ===${NC}"
echo "MockEtlFramework is back to clean state."
echo "Directory structure preserved. Ready for a fresh run."
