---
layout: base
title: "Implicit Chain-of-Thought"
seo-title: "Implicit Chain-of-Thought Papers & Research Map"
share-title: "Implicit Chain-of-Thought — Papers and Research Map"
share-description: "A living map of 108 papers on how language models reason without writing every intermediate step."
show-avatar: false
nav-short: true
last_modified_at: 2026-10-18
---

<main class="lit-home">
  <section class="lit-hero" aria-labelledby="lit-title">
    <div class="lit-shell">
      <p class="lit-eyebrow">Implicit chain-of-thought · A living map of {{ site.data.papers | size }} papers</p>
      <h1 id="lit-title">Can language models reason without writing every intermediate step?</h1>
      <p class="lit-deck">Explore {{ site.data.papers | size }} papers across six research directions—from internalized reasoning and thinking tokens to continuous states, recurrence, alternative schedules, and evaluation.</p>
      <div class="lit-actions" aria-label="Choose how to use the guide">
        <a class="lit-button lit-button-primary" href="{{ '/papers/' | relative_url }}">Explore {{ site.data.papers | size }} papers</a>
        <a class="lit-button lit-button-secondary" href="#map">New here? Start with the map</a>
      </div>
      <div class="lit-status" aria-label="Resource status">
        <span>{{ site.data.papers | size }} curated papers</span>
        <span>Search refreshed {{ site.data.meta.search_refreshed_at | date: "%b %-d, %Y" }}</span>
        <span>Newest record {{ site.data.meta.latest_included_first_public | date: "%b %-d, %Y" }}</span>
        <span>JSON, BibTeX, and schema</span>
      </div>
    </div>
  </section>

  <section class="lit-entryways" aria-label="Ways to use the resource">
    <div class="lit-shell lit-three-up">
      <a class="lit-entry" href="{{ '/topics/' | relative_url }}">
        <span class="lit-entry-number">01 · For newcomers</span>
        <h2>Learn the landscape</h2>
        <p>Start with a plain-language map of the main approaches, questions, and scope boundaries.</p>
        <span class="lit-text-link">Open the concepts guide →</span>
      </a>
      <a class="lit-entry" href="{{ '/papers/?sort=date-desc' | relative_url }}">
        <span class="lit-entry-number">02 · For active researchers</span>
        <h2>Find the relevant work</h2>
        <p>Search and filter by approach, research question, evidence, title, author, or date.</p>
        <span class="lit-text-link">Browse newest first →</span>
      </a>
      <a class="lit-entry" href="{{ '/data/' | relative_url }}">
        <span class="lit-entry-number">03 · For research agents &amp; builders</span>
        <h2>Use it without scraping</h2>
        <p>Stable records, an explicit ontology, citation exports, provenance, and release history.</p>
        <span class="lit-text-link">Open machine-readable data →</span>
      </a>
    </div>
  </section>

  <section class="lit-section" id="map" aria-labelledby="map-title">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <p class="lit-eyebrow">The field in 30 seconds</p>
        <h2 id="map-title">Four overlapping ways to move reasoning beyond written steps</h2>
        <p>These are lenses, not mutually exclusive boxes. Many papers combine several of them, while analysis and evaluation cut across every branch.</p>
      </div>
      <div class="lit-field-map">
        <article>
          <span class="lit-map-marker">A</span>
          <h3>Internalize an explicit trace</h3>
          <p>Learn from readable reasoning, then transfer some or all intermediate steps into internal computation.</p>
        </article>
        <article>
          <span class="lit-map-marker">B</span>
          <h3>Change the representation</h3>
          <p>Compute through hidden states, continuous thoughts, learned tokens, compressed memories, or hybrids.</p>
        </article>
        <article>
          <span class="lit-map-marker">C</span>
          <h3>Add recurrent or stateful compute</h3>
          <p>Spend more computation through repeated depth, dynamic halting, memory, or key/value-cache state.</p>
        </article>
        <article>
          <span class="lit-map-marker">D</span>
          <h3>Change the schedule</h3>
          <p>Explore parallel, diffusion-based, hierarchical, and other alternatives to left-to-right reasoning.</p>
        </article>
      </div>
    </div>
  </section>

  <section class="lit-section lit-start" aria-labelledby="routes-title">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <p class="lit-eyebrow">Choose an entry point</p>
        <h2 id="routes-title">Follow the question you care about</h2>
        <p>Choose a research direction, then read its papers in chronological order.</p>
      </div>
      <div class="lit-route-grid">
        {% for method in site.data.methods %}
        <a href="{{ method.url | relative_url }}"><span>{{ method.number }}</span><h3>{{ method.label }}</h3><p>{{ method.question }}</p></a>
        {% endfor %}
      </div>
      <div class="lit-history-callout">
        <div><p class="lit-eyebrow">Prefer the historical view?</p><h3>Follow the dated record of the research.</h3></div>
        <a class="lit-text-link" href="{{ '/papers/?sort=date-asc' | relative_url }}">Browse the full chronology →</a>
      </div>
    </div>
  </section>

  <section class="lit-section lit-about" aria-labelledby="about-title">
    <div class="lit-shell lit-about-grid">
      <div>
        <p class="lit-eyebrow">From workshop to research guide</p>
        <h2 id="about-title">A shared reference with visible provenance</h2>
      </div>
      <div>
        <p>This map grew out of the <a href="{{ '/workshop/2026/' | relative_url }}">Latent &amp; Implicit Thinking workshop at ICLR 2026</a>. The event pages remain available as an archive while the literature guide is maintained through an open correction and contribution process.</p>
        <p class="lit-acknowledgment"><strong>Acknowledgment.</strong> Initial paper discovery and reconciliation draw substantially on the independently maintained <a href="https://github.com/EIT-NLP/Awesome-Latent-CoT">Awesome-Latent-CoT bibliography</a> and its associated survey. We are grateful to its maintainers for assembling and updating a broad record of the literature.</p>
      </div>
    </div>
  </section>

  <section class="lit-contribute-band" aria-labelledby="contribute-title">
    <div class="lit-shell">
      <div><p class="lit-eyebrow">Keep the map useful</p><h2 id="contribute-title">Missing paper, incorrect date, or debatable classification?</h2></div>
      <a class="lit-button lit-button-primary" href="{{ '/contribute/' | relative_url }}">Suggest a change</a>
    </div>
  </section>
</main>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Implicit Chain-of-Thought",
  "alternateName": ["Implicit CoT Research Map", "Implicit Chain-of-Thought Papers"],
  "url": {{ '/' | absolute_url | jsonify }},
  "description": "A living research map of papers on reasoning without written intermediate steps.",
  "inLanguage": "en",
  "about": {"@type": "Thing", "name": "Implicit chain-of-thought reasoning"},
  "hasPart": [
    {"@type": "CollectionPage", "name": "Implicit Chain-of-Thought paper index", "url": {{ '/papers/' | absolute_url | jsonify }}},
    {"@type": "Dataset", "name": "Implicit Chain-of-Thought research corpus", "url": {{ '/data/' | absolute_url | jsonify }}}
  ]
}
</script>
