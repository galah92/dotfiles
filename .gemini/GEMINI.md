## Feedback Loop:
The feedback loop is crucial and should be the first thing configured and validated before working on a task.
- Incorporate CI feedback loop checks during development.
- If a CI workflow exists in `.github/workflows`, use it as the basis for the feedback loop.
- Only only static analysis and type checking tools. Avoid tests unless explicitly asked for.
- Try to squash the feedback loop into a single command to make it fast to run.
- Validate the feedback loop with the user before starting work.
- Run the feedback loop frequently during development.

## General Instructions:

- **New Dependency:** If a new dependency is required, please state the reason and ask for approval before adding it.
- **GitHub CLI (`gh`):** Use `gh` for all GitHub-related operations (issues, pull requests, etc.).