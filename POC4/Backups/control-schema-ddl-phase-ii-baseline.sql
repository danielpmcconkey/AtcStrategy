--
-- PostgreSQL database dump
--

\restrict iST71I7mcrpqAx27Iz3n3zLgXjvinegGGUDfMR2hR7qfvkPrdRNYzMcHpAS5pU7

-- Dumped from database version 17.5 (Ubuntu 17.5-1.pgdg24.04+1)
-- Dumped by pg_dump version 17.9 (Ubuntu 17.9-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: control; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA control;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: comparison_queue; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.comparison_queue (
    task_id integer NOT NULL,
    config_path text NOT NULL,
    lhs_path text NOT NULL,
    rhs_path text NOT NULL,
    job_key text,
    date_key date,
    status character varying(20) DEFAULT 'Pending'::character varying NOT NULL,
    result character varying(10),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    result_json jsonb,
    error_message text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: comparison_queue_task_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.comparison_queue_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comparison_queue_task_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.comparison_queue_task_id_seq OWNED BY control.comparison_queue.task_id;


--
-- Name: job_dependencies; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.job_dependencies (
    dependency_id integer NOT NULL,
    job_id integer NOT NULL,
    depends_on_job_id integer NOT NULL,
    dependency_type character varying(20) DEFAULT 'SameDay'::character varying NOT NULL,
    CONSTRAINT job_dep_no_self_loop CHECK ((job_id <> depends_on_job_id)),
    CONSTRAINT job_dep_type_check CHECK (((dependency_type)::text = ANY ((ARRAY['SameDay'::character varying, 'Latest'::character varying])::text[])))
);


--
-- Name: TABLE job_dependencies; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON TABLE control.job_dependencies IS 'Directed dependency edges between jobs. A row (job_id → depends_on_job_id) means job_id cannot run until depends_on_job_id has succeeded.';


--
-- Name: COLUMN job_dependencies.job_id; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_dependencies.job_id IS 'The downstream job — the one that has a dependency.';


--
-- Name: COLUMN job_dependencies.depends_on_job_id; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_dependencies.depends_on_job_id IS 'The upstream job that must succeed first.';


--
-- Name: COLUMN job_dependencies.dependency_type; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_dependencies.dependency_type IS 'SameDay: upstream must succeed for the same run_date. Latest: upstream must have succeeded at least once for any run_date.';


--
-- Name: job_dependencies_dependency_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.job_dependencies_dependency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_dependencies_dependency_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.job_dependencies_dependency_id_seq OWNED BY control.job_dependencies.dependency_id;


--
-- Name: job_runs; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.job_runs (
    run_id integer NOT NULL,
    job_id integer NOT NULL,
    run_date date NOT NULL,
    attempt_number integer DEFAULT 1 NOT NULL,
    status character varying(20) DEFAULT 'Pending'::character varying NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    triggered_by character varying(100) DEFAULT 'manual'::character varying NOT NULL,
    rows_processed integer,
    error_message text,
    min_effective_date date,
    max_effective_date date,
    CONSTRAINT job_runs_attempt_positive CHECK ((attempt_number >= 1)),
    CONSTRAINT job_runs_status_check CHECK (((status)::text = ANY ((ARRAY['Pending'::character varying, 'Running'::character varying, 'Succeeded'::character varying, 'Failed'::character varying, 'Skipped'::character varying])::text[])))
);


--
-- Name: TABLE job_runs; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON TABLE control.job_runs IS 'Execution history for all job runs. One row per attempt.';


--
-- Name: COLUMN job_runs.run_date; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.run_date IS 'The business/effective date this execution was processing.';


--
-- Name: COLUMN job_runs.attempt_number; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.attempt_number IS 'Incremented on each retry for the same (job_id, run_date).';


--
-- Name: COLUMN job_runs.triggered_by; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.triggered_by IS 'Who or what initiated the run: manual, scheduler, or dependency.';


--
-- Name: COLUMN job_runs.rows_processed; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.rows_processed IS 'Optional row count written by the final DataFrameWriter step, populated by the executor.';


--
-- Name: COLUMN job_runs.min_effective_date; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.min_effective_date IS 'Earliest as_of date included in this run''s data pull.';


--
-- Name: COLUMN job_runs.max_effective_date; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.job_runs.max_effective_date IS 'Latest as_of date included in this run''s data pull. The executor gap-fills from (last succeeded max + 1 day) to today.';


--
-- Name: job_runs_run_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.job_runs_run_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_runs_run_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.job_runs_run_id_seq OWNED BY control.job_runs.run_id;


--
-- Name: jobs; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.jobs (
    job_id integer NOT NULL,
    job_name character varying(255) NOT NULL,
    description text,
    job_conf_path character varying(500) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE jobs; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON TABLE control.jobs IS 'Registry of all known ETL jobs.';


--
-- Name: COLUMN jobs.job_name; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.jobs.job_name IS 'Unique logical name for the job (e.g. CustomerAccountSummary).';


--
-- Name: COLUMN jobs.job_conf_path; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.jobs.job_conf_path IS 'Relative or absolute path to the JSON job configuration file.';


--
-- Name: COLUMN jobs.is_active; Type: COMMENT; Schema: control; Owner: -
--

COMMENT ON COLUMN control.jobs.is_active IS 'False disables scheduling without deleting the job record.';


--
-- Name: jobs_job_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.jobs_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_job_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.jobs_job_id_seq OWNED BY control.jobs.job_id;


--
-- Name: proofmark_test_queue; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.proofmark_test_queue (
    task_id integer NOT NULL,
    config_path text NOT NULL,
    lhs_path text NOT NULL,
    rhs_path text NOT NULL,
    job_key text,
    date_key date,
    status character varying(20) DEFAULT 'Pending'::character varying NOT NULL,
    result character varying(10),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    result_json jsonb,
    error_message text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: proofmark_test_queue_task_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.proofmark_test_queue_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proofmark_test_queue_task_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.proofmark_test_queue_task_id_seq OWNED BY control.proofmark_test_queue.task_id;


--
-- Name: task_queue; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.task_queue (
    task_id integer NOT NULL,
    job_name character varying(255) NOT NULL,
    effective_date date NOT NULL,
    execution_mode character varying(10) DEFAULT 'parallel'::character varying NOT NULL,
    status character varying(20) DEFAULT 'Pending'::character varying NOT NULL,
    queued_at timestamp without time zone DEFAULT now() NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    error_message text
);


--
-- Name: task_queue_task_id_seq; Type: SEQUENCE; Schema: control; Owner: -
--

CREATE SEQUENCE control.task_queue_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_queue_task_id_seq; Type: SEQUENCE OWNED BY; Schema: control; Owner: -
--

ALTER SEQUENCE control.task_queue_task_id_seq OWNED BY control.task_queue.task_id;


--
-- Name: comparison_queue task_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.comparison_queue ALTER COLUMN task_id SET DEFAULT nextval('control.comparison_queue_task_id_seq'::regclass);


--
-- Name: job_dependencies dependency_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_dependencies ALTER COLUMN dependency_id SET DEFAULT nextval('control.job_dependencies_dependency_id_seq'::regclass);


--
-- Name: job_runs run_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_runs ALTER COLUMN run_id SET DEFAULT nextval('control.job_runs_run_id_seq'::regclass);


--
-- Name: jobs job_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.jobs ALTER COLUMN job_id SET DEFAULT nextval('control.jobs_job_id_seq'::regclass);


--
-- Name: proofmark_test_queue task_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.proofmark_test_queue ALTER COLUMN task_id SET DEFAULT nextval('control.proofmark_test_queue_task_id_seq'::regclass);


--
-- Name: task_queue task_id; Type: DEFAULT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.task_queue ALTER COLUMN task_id SET DEFAULT nextval('control.task_queue_task_id_seq'::regclass);


--
-- Name: comparison_queue comparison_queue_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.comparison_queue
    ADD CONSTRAINT comparison_queue_pkey PRIMARY KEY (task_id);


--
-- Name: job_dependencies job_dep_unique; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_dependencies
    ADD CONSTRAINT job_dep_unique UNIQUE (job_id, depends_on_job_id);


--
-- Name: job_dependencies job_dependencies_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_dependencies
    ADD CONSTRAINT job_dependencies_pkey PRIMARY KEY (dependency_id);


--
-- Name: job_runs job_runs_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_runs
    ADD CONSTRAINT job_runs_pkey PRIMARY KEY (run_id);


--
-- Name: jobs jobs_name_unique; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.jobs
    ADD CONSTRAINT jobs_name_unique UNIQUE (job_name);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (job_id);


--
-- Name: proofmark_test_queue proofmark_test_queue_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.proofmark_test_queue
    ADD CONSTRAINT proofmark_test_queue_pkey PRIMARY KEY (task_id);


--
-- Name: task_queue task_queue_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.task_queue
    ADD CONSTRAINT task_queue_pkey PRIMARY KEY (task_id);


--
-- Name: idx_control_comparison_queue_keys; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_control_comparison_queue_keys ON control.comparison_queue USING btree (job_key, date_key);


--
-- Name: idx_control_comparison_queue_status; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_control_comparison_queue_status ON control.comparison_queue USING btree (status);


--
-- Name: idx_control_proofmark_test_queue_keys; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_control_proofmark_test_queue_keys ON control.proofmark_test_queue USING btree (job_key, date_key);


--
-- Name: idx_control_proofmark_test_queue_status; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_control_proofmark_test_queue_status ON control.proofmark_test_queue USING btree (status);


--
-- Name: idx_job_dep_upstream; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_job_dep_upstream ON control.job_dependencies USING btree (depends_on_job_id);


--
-- Name: idx_job_runs_job_date; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_job_runs_job_date ON control.job_runs USING btree (job_id, run_date);


--
-- Name: idx_job_runs_status; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_job_runs_status ON control.job_runs USING btree (status);


--
-- Name: idx_task_queue_status; Type: INDEX; Schema: control; Owner: -
--

CREATE INDEX idx_task_queue_status ON control.task_queue USING btree (status);


--
-- Name: job_dependencies job_dependencies_depends_on_job_id_fkey; Type: FK CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_dependencies
    ADD CONSTRAINT job_dependencies_depends_on_job_id_fkey FOREIGN KEY (depends_on_job_id) REFERENCES control.jobs(job_id);


--
-- Name: job_dependencies job_dependencies_job_id_fkey; Type: FK CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_dependencies
    ADD CONSTRAINT job_dependencies_job_id_fkey FOREIGN KEY (job_id) REFERENCES control.jobs(job_id);


--
-- Name: job_runs job_runs_job_id_fkey; Type: FK CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.job_runs
    ADD CONSTRAINT job_runs_job_id_fkey FOREIGN KEY (job_id) REFERENCES control.jobs(job_id);


--
-- PostgreSQL database dump complete
--

\unrestrict iST71I7mcrpqAx27Iz3n3zLgXjvinegGGUDfMR2hR7qfvkPrdRNYzMcHpAS5pU7

