## A short reading path

Five papers, in date order: the implicit-CoT proposal, stepwise internalization, recurrent continuous states, self-distillation, and a survey of the wider field. [Read the guide]({{ '/topics/#reading-path' | absolute_url }}) or [browse all papers]({{ '/papers/' | absolute_url }}).
{% for paper_id in site.data.reading_path %}{% assign paper = paper_id | lit_paper_by_id %}{% assign record = paper | lit_record %}
### {{ paper.first_public }} — [{{ paper.title }}]({{ record.record_url }})

Authors: {{ paper.authors }}.

{{ paper.summary }}

[Original paper]({{ paper.paper_url }}) · [JSON record]({{ record.json_url }}) · [BibTeX]({{ record.bibtex_url }}) · [CSL-JSON]({{ record.csl_url }})
{% endfor %}
