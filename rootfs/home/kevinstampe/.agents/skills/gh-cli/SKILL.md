---
name: gh-cli
description: >
  GitHub operations through the gh CLI instead of the GitHub MCP server. Covers pull requests,
  issues, reviews, releases, Actions runs, and repo queries. Use when the user asks to open/list/
  review/merge a PR, create or triage issues, check CI status, cut a release, or search GitHub.
  Replaces github MCP tools when those are disabled to save context.
---

Use `gh` for all GitHub work. Prefer `--json` output and parse it — never scrape human-readable output.

## Ground rules

- Never guess repo/owner. Resolve first: `gh repo view --json nameWithOwner -q .nameWithOwner`
- Never push, merge, force-push, or create releases unless explicitly asked.
- Inspect before writing: `git status`, `git diff`, `gh pr diff`.
- Long bodies: write to a temp file and use `--body-file`, not `--body` with escaped newlines.
- Paginate deliberately. Default `--limit` is 30; raise it only when needed.

## Pull requests

```bash
# list
gh pr list --state open --limit 20 --json number,title,author,headRefName,isDraft

# read one (metadata + body + comments)
gh pr view 123 --json number,title,body,state,files,reviews,comments
gh pr diff 123
gh pr diff 123 --name-only

# create (base defaults to repo default branch)
gh pr create --base main --head my-branch --title "..." --body-file /tmp/pr.md
gh pr create --draft --fill        # --fill reuses commit messages

# checks / CI
gh pr checks 123
gh pr checks 123 --watch

# merge
gh pr merge 123 --squash --delete-branch
```

Before creating a PR, look for a template and follow it:
`ls .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null`

## Reviews

```bash
gh pr review 123 --approve
gh pr review 123 --request-changes --body-file /tmp/review.md
gh pr review 123 --comment --body "..."
```

Line-level comments are not well supported by `gh` directly. Use the API:

```bash
gh api repos/{owner}/{repo}/pulls/123/comments \
  -f body="..." -f commit_id="SHA" -f path="src/foo.ts" -F line=42 -f side=RIGHT
```

Read existing review threads:
```bash
gh api repos/{owner}/{repo}/pulls/123/comments --paginate \
  --jq '.[] | {path, line, user: .user.login, body}'
```

## Issues

```bash
gh issue list --state open --limit 30 --json number,title,labels,assignees
gh issue view 45 --json number,title,body,comments
gh issue create --title "..." --body-file /tmp/issue.md --label bug
gh issue comment 45 --body "..."
gh issue close 45 --reason completed      # or: not planned
gh issue edit 45 --add-label p1 --add-assignee kevinstampe
```

Search before creating, to avoid duplicates:
```bash
gh issue list --search "keyword in:title state:open"
```

## Actions / CI

```bash
gh run list --limit 10 --json databaseId,status,conclusion,workflowName,headBranch
gh run view <id> --log-failed        # only the failing step's log
gh run watch <id>
gh run rerun <id> --failed
```

`--log-failed` matters — full logs are enormous and will blow up context.

## Releases

```bash
gh release list --limit 10
gh release view v1.2.3 --json tagName,body,publishedAt
gh release create v1.2.3 --title "..." --notes-file /tmp/notes.md
gh release create v1.2.3 --generate-notes --draft
```

## Repo / search

```bash
gh repo view --json nameWithOwner,defaultBranchRef,description
gh search repos "topic:rust stars:>1000" --limit 10
gh search code "func NewServer" --repo owner/name --limit 20
gh api repos/{owner}/{repo}/contents/path/to/file --jq '.content' | base64 -d
```

## Escape hatch: raw API

Anything `gh` lacks a subcommand for:

```bash
gh api graphql -f query='query { viewer { login } }'
gh api repos/{owner}/{repo}/branches --paginate --jq '.[].name'
```

`{owner}` and `{repo}` are auto-substituted inside a repo checkout.

## Output discipline

Always narrow with `--json` + `--jq`. Dumping full `gh api` responses wastes enormous context:

```bash
# bad
gh api repos/o/r/pulls
# good
gh api repos/o/r/pulls --jq '.[] | {number, title, user: .user.login}'
```
