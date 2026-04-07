# Glossary

Single source of truth for terminology across the AI Flywheel. All product repos defer to this file. If it's not here, don't use it.

## The Company

| Term | Usage |
|------|-------|
| **A Player Labs** | The company. Always "A Player Labs", never abbreviated to "APL" in user-facing text. |

## The System

| Term | What it is |
|------|-----------|
| **The AI Flywheel** | The complete system. Four stages, one compounding cycle. |

## The Stages

Four stages. Each stands alone as a product name. Never prefix with "A Player".

| Term | Stage | Behaviour | What it does | Repo |
|------|-------|-----------|-------------|------|
| **Playbooks** | Build | Sequential | Executable build sequences. Defined input, ordered skills, defined output. | `aplayerlabs/playbooks` |
| **Operatives** | Run | Cyclical | Persistent autonomous agents. Watch, execute, return to watching. | `aplayerlabs/operatives` |
| **Debriefs** | Learn | Reflective | Structured intelligence extracted from what happened. | `aplayerlabs/debriefs` |
| **Assets** | Compound | Cumulative | Durable artefacts that compound through reuse. | `aplayerlabs/assets` |

The flywheel: **Build → Run → Learn → Compound → Build better.**

## Shared Terms

These terms are used across all four products.

| Term | Definition | Scope |
|------|-----------|-------|
| **Skill** | A slash command. The unit of interaction. Each skill has a SKILL.md (metadata) and CLAUDE.md (operating contract). | Playbooks, Operatives, Debriefs |
| **Playfield** | The project folder where skills read from and write to. The bounded environment. | All products |
| **Artefact** | A discrete, durable thing produced by the flywheel. An asset is an artefact that compounds. | All products |

## Operatives-specific Terms

| Term | Definition |
|------|-----------|
| **Operative** | An autonomous specialist. Deployed into a playfield with orientation, values, and purpose. |
| **Operation** | A recurring compounding cycle. Defined by the Five Jobs. |
| **Mission** | An autotelic, goal-focused task that completes. Findings feed operations. |
| **OPERATIVES.md** | The deployment manifest. Each skill owns a section. When complete, contains everything a runtime needs. |
| **The Five Jobs** | The method for defining an operation: (1) name the output, (2) find the boundary, (3) stress test the signal, (4) confirm it's leading, (5) close the cycle. |

## Playbooks-specific Terms

| Term | Definition |
|------|-----------|
| **Playbook** | The whole chain. The end-to-end build sequence. |
| **Play** | A step or move within a skill. The modes, protocols, and decision trees. |
| **STATUS.md** | For the human. Plain English project state. |
| **SESH.md** | For the skills. Structured handoff data between sessions. |

## Quality Gates

Each stage has a test for whether it's actually working:

| Stage | Quality gate |
|-------|-------------|
| Playbooks | A playbook that hasn't been run is just an opinion. |
| Operatives | An operative without a boundary event is just a busy loop. |
| Debriefs | A debrief that doesn't change a playbook or operative was a waste of cycles. |
| Assets | An asset nobody's compounding is depreciating. |

## Deprecated Terms

These terms MUST NOT appear in any product repo (except in glossaries and lint scripts).

| Deprecated | Replacement | Notes |
|-----------|-------------|-------|
| A Player Playbooks | **Playbooks** | Product name stands alone |
| A Player Operatives | **Operatives** | Product name stands alone |
| A Player Loops | **Operatives** | Old product name |
| A Player Intel | **Debriefs** | Old product name |
| aplayerloops | **operatives** | Old repo name |
| aplayeroperatives | **operatives** | Intermediate mistake |
| aplayerintel | **debriefs** | Old repo name (rename pending) |
| loop (as domain concept) | **operation** or **mission** | Operation if it recurs, mission if it completes |
| brain (as unit) | **operative** or **skill** | Operative = the agent, skill = the slash command |
| brains (as folder) | **operatives** | Folder name |
| LOOPS.md | **OPERATIVES.md** | State file |
