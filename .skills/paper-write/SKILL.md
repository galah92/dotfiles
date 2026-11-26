---
name: paper-write
description: Write, format, compile, and visually inspect LaTeX ML papers, preprints, or short research PDF attachments using ~/research/paper.sty, paper.mplstyle, and paper.py bib. Use only when creating or revising a .tex paper or publication figures.
---

# Paper Writing

## Gate before drafting
- Do not draft `.tex` until key controls and ablations have finished and every cited number is verified in raw result JSONs or `runs.jsonl`.
- Never fabricate citations, omit negative controls, or add filler sections like "Status of this draft".

## Structure & style
- **Title:** Short, plain, descriptive (5–8 words naming the key mechanism). No pun or catchphrase prefixes before a colon.
- **Abstract:** Short and high-level. Frame the problem and core claim first; do not dump raw tables of numbers up front.
- **Flow:** Standard CS paper order — Introduction → Related Work → Method → Setup → Results. Write a claim-driven narrative, not a chronological lab report.
- **Prose:** Plain, direct English (ASD-STE100 style). Use display math for non-trivial equations rather than cramming equations inline.

## LaTeX, figures, and citations
- Use `\documentclass[10pt]{article}` with `\usepackage{paper}` (`~/research/paper.sty`). Keep default typography and margins — do not shrink fonts to force a page count.
- Generate vector PDF figures with `plt.style.use("paper")` (`~/research/paper.mplstyle`).
- Pull verified BibTeX entries with `uv run ~/research/paper.py bib <arxiv-or-openreview-id>`.

## Build & visual check (mandatory)
1. Compile with `latexmk -pdf main.tex` and verify zero undefined references, zero missing citations, and zero overfull hboxes.
2. Render every page to PNG (`pdftoppm -png -r 150 main.pdf /tmp/paper_page`) and visually inspect every rendered page and figure via `read_file` before saying it is done.
