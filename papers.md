---
layout: base
title: "Explore papers"
seo-title: "Implicit Chain-of-Thought Papers: Searchable Research Index"
share-description: "Search the implicit chain-of-thought literature by method family, representation, computation, training, evidence, and research question."
permalink: /papers/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-22
js:
  - "/assets/js/lit-hub.js"
---

<main class="lit-index-page">
  <header class="lit-index-hero">
    <div class="lit-shell">
      <div class="lit-index-title-row">
        <div>
          <h1>Browse papers</h1>
          <p>Search by title, author, or topic. Read from oldest to newest, or sort by newest papers.</p>
          <p class="lit-index-freshness">Literature checked through {{ site.data.meta.search_refreshed_at | date: "%B %-d, %Y" }} · <a href="{{ '/recent/' | relative_url }}">Recent additions</a> · <a href="{{ '/contribute/' | relative_url }}">Suggest a paper</a></p>
        </div>
        <div class="lit-corpus-stat" aria-label="Corpus size">
          <strong>{{ site.data.papers | size }}</strong>
          <span>papers</span>
        </div>
      </div>
    </div>
  </header>

  <section class="lit-explorer" aria-label="Paper explorer">
    <div class="lit-shell">
      <div class="lit-explorer-toolbar">
        <div class="lit-search-wrap">
          <label for="paper-search">Search title, author, arXiv ID, venue, or method</label>
          <input id="paper-search" class="lit-search" type="search" placeholder="Try “internalized”, an author, or an arXiv ID…" autocomplete="off">
        </div>
        <div class="lit-sort-wrap">
          <label for="paper-sort">Sort</label>
          <select id="paper-sort" class="lit-sort">
            <option value="date-asc">First posted: oldest</option>
            <option value="date-desc">First posted: newest</option>
            <option value="added-desc">Added to this list: newest</option>
            <option value="title">Title</option>
          </select>
        </div>
      </div>

      <div class="lit-filter-bar lit-approach-filter" aria-label="Filter papers">
        <fieldset data-filter-set="lens">
          <legend>Approach</legend>
          <div class="lit-filter-options">
            <button type="button" class="lit-filter is-active" data-filter-value="all" aria-pressed="true">All</button>
            {% for method in site.data.methods %}<button type="button" class="lit-filter" data-filter-value="{{ method.id }}" aria-pressed="false">{{ method.label }}</button>{% endfor %}
          </div>
        </fieldset>
      </div>

      <details id="paper-advanced" class="lit-advanced-filters">
        <summary>More filters<span id="paper-advanced-count"></span></summary>
        <div class="lit-filter-bar lit-extra-filter-bar">
        <fieldset data-filter-set="question">
          <legend>Research question</legend>
          <div class="lit-filter-options">
            <button type="button" class="lit-filter is-active" data-filter-value="all" aria-pressed="true">All</button>
            <button type="button" class="lit-filter" data-filter-value="capability" aria-pressed="false">Capability</button>
            <button type="button" class="lit-filter" data-filter-value="efficiency" aria-pressed="false">Efficiency</button>
            <button type="button" class="lit-filter" data-filter-value="scaling" aria-pressed="false">Scaling</button>
            <button type="button" class="lit-filter" data-filter-value="controllability" aria-pressed="false">Controllability</button>
            <button type="button" class="lit-filter" data-filter-value="interpretability" aria-pressed="false">Interpretability</button>
            <button type="button" class="lit-filter" data-filter-value="theory" aria-pressed="false">Theory</button>
            <button type="button" class="lit-filter" data-filter-value="evaluation" aria-pressed="false">Evaluation</button>
            <button type="button" class="lit-filter" data-filter-value="limitations" aria-pressed="false">Limitations</button>
            <button type="button" class="lit-filter" data-filter-value="architecture" aria-pressed="false">Architecture</button>
            <button type="button" class="lit-filter" data-filter-value="generalization" aria-pressed="false">Generalization</button>
            <button type="button" class="lit-filter" data-filter-value="survey" aria-pressed="false">Survey</button>
            <button type="button" class="lit-filter" data-filter-value="taxonomy" aria-pressed="false">Classifications</button>
          </div>
        </fieldset>
        <fieldset data-filter-set="evidence">
          <legend>Type of study</legend>
          <div class="lit-filter-options">
            <button type="button" class="lit-filter is-active" data-filter-value="all" aria-pressed="true">All</button>
            <button type="button" class="lit-filter" data-filter-value="empirical" aria-pressed="false">Experiments</button>
            <button type="button" class="lit-filter" data-filter-value="formal" aria-pressed="false">Proofs and theory</button>
            <button type="button" class="lit-filter" data-filter-value="mechanistic" aria-pressed="false">Internal mechanisms</button>
            <button type="button" class="lit-filter" data-filter-value="boundary" aria-pressed="false">Limits and counterexamples</button>
            <button type="button" class="lit-filter" data-filter-value="survey" aria-pressed="false">Surveys</button>
            <button type="button" class="lit-filter" data-filter-value="probing" aria-pressed="false">Hidden-state probes</button>
            <button type="button" class="lit-filter" data-filter-value="scaling" aria-pressed="false">Scaling studies</button>
          </div>
        </fieldset>
        </div>
        <p class="lit-filter-help">“Internal mechanisms” covers experiments on how model components affect an answer. “Hidden-state probes” test what information can be read from internal states. Papers can have several labels.</p>
        <div class="lit-advanced-filter-grid">
          <label>Representation
            <select data-filter-select="representation">
              <option value="all">All representations</option>
              <option value="hidden-state">Hidden state</option>
              <option value="continuous-state">Continuous state</option>
              <option value="discrete-token">Discrete or learned token</option>
              <option value="text-latent-hybrid">Text–internal hybrid</option>
              <option value="cache-memory">Cache or memory</option>
              <option value="multimodal-latent">Multimodal state</option>
              <option value="survey">Survey</option>
            </select>
          </label>
          <label>Computation
            <select data-filter-select="computation">
              <option value="all">All computation</option>
              <option value="depth-wise">Depth-wise</option>
              <option value="token-wise">Token-wise</option>
              <option value="recurrent">Recurrent</option>
              <option value="stateful">Stateful</option>
              <option value="parallel">Parallel</option>
              <option value="diffusion">Diffusion</option>
              <option value="hierarchical">Hierarchical</option>
              <option value="search">Search</option>
              <option value="survey">Survey</option>
            </select>
          </label>
          <label>Training or adaptation
            <select data-filter-select="training">
              <option value="all">All training</option>
              <option value="distillation">Distillation</option>
              <option value="curriculum">Curriculum</option>
              <option value="supervised">Supervised</option>
              <option value="reinforcement-learning">Reinforcement learning</option>
              <option value="self-distillation">Self-distillation</option>
              <option value="self-training">Self-training</option>
              <option value="pretraining">Pretraining</option>
              <option value="test-time-optimization">Test-time optimization</option>
              <option value="inference-only">Inference only</option>
              <option value="analysis-only">Analysis only</option>
            </select>
          </label>
          <label>Modality
            <select data-filter-select="modality">
              <option value="all">All modalities</option>
              <option value="language">Language</option>
              <option value="symbolic">Symbolic or algorithmic</option>
              <option value="vision">Vision</option>
              <option value="multimodal">Multimodal</option>
            </select>
          </label>
        </div>
      </details>

      <div class="lit-results-heading">
        <p id="paper-result-count" role="status" aria-live="polite">Showing {{ site.data.papers | size }} papers</p>
        <div><a class="lit-reset" href="{{ '/data/' | relative_url }}">Download citations</a><button id="paper-share" class="lit-reset" type="button" aria-live="polite">Copy link to results</button><button id="paper-reset" class="lit-reset" type="button">Reset filters</button></div>
      </div>

      <div id="paper-list" class="lit-paper-list">
        {% for paper in site.data.papers %}
        {% capture lens_labels %}{% for value in paper.lens %}{% case value %}{% when 'internalized' %}internalized reasoning{% when 'learned-tokens' %}thinking tokens learned tokens{% when 'continuous' %}continuous states{% when 'recurrent' %}recurrent stateful{% when 'beyond-sequential' %}alternative schedules beyond sequential{% when 'analysis' %}analysis evaluation limits{% endcase %} {% endfor %}{% endcapture %}
        {% assign publication = site.data.publications[paper.id] %}
        {% capture searchable %}{{ paper.id }} {% if paper.arxiv %}arXiv:{{ paper.arxiv }}{% else %}DOI:{{ paper.doi }}{% endif %} {{ paper.venue }} {{ paper.title }} {{ paper.previous_titles | join: ' ' }} {{ paper.related_terms | join: ' ' }} {{ paper.authors }} {{ paper.summary }} {{ paper.lens | join: ' ' }} {{ lens_labels }} {% for value in paper.lens %}{% assign category = site.data.methods | where: "id", value | first %}{{ category.label }} {% endfor %} {{ paper.representation | join: ' ' }} {{ paper.computation | join: ' ' }} {{ paper.training | join: ' ' }} {{ paper.questions | join: ' ' }} {{ paper.evidence | join: ' ' }} {{ paper.modality | join: ' ' }}{% endcapture %}
        <article
          id="paper-{{ paper.id | replace: '.', '-' }}"
          class="lit-paper-row"
          data-paper-id="{{ paper.id }}"
          data-search="{{ searchable | downcase | escape }}"
          data-lens="{{ paper.lens | join: ' ' }}"
          data-question="{{ paper.questions | join: ' ' }}"
          data-evidence="{{ paper.evidence | join: ' ' }}"
          data-modality="{{ paper.modality | join: ' ' }}"
          data-representation="{{ paper.representation | join: ' ' }}"
          data-computation="{{ paper.computation | join: ' ' }}"
          data-training="{{ paper.training | join: ' ' }}"
          data-date="{{ paper.first_public }}"
          data-added="{{ paper.added_at }}"
          data-title="{{ paper.title | downcase | escape }}"
        >
          <div class="lit-paper-meta">
            <time datetime="{{ paper.first_public }}">{{ paper.first_public | date: "%b %Y" }}</time>
            <span>{{ paper.venue }}</span>
            {% if paper.added_at %}<span>Added {{ paper.added_at | date: "%b %-d, %Y" }}</span>{% endif %}
          </div>
          <div class="lit-paper-main">
            <h2><a href="{{ paper.paper_url }}">{{ paper.title }}</a></h2>
            <p class="lit-paper-authors">{{ paper.authors }}</p>
            <p class="lit-paper-summary">{{ paper.summary }}</p>
            {% if paper.related_terms %}<p class="lit-guide-note">Related terms: {{ paper.related_terms | join: ', ' | escape }}.</p>{% endif %}
            {% if paper.first_public_note %}<details class="lit-date-details"><summary>About this date</summary><p><a href="{{ paper.first_public_source }}">Date source</a>: {{ paper.first_public_note }}{% if paper.arxiv %} Linked arXiv version: {{ paper.citation_date | date: "%B %-d, %Y" }}.{% endif %}</p></details>{% endif %}
            <div class="lit-paper-tags" aria-label="Approaches">
              {% for value in paper.lens %}{% assign category = site.data.methods | where: "id", value | first %}<span>{{ category.label }}</span>{% endfor %}
            </div>
          </div>
          <div class="lit-paper-actions">
            <a href="{{ paper.paper_url }}">Paper ↗</a>
            {% if paper.arxiv %}<a href="https://arxiv.org/pdf/{{ paper.arxiv }}">PDF ↗</a>{% endif %}
            {% if paper.html_url %}<a href="{{ paper.html_url }}">HTML ↗</a>{% endif %}
            {% if paper.code_url %}<a href="{{ paper.code_url }}">Code ↗</a>{% endif %}
            <a class="lit-record-link" href="{{ '/papers/' | append: paper.id | append: '/' | relative_url }}" aria-label="Details and citations for {{ paper.title | escape }}">Details &amp; citations</a>
            {% if paper.arxiv %}<span>arXiv:{{ paper.arxiv }}</span>{% elsif paper.doi %}<span>DOI:{{ paper.doi }}</span>{% endif %}
          </div>
        </article>
        {% endfor %}
      </div>

      <div id="paper-empty" class="lit-empty" hidden>
        <h2>No papers match these filters</h2>
        <p>Try another search, reset the filters, or <a href="{{ '/contribute/' | relative_url }}">suggest a missing paper</a>.</p>
      </div>
    </div>
  </section>

  <aside class="lit-source-note">
    <div class="lit-shell">
      <p><strong>Download citations:</strong> <a href="{{ '/data/papers.bib' | relative_url }}">BibTeX</a> · <a href="{{ '/data/papers.csl.json' | relative_url }}">CSL-JSON</a>. These files cite each entry’s linked source. <a href="{{ '/data/#citation' | relative_url }}">Citation details →</a></p>
      <p><a href="{{ '/contribute/' | relative_url }}">Suggest a paper or correction</a>. Thanks to the <a href="https://github.com/EIT-NLP/Awesome-Latent-CoT">Awesome-Latent-CoT bibliography</a> and its associated survey for helping us find many of these papers.</p>
    </div>
  </aside>

  <section class="lit-section" aria-labelledby="precursor-title">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <h2 id="precursor-title">Related background papers</h2>
        <p>Earlier work on repeated computation, deciding when to stop, and learning algorithms.</p>
      </div>
      <div class="lit-precursor-list">
        {% for paper in site.data.precursors %}
        <article id="precursor-{{ paper.id | replace: '.', '-' }}">
          <div><time datetime="{{ paper.first_public }}">{{ paper.first_public | date: "%Y" }}</time><span>Context</span></div>
          <div><h3><a href="{{ paper.paper_url }}">{{ paper.title }}</a></h3><p class="lit-paper-authors">{{ paper.authors }}</p><p>{{ paper.connection }}</p>{% assign precursor_arxiv_id = paper | lit_arxiv_id %}{% if precursor_arxiv_id %}<a href="https://arxiv.org/pdf/{{ precursor_arxiv_id }}">PDF ↗</a> · {% endif %}<a href="{{ '/papers/' | append: paper.id | append: '/' | relative_url }}">Details &amp; citations</a></div>
        </article>
        {% endfor %}
      </div>
    </div>
  </section>
</main>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "CollectionPage",
  "name": "Implicit Chain-of-Thought Papers: Searchable Research Index",
  "description": "A searchable, chronological index of implicit chain-of-thought research papers.",
  "url": {{ page.url | absolute_url | jsonify }},
  "isPartOf": {"@type": "WebSite", "name": "Implicit Chain-of-Thought", "url": {{ '/' | absolute_url | jsonify }}},
  "mainEntity": {
    "@type": "ItemList",
    "numberOfItems": {{ site.data.papers | size }},
    "itemListOrder": "https://schema.org/ItemListOrderAscending",
    "itemListElement": [
      {% for paper in site.data.papers %}{"@type": "ListItem", "position": {{ forloop.index }}, "item": {% include scholarly-article.json paper=paper %}}{% unless forloop.last %},{% endunless %}{% endfor %}
    ]
  }
}
</script>
