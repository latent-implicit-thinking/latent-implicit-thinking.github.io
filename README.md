# Implicit Chain-of-Thought

A living research map for **implicit chain-of-thought**: intermediate reasoning carried out without writing every step as natural language.

The site serves three audiences from one canonical corpus:

- newcomers can learn the principal research lenses and scope;
- researchers can search and filter 108 core papers plus eight separately labeled precursors; and
- research agents can use versioned JSON, BibTeX, CSL-JSON, Markdown, schema, ontology, provenance, and change data without scraping HTML.

The original **Latent & Implicit Thinking – Going Beyond CoT Reasoning workshop at ICLR 2026** is preserved under `/workshop/2026/` with its program and event pages clearly labeled as an archive.

## Corpus and coverage

Core records live in `_data/papers.yml`; architectural precursors live in `_data/precursors.yml`. Human pages and files under `/data/` are generated from those sources. `_data/meta.yml` centralizes release and search dates.

Version 0.5.0 is the first public research-map release, dated October 18, 2026; the literature search was last refreshed against primary scholarly sources on September 5, 2026. The newest dated record found in that pass is September 3, 2026. The map aims for broad, useful coverage but does not claim that every relevant paper has been found. Citation exports describe arXiv preprints using their initial submission dates, separately from earlier chronology dates and later venue labels.

Each of the six method families has a crawlable guide under `/topics/` with its definition, guiding questions, and an oldest-first chronology. These pages and the paper explorer are generated from the same YAML corpus.

## Contributing

Use the public [paper-suggestion](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=paper.yml) and [correction](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=correction.yml) forms. The inclusion rule and required evidence are documented in [CONTRIBUTING.md](CONTRIBUTING.md).

## Local build

```sh
bundle install
bundle exec jekyll serve
```

## Acknowledgment

Initial paper discovery and reconciliation draw substantially on the independently maintained [Awesome-Latent-CoT bibliography](https://github.com/EIT-NLP/Awesome-Latent-CoT) and its associated survey, [Reasoning Beyond Language](https://arxiv.org/abs/2505.16782). We are grateful to its maintainers for assembling and continually updating a broad record of the field.

The site uses [Beautiful Jekyll](https://beautifuljekyll.com/) under its MIT license.

## License

Except where otherwise noted, original taxonomy, normalized curation metadata, summaries, and editorial material are available under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Underlying papers and third-party works remain under their own terms. Site code and the Beautiful Jekyll theme are covered by [LICENSE](LICENSE).

<https://latent-implicit-thinking.github.io/>
