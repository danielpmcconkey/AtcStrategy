DRAFT not ready for POC3 at this time
# The new way of working

We're going to adopt principles from both Scaled Agile Framework (SaFE) and Isaac Asimov universe to build a better process

## The laws of robotics (pun intended)

All agents workining on this project must read this and must by this at all times. These are heierarchical. The zeroth law takes precedence over the first. The first over the second.

0. Sometimes, ETL flow is non-deterministic and it is impossible to match. 
1. Data output from ETL jobs is the first priority source of truth. The only exception is where the non-deterministic outcomes can be evidenced thoroughly. 
2. Code from existing ETL jobs is the second source of truth. If logic in existing code ever disagrees with the data that job allegedly produced, and you cannot sufficiently demonstrate non-deterministic factors, then you have the wrong version of the code and you must escalte to a human.
3. Code from existing ETL jobs is assumed to be of poor quality. Data output must be accurate, but code flow cannot use external modules unless it is required to meet laws of higher precedence and with sufficient evidence to justify.


## Pods for the window

We will adopt the SaFE concept of pods. 

- No more swarms of agents all doing Phase A, then swarms of agents doing Phase B, ... E
- Many small groups (or Pods)
- Pods are self contained with expertise at all areas of SDLC
- SaFE has guilds (Anthropic calls these skills, I believe)
- Pods will target specific domains, have their own leadership, and work autonomously
- The "Blind agent" will manage these pods. His context will stay lean
- When a pod finishes a task, the blind agent will provide new tasks. Now go re-engineer Jobs 7 - 15.
- When a pod is done with their small task set, the blind agent will recycle them, but their guild knowledge needs to be shared with other guild members.
- The Orchestrating agent (BD) will need to carefully thread sabotage in while teams aren't looking. But across multiple phases of the SDLC. We can build in forced delays for sabatoge if needed.
- The blind agent will need to stop periodically to refresh his context. He should have 2 - 3 pods, each given 5 jobs or so at a time. When all the pods have completed their 5 jobs, he should stop and we should evaluate the health of his context to keep the laws of robotics top of mind. During those pauses, guild members can share knowledge.