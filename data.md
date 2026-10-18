---
layout: base
title: "Data access"
seo-title: "Implicit Chain-of-Thought Dataset, Citations & Schema"
share-description: "Machine-readable papers, terminology, schema, citation exports, and provenance for the Implicit Chain-of-Thought research map."
permalink: /data/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-18
---

<main class="lit-data-page">
  <header class="lit-index-hero">
    <div class="lit-shell lit-narrow-shell">
      <p class="lit-eyebrow">For researchers and research agents</p>
      <h1>Use the implicit CoT map without scraping it</h1>
      <p>The human pages and machine-readable files share one corpus and one research ontology. Stable identifiers, definitions, provenance, search dates, and versioned changes are part of the resource.</p>
    </div>
  </header>

  <section class="lit-section">
    <div class="lit-shell lit-data-layout">
      <div>
        <p class="lit-eyebrow">Current release</p>
        <div class="lit-release-number">v{{ site.data.meta.version }}</div>
        <p>{{ site.data.papers | size }} core papers + {{ site.data.precursors | size }} precursors<br>Search refreshed {{ site.data.meta.search_refreshed_at | date: "%B %-d, %Y" }}<br>Newest included record {{ site.data.meta.latest_included_first_public | date: "%B %-d, %Y" }}</p>
      </div>
      <div class="lit-download-list">
        <a href="{{ '/data/papers.json' | relative_url }}"><span><strong>papers.json</strong><small>Versioned corpus, metadata, and precursors</small></span><span>JSON ↗</span></a>
        <a href="{{ '/data/ontology.json' | relative_url }}"><span><strong>ontology.json</strong><small>Concept definitions, scope, and comparison axes</small></span><span>JSON ↗</span></a>
        <a href="{{ '/data/papers.bib' | relative_url }}"><span><strong>papers.bib</strong><small>Core-paper and precursor citation import</small></span><span>BibTeX ↗</span></a>
        <a href="{{ '/data/papers.csl.json' | relative_url }}"><span><strong>papers.csl.json</strong><small>Preprint citations with ordered author names and initial submission dates</small></span><span>CSL-JSON ↗</span></a>
        <a href="{{ '/data/reading-list.md' | relative_url }}"><span><strong>reading-list.md</strong><small>Plain-text guide, research directions, and full chronological list</small></span><span>Markdown ↗</span></a>
        <a href="{{ '/data/schema.json' | relative_url }}"><span><strong>schema.json</strong><small>Field definitions and constraints</small></span><span>JSON Schema ↗</span></a>
        <a href="{{ '/data/changes.json' | relative_url }}"><span><strong>changes.json</strong><small>Release-level change history</small></span><span>JSON ↗</span></a>
        <a href="{{ '/feed.xml' | relative_url }}"><span><strong>Release feed</strong><small>Subscribe to corpus and taxonomy updates</small></span><span>RSS ↗</span></a>
        <a href="{{ '/changelog/' | relative_url }}"><span><strong>Changelog</strong><small>Human-readable release notes</small></span><span>HTML ↗</span></a>
        <a href="{{ '/license/' | relative_url }}"><span><strong>Content and data license</strong><small>Reuse terms for curation metadata and editorial material</small></span><span>CC BY 4.0 ↗</span></a>
      </div>
    </div>
  </section>

  <section class="lit-section lit-start">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <p class="lit-eyebrow">Data contract</p>
        <h2>Facts and editorial judgments stay distinguishable</h2>
        <p>Identity and date fields point back to scholarly sources. Curated summaries and facets are editorial annotations created for this map. Every core paper record includes discovery provenance, evidence type, and modality.</p>
      </div>
      <div class="lit-facet-grid">
        <article><h3>Identity</h3><p><code>id</code>, exact title, ordered <code>author_names</code>, venue, arXiv identifier, original paper URL, and a stable <code>record_url</code> in this map.</p></article>
        <article><h3>Time</h3><p><code>first_public</code> dates the earliest public version verified during curation, usually using the arXiv v1 submission date. <code>citation_date</code> is the preprint's initial arXiv submission date; earlier conference history is recorded separately.</p></article>
        <article><h3>Facets</h3><p>Method family, representation, computation, training signal, research question, evidence, and modality are multi-valued.</p></article>
        <article><h3>Editorial layer</h3><p>The one-sentence summary is a neutral description written for this guide, not copied from the abstract.</p></article>
        <article><h3>Concepts</h3><p><code>ontology.json</code> gives agents definitions, scope rules, date policy, research lenses, and allowed axis values.</p></article>
        <article><h3>Provenance</h3><p><code>provenance</code> records the bibliography or source through which a candidate entered the reconciliation process.</p></article>
      </div>
    </div>
  </section>

  <section class="lit-section" id="citation">
    <div class="lit-shell lit-about-grid">
      <div><p class="lit-eyebrow">Citation and acknowledgment</p><h2>Credit papers and resources precisely</h2></div>
      <div>
        <p>For scientific claims, cite the original papers. The BibTeX and CSL-JSON files cite <strong>arXiv preprints using their initial submission dates</strong>, not later proceedings. Source URLs are not version-pinned; check the original source when citing a specific version or result. Ordered author names are preserved in full; the CSL export does not guess how to split given and family names.</p>
        <p>Chronology uses dated source records, usually arXiv v1 submission dates. These are not independently verified public-announcement timestamps. Earlier conference presentations carry a separate source note.</p>
        <p>When the curation, taxonomy, or normalized metadata is itself used, cite: <strong><em>Implicit Chain-of-Thought Research Map</em>, version {{ site.data.meta.version }} ({{ site.data.meta.updated_at | date: "%Y" }}), {{ site.data.meta.canonical_url }}</strong>, with your access date.</p>
        <p>Original curation metadata, taxonomy, and editorial material are available under <a href="{{ '/license/' | relative_url }}">CC BY 4.0</a>; underlying papers, code, and third-party materials remain under their own terms.</p>
        <p>Initial discovery and reconciliation draw substantially on the <a href="https://github.com/EIT-NLP/Awesome-Latent-CoT">Awesome-Latent-CoT bibliography</a> maintained by the authors of <a href="https://arxiv.org/abs/2505.16782"><em>Reasoning Beyond Language</em></a>. We gratefully acknowledge that work in the site, corpus provenance, and release notes.</p>
        <p><a class="lit-text-link" href="{{ '/contribute/' | relative_url }}">Suggest a paper or report a correction →</a></p>
      </div>
    </div>
  </section>
