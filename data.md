---
layout: base
title: "Downloads"
seo-title: "Implicit Chain-of-Thought Dataset, Citations & Schema"
share-description: "Download the paper list in JSON or Markdown and citations in BibTeX or CSL-JSON."
permalink: /data/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-19
---

<main class="lit-data-page">
  <header class="lit-index-hero">
    <div class="lit-shell lit-narrow-shell">
      <h1>Download the reading list</h1>
      <p>Get citations for your reference manager, a text copy to read, or JSON for research tools and agents. Every download uses the same paper list as the website.</p>
    </div>
  </header>

  <section class="lit-section">
    <div class="lit-shell lit-data-layout">
      <div>
        <p class="lit-eyebrow">Version</p>
        <div class="lit-release-number">v{{ site.data.meta.version }}</div>
        <p>{{ site.data.papers | size }} papers + {{ site.data.precursors | size }} background papers<br>Literature checked through {{ site.data.meta.search_refreshed_at | date: "%B %-d, %Y" }}</p>
      </div>
      <div class="lit-download-list">
        <a href="{{ '/data/papers.bib' | relative_url }}"><span><strong>Citations for LaTeX and reference managers</strong><small>papers.bib · Includes all papers and background papers</small></span><span>BibTeX ↗</span></a>
        <a href="{{ '/data/papers.csl.json' | relative_url }}"><span><strong>Citations in CSL-JSON</strong><small>papers.csl.json · For Zotero and other compatible tools</small></span><span>CSL-JSON ↗</span></a>
        <a href="{{ '/data/publications.bib' | relative_url }}"><span><strong>Published-version citations</strong><small>publications.bib · Conference and journal records available in this list</small></span><span>BibTeX ↗</span></a>
        <a href="{{ '/data/reading-list.md' | relative_url }}"><span><strong>The complete reading list as text</strong><small>reading-list.md · Explanations, summaries, authors, and links</small></span><span>Markdown ↗</span></a>
        <a href="{{ '/data/papers.json' | relative_url }}"><span><strong>Paper details for scripts and agents</strong><small>papers.json · Titles, authors, dates, categories, summaries, and links</small></span><span>JSON ↗</span></a>
      </div>
    </div>
  </section>

  <section class="lit-section lit-start lit-download-details">
    <div class="lit-shell lit-narrow-shell">
      <details class="lit-file-details">
        <summary>Using the JSON files in a script or agent</summary>
        <p>Start with <a href="{{ '/data/papers.json' | relative_url }}">papers.json</a>. It contains <code>papers</code>, <code>precursors</code> (the background papers), and <code>metadata</code>. The <a href="{{ '/llms.txt' | relative_url }}">agent guide</a> links to every file.</p>
        <p>The <a href="{{ '/data/navigation.json' | relative_url }}">JSON URL directory</a> lists this site's pages, downloads, and topic-specific files with their exact URLs. It distinguishes canonical pages from compatibility aliases.</p>
        <dl>
          <dt>Paper details</dt><dd><code>id</code> is a stable identifier. <code>author_names</code> preserves author order. <code>paper_url</code> links to the source; <code>record_url</code> links to an individual page with its own JSON, Markdown, BibTeX and CSL-JSON downloads. <code>legacy_record_url</code> preserves the earlier full-list anchor.</dd>
          <dt>Published versions</dt><dd>Optional <code>publication</code> metadata gives the conference or journal version, with its own title, authors, year and citation links.</dd>
          <dt>Demos</dt><dd>Optional <code>demos</code> link to interactive examples and model details. <code>relationship</code> distinguishes an <code>implementation</code> from a <code>related_method</code> example; <code>paper_relationships</code> names the associated papers.</dd>
          <dt>Dates</dt><dd><code>first_public</code> is the earliest dated public version we found, usually the first arXiv submission. <code>citation_date</code> is the linked source’s date: initial submission for an arXiv preprint, or publication for a DOI-only entry. Earlier conference presentations have a separate source note.</dd>
          <dt>Following additions</dt><dd><code>added_at</code> is when a paper joined this list, not when it was published. It is tracked for additions after the initial collection; initial records have no <code>added_at</code>. Filter this field to find new entries, including older papers we previously missed. Release history also lists <code>added_papers</code> by stable ID.</dd>
          <dt>Keeping a local copy current</dt><dd>Release history can identify <code>updated_papers</code> with changed fields and <code>removed_papers</code> by ID. The current JSON file is the authority for which entries are on the list.</dd>
          <dt>Categories and summaries</dt><dd><code>lens</code> lists approaches. Other fields describe training, computation, research questions, evidence, and modality. A paper can have several labels. Summaries and labels are written for this list.</dd>
          <dt>Sources</dt><dd><code>provenance</code> records where we found the paper. Use <code>paper_url</code> to check the paper itself.</dd>
        </dl>
        <p><a href="{{ '/data/ontology.json' | relative_url }}">Category definitions (ontology.json)</a> · <a href="{{ '/data/schema.json' | relative_url }}">Field types and allowed values (JSON Schema)</a> · <a href="{{ '/data/changes.json' | relative_url }}">Version history (JSON)</a></p>
      </details>
      <h2>Download one topic</h2>
      <ul>{% for method in site.data.methods %}<li>{{ method.label }}: <a href="{{ '/data/topics/' | append: method.slug | append: '.md' | relative_url }}">Markdown</a> · <a href="{{ '/data/topics/' | append: method.slug | append: '.json' | relative_url }}">JSON</a></li>{% endfor %}</ul>
      <p class="lit-guide-note">To follow updates, see <a href="{{ '/recent/' | relative_url }}">recent additions</a>, <a href="{{ '/feed.xml' | relative_url }}">subscribe to the RSS feed</a>, or <a href="{{ '/changelog/' | relative_url }}">read what changed</a>.</p>
    </div>
  </section>

  <section class="lit-section" id="citation">
    <div class="lit-shell lit-about-grid">
      <div><h2>Citing and reusing the list</h2></div>
      <div>
        <p>The complete <code>papers.bib</code> and <code>papers.csl.json</code> downloads cite each entry’s linked source: an arXiv preprint, or a publication when no arXiv version is listed. A separate <a href="{{ '/data/publications.bib' | relative_url }}">BibTeX file</a> and <a href="{{ '/data/publications.csl.json' | relative_url }}">CSL-JSON file</a> contain the available published-version records. Individual paper pages offer both choices where available. Cite the version you used.</p>
        <p>If you reuse our categories, summaries, or data, credit <em>Implicit Chain-of-Thought</em>, version {{ site.data.meta.version }} ({{ site.data.meta.updated_at | date: "%Y" }}), {{ site.data.meta.canonical_url }}, with your access date. Our original text and annotations are available under <a href="{{ '/license/' | relative_url }}">CC BY 4.0</a>. Papers, code, and other third-party material keep their own licenses.</p>
        <details class="lit-file-details"><summary>Date and citation-format details</summary><p>Dates usually refer to the first arXiv submission. Where an earlier presentation is documented, its date is shown separately from the linked arXiv submission date.</p><p>Source links are not pinned to an arXiv revision. Author names are kept in full and in order. CSL-JSON stores each full name as a literal string.</p></details>
        <p>Thanks to the <a href="https://github.com/EIT-NLP/Awesome-Latent-CoT">Awesome-Latent-CoT bibliography</a> and its associated survey, <a href="https://arxiv.org/abs/2505.16782"><em>Reasoning Beyond Language</em></a>, which helped us find many of these papers.</p>
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
  "description": "A bibliography and reading guide for implicit chain-of-thought research.",
  "creator": {% include dataset-creator.json %},
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
      "name": "Site URL directory",
      "contentUrl": {{ '/data/navigation.json' | absolute_url | jsonify }}
    },
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
