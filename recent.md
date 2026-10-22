---
layout: base
title: "Recent additions"
seo-title: "Recent Additions to the Implicit Chain-of-Thought Reading List"
share-description: "See which papers have joined the implicit chain-of-thought reading list, with summaries, authors, and links to the original papers."
permalink: /recent/
show-avatar: false
nav-short: true
last_modified_at: 2026-10-22
---

{% assign tracked_papers = site.data.papers | where_exp: "paper", "paper.added_at" | reverse %}
{% assign additions = tracked_papers | group_by: "added_at" | sort: "name" | reverse %}
<main class="lit-recent-page">
  <header class="lit-index-hero">
    <div class="lit-shell">
      <h1>Recent additions</h1>
      <p>Papers added to this reading list since the initial collection. Some are new research; others are older work we missed.</p>
      <p class="lit-index-freshness">Literature checked through {{ site.data.meta.search_refreshed_at | date: "%B %-d, %Y" }} · <a href="{{ '/papers/?sort=date-desc' | relative_url }}">Sort all papers by publication date</a> · <a href="{{ '/feed.xml' | relative_url }}">Follow by RSS</a></p>
    </div>
  </header>

  {% for group in additions %}
  <section class="lit-section" aria-labelledby="added-{{ group.name }}">
    <div class="lit-shell">
      <div class="lit-section-heading">
        <h2 id="added-{{ group.name }}">Added {{ group.name | date: "%B %-d, %Y" }}</h2>
        {% assign addition_count = group.items | size %}<p>{{ addition_count }} paper{% unless addition_count == 1 %}s{% endunless %} · Newest research first within this update</p>
      </div>
      <div class="lit-paper-list">
        {% for paper in group.items %}
        <article class="lit-paper-row" data-paper-id="{{ paper.id }}" data-added="{{ paper.added_at }}">
          <div class="lit-paper-meta">
            <span>First posted</span>
            <time datetime="{{ paper.first_public }}">{{ paper.first_public | date: "%b %-d, %Y" }}</time>
            <span>{{ paper.venue }}</span>
          </div>
          <div class="lit-paper-main">
            <h3><a href="{{ paper.paper_url }}">{{ paper.title | escape }}</a></h3>
            <p class="lit-paper-authors">{{ paper.authors | escape }}</p>
            <p class="lit-paper-summary">{{ paper.summary | escape }}</p>
            <div class="lit-paper-tags" aria-label="Approaches">
              {% for value in paper.lens %}{% assign category = site.data.methods | where: "id", value | first %}<span>{{ category.label }}</span>{% endfor %}
            </div>
          </div>
          <div class="lit-paper-actions">
            <a href="{{ paper.paper_url }}">Paper ↗</a>
            {% if paper.arxiv %}<a href="https://arxiv.org/pdf/{{ paper.arxiv }}">PDF ↗</a>{% endif %}
            {% if paper.html_url %}<a href="{{ paper.html_url }}">HTML ↗</a>{% endif %}
            {% if paper.code_url %}<a href="{{ paper.code_url }}">Code ↗</a>{% endif %}
            <a href="{{ '/papers/' | append: paper.id | append: '/' | relative_url }}">Details &amp; citations</a>
            {% if paper.arxiv %}<span>arXiv:{{ paper.arxiv }}</span>{% else %}<span>DOI:{{ site.data.publications[paper.id].doi }}</span>{% endif %}
          </div>
        </article>
        {% endfor %}
      </div>
    </div>
  </section>
  {% endfor %}

  <aside class="lit-source-note">
    <div class="lit-shell">
      <p>Looking for a particular topic? <a href="{{ '/papers/?sort=added-desc' | relative_url }}">Search all papers, newest additions first</a>. For corrections and other changes, see the <a href="{{ '/changelog/' | relative_url }}">release history</a>.</p>
      <p><a href="{{ '/contribute/' | relative_url }}">Suggest a missing paper or correction</a>.</p>
    </div>
  </aside>
</main>
