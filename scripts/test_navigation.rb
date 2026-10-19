#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "json"
require "rexml/document"
require "uri"
require "yaml"

module NavigationChecks
  module_function

  PAGE_PATHS = {
    "introduction" => "/topics/", "papers" => "/papers/",
    "recent_additions" => "/recent/", "downloads" => "/data/"
  }.freeze
  FILE_PATHS = {
    "agent_guide" => "/llms.txt", "navigation" => "/data/navigation.json",
    "reading_list_markdown" => "/data/reading-list.md", "papers_json" => "/data/papers.json",
    "bibtex" => "/data/papers.bib", "csl_json" => "/data/papers.csl.json",
    "publications_bibtex" => "/data/publications.bib", "publications_csl_json" => "/data/publications.csl.json",
    "ontology_json" => "/data/ontology.json", "schema_json" => "/data/schema.json",
    "changes_json" => "/data/changes.json", "rss" => "/feed.xml"
  }.freeze
  HISTORY_SOURCES = %w[
    https://arxiv.org/html/2311.01460v1#S2.SS3
    https://arxiv.org/html/2311.01460v1#S3
    https://arxiv.org/abs/2405.14838
  ].freeze

  def assert(condition, message, errors)
    errors << "Navigation: #{message}" unless condition
  end

  def read_file(root, path, errors)
    File.read(File.join(root, path))
  rescue Errno::ENOENT
    errors << "Navigation: missing #{path}"
    ""
  end

  def read_json(root, path, errors)
    JSON.parse(read_file(root, path, errors))
  rescue JSON::ParserError => error
    errors << "Navigation: invalid JSON in #{path}: #{error.message}"
    nil
  end

  def attributes(html, tag)
    html.scan(/<#{tag}\b([^>]+)>/i).map do |match|
      match.first.scan(/([\w:-]+)\s*=\s*["']([^"']*)["']/).to_h.transform_values { |value| CGI.unescapeHTML(value) }
    end
  end

  def text(html)
    CGI.unescapeHTML(html.gsub(/<(script|style)\b[^>]*>.*?<\/\1>/mi, "").gsub(/<[^>]*>/, "")).gsub(/\s+/, " ").strip
  end

  def main(html)
    html[/<main\b[^>]*>.*?<\/main>/m].to_s.gsub(/\s+/, " ").strip
  end

  def check_canonical(html, expected, context, errors)
    canonical = attributes(html, "link").select { |entry| entry["rel"] == "canonical" }
    assert(canonical.length == 1 && canonical.first["href"] == expected, "#{context}: expected exactly one canonical link to #{expected}", errors)
    og_urls = attributes(html, "meta").select { |entry| entry["property"] == "og:url" }
    assert(og_urls.length == 1 && og_urls.first["content"] == expected, "#{context}: Open Graph URL must match the canonical URL", errors)
  end

  def resolve_url(url, canonical, site_root, errors, context)
    parsed, origin = URI.parse(url.to_s), URI.parse(canonical)
    same_origin = parsed.scheme == origin.scheme && parsed.host == origin.host && parsed.port == origin.port
    unless same_origin
      errors << "Navigation: #{context}: URL is not an absolute same-origin route: #{url}"
      return
    end
    decoded_path = URI::DEFAULT_PARSER.unescape(parsed.path)
    if decoded_path.include?("\0") || decoded_path.split("/").include?("..")
      errors << "Navigation: #{context}: unsafe path: #{url}"
      return
    end
    target = File.expand_path(decoded_path.sub(%r{\A/+}, ""), site_root)
    target = File.join(target, "index.html") if decoded_path.end_with?("/") || File.directory?(target)
    unless target.start_with?(File.expand_path(site_root) + "/") && File.file?(target)
      errors << "Navigation: #{context}: route does not resolve in the build: #{url}"
      return
    end
    if parsed.fragment && target.end_with?(".html")
      fragment = Regexp.escape(URI::DEFAULT_PARSER.unescape(parsed.fragment))
      assert(File.read(target).match?(/(?:id|name)=["']#{fragment}["']/), "#{context}: fragment does not resolve: #{url}", errors)
    end
    target
  rescue URI::InvalidURIError, ArgumentError => error
    errors << "Navigation: #{context}: invalid route #{url.inspect}: #{error.message}"
    nil
  end

  def each_url(value, path = "$", &block)
    case value
    when Hash
      value.each { |key, child| each_url(child, "#{path}.#{key}", &block) }
    when Array
      value.each_with_index { |child, index| each_url(child, "#{path}[#{index}]", &block) }
    when String
      yield(value, path) if value.match?(%r{\Ahttps?://})
    end
  end

  def validate_manifest(manifest, methods, papers, meta, site_root, errors)
    assert(manifest.is_a?(Hash), "navigation manifest must be an object", errors)
    return unless manifest.is_a?(Hash)

    canonical = meta.fetch("canonical_url")
    base = canonical.delete_suffix("/")
    assert(manifest["schema_version"] == 1, "navigation manifest schema version is unsupported", errors)
    %w[name version updated_at canonical_url].each do |key|
      assert(manifest[key] == meta[key], "navigation manifest #{key} differs from current site metadata", errors)
    end
    pages = manifest["pages"]
    assert(pages.is_a?(Hash) && pages.keys.sort == PAGE_PATHS.keys.sort, "navigation manifest page set differs from the supported routes", errors)
    if pages.is_a?(Hash)
      PAGE_PATHS.each do |name, path|
        entry = pages[name]
        assert(entry.is_a?(Hash) && entry["url"] == base + path, "navigation manifest has the wrong #{name} route", errors)
      end
      intro = pages["introduction"]
      assert(intro.is_a?(Hash) && intro["aliases"] == [base + "/start-here/"], "navigation manifest does not describe the working introduction alias", errors)
    end
    expected_files = FILE_PATHS.transform_values { |path| base + path }
    assert(manifest["files"] == expected_files, "navigation manifest file URLs differ from the published interfaces", errors)
    expected_topics = methods.map do |method|
      {"id" => method.fetch("id"), "label" => method.fetch("label"), "url" => base + method.fetch("url"),
       "markdown_url" => "#{base}/data/topics/#{method.fetch('slug')}.md",
       "json_url" => "#{base}/data/topics/#{method.fetch('slug')}.json"}
    end
    assert(manifest["topics"] == expected_topics, "navigation manifest topics differ from the canonical guides and downloads", errors)
    each_url(manifest) { |url, path| resolve_url(url, canonical, site_root, errors, path) }
    methods.each do |method|
      prefix = "data/topics/#{method.fetch('slug')}"
      topic = read_json(site_root, prefix + ".json", errors)
      expected_ids = papers.select { |paper| paper.fetch("lens").include?(method.fetch("id")) }.map { |paper| paper.fetch("id") }
      assert(topic.is_a?(Hash) && topic.dig("metadata", "topic_id") == method["id"] && topic.dig("metadata", "topic_url") == base + method["url"], "#{method['id']}: navigation points at the wrong topic JSON", errors)
      assert(topic.is_a?(Hash) && Array(topic["papers"]).map { |paper| paper["id"] } == expected_ids, "#{method['id']}: linked topic JSON has missing, reordered or unrelated papers", errors)
      markdown = read_file(site_root, prefix + ".md", errors)
      assert(markdown.start_with?("# #{method.fetch('label')}\n") && !markdown.match?(/<(?:html|head|body)\b/i), "#{method['id']}: linked topic Markdown is not the matching plain-text guide", errors)
    end
  end

  def negative_checks(site_root, canonical)
    errors = []
    probe = []
    resolve_url(canonical + "__navigation_missing_route_7a2be1__/", canonical, site_root, probe, "negative fixture")
    assert(probe.any? { |message| message.include?("does not resolve") }, "missing-route negative fixture was not rejected", errors)
    probe = []
    resolve_url(canonical + "%2E%2E/private.txt", canonical, site_root, probe, "negative fixture")
    assert(probe.any? { |message| message.include?("unsafe path") }, "path-traversal negative fixture was not rejected", errors)
    probe = []
    resolve_url("https://example.invalid/topics/", canonical, site_root, probe, "negative fixture")
    assert(probe.any? { |message| message.include?("same-origin") }, "external-route negative fixture was not rejected", errors)
    probe = []
    html = '<link rel="canonical" href="https://example.invalid/wrong/"><meta property="og:url" content="https://example.invalid/wrong/">'
    check_canonical(html, canonical + "topics/", "negative fixture", probe)
    assert(probe.length == 2, "canonical/OG mismatch negative fixture was not rejected", errors)
    errors
  end

  def validate(repo_root, site_root)
    errors = []
    meta = YAML.safe_load(File.read(File.join(repo_root, "_data/meta.yml")), permitted_classes: [Date], aliases: false)
    methods = YAML.safe_load(File.read(File.join(repo_root, "_data/methods.yml")), aliases: false)
    papers = YAML.safe_load(File.read(File.join(repo_root, "_data/papers.yml")), aliases: false)
    canonical = meta.fetch("canonical_url")
    base = canonical.delete_suffix("/")
    home = read_file(site_root, "index.html", errors)
    topics = read_file(site_root, "topics/index.html", errors)
    intro_alias = read_file(site_root, "start-here/index.html", errors)
    assert(!main(topics).empty? && main(intro_alias) == main(topics), "introduction alias does not contain the complete static canonical introduction", errors)
    %w[topics/index.html start-here/index.html].zip([topics, intro_alias]).each do |path, html|
      check_canonical(html, base + "/topics/", path, errors)
      assert(!attributes(html, "meta").any? { |entry| entry["http-equiv"].to_s.downcase == "refresh" }, "#{path}: introduction must not depend on a timed redirect", errors)
      inline_scripts = html.scan(/<script\b[^>]*>(.*?)<\/script>/m).flatten.join("\n")
      assert(!inline_scripts.match?(/(?:window\s*\.\s*)?location\s*(?:\.\s*(?:href|replace|assign))?\s*(?:=|\()/i), "#{path}: introduction must not depend on JavaScript redirection", errors)
      assert(text(main(html)).include?("booking fee") && html.include?('id="example-title"'), "#{path}: concrete beginner example is missing from static HTML", errors)
      methods.each { |method| assert(attributes(html, "a").any? { |entry| [method["url"], base + method["url"]].include?(entry["href"]) }, "#{path}: approach guide link is missing", errors) }
    end
    histories = [home, topics, intro_alias].map { |html| html[/<p\b[^>]*class="[^"]*\blit-history\b[^"]*"[^>]*>.*?<\/p>/m].to_s }
    assert(!histories.first.empty? && histories.map { |paragraph| text(paragraph) }.uniq.length == 1, "introduction alias changed or omitted the existing historical attribution", errors)
    histories.each do |paragraph|
      links = attributes(paragraph, "a").map { |entry| entry["href"] }
      assert(HISTORY_SOURCES.all? { |url| links.include?(url) }, "historical attribution lost a direct dated primary source", errors)
    end
    %w[/llms.txt /data/navigation.json].each do |path|
      anchors = home.scan(/<a\b[^>]*>.*?<\/a>/m)
      assert(anchors.any? { |anchor| attributes(anchor, "a").any? { |attrs| [path, base + path].include?(attrs["href"]) } && text(anchor).include?(path) }, "homepage must visibly name and link #{path}", errors)
    end
    title = text(home[/<title\b[^>]*>.*?<\/title>/m].to_s)
    %w[Implicit\ Chain-of-Thought Reading\ List Latent\ Reasoning].each do |phrase|
      assert(title.include?(phrase), "homepage SEO title omits #{phrase}", errors)
    end
    [home, topics, intro_alias].each do |html|
      described = attributes(html, "link").select { |entry| entry.fetch("rel", "").split.include?("describedby") }
      assert(described.any? { |entry| entry["href"] == base + "/data/navigation.json" && entry["type"] == "application/json" }, "HTML head does not advertise the navigation manifest", errors)
    end
    llms = read_file(site_root, "llms.txt", errors)
    assert(llms.start_with?("# Implicit Chain-of-Thought") && !llms.include?("<html"), "agent guide is not plain text", errors)
    llms_visible = llms.gsub(/\[([^\]]+)\]\([^\)]+\)/, '\1').delete("`")
    %w[/topics/ /start-here/ /data/navigation.json].each do |path|
      assert(llms_visible.include?(path), "agent guide does not explicitly document #{path}", errors)
      assert(llms.include?(base + path), "agent guide does not link #{path}", errors)
    end
    manifest = read_json(site_root, "data/navigation.json", errors)
    validate_manifest(manifest, methods, papers, meta, site_root, errors)
    sitemap = read_file(site_root, "sitemap.xml", errors)
    begin
      urls = REXML::XPath.match(REXML::Document.new(sitemap), "//*[local-name()='loc']").map(&:text)
      assert(urls.count(base + "/topics/") == 1, "canonical introduction must have exactly one sitemap entry", errors)
      assert(!urls.any? { |url| url.start_with?(base + "/start-here/") }, "introduction alias should not compete with the canonical sitemap entry", errors)
    rescue REXML::ParseException => error
      errors << "Navigation: sitemap is invalid: #{error.message}"
    end
    errors.concat(negative_checks(site_root, canonical))
    errors
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("..", __dir__)
  site_root = File.expand_path(ARGV.fetch(0, "_site"), repo_root)
  errors = NavigationChecks.validate(repo_root, site_root)
  abort(errors.uniq.sort.join("\n")) unless errors.empty?
  puts "Validated static introduction alias, canonical metadata, navigation manifest, agent discovery links, topic destinations, and negative route fixtures."
end
