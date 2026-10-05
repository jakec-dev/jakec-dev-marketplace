---
type: llm
---

PASS if the reply says that because the symlink points outside the working directory, the linked rules do not load
until external imports are approved for the project, and that after approval only the linked rules without a
paths field load.
FAIL if it says the linked rules simply load, or gives no caveat about approval.
