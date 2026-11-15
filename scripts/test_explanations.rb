#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require_relative "test_agent_exports"

module ExplanationChecks
  module_function

  FIELD = "explanations_and_discussion"
  SECTION = "explanations-and-discussion"

  def assert(condition, message, errors)
    errors << "Explanations: #{message}" unless condition
  end

  def read(site_root, path, errors)
    AgentExports.read_file(site_root, path, errors)
  end

  def check_html(site_root, path, expected, all, language, errors)
    html = read(site_root, path, errors)
    section = html[/<section\b[^>]*\bid=["']#{SECTION}["'][^>]*>.*?<\/section>/m].to_s
    if expected.empty?
      assert(section.empty?, "#{path}: empty or unrelated section rendered", errors)
      return
    end
    heading = language == "zh" ? "讲解与讨论" : "Explanations and discussion"
    assert(AgentExports.visible_text(section).include?(heading), "#{path}: missing section heading", errors)
    links = AgentExports.attributes(section, "a").map { |link| link["href"] }
    assert(links.select { |url| all.any? { |item| item["url"] == url } } == expected.map { |item| item["url"] }, "#{path}: missing, duplicated, reordered or unrelated resource links", errors)
    visible = AgentExports.visible_text(section)
    expected.each do |resource|
      wording = language == "zh" ? resource.fetch("zh") : resource
      %w[title source_label description].each do |field|
        assert(visible.include?(wording.fetch(field)), "#{path}: missing #{field} for #{resource['id']}", errors)
      end
    end
  end

  def check_markdown(text, expected, language, label, errors)
    expected.each do |resource|
      wording = language == "zh" ? resource.fetch("zh") : resource
      [resource.fetch("url"), wording.fetch("title"), wording.fetch("source_label"), wording.fetch("description")].each do |value|
        assert(text.include?(value), "#{label}: missing resource content for #{resource['id']}", errors)
      end
    end
  end

  def validate(repo_root, site_root)
    errors = []
    resources = AgentExports.load_yaml(repo_root, "explanations")
    papers = AgentExports.load_yaml(repo_root, "papers")
    methods = AgentExports.load_yaml(repo_root, "methods")
    corpus = JSON.parse(read(site_root, "data/papers.json", errors)).fetch("papers")
    assert(resources.map { |item| item.fetch("source_type") }.sort == %w[lecture_material media_article translation], "the selected links must retain their three distinct source types", errors)
    assert(resources.map { |item| item.fetch("url") }.uniq.length == resources.length, "duplicate source URL", errors)
    expected_ids = {"translation" => ["2311.01460"], "media_article" => ["2405.14838"], "lecture_material" => ["2405.14838"]}
    resources.each do |resource|
      assert(resource["paper_ids"] == expected_ids.fetch(resource["source_type"]), "#{resource['id']}: wrong associated paper", errors)
      assert(resource["topic_ids"] == ["internalized"], "#{resource['id']}: wrong topic association", errors)
    end

    papers.each do |paper|
      id = paper.fetch("id")
      expected = resources.select { |resource| resource.fetch("paper_ids").include?(id) }
      aggregate = corpus.find { |item| item.fetch("id") == id }
      record = JSON.parse(read(site_root, "papers/#{id}/record.json", errors))
      [aggregate, record].each do |entry|
        assert(entry.fetch(FIELD, []) == expected, "#{id}: JSON links or metadata differ from the source selection", errors)
        assert(!entry.key?(FIELD), "#{id}: unrelated record gained an empty resource field", errors) if expected.empty?
      end
      check_html(site_root, "papers/#{id}/index.html", expected, resources, "en", errors)
      next if expected.empty?

      check_html(site_root, "zh/papers/#{id}/index.html", expected, resources, "zh", errors)
      markdown = read(site_root, "papers/#{id}/index.md", errors)
      assert(markdown.scan(/^## Explanations and discussion$/).length == 1, "#{id}: missing or duplicated Markdown section", errors)
      check_markdown(markdown, expected, "en", id, errors)
      (resources - expected).each do |resource|
        assert(!markdown.include?(resource.fetch("url")), "#{id}: unrelated resource in individual Markdown", errors)
      end
    end

    methods.each do |method|
      topic = JSON.parse(read(site_root, "data/topics/#{method['slug']}.json", errors))
      expected = resources.select { |resource| resource.fetch("topic_ids").include?(method.fetch("id")) }
      assert(topic.fetch(FIELD, []) == expected, "#{method['id']}: topic resource selection differs", errors)
      check_html(site_root, method.fetch("url").delete_prefix("/") + "index.html", expected, resources, "en", errors)
      markdown = read(site_root, "data/topics/#{method['slug']}.md", errors)
      check_markdown(markdown, expected, "en", method.fetch("id"), errors)
      nested = markdown.split(/^## Papers — oldest first$/, 2).last.to_s
      assert(!nested.match?(/^## Explanations and discussion$/), "#{method['id']}: paper resource heading escaped its paper section", errors)
    end
    check_html(site_root, "zh/topics/index.html", resources, resources, "zh", errors)
    %w[llms.txt data/reading-list.md].each do |path|
      check_markdown(read(site_root, path, errors), resources, "en", path, errors)
    end
    check_markdown(read(site_root, "data/zh/reading-guide.md", errors), resources, "zh", "Chinese Markdown guide", errors)
    %w[data/papers.bib data/papers.csl.json data/publications.bib data/publications.csl.json].each do |path|
      citations = read(site_root, path, errors)
      assert(resources.none? { |resource| citations.include?(resource.fetch("url")) }, "#{path}: explanatory resources entered paper citations", errors)
    end
    errors
  rescue KeyError, JSON::ParserError => error
    errors << "Explanations: missing or invalid resource/export data: #{error.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("..", __dir__)
  site_root = File.expand_path(ARGV.fetch(0, "_site"), repo_root)
  errors = ExplanationChecks.validate(repo_root, site_root)
  abort(errors.uniq.sort.join("\n")) unless errors.empty?
  puts "Validated explanation links, source labels, bilingual pages, agent exports and citation separation."
end