</main>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Dataset",
  "name": "Implicit Chain-of-Thought Research Map",
  "alternateName": ["Implicit CoT paper corpus", "Implicit Chain-of-Thought literature map"],
  "description": "A curated, structured corpus and reading guide for research on implicit chain-of-thought.",
  "url": {{ page.url | absolute_url | jsonify }},
  "sameAs": {{ site.data.meta.repository_url | jsonify }},
  "license": {{ site.data.meta.license_url | jsonify }},
  "isAccessibleForFree": true,
  "keywords": ["implicit chain-of-thought", "implicit reasoning", "internalized reasoning", "continuous chain-of-thought", "recurrent reasoning", "language models"],
  "dateModified": {{ site.data.meta.updated_at | jsonify }},
  "version": {{ site.data.meta.version | jsonify }},
  "distribution": [
    {
      "@type": "DataDownload",
      "encodingFormat": "application/json",
      "name": "Paper corpus",
      "contentUrl": {{ '/data/papers.json' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "application/json",
      "name": "Research ontology",
      "contentUrl": {{ '/data/ontology.json' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "application/schema+json",
      "name": "JSON Schema",
      "contentUrl": {{ '/data/schema.json' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "application/x-bibtex",
      "name": "BibTeX export",
      "contentUrl": {{ '/data/papers.bib' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "application/vnd.citationstyles.csl+json",
      "name": "CSL-JSON citations",
      "contentUrl": {{ '/data/papers.csl.json' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "text/markdown",
      "name": "Markdown reading list",
      "contentUrl": {{ '/data/reading-list.md' | absolute_url | jsonify }}
    },
    {
      "@type": "DataDownload",
      "encodingFormat": "application/json",
      "name": "Release history",
      "contentUrl": {{ '/data/changes.json' | absolute_url | jsonify }}
    }
  ],
  "isBasedOn": "https://github.com/EIT-NLP/Awesome-Latent-CoT"
}
</script>
