# Contributing to the Implicit Chain-of-Thought reading list

## Suggest a paper

Use the [quick suggestion form](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=quick-paper.yml). A paper link and one sentence about why it belongs are enough. We can fill in the authors, dates, and categories.

## Report a correction

Use the [correction form](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=correction.yml). Tell us which paper or page is affected, what is wrong, and what it should say. A source link helps us check the change.

## What belongs on the list?

The list covers methods that replace, compress, or learn from written reasoning, as well as repeated computation, related generation methods, and studies of what these methods can and cannot do. General representation learning, recurrence, memory, or diffusion alone is not enough; there should be a clear connection to this literature. Earlier background papers are listed separately.

## Editing the data directly

Paper entries live in `_data/papers.yml`; background papers live in `_data/precursors.yml`. The website and JSON, Markdown, BibTeX, and CSL-JSON downloads are generated from these files.

- Check titles, authors, links, and dates against the original paper. Write summaries in your own words.
- `first_public` is the earliest public date we have verified, usually the first arXiv submission. For an earlier conference presentation, include `first_public_source` and `first_public_note`. Set `citation_date` to the initial submission date of the linked arXiv preprint. Do not infer dates from an arXiv identifier or venue label.
- Preserve author names and order. The current comma-separated format requires each author's name to contain no comma.
- Assign more than one category when appropriate. The allowed values are in `data/ontology.json`.
- Citation exports currently describe arXiv preprints, not later proceedings. Supporting other sources would require changes to the exports and their tests.
- Describe substantial reading-list changes in `_data/releases.yml`.

We review suggestions before adding them.
