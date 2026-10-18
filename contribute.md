---
layout: base
title: "Contribute"
share-description: "Suggest a paper or report a correction to the Implicit Chain-of-Thought research map."
permalink: /contribute/
last_modified_at: 2026-10-18
show-avatar: false
nav-short: true
---

<main class="lit-contribute-page">
  <header class="lit-index-hero">
    <div class="lit-shell lit-narrow-shell">
      <p class="lit-eyebrow">Open curation</p>
      <h1>Help keep the map accurate</h1>
      <p>Suggest a missing paper, correct a record, or challenge a classification. Every proposal should point to a public scholarly source so the change can be checked.</p>
      <div class="lit-actions">
        <a class="lit-button lit-button-primary" href="https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=paper.yml">Suggest a paper</a>
        <a class="lit-button lit-button-secondary" href="https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=correction.yml">Report a correction</a>
      </div>
      <p class="lit-quick-contribute">Short on time? <a href="https://github.com/latent-implicit-thinking/latent-implicit-thinking.github.io/issues/new?template=quick-paper.yml">Drop a scholarly link and one sentence</a>.</p>
    </div>
  </header>

  <section class="lit-section">
    <div class="lit-shell lit-contribution-grid">
      <article>
        <p class="lit-eyebrow">What belongs</p>
        <h2>Core inclusion rule</h2>
        <p>A paper belongs in the core map when it studies intermediate computation that substitutes for, compresses, internalizes, or changes the schedule of an explicit reasoning trace.</p>
        <p>General representation learning, recurrence, memory, or diffusion alone is not sufficient. Adjacent work is included when it provides an essential precursor, comparison, evaluation, or theoretical explanation.</p>
      </article>
      <article>
        <p class="lit-eyebrow">What to provide</p>
        <h2>Enough evidence to verify it</h2>
        <ul class="lit-check-list">
          <li>Canonical title and author list</li>
          <li>Earliest public version and date</li>
          <li>ArXiv, OpenReview, proceedings, or official project URL</li>
          <li>A sentence explaining the connection to implicit chain-of-thought</li>
          <li>Code URL when one is publicly verified</li>
        </ul>
      </article>
      <article>
        <p class="lit-eyebrow">How decisions work</p>
        <h2>Transparent rather than automatic</h2>
        <p>Suggestions are checked against the published scope and source record. Editorial summaries and facets may change during review. Disputed classifications can carry multiple labels or be documented in the changelog.</p>
        <p>The map is maintained by <a href="https://yuntiandeng.com/">Yuntian Deng</a>.</p>
        <p>For private corrections, email <a href="mailto:latent-implicit-thinking@googlegroups.com?subject=Implicit%20CoT%20map%20correction">the workshop contact address</a>.</p>
      </article>
    </div>
  </section>

  <section class="lit-contribute-band">
    <div class="lit-shell">
      <div><p class="lit-eyebrow">Before submitting</p><h2>Check the paper explorer to avoid duplicate suggestions.</h2></div>
      <a class="lit-button lit-button-primary" href="{{ '/papers/' | relative_url }}">Search the corpus</a>
    </div>
  </section>
</main>
