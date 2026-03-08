# Dan's new vision - ATC POC 5

## Broad strokes

### 1. Network isolation
In POC 4, we saw the orchestrator make edits to the ETL Framework or make changes to the V1 jobs. We've learned these types of things cannot be prevented through markdown instructions given to agents. I want to set this up like we'll have this in the production environment. Agents will have access to ETL Framework code and access to the V1 job confs, but those will be copies only. We'll run the actual ETL FW and the actual Proofmark on the host side of the host / docker line. ETL FW and Proofmark will but their output files in directory that the agents in the docker container will have read access to, but not write access to. Reverse engineering agents in the docker container will add run instructions to queue for those apps via the Postgres database tables that are already set up for that purpose.

### 2. Horizontal, not vertical
In POCs 3 and 4, we tried to move through the reverse engineering process vertically, in both the overall reverse engineering process and during the E.6 execution phase. We first inferred busniess requirements across the entire portfolio. Then we wrote specs and tests across the entire portfolio. Then we wrote code across the entire portfolio. Then we validated that effort across the entire portfolio. But in that last phase, it was even worse. We tried to run all jobs for Oct 1, validate them, triage them, fix them. Then all jobs for Oct 2...all the way to Dec 31. Our orchestrators in that last phase (E.6) had high-speed come-apart incidents every time, and we never got out of the 5-job dry run.

Instead, this POC will strive for a horizontal approach. One job at a time. Infer its requirements, build its spec and tests, build its code, validate that the output data matches across all effective dates. Move on to the next job.

### 3. Minimize human involvement
The ultimate goal is to see if we can do this at scale. And, across a production platform of 15k+ ETL jobs, having a human in the middle at all times isn't scalable. For this POC, we want to see how close we can get to pressing a button in the evening and having a fresh portfolio of 100 reverse engineered jobs in the morning.

### 4. Briggsy's tooling stack
Several Claude agents have spent many tokens analyzing whether it made sense to adopt his stack and generally answered "no" for most of it. Two things there:

 - Briggsy insists this is the only way to do this without humans in the middle
 - We've hit a brick wall with every attempt to build out our POC and still have it run. (2 failed POCs in a row)

### 5. Parallelism is ideal
Too much time was lost in POC4 waiting on all 5 analyst agents to finish before any one review agent could start. This sucked when one job was easy and another was significantly harder. Everyone had to wait around for the slow bus to catch up. We will to strive for better parallelism. Ideally, we should have 8-12 "birds in the air" and we should strive for our 8-12 to be "fungible". If we have 5 review tasks to be done, we should have 5 reviewers. If we have only 1 analysts task, we shouldn't have 8 analyst agenst idling.

### 6. Agent atomicity
Agents should do as little as possible. Fire off a FSD review agent and say "you're working job ID 12". Here's what should happen:
 - The FSD review agent should see a Job 12 FSD review task in the queue and "claim it" (see how we do threadsafe select/update queries in the ETL FW and Proofmark queue methods)
 - The FSD review agent should review the most recent FSD with all the predefined blueprint we can give them for that skill (TBD on whether docs should overwrite or be versioned)
 - The FSD review agent should write their report to project documentation with a timestap or a task queue ID
 - If the FSD passes:
   -- The FSD review agent knows to update their task as complete with a note that says "pass"
   -- The FSD review agent knows that the next step in the process is to have the test architect create test cases so they add a task for a "test architect" task to the queue for Job 12
 - If the FSD falis:
   -- The FSD review agent knows to update their task as complete with a note that says "failed" (the details are in the report)
   -- The FSD review agent knows that the next step in the process is to have the FSD design architect come back, so they add a task for an "FSD design architect" task to the queue for Job 12
 - Regardless, of pass or fail, the FSD review agent's use is now done. It cycles down.

### 7. Minimize "orchestration" LLMs
In POC 3 and 4, this was a bottleneck and a problem. They're slow, their context rots, too much to keep track of, they suck at sequencing. Take all decision making out of our orchestrators. In POC4, we decided "fuck this" and built a bash script instead. From a cost model, it makes sense to do this deterministly. But from a POC, it makes sense to see if we can do it with LLMs alone. The hope here is that, by using Briggsy's tooling, our orchestration is very minimal within the LLMs and that layer is really only seeing that there's a task of type X that hasn't been "claimed" and fires off an agent of that task time, unless we've reached our parallelism limit.
