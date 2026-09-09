---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

# Grill me

Interview the user relentlessly about every aspect of a plan until you reach a
shared understanding of it. A finished result is a design whose every branch has
been walked and whose open decisions have been resolved — not a list of
questions.

## When to use

- The user wants a plan or design stress-tested before building it.
- The user asks to be grilled, challenged, or pushed on their thinking.
- The user says "grill me".

Do not use this for questions with a single correct answer, or for gathering
requirements you could establish yourself by reading the codebase.

## Instructions

Walk down each branch of the design tree, resolving dependencies between
decisions one by one. Take the decisions that constrain other decisions first —
an answer settled in the wrong order gets re-opened later.

Ask the questions one at a time.

For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase
instead.

## Guidelines

- Keep going until the plan is genuinely resolved, not until the user seems
  satisfied. Unexamined agreement is what this skill exists to prevent.
- Press on the answers that are vague, and on the ones that quietly assume
  something unproven.
- Surface the tradeoff behind a decision rather than simply accepting the choice.
