---
layout: base
title: "Concepts & scope"
seo-title: "Implicit Chain-of-Thought: Concepts, Methods & Taxonomy"
share-description: "The terminology, method families, and comparison axes used by the Implicit Chain-of-Thought research map."
permalink: /topics/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-18
---

<main class="lit-topic-page">
  <header class="lit-index-hero">
    <div class="lit-shell lit-narrow-shell">
      <p class="lit-eyebrow">Concepts and scope</p>
      <h1>A practical map of implicit chain-of-thought</h1>
      <p>Implicit chain-of-thought (implicit CoT) studies intermediate reasoning that is not fully written out as natural language. Use these research directions and comparison axes to understand the field and find related work.</p>
      <p class="lit-terminology-note">Across the literature, related work may be labeled latent chain-of-thought, latent reasoning, continuous thought, hidden-state reasoning, or recurrent reasoning. This guide uses <strong>implicit chain-of-thought</strong> as the umbrella term while preserving each paper's terminology.</p>
    </div>
  </header>

  <section class="lit-section lit-start">
    <div class="lit-shell lit-taxonomy-grid">
      <div class="lit-taxonomy-intro">
        <p class="lit-eyebrow">For newcomers</p>
        <h2>Six ways into the field</h2>
        <p>These research lenses overlap: a continuous-state method might also use recurrence, distillation, reinforcement learning, and parallel computation.</p>
      </div>
      <div class="lit-taxonomy-items">
        {% for method in site.data.methods %}
        <article><span>{{ method.number }}</span><div><h3>{{ method.label }}</h3><p>{{ method.definition }}</p><a href="{{ method.url | relative_url }}">Open the {{ method.label | downcase }} guide →</a></div></article>
        {% endfor %}
      </div>
    </div>
  </section>

  <section class="lit-section">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <p class="lit-eyebrow">For systematic comparison</p>
        <h2>Six independent facets describe each paper</h2>
        <p>The taxonomy records what a paper studies and what kind of evidence it provides; it does not score the paper or presume that an implicit process is faithful.</p>
      </div>
      <div class="lit-facet-grid lit-facet-grid-six">
        <article><h3>Representation</h3><p>Hidden state · continuous state · learned discrete token · cache or memory · text–internal hybrid · multimodal state</p></article>
        <article><h3>Computation</h3><p>Depth-wise · token-wise · recurrent · stateful · hierarchical · parallel · diffusion · search</p></article>
        <article><h3>Training or adaptation</h3><p>Distillation · curriculum · supervised learning · reinforcement learning · self-training · pretraining · test-time optimization · inference-only</p></article>
        <article><h3>Research question</h3><p>Capability · efficiency · scaling · controllability · interpretability · theory · evaluation · limitations</p></article>
        <article><h3>Evidence</h3><p>Empirical result · probing · causal or mechanistic analysis · scaling result · formal result · boundary result · synthesis</p></article>
        <article><h3>Modality</h3><p>Language · symbolic or algorithmic · vision · multimodal</p></article>
      </div>
    </div>
  </section>

  <section class="lit-section lit-start">
    <div class="lit-shell lit-about-grid">
      <div><p class="lit-eyebrow">Scope boundaries</p><h2>Broad enough to connect; precise enough to be useful</h2></div>
      <div>
        <p>A paper belongs in the core map when it studies intermediate computation that substitutes for, compresses, internalizes, or changes the schedule of an explicit reasoning trace. General representation learning alone is not sufficient.</p>
        <p>Adjacent work is included in a separately labeled precursor section when it provides essential architectural or theoretical context. Ambiguous core records can carry several research lenses, and material corrections are recorded in the changelog.</p>
        <p><a class="lit-text-link" href="{{ '/contribute/' | relative_url }}">Read the inclusion policy or challenge a classification →</a></p>
      </div>
    </div>
  </section>
</main>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "DefinedTermSet",
  "name": "Implicit Chain-of-Thought method taxonomy",
  "description": "Six overlapping research directions used to organize research on implicit chain-of-thought.",
  "url": {{ page.url | absolute_url | jsonify }},
  "hasDefinedTerm": [
    {% for method in site.data.methods %}{"@type": "DefinedTerm", "name": {{ method.label | jsonify }}, "description": {{ method.definition | jsonify }}, "url": {{ method.url | absolute_url | jsonify }}, "inDefinedTermSet": {{ page.url | absolute_url | jsonify }}}{% unless forloop.last %},{% endunless %}{% endfor %}
  ]
}
</script>
