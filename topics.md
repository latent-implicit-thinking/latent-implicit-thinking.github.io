---
layout: base
title: "Start here"
seo-title: "What Is Implicit Chain-of-Thought? Approaches and Papers"
share-description: "An introduction to reasoning without written steps: internalized reasoning, thinking tokens, continuous states, repeated computation, and how to test them."
permalink: /topics/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-18
---

<main class="lit-topic-page">
  <header class="lit-index-hero">
    <div class="lit-shell lit-narrow-shell">
      <h1>What is implicit chain-of-thought?</h1>
      <p>In an explicit chain of thought, a language model writes intermediate steps before its answer. Implicit chain-of-thought methods try to carry out some or all of those steps without expressing them as words. This research is also discussed as latent reasoning or latent chain-of-thought.</p>
      <p class="lit-history">Yuntian Deng and colleagues first proposed implicit chain-of-thought reasoning in <a href="https://arxiv.org/html/2311.01460v1#S2.SS3">2023</a>: training language models to reason through continuous hidden states rather than write out explicit intermediate steps. The paper's <a href="https://arxiv.org/html/2311.01460v1#S3">distillation method</a> is one implementation of that proposal. Their <a href="https://arxiv.org/abs/2405.14838">2024 work</a> introduced step-by-step internalization.</p>
      <p>The aim is not simply to hide a written explanation from the user. Researchers change how a model is trained or how it computes, then test whether it can solve problems without generating the full explanation.</p>
    </div>
  </header>

  <section class="lit-section lit-intro-example" aria-labelledby="example-title">
    <div class="lit-shell lit-narrow-shell">
      <h2 id="example-title">A simple example</h2>
      <p>Suppose the question is: “Three tickets cost $8 each, plus a $2 booking fee for the order. What is the total?”</p>
      <div class="lit-example-pair">
        <div><h3>With written steps</h3><p class="lit-example-output">“3 × 8 = 24 for the tickets. Adding the $2 fee gives $26.”</p></div>
        <div><h3>Without written steps</h3><p class="lit-example-output">“The total is $26.”</p></div>
      </div>
      <p>The shorter answer does not prove that the model reasoned internally. It could also have memorized the answer or used a shortcut. The papers below study ways to train and run models, and ways to test what actually happens inside them.</p>
    </div>
  </section>

  <section class="lit-section lit-start" aria-labelledby="approaches-title">
    <div class="lit-shell lit-narrow-shell">
      <div class="lit-section-heading">
        <h2 id="approaches-title">The main approaches</h2>
        <p>Start with any explanation that interests you. Each link leads to papers in date order.</p>
      </div>
      <div class="lit-taxonomy-items">
        {% for method in site.data.methods %}
        <article><span>{{ method.number }}</span><div><h3>{{ method.label }}</h3><p>{{ method.definition }}</p><a href="{{ method.url | relative_url }}">Example and papers →</a></div></article>
        {% endfor %}
      </div>
      <p class="lit-guide-note">A model might learn to replace written steps with vectors, then update those vectors by running the same layers several times. That paper can appear under internalized reasoning, continuous-state reasoning, and recurrent reasoning.</p>
    </div>
  </section>

  <section class="lit-section" aria-labelledby="reading-title">
    <div class="lit-shell lit-narrow-shell lit-reading-advice">
      <h2 id="reading-title">What to look for when reading a paper</h2>
      <ul>
        <li><strong>What changes?</strong> Look for the change to training or to the steps the model runs when answering. All neural networks have hidden states; using them does not by itself establish a new reasoning method.</li>
        <li><strong>What does it cost?</strong> Fewer output tokens can still mean more computation. Check for extra model passes, repeated layers, and changes in accuracy as well as speed.</li>
        <li><strong>What does the evidence show?</strong> Correct answers alone do not establish how a model solves a problem. Tests on new problems and experiments that alter internal states can help distinguish reasoning from shortcuts.</li>
      </ul>
      <p>The list also includes related generation methods and earlier background papers. Paper titles retain the authors' terminology.</p>
      <a class="lit-button lit-button-primary" href="{{ '/papers/' | relative_url }}">Browse all {{ site.data.papers | size }} papers</a>
    </div>
  </section>
</main>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "DefinedTermSet",
  "name": "Implicit Chain-of-Thought approaches",
  "description": "Explanations of approaches to implicit chain-of-thought and related research.",
  "url": {{ page.url | absolute_url | jsonify }},
  "hasDefinedTerm": [
    {% for method in site.data.methods %}{"@type": "DefinedTerm", "name": {{ method.label | jsonify }}, "description": {{ method.definition | jsonify }}, "url": {{ method.url | absolute_url | jsonify }}, "inDefinedTermSet": {{ page.url | absolute_url | jsonify }}}{% unless forloop.last %},{% endunless %}{% endfor %}
  ]
}
</script>
