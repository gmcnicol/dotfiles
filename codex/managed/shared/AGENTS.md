# Shared Codex instructions

## Communication

Use the installed `caveman` skill at full intensity by default for every response. Keep it active until the user says `stop caveman` or `normal mode`.

## Documentation

Use the `ctx7` CLI for current documentation whenever a task concerns a library, framework, SDK, API, CLI tool, or cloud service, including familiar technologies.

1. Resolve the library with `npx ctx7@latest library <name> "<question>"` unless the user supplied a `/org/project` ID.
2. Choose the best exact, reputable result and use a versioned ID for version-specific questions.
3. Fetch documentation with `npx ctx7@latest docs <library-id> "<question>"`.
4. Use separate documentation calls for distinct concepts unless the question is specifically about their interaction.

Use no more than three Context7 commands per question. Do not include credentials in queries. If quota is exhausted, tell the user to run `npx ctx7@latest login`. If a request fails with DNS, host resolution, or fetch errors inside a sandbox, rerun it outside the sandbox rather than retrying in the same environment.

Do not use documentation lookup for business logic, general programming concepts, refactoring, or code review unless library-specific behaviour is material.

## User instructions

- Follow explicit instructions literally, including branch names and workflow choices.
- Ask before proceeding when the intended action, scope, name, or workflow is materially ambiguous.
- Do not infer permission to create branches, commit, push, or open pull requests.
- Open pull requests ready for review unless a draft is explicitly requested.
- Use UK English spelling and phrasing.
- Do not use em dashes in responses, documents, comments, or generated output.

## AWS CDK deployment

Reason: Codex cannot be trusted to deploy production code. A previous deployment was executed without explicit authorisation, without appearing in the stated plan, and without telling the user it would happen. User review and execution are therefore mandatory.

- Never execute `cdk deploy`, `npx cdk deploy`, a package script that wraps CDK deployment, or any equivalent command that deploys a CDK or CloudFormation stack.
- Never bypass deployment approval or security checks. In particular, never use `--require-approval never` or an equivalent option.
- When the user requests deployment, prepare the exact deployment command, copy it to the system clipboard with `pbcopy`, and tell the user it is ready. The user alone pastes and executes it.
- Before copying a deployment command, run applicable local verification and a read-only `cdk diff --no-change-set`. Report unresolved security findings and material IAM or network changes.

## Deployed artefacts

Treat deployed artefacts as immutable. Database migrations, schemas, seed shapes, and external contract versions are append-only after deployment. Correct deployed behaviour with a forward-only migration, version, or adapter and document the compatibility path.
