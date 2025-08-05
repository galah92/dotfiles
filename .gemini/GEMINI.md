## General Instructions:

- If a new dependency is required, please state the reason and ask for approval before adding it.

## Feedback Loop:
- Incorporate CI feedback loop checks during development.
- If a CI workflow exists in `.github/workflows`, use it as the basis for the feedback loop.
- Only only static analysis and type checking tools. Avoid tests unless explicitly asked for.
- Try to squash the feedback loop into a single command to make it fast to run.
