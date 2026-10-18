---
layout: base
title: "Implicit Chain-of-Thought"
seo-title: "Implicit Chain-of-Thought Papers & Research Map"
share-title: "Implicit Chain-of-Thought — Papers and Research Map"
share-description: "A growing reading list on reasoning without written steps, with explanations of the main approaches and downloadable citations."
show-avatar: false
nav-short: true
last_modified_at: 2026-10-18
---

<main class="lit-home">
  <section class="lit-hero" aria-labelledby="lit-title">
    <div class="lit-shell">
      <p class="lit-eyebrow">Implicit chain-of-thought · A reading list</p>
      <h1 id="lit-title">Can language models reason without writing every intermediate step?</h1>
      <p class="lit-deck">An explicit chain of thought writes out intermediate steps. Implicit chain-of-thought methods try to do some or all of that work without putting each step into words.</p>
      <div class="lit-actions" aria-label="Choose how to use the guide">
        <a class="lit-button lit-button-primary" href="{{ '/papers/' | relative_url }}">Browse {{ site.data.papers | size }} papers</a>
        <a class="lit-button lit-button-secondary" href="{{ '/topics/' | relative_url }}">New here? Start here</a>
      </div>
      <p class="lit-demo-shortcuts">Try an example: {% for demo in site.data.demos %}<a href="{{ demo.url }}">{{ demo.label | escape }}</a>{% unless forloop.last %} · {% endunless %}{% endfor %}</p>
      <div class="lit-status" aria-label="Resource status">
        <span>Literature checked through {{ site.data.meta.search_refreshed_at | date: "%B %-d, %Y" }}</span>
        <a href="{{ '/recent/' | relative_url }}">Recent additions</a>
        <a href="{{ '/data/' | relative_url }}">Download the list and citations</a>
      </div>
    </div>
  </section>

  <section class="lit-section" id="map" aria-labelledby="map-title">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <h2 id="map-title">How do these methods work?</h2>
        <p>Some learn to skip written steps. Others add computation between words or reuse model layers. The list also covers related generation methods and studies of when these approaches work or fail.</p>
      </div>
      <div class="lit-route-grid">
        {% for method in site.data.methods %}
        <a href="{{ method.url | relative_url }}"><h3>{{ method.label }}</h3><p>{{ method.short_description }}</p><span class="lit-route-link">Explanation and papers →</span></a>
        {% endfor %}
      </div>
    </div>
  </section>

  <section class="lit-section lit-about" aria-labelledby="about-title">
    <div class="lit-shell lit-about-grid">
      <div>
        <h2 id="about-title">About this reading list</h2>
      </div>
      <div>
        <p>This reading list grew out of the <a href="{{ '/workshop/2026/' | relative_url }}">Latent &amp; Implicit Thinking workshop at ICLR 2026</a>. You can still find the workshop program and event information in the archive.</p>
        <p>Thanks to the <a href="https://github.com/EIT-NLP/Awesome-Latent-CoT">Awesome-Latent-CoT bibliography</a> and its associated survey, which helped us find many of these papers.</p>
        <p>The list may miss relevant work. <a href="{{ '/contribute/' | relative_url }}">Suggest a paper or correction</a>.</p>
      </div>
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
  "description": "A reading list with explanations, paper summaries, and citations for research on reasoning without written intermediate steps.",
  "inLanguage": "en",
  "about": {"@type": "Thing", "name": "Implicit chain-of-thought reasoning"},
  "hasPart": [
    {"@type": "CollectionPage", "name": "Implicit Chain-of-Thought paper index", "url": {{ '/papers/' | absolute_url | jsonify }}},
    {"@type": "Dataset", "name": "Implicit Chain-of-Thought research corpus", "url": {{ '/data/' | absolute_url | jsonify }}}
  ]
}
</script>
