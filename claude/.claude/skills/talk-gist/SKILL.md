---
name: talk-gist
description: >-
  Condense a long analysis, document, or thread into a short, glanceable set of
  spoken talking points for a live meeting or conversation. Use when the user
  asks for a "talk gist", meeting gist, talking points, a conversation
  cheat-sheet, or wants to turn a lengthy analysis/doc into points they can
  speak from and react with in real time.
---

# Talk Gist

Turn a long analysis into a one-screen speaking aid for a live conversation.

## What a talk gist is (and is not)

A talk gist is a **speaking aid and recall trigger**, not a summary. It is read
mid-conversation, under time pressure, while you also have to listen and talk.

It optimizes for three things only:
1. **Glanceability** — you can find your next point in a half-second glance.
2. **Buying thinking time** — it hands you a question to ask so you get seconds
   to process while the other person answers.
3. **Live branching** — when they say X, the relevant fork is already on the page.

The full reasoning, scoring, and caveats stay in the source analysis and in your
head. The gist only carries the *triggers, forks, and asks*. If a line doesn't
help you say something, ask something, or branch — cut it.

## Transformation procedure

Given a long analysis, produce the gist in this order:

1. **Name the conversation goal** in one line: what you need to land, decide, or
   learn. The gist serves the meeting's goal, not the document's structure.
2. **Select 2–5 anchors** — only the points you will actually raise. Everything
   that is justification, evidence, or background gets dropped.
3. **For each anchor**, write a headline (a claim or an ask) + the key **forks**
   in parentheses (the alternatives you might branch on) + at most 3 sub-probes.
4. **Compress to fragments** — noun phrases, roughly ≤7 words. No sentences.
   The fragment triggers recall of analysis you already did; it doesn't re-explain.
5. **Turn what you want *from them* into questions.** Asking opens the floor and
   buys you processing time. Mark open probes with a trailing `?`.
6. **Order by the room** — what you'll raise first / what drives the discussion,
   not the logical order of the source.
7. **Fit one screen** — no scrolling. If it doesn't fit, cut anchors.

## Format conventions

- Numbered top-level = the handful of points you intend to raise.
- `(option A?, option B?)` after a headline = forks to branch on live.
- `-` sub-bullets = the sharpest 1–3 probes/sub-points, as fragments.
- `label: a, b` = a categorized sub-point with its options.
- Trailing `?` = an open probe (something to ask, not assert).
- `any others?` (or similar catch-all) = keep the floor open on purpose.

## Template

```
Goal: <one line — what you need out of this conversation>

1. <Anchor: claim or ask> (<fork?>, <fork?>)
   - <sharp sub-point or probe>
   - <alternative / risk?>
2. <Anchor> — <one-phrase frame>
   - <option?> <terse why-weak / why-strong>
   - <option?> <terse tension>
   - any others?
```

## Example

Source: a long analysis weighing whether to migrate a service off a legacy
queue, covering failure history, cost models, vendor lock-in, and team skills.

Gist:

```
Goal: get a go/no-go on migrating off the legacy queue this quarter

1. Why legacy queue hurts (cost? reliability?)
   - outages: tail latency, redelivery storms
   - lock-in: proprietary protocol, no portable client
2. Migration target (managed? self-host?)
   - managed: fast, but per-msg cost at our volume?
   - self-host: cheaper, ops burden — who owns on-call?
   - any others?
3. Cost of waiting one more quarter — who absorbs the next outage?
```

Everything else from the analysis (the numbers, the history, the scoring) is
left out — it lives in the source and gets pulled in only if someone asks.

## Anti-patterns

- **Not a summary/abstract.** Don't try to be complete; capture only what you'll
  say, ask, or branch on.
- **No full sentences or paragraphs.** You can't read prose while talking.
- **No conclusions you won't voice.** If you won't say it out loud, cut it.
- **Don't drop the forks.** The parenthetical alternatives are the live-branching
  value; a gist without forks is just a flat list.
- **Don't exceed ~5 anchors / one screen.** Past that it stops being glanceable.
- **Don't paste the reasoning.** Keep a pointer to the source analysis for depth.
```
