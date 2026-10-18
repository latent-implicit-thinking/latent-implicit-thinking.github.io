---
layout: page
title: Changelog
share-description: "Versioned updates to the Implicit Chain-of-Thought research map."
permalink: /changelog/
last_modified_at: 2026-10-18
---

Changes to the reading list and website are listed below. You can follow updates through the [RSS feed]({{ '/feed.xml' | relative_url }}) or download the history as [`changes.json`]({{ '/data/changes.json' | relative_url }}).

{% for release in site.data.releases %}
## v{{ release.version }} · {{ release.date | date: "%B %-d, %Y" }} {#v{{ release.version | replace: '.', '-' }}}

**{{ release.title }}**

{% for change in release.changes %}
- {{ change }}
{% endfor %}

{% endfor %}
