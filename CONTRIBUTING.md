# Contributing to the Implicit Chain-of-Thought research map

Thank you for helping keep the literature record accurate and useful.

## Suggest a paper

Use the [paper suggestion form](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=paper.yml). Include the canonical title, author list, earliest public date, scholarly URL, and a short explanation of how the work fits the published scope.

## Report a correction

Use the [correction form](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=correction.yml) for metadata, date, link, summary, or classification problems. Point to an authoritative public source whenever possible.

## Scope

Core records study intermediate computation that substitutes for, compresses, internalizes, or changes the schedule of an explicit reasoning trace. General representation learning, recurrence, memory, or diffusion alone is not sufficient. Adjacent work may be included when it provides an essential precursor, comparison, evaluation, or theoretical explanation.

Paper records live in `_data/papers.yml`. The website, JSON, Markdown, BibTeX, and CSL-JSON exports are generated from that source. Keep factual metadata separate from editorial annotations. `first_public` dates the earliest public version verified during curation, usually by the arXiv v1 submission date; it is not a verified announcement timestamp. When an earlier conference presentation establishes the chronology, provide `first_public_source` and `first_public_note`, and set `citation_date` to the linked arXiv version's submission date. Do not infer dates from an arXiv identifier or a venue label.

Citation exports describe arXiv versions, not later proceedings. Keep exact author names and order; the current comma-separated format requires each author name to contain no comma. The generated structured author arrays and CSL literal names must remain lossless. Any future non-arXiv citation source needs an explicit version-specific export contract and validation.

Inclusion is curated rather than automatic. Multi-label classifications are preferred when a paper spans method families, and material changes are recorded in the public changelog.
