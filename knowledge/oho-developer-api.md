# Repo: oho-developer-api

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Node.js public/developer-facing API.

## Notes

- Developer API has its own partner-connection routes — keep contracts separate from the member-facing web app and backoffice. Don't reuse their route shapes here.
- External callers authenticate with `x-oho-api-key` style headers; treat contract changes as breaking.
