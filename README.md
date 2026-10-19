# Implicit Chain-of-Thought

A reading list about reasoning without writing every intermediate step, also discussed as latent reasoning or latent chain-of-thought.

[Visit the reading list](https://latent-implicit-thinking.github.io/).

Yuntian Deng and colleagues first proposed implicit chain-of-thought reasoning in [2023](https://arxiv.org/html/2311.01460v1#S2.SS3): training language models to reason through continuous hidden states rather than write out explicit intermediate steps. Their [2024 work](https://arxiv.org/abs/2405.14838) introduced step-by-step internalization.

- New to the field? [Start with explanations and concrete examples](https://latent-implicit-thinking.github.io/topics/).
- Looking for papers? [Browse the paper list](https://latent-implicit-thinking.github.io/papers/), search by author, title, method, or arXiv ID, and sort by publication date or when papers joined the list. Related background papers are listed separately.
- Using a reference manager or research agent? [Download the list and citations](https://latent-implicit-thinking.github.io/data/) in BibTeX, CSL-JSON, Markdown, or JSON.

The original [Latent & Implicit Thinking – Going Beyond CoT Reasoning workshop at ICLR 2026](https://latent-implicit-thinking.github.io/workshop/2026/) is preserved in the workshop archive.

## Papers and coverage

Paper entries live in `_data/papers.yml`; background papers live in `_data/precursors.yml`. The website and downloads under `/data/` are generated from those files. Each topic guide explains the approach, gives an example, and lists its papers oldest first.

The current literature-check date appears on the website and in the JSON metadata. [Recent additions](https://latent-implicit-thinking.github.io/recent/) shows papers added after the initial collection, including older omissions. The list is not exhaustive.

New records carry an `added_at` date, distinct from `first_public`. Initial-collection records omit `added_at`. Release history identifies additions by stable paper ID, and the RSS feed includes their titles and source links.

Every paper has a permanent page at `/papers/{arXiv-ID}/`, an individual JSON and Markdown record, and individual citation downloads. Earlier full-list anchors remain available. Topic-specific JSON and Markdown files provide smaller downloads with the same summaries and source-linked comparisons.

The complete citation downloads describe arXiv preprints using their initial submission dates. Separately verified publication records in `_data/publications.yml` provide an additional citation choice, with their own title, ordered authors, year and DOI where available. The published-version downloads contain only this verified subset; an absent record does not mean the paper is unpublished. Release history records additions, metadata updates and removals by ID.

## Contributing

[A paper link and a sentence](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=quick-paper.yml) are enough to suggest an addition. You can also [report a correction](https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=correction.yml). See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Local build

```sh
bundle install
bundle exec jekyll serve
```

## Acknowledgment

Thanks to the [Awesome-Latent-CoT bibliography](https://github.com/EIT-NLP/Awesome-Latent-CoT) and its associated survey, [Reasoning Beyond Language](https://arxiv.org/abs/2505.16782), which helped us find many of these papers.

The site uses [Beautiful Jekyll](https://beautifuljekyll.com/) under its MIT license.

## License

Our categories, summaries, and data are available under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Original papers and third-party works keep their own terms. Site code and the Beautiful Jekyll theme are covered by [LICENSE](LICENSE).
