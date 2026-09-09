---
name: address-review
description: Read the outstanding review feedback on a pull request, triage it, apply the fixes, and reply on each thread saying what happened. Use when the user wants to address, respond to, handle, or work through PR review comments or reviewer feedback, or asks what a reviewer is still waiting on.
---

# Address review feedback

Take a pull request's outstanding review feedback and close the loop on it:
work out what is still outstanding, decide what to do with each piece, apply
the fixes, and reply on each thread so the reviewer can see what happened
without re-reading the diff. A finished result is a PR where every thread has
either been answered or been fixed and answered.

## When to use

- The user asks to address, respond to, or work through review comments.
- The user asks what a reviewer is still waiting on, or what is unresolved.
- A PR has come back with changes requested.

Do not use this to *give* a review — that is `/code-review`. Do not use it to
open a PR — that is `create-pr`. GitHub only; see Notes.

## Instructions

### 1. Identify the pull request

Default to the PR for the current branch; accept a number or URL as an
argument. If there is no PR, say so rather than guessing at one.

```bash
gh pr view --json number,url,headRefName
gh repo view --json owner,name -q '.owner.login + " " + .name'
```

### 2. Read all three surfaces

Feedback lives in three separate places and reading only one silently misses
the rest.

**Line-level threads — via GraphQL, not REST.** REST's
`/pulls/{n}/comments` does not expose whether a thread is resolved, and
`gh pr view --comments` returns a flat dump with no thread IDs and no
resolution state. Neither can tell outstanding feedback from settled feedback,
which is the whole job here.

```bash
gh api graphql -F owner="$OWNER" -F repo="$REPO" -F pr="$NUMBER" -f query='
query($owner:String!, $repo:String!, $pr:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:50) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line
          comments(first:100) { nodes { author { login } body } }
        }
      }
    }
  }
}'
```

**Review bodies and conversation comments — via REST.**

```bash
gh api --paginate "repos/$OWNER/$REPO/pulls/$NUMBER/reviews" \
  -q '.[] | select(.body != "") | {user: .user.login, state, body}'
gh api --paginate "repos/$OWNER/$REPO/issues/$NUMBER/comments" \
  -q '.[] | {user: .user.login, body}'
```

Paginate deliberately. `first: 50` threads is not "all threads", and a busy PR
is exactly where this skill earns its keep. Tell the user how many threads you
found, so a truncation is visible rather than silent.

### 3. Filter to what is outstanding

Keep threads where `isResolved` is false, plus review bodies and conversation
comments that have not been answered. A thread marked `isOutdated` points at
code that has since changed — read it against the current file, not against the
diff it was written on.

Automated reviewers are normal. Treat a bot's comment as feedback to triage like
any other; do not assume a human wrote it, and do not dismiss it because one
did not.

### 4. Triage, and show the user before changing anything

Sort every outstanding item into three groups and present them:

- **Will fix** — with the change you intend to make.
- **Already correct** — with the reason the current code is right.
- **Needs discussion** — with the question you would ask the reviewer.

Wait for approval before touching code. A wrong triage is worse than no triage:
filing a real problem under "already correct" buries it where nobody looks
again.

### 5. Apply the fixes

Group commits by concern rather than one per thread — a busy review otherwise
produces a dozen one-line commits. Each commit message names what it addresses.

### 6. Reply on every thread you acted on

```bash
gh api graphql -F tid="$THREAD_ID" -F body="$TEXT" -f query='
mutation($tid:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$tid, body:$body}) {
    comment { url }
  }
}'
```

Say what changed and in which commit. For **already correct**, reply with the
reasoning and leave the thread open — whether the reviewer is satisfied is
their call, not the author's. Reply plainly; do not argue, and do not thank
effusively.

### 7. Resolve only what you actually fixed

```bash
gh api graphql -F tid="$THREAD_ID" -f query='
mutation($tid:ID!) { resolveReviewThread(input:{threadId:$tid}) { thread { isResolved } } }'
```

Confirm with the user before the first resolve of a session. Never resolve a
thread you replied to with a disagreement, and never resolve one you did not
address — resolving ends a conversation someone else opened.

### 8. Push and report

Push the fixes, then say what is left open and why: the threads awaiting the
reviewer, and the questions you asked. That list is the handover.

## Guidelines

- Replying and resolving are outward-facing and visible to other people.
  Confirm the triage before changing code, and confirm before the first resolve.
- Never mark something addressed that was not addressed. If a fix turned out to
  be harder than expected, say so in the thread and leave it open.
- Answer the comment that was written, not the one that would have been easier
  to answer.
- A reviewer asking a question wants an answer, not a code change. Not every
  thread ends in a commit.
- Do not claim a fix is tested unless you ran the tests.

## Notes

**GitHub only.** `create-pr` covers GitHub, GitLab, Bitbucket and Azure DevOps,
so this is a deliberate asymmetry: GitLab's discussion API is a different enough
shape to deserve its own work rather than a guess. On any other host, say so and
stop instead of improvising.

**Why GraphQL.** Thread resolution state exists only there. REST's comment
objects have no `resolved` field, so a REST-based version would re-address
threads that were closed weeks ago.
