#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "json"
require "rexml/document"
require "uri"
require "yaml"

# Check rendered artifacts, not just the templates that produce them. This also
# runs from validate_corpus.rb, so the deployment gate covers every paper page.
module AgentExports
  module_function

  def load_yaml(root, name)
    YAML.safe_load(File.read(File.join(root, "_data", "#{name}.yml")), permitted_classes: [Date], aliases: false)
  end

  def read_file(root, path, errors)
    File.read(File.join(root, path))
  rescue Errno::ENOENT
    errors << "Agent exports: missing #{path}"
    ""
  end

  def read_json(root, path, errors)
    JSON.parse(read_file(root, path, errors))
  rescue JSON::ParserError => error
    errors << "Agent exports: invalid JSON in #{path}: #{error.message}"
    nil
  end

  def visible_text(html)
    CGI.unescapeHTML(html.gsub(/<(script|style)\b[^>]*>.*?<\/\1>/mi, " ").gsub(/<[^>]*>/, " ")).gsub(/\s+/, " ").strip
  end

  def attributes(html, tag)
    html.scan(/<#{tag}\b([^>]+)>/i).map do |match|
      match.first.scan(/([\w:-]+)\s*=\s*["']([^"']*)["']/).to_h.transform_values { |value| CGI.unescapeHTML(value) }
    end
  end

  def linked?(html, expected_url, base_url)
    path = expected_url.sub(base_url.delete_suffix("/"), "")
    attributes(html, "a").any? { |attrs| [expected_url, path].include?(attrs["href"]) }
  end

  def json_ld(html, path, errors)
    html.scan(/<script\s+type="application\/ld\+json"[^>]*>(.*?)<\/script>/m).flatten.flat_map do |content|
      object = JSON.parse(content)
      object.is_a?(Array) ? object : [object]
    rescue JSON::ParserError => error
      errors << "Agent exports: invalid JSON-LD in #{path}: #{error.message}"
      []
    end
  end

  def citations(value)
    value.is_a?(Array) ? value : [value].compact
  end

  def bib_entries(text)
    text.scan(/^@\w+\{([^,]+),\n(.*?)^\}/m).to_h
  end

  def assert(condition, message, errors)
    errors << "Agent exports: #{message}" unless condition
  end

  def validate_publication_source(id, publication, record, errors)
    required = %w[title author_names year type container_title url source_url verified_at]
    assert(publication.is_a?(Hash), "#{id}: publication metadata must be an object", errors)
    return unless publication.is_a?(Hash)

    required.each { |field| assert(publication.key?(field) && publication[field] != "", "#{id}: publication lacks #{field}", errors) }
    names = publication["author_names"]
    assert(names.is_a?(Array) && !names.empty? && names.all? { |name| name.is_a?(String) && !name.strip.empty? }, "#{id}: publication authors must be an ordered name array", errors)
    assert(%w[paper-conference article-journal].include?(publication["type"]), "#{id}: publication type must identify a conference or journal", errors)
    year = publication["year"]
    assert(year.is_a?(Integer) && year >= record.fetch("first_public").to_s[0, 4].to_i && year <= Date.today.year, "#{id}: publication year is not a plausible verified year", errors)
    %w[url source_url].each do |field|
      begin
        parsed = URI.parse(publication[field].to_s)
        assert(parsed.scheme == "https" && parsed.host && !parsed.host.empty?, "#{id}: publication #{field} must be an absolute HTTPS source", errors)
      rescue URI::InvalidURIError
        errors << "Agent exports: #{id}: invalid publication #{field}"
      end
    end
    begin
      checked = Date.iso8601(publication["verified_at"].to_s)
      assert(checked <= Date.today, "#{id}: publication verification is in the future", errors)
    rescue Date::Error
      errors << "Agent exports: #{id}: publication verification date is invalid"
    end
    if publication["doi"]
      assert(publication["doi"].match?(%r{\A10\.\d{4,9}/\S+\z}), "#{id}: publication DOI must be a DOI, not an invented URL", errors)
    end
  end

  def validate(repo_root, site_root)
    errors = []
    papers = load_yaml(repo_root, "papers")
    precursors = load_yaml(repo_root, "precursors")
    methods = load_yaml(repo_root, "methods")
    meta = load_yaml(repo_root, "meta")
    publications = load_yaml(repo_root, "publications") || {}
    comparisons = load_yaml(repo_root, "comparisons") || {}
    records = papers + precursors
    source_by_id = records.each_with_object({}) { |paper, hash| hash[paper.fetch("id")] = paper }
    canonical = meta.fetch("canonical_url")
    corpus = read_json(site_root, "data/papers.json", errors)
    return errors unless corpus.is_a?(Hash)

    generated_records = Array(corpus["papers"]) + Array(corpus["precursors"])
    generated_by_id = generated_records.each_with_object({}) { |paper, hash| hash[paper.fetch("id")] = paper }
    aggregate_csl = citations(read_json(site_root, "data/papers.csl.json", errors))
    aggregate_bib = bib_entries(read_file(site_root, "data/papers.bib", errors))
    publication_csl = citations(read_json(site_root, "data/publications.csl.json", errors))
    publication_bib_text = read_file(site_root, "data/publications.bib", errors)
    publication_bib = bib_entries(publication_bib_text)
    old_index = read_file(site_root, "papers/index.html", errors)
    sitemap = read_file(site_root, "sitemap.xml", errors)
    sitemap_urls = []
    begin
      sitemap_document = REXML::Document.new(sitemap)
      REXML::XPath.each(sitemap_document, "//*[local-name()='loc']") { |element| sitemap_urls << element.text }
    rescue REXML::ParseException => error
      errors << "Agent exports: invalid sitemap: #{error.message}"
    end

    assert((publications.keys - source_by_id.keys).empty?, "publication metadata contains unknown paper IDs", errors)
    assert(publication_csl.length == publications.length && publication_bib.length == publications.length, "aggregate publication citations do not cover exactly the verified subset", errors)
    assert((comparisons.keys - methods.map { |method| method["id"] }).empty?, "comparison notes contain unknown topics", errors)

    records.each_with_index do |paper, index|
      id = paper.fetch("id")
      collection = index < papers.length ? "core" : "precursor"
      prefix = collection == "core" ? "paper-" : "precursor-"
      citation_key = "lit_#{collection == 'precursor' ? 'precursor_' : ''}#{id.tr('.', '_')}"
      path = "papers/#{id}"
      url = "#{canonical}#{path}/"
      expected_legacy = "#{canonical}papers/##{prefix}#{id.tr('.', '-')}"
      record = read_json(site_root, "#{path}/record.json", errors)
      html = read_file(site_root, "#{path}/index.html", errors)
      markdown = read_file(site_root, "#{path}/index.md", errors)
      bib = read_file(site_root, "#{path}/citation.bib", errors)
      csl = citations(read_json(site_root, "#{path}/citation.csl.json", errors))
      authors = paper.fetch("authors").split(", ")
      summary = paper.fetch("summary", paper["connection"])

      assert(record == generated_by_id[id], "#{id}: standalone record differs from aggregate corpus", errors)
      assert(record.is_a?(Hash) && record["record_url"] == url && record["legacy_record_url"] == expected_legacy, "#{id}: new or legacy record address is incorrect", errors)
      next unless record.is_a?(Hash)

      {"json_url" => "record.json", "markdown_url" => "index.md", "bibtex_url" => "citation.bib", "csl_url" => "citation.csl.json"}.each do |field, filename|
        assert(record.is_a?(Hash) && record[field] == "#{url}#{filename}", "#{id}: record does not advertise its #{filename} endpoint", errors)
      end
      assert(old_index.include?("id=\"#{prefix}#{id.tr('.', '-')}\""), "#{id}: original deep link no longer resolves", errors)
      assert(sitemap_urls.count(url) == 1, "#{id}: paper page must have one sitemap entry", errors)
      canonical_links = attributes(html, "link").select { |attrs| attrs["rel"] == "canonical" }
      assert(canonical_links.length == 1 && canonical_links.first["href"] == url, "#{id}: paper page canonical URL is not its permanent record", errors)
      assert(html.scan(/<h1\b/i).length == 1 && visible_text(html[/<h1\b[^>]*>.*?<\/h1>/m].to_s) == paper["title"], "#{id}: paper title is not the visible page heading", errors)
      visible = visible_text(html)
      [paper["title"], summary, *authors].each do |text|
        assert(visible.include?(text.gsub(/\s+/, " ")), "#{id}: visible paper page omits title, summary or an author", errors)
      end
      assert(linked?(html, paper["paper_url"], canonical), "#{id}: paper page lacks the primary-source link", errors)
      %w[record.json index.md citation.bib citation.csl.json].each do |filename|
        assert(linked?(html, "#{url}#{filename}", canonical), "#{id}: paper page does not expose #{filename}", errors)
      end
      assert(markdown.start_with?("# ") && !markdown.match?(/<(?:html|head|body)\b/i), "#{id}: Markdown export was converted to HTML", errors)
      [paper["title"], *authors, summary, paper["paper_url"], url, paper["first_public"]].each do |text|
        assert(markdown.include?(text.to_s), "#{id}: Markdown omits an essential record field", errors)
      end
      assert(csl.length == 1 && csl.first == aggregate_csl.find { |item| item["id"] == citation_key }, "#{id}: standalone preprint CSL differs from the aggregate citation", errors)
      entries = bib_entries(bib)
      assert(entries.keys == [citation_key] && entries[citation_key] == aggregate_bib[citation_key], "#{id}: standalone preprint BibTeX differs from aggregate citation", errors)

      structured = json_ld(html, "#{path}/index.html", errors)
      page = structured.find { |item| item["@type"] == "WebPage" }
      assert(page && page["url"] == url && page["@context"] == "https://schema.org", "#{id}: WebPage structured data does not identify its canonical page", errors)
      article = page && page["mainEntity"]
      assert(!article.nil?, "#{id}: paper page lacks scholarly structured data", errors)
      if article
        assert(article["@type"] == "ScholarlyArticle" && article["name"] == paper["title"] && article["description"] == summary, "#{id}: structured article differs from visible title or summary", errors)
        assert(article["author"] == authors.map { |name| {"@type" => "Person", "name" => name} }, "#{id}: structured article authors differ from visible authors", errors)
        assert(article.dig("identifier", "value") == id, "#{id}: structured article identifier differs", errors)
        assert([paper["paper_url"], url].include?(article["url"]), "#{id}: structured article URL points at another work", errors)
      end
      if publications[id]
        assert(record["publication"] == publications[id], "#{id}: exported publication differs from verified source metadata", errors)
        {"publication_bibtex_url" => "publication.bib", "publication_csl_url" => "publication.csl.json"}.each do |field, filename|
          assert(record[field] == "#{url}#{filename}", "#{id}: record does not advertise #{filename}", errors)
        end
      else
        assert(!record.key?("publication") && !record.key?("publication_bibtex_url") && !record.key?("publication_csl_url"), "#{id}: record advertises an unverified publication", errors)
      end
      validate_publication(id, publications[id], paper, html, markdown, path, site_root, publication_csl, publication_bib, canonical, errors)
    end

    methods.each do |method|
      validate_topic(method, papers, generated_by_id, comparisons, meta, canonical, site_root, errors)
    end

    errors
  end

  def validate_publication(id, publication, paper, html, markdown, path, site_root, aggregate_csl, aggregate_bib, canonical, errors)
    unless publication
      %w[publication.bib publication.csl.json].each do |filename|
        assert(!File.exist?(File.join(site_root, path, filename)), "#{id}: unverified publication citation was generated", errors)
      end
      return
    end
    validate_publication_source(id, publication, paper, errors)
    csl = citations(read_json(site_root, "#{path}/publication.csl.json", errors))
    bib = read_file(site_root, "#{path}/publication.bib", errors)
    entries = bib_entries(bib)
    assert(csl.length == 1, "#{id}: publication CSL must describe one publication", errors)
    return unless csl.length == 1 && csl.first.is_a?(Hash)

    citation = csl.first
    key = citation["id"]
    prefix = paper.key?("connection") ? "lit_precursor_" : "lit_"
    assert(key == "#{prefix}#{id.tr('.', '_')}_published", "#{id}: publication citation key collides with or is disconnected from the preprint", errors)
    assert(aggregate_csl.count { |item| item == citation } == 1, "#{id}: publication CSL differs from aggregate citation", errors)
    assert(entries.keys == [key] && entries[key] == aggregate_bib[key], "#{id}: publication BibTeX differs from aggregate citation", errors)
    assert(citation["title"] == publication["title"] && citation["URL"] == publication["url"] && citation["type"] == publication["type"], "#{id}: publication title, URL or type differs from verified metadata", errors)
    assert(citation["author"] == publication.fetch("author_names", []).map { |name| {"literal" => name} }, "#{id}: publication author list differs from verified order", errors)
    assert(citation.dig("issued", "date-parts") == [[publication["year"]]], "#{id}: publication year must not be replaced by arXiv chronology", errors)
    assert(citation["container-title"] == publication["container_title"] && citation["publisher"] == publication["publisher"], "#{id}: publication venue or publisher differs from verified metadata", errors)
    {"doi" => "DOI", "pages" => "page", "volume" => "volume"}.each do |source_key, csl_key|
      assert(citation[csl_key] == publication[source_key], "#{id}: publication #{csl_key} differs from verified metadata", errors)
    end
    assert(!citation.key?("archive") && !citation.key?("number") && citation["genre"] != "Preprint", "#{id}: publication citation incorrectly describes a preprint", errors)
    entry = entries.fetch(key, "")
    assert(entry.match?(/year\s*=\s*\{\s*#{publication['year']}\s*\}/), "#{id}: publication BibTeX year differs", errors)
    assert(entry.include?("url = {#{publication['url']}}"), "#{id}: publication BibTeX source identity differs", errors)
    %w[publication.bib publication.csl.json].each do |filename|
      assert(linked?(html, "#{canonical}#{path}/#{filename}", canonical), "#{id}: paper page omits publication download #{filename}", errors)
    end
    assert(linked?(html, publication["url"], canonical), "#{id}: publication source is not visible", errors)
    assert(visible_text(html).include?(publication["container_title"]) && visible_text(html).include?(publication["year"].to_s), "#{id}: verified publication venue and year are not visible", errors)
    assert(markdown.include?(publication["url"]) && markdown.include?(publication["container_title"]), "#{id}: Markdown omits verified publication version", errors)
  end

  def validate_topic(method, papers, generated_by_id, comparisons, meta, canonical, site_root, errors)
    id = method.fetch("id")
    slug = method.fetch("slug")
    selected = papers.select { |paper| paper.fetch("lens").include?(id) }
    expected = selected.map { |paper| generated_by_id.fetch(paper["id"]) }
    json = read_json(site_root, "data/topics/#{slug}.json", errors)
    markdown = read_file(site_root, "data/topics/#{slug}.md", errors)
    html = read_file(site_root, "#{method.fetch('url').sub(%r{\A/}, '')}index.html", errors)
    assert(json.is_a?(Hash) && json["papers"] == expected, "#{id}: topic export omits, duplicates, reorders or changes records", errors)
    if json.is_a?(Hash)
      metadata = json.fetch("metadata", {})
      assert(metadata["topic_id"] == id && metadata["name"] == method["label"] && metadata["definition"] == method["definition"], "#{id}: topic JSON metadata differs from the visible guide", errors)
      assert(metadata["record_count"] == selected.length && metadata["topic_url"] == "#{canonical.delete_suffix('/')}#{method['url']}", "#{id}: topic JSON count or canonical guide URL differs", errors)
      %w[version updated_at search_refreshed_at].each do |field|
        assert(metadata[field] == meta[field], "#{id}: topic JSON #{field} differs from corpus version", errors)
      end
      assert(metadata["source_url"] == "#{canonical}data/papers.json", "#{id}: topic JSON does not identify its aggregate source", errors)
    end
    assert(selected == selected.sort_by { |paper| [paper["first_public"], paper["id"]] }, "#{id}: topic list is not chronological", errors)
    assert(markdown.start_with?("# ") && !markdown.match?(/<(?:html|head|body)\b/i), "#{id}: topic Markdown was converted to HTML", errors)
    [method["label"], method["definition"], method["example"]].each do |text|
      assert(markdown.include?(text), "#{id}: topic Markdown omits the guide or concrete example", errors)
    end
    selected.each do |paper|
      [paper["title"], paper["paper_url"], paper["summary"], "#{canonical}papers/#{paper['id']}/"].each do |text|
        assert(markdown.include?(text), "#{id}: topic Markdown omits paper #{paper['id']}", errors)
      end
    end
    %w[json md].each do |extension|
      assert(linked?(html, "#{canonical}data/topics/#{slug}.#{extension}", canonical), "#{id}: topic page does not expose its #{extension} export", errors)
    end
    Array(comparisons[id]).each do |comparison|
      assert(comparison["text"].is_a?(String) && !comparison["text"].empty?, "#{id}: comparison is missing text", errors)
      source_ids = Array(comparison["source_ids"])
      source_urls = Array(comparison["source_urls"])
      assert(!source_ids.empty? && (source_ids - generated_by_id.keys).empty?, "#{id}: comparison cites missing records", errors)
      assert(!source_urls.empty? && source_urls.all? { |url| url.match?(%r{\Ahttps://}) }, "#{id}: comparison lacks primary source URLs", errors)
      assert(visible_text(html).include?(comparison["text"]), "#{id}: sourced comparison is not visible in topic guide", errors)
      assert(markdown.include?(comparison["text"]), "#{id}: sourced comparison is missing from topic Markdown", errors)
      source_urls.each do |url|
        assert(linked?(html, url, canonical) && markdown.include?(url), "#{id}: comparison source is not available to both readers and agents", errors)
      end
    end
  rescue KeyError => error
    errors << "Agent exports: #{id}: missing topic field: #{error.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("..", __dir__)
  site_root = File.expand_path(ARGV.fetch(0, "_site"), repo_root)
  errors = AgentExports.validate(repo_root, site_root)
  abort(errors.uniq.sort.join("\n")) unless errors.empty?
  puts "Validated individual paper pages, topic exports, stable links, scholarly metadata, and preprint/publication citation identity."
end
