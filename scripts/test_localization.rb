#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require "rexml/document"
require "yaml"
require_relative "test_navigation"

module LocalizationChecks
  module_function

  def assert(condition, message, errors)
    errors << "Localization: #{message}" unless condition
  end

  def read(site_root, path, errors)
    NavigationChecks.read_file(site_root, path, errors)
  end

  def attributes(html, tag)
    NavigationChecks.attributes(html, tag)
  end

  def json_ld(html)
    html.scan(/<script\s+type="application\/ld\+json"[^>]*>(.*?)<\/script>/m).flatten.map { |raw| JSON.parse(raw) }
  end

  def alternates(html)
    attributes(html, "link").select { |link| link["rel"] == "alternate" && link["hreflang"] }
  end

  def check_pair_metadata(html, language, pair, base, errors)
    expected = pair.merge("x-default" => pair.fetch("en")).transform_values { |path| base + path }
    links = alternates(html)
    actual = links.to_h { |link| [link["hreflang"], link["href"]] }
    assert(links.length == expected.length && actual == expected, "#{pair[language]} has missing, duplicate, or incorrect language alternatives", errors)
    NavigationChecks.check_canonical(html, base + pair.fetch(language), pair.fetch(language), errors)
    assert(attributes(html, "html").first&.fetch("lang", nil) == language, "#{pair[language]} has the wrong document language", errors)
    assert(!attributes(html, "meta").any? { |meta| meta["name"] == "robots" && meta["content"].to_s.match?(/\bnoindex\b/) }, "#{pair[language]} is marked noindex", errors)
    other_language = language == "en" ? "zh-Hans" : "en"
    switches = attributes(html, "a").select { |link| link["hreflang"] == other_language }
    assert(switches.any? { |link| [pair[other_language], base + pair[other_language]].include?(link["href"]) }, "#{pair[language]} has no visible link to its translation", errors)
  end

  def validate(repo_root, site_root)
    errors = []
    meta = YAML.safe_load(File.read(File.join(repo_root, "_data/meta.yml")))
    base = meta.fetch("canonical_url").delete_suffix("/")
    localizations = YAML.safe_load(File.read(File.join(repo_root, "_data/localizations.yml")))
    translations = YAML.safe_load(File.read(File.join(repo_root, "_data/zh.yml")))
    pairs = localizations.fetch("pages")
    manifest = JSON.parse(read(site_root, "data/navigation.json", errors))
    papers = JSON.parse(read(site_root, "data/papers.json", errors))
    guide = read(site_root, "data/zh/reading-guide.md", errors)
    assert(guide.start_with?("# 隐式思维链（Implicit CoT）阅读指南\n") && !guide.match?(/<(?:html|head|body|h[1-6]|p)\b/i), "Chinese Markdown guide was converted to HTML or is missing its title", errors)
    assert(guide.include?("https://github.com/EIT-NLP/Awesome-Latent-CoT"), "Chinese Markdown guide is missing the bibliography acknowledgment", errors)
    assert(guide.include?("https://arxiv.org/html/2311.01460v1#S2.SS3") && guide.include?("https://arxiv.org/html/2311.01460v1#S3"), "Chinese Markdown guide must link the 2023 proposal and implementation separately", errors)
    editions = manifest.fetch("editions", {})
    assert(editions.keys.sort == %w[en zh-Hans].sort, "navigation directory is missing an edition", errors)
    {"en" => ["/", "/topics/", "/llms.txt"], "zh-Hans" => ["/zh/", "/zh/topics/", "/data/zh/reading-guide.md"]}.each do |language, paths|
      %w[overview_url introduction_url reading_guide_url].zip(paths).each do |field, path|
        assert(editions.dig(language, field) == base + path, "#{language} #{field} is not the published URL", errors)
      end
    end
    sitemap_urls = REXML::XPath.match(REXML::Document.new(read(site_root, "sitemap.xml", errors)), "//*[local-name()='loc']").map(&:text)
    translated_records = []
    pairs.each do |pair|
      html_by_language = pair.to_h do |language, path|
        html = read(site_root, path.delete_prefix("/") + "index.html", errors)
        check_pair_metadata(html, language, pair, base, errors)
        assert(sitemap_urls.count(base + path) == 1, "#{path} must have exactly one sitemap entry", errors)
        [language, html]
      end
      next unless pair.fetch("en").start_with?("/papers/")

      id = pair.fetch("en").split("/").last
      record = JSON.parse(read(site_root, "papers/#{id}/record.json", errors))
      chinese = html_by_language.fetch("zh-Hans")
      article_by_language = html_by_language.transform_values do |html|
        json_ld(html).find { |entry| entry["@type"] == "WebPage" }&.fetch("mainEntity", nil)
      end
      assert(article_by_language["en"].is_a?(Hash) && article_by_language["zh-Hans"] == article_by_language["en"], "#{id}: Chinese edition changed the original scholarly identity or metadata", errors)
      article = article_by_language["zh-Hans"] || {}
      assert(article["@id"] == record["paper_url"] && article["identifier"]&.fetch("value", nil) == id, "#{id}: Chinese paper page does not identify the original source", errors)
      visible = NavigationChecks.text(chinese)
      %w[title first_public].each { |field| assert(visible.include?(record.fetch(field)), "#{id}: Chinese paper page is missing #{field}", errors) }
      record.fetch("author_names").each { |author| assert(visible.include?(author), "#{id}: Chinese paper page is missing author #{author}", errors) }
      links = attributes(chinese, "link") + attributes(chinese, "a")
      %w[json_url bibtex_url csl_url publication_bibtex_url publication_csl_url].each do |field|
        next unless record[field]

        assert(links.any? { |link| link["href"] == record[field] }, "#{id}: Chinese paper page does not link the shared #{field}", errors)
      end
      assert(!chinese.match?(%r{/zh/papers/#{Regexp.escape(id)}/(?:citation|publication)\.(?:bib|csl\.json)}), "#{id}: Chinese page points to a duplicate citation", errors)
      translated_records << {"id" => id, "url" => base + pair.fetch("zh-Hans"), "record_url" => record["record_url"], "json_url" => record["json_url"], "bibtex_url" => record["bibtex_url"], "csl_url" => record["csl_url"]}
    end
    assert(editions.dig("zh-Hans", "paper_pages") == translated_records, "Chinese navigation entries differ from the shared paper records", errors)
    YAML.safe_load(File.read(File.join(repo_root, "_data/reading_path.yml"))).each do |id|
      record = JSON.parse(read(site_root, "papers/#{id}/record.json", errors))
      %w[title first_public bibtex_url csl_url json_url].each { |field| assert(guide.include?(record.fetch(field)), "#{id}: Chinese reading guide is missing #{field}", errors) }
      record.fetch("author_names").each { |author| assert(guide.include?(author), "#{id}: Chinese reading guide is missing author #{author}", errors) }
      assert(guide.include?(translations.fetch("papers").fetch(id).fetch("summary")), "#{id}: guide summary differs from the visible Chinese edition", errors)
    end
    %w[llms.txt].each do |path|
      text = read(site_root, path, errors)
      assert(text.include?(base + "/data/zh/reading-guide.md") && text.include?(base + "/zh/"), "#{path}: Chinese edition is not discoverable", errors)
    end
    # A different page canonical or a duplicate hreflang must fail independently
    # of whether its URL still points at a readable page.
    probe = []
    fixture = '<html lang="en"><link rel="canonical" href="' + base + '/zh/"><meta property="og:url" content="' + base + '/"><link rel="alternate" hreflang="en" href="' + base + '/"><link rel="alternate" hreflang="en" href="' + base + '/"><a hreflang="zh-Hans" href="/zh/">中文</a>'
    check_pair_metadata(fixture, "en", pairs.first, base, probe)
    assert(probe.any? { |message| message.include?("language alternatives") } && probe.any? { |message| message.include?("canonical") }, "broken canonical/alternate fixture was not rejected", errors)
    errors
  rescue KeyError, JSON::ParserError, REXML::ParseException => error
    errors << "Localization: invalid data or structured metadata: #{error.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("..", __dir__)
  site_root = File.expand_path(ARGV.fetch(0, "_site"), repo_root)
  errors = LocalizationChecks.validate(repo_root, site_root)
  abort(errors.uniq.sort.join("\n")) unless errors.empty?
  puts "Validated language URLs, reciprocal hreflang, canonical scholarly identities, shared citations, Chinese reading guide, and discovery links."
end
