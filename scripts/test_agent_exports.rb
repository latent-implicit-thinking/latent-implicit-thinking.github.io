#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
require "json"
require "rexml/document"
require "uri"
require "yaml"
require_relative "public_files"

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

  def named_link?(html, url, label, canonical)
    html.scan(/<a\b[^>]*>.*?<\/a>/m).any? do |anchor|
      linked?(anchor, url, canonical) && visible_text(anchor) == label
    end
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

  def dataset_nodes(value)
    case value
    when Hash
      own = Array(value["@type"]).include?("Dataset") ? [value] : []
      own + value.values.flat_map { |child| dataset_nodes(child) }
    when Array
      value.flat_map { |child| dataset_nodes(child) }
    else
      []
    end
  end

  def validate_dataset_metadata(objects, context, errors)
    datasets = dataset_nodes(objects)
    datasets.each_with_index do |dataset, index|
      %w[name description].each do |field|
        value = dataset[field]
        assert(value.is_a?(String) && !value.strip.empty?, "#{context}: Dataset #{index + 1} #{field} must be nonempty text", errors)
      end
    end
    datasets
  end

  def validate_dataset_creator(dataset, canonical, context, errors)
    expected = {"@type" => "Organization", "name" => "Latent & Implicit Thinking (LIT) workshop organizing team",
                "url" => "#{canonical}organizers/"}
    assert(dataset["creator"] == expected, "#{context}: Dataset creator must identify the LIT workshop organizing team and organizers page", errors)
  end

  def validate_dataset_discovery(site_root, meta, errors)
    datasets = %w[index.html data/index.html].map do |path|
      objects = json_ld(read_file(site_root, path, errors), path, errors)
      entries = validate_dataset_metadata(objects, path, errors)
      assert(entries.length == 1, "#{path}: expected exactly one research Dataset", errors)
      dataset = entries.first || {}
      validate_dataset_creator(dataset, meta.fetch("canonical_url"), path, errors)
      dataset
    end
    homepage, downloads = datasets
    datasets.each do |dataset|
      assert(dataset["url"] == "#{meta.fetch('canonical_url')}data/", "Dataset must identify the canonical downloads URL", errors)
      assert(dataset["license"] == meta.fetch("license_url"), "Dataset license differs from the canonical data license", errors)
    end
    assert(homepage["description"] == downloads["description"], "homepage Dataset description differs from the canonical downloads Dataset", errors)
  end

  def validate_dataset_regressions(errors)
    valid = {"@type" => "Dataset", "name" => "Example corpus", "description" => "A research corpus."}
    [valid, valid.reject { |key, _| key == "description" }, valid.merge("description" => nil),
     valid.merge("description" => "  \n"), valid.merge("description" => []), valid.merge("name" => "")].each_with_index do |dataset, index|
      nested = {"@type" => "WebSite", "hasPart" => [{"@type" => "WebPage"}, dataset]}
      observed = []
      found = validate_dataset_metadata([nested], "nested fixture #{index}", observed)
      assert(found == [dataset] && observed.empty? == index.zero?, "Dataset regression #{index}: nested validation did not #{index.zero? ? 'accept' : 'reject'} the fixture", errors)
    end
    graph = {"@graph" => [valid.merge("@type" => ["CreativeWork", "Dataset"])]}
    observed = []
    found = validate_dataset_metadata(graph, "graph fixture", observed)
    assert(found.length == 1 && observed.empty?, "Dataset regression: graph or multiple-type Dataset was not recognized", errors)

    canonical = "https://latent-implicit-thinking.github.io/"
    creator = {"@type" => "Organization", "name" => "Latent & Implicit Thinking (LIT) workshop organizing team",
               "url" => "https://latent-implicit-thinking.github.io/organizers/"}
    creator_cases = [
      ["matching organizing team", creator, true],
      ["missing creator", nil, false],
      ["text instead of object", creator["name"], false],
      ["wrong type", creator.merge("@type" => "Person"), false],
      ["missing name", creator.reject { |key, _| key == "name" }, false],
      ["wrong name", creator.merge("name" => "Another team"), false],
      ["missing URL", creator.reject { |key, _| key == "url" }, false],
      ["wrong URL", creator.merge("url" => "#{canonical}data/"), false],
      ["unexpected field", creator.merge("alternateName" => "Example team"), false]
    ]
    creator_cases.each do |name, value, accepted|
      observed = []
      fixture = value.nil? ? {} : {"creator" => value}
      validate_dataset_creator(fixture, canonical, name, observed)
      assert(observed.empty? == accepted, "Dataset creator regression #{name}: validation did not #{accepted ? 'accept' : 'reject'} the fixture", errors)
    end
  end

  def validate_comparison_sources(comparisons, source_by_id, methods, errors)
    topic_ids = methods.map { |method| method.fetch("id") }
    assert(comparisons.is_a?(Hash), "method comparisons must be grouped by topic", errors)
    return unless comparisons.is_a?(Hash)

    assert((comparisons.keys - topic_ids).empty?, "comparison notes contain unknown topics", errors)
    comparisons.each do |topic_id, notes|
      assert(notes.is_a?(Array) && !notes.empty?, "#{topic_id}: comparisons must be a nonempty array", errors)
      next unless notes.is_a?(Array)

      titles = []
      notes.each_with_index do |note, index|
        context = "#{topic_id} comparison #{index + 1}"
        assert(note.is_a?(Hash), "#{context}: comparison must be an object", errors)
        next unless note.is_a?(Hash)

        %w[title text].each do |field|
          assert(note[field].is_a?(String) && !note[field].strip.empty?, "#{context}: #{field} must be nonempty text", errors)
        end
        titles << note["title"]
        ids, urls, labels = note.values_at("source_ids", "source_urls", "source_labels")
        assert(ids.is_a?(Array) && !ids.empty? && ids.uniq == ids && (ids - source_by_id.keys).empty?, "#{context}: source IDs must be distinct known papers", errors)
        assert(urls.is_a?(Array) && !urls.empty? && urls.uniq == urls, "#{context}: source URLs must be a nonempty distinct array", errors)
        Array(urls).each do |url|
          begin
            parsed = URI.parse(url.to_s)
            assert(url.is_a?(String) && parsed.scheme == "https" && parsed.host && !parsed.host.empty?, "#{context}: source URL must be absolute HTTPS", errors)
          rescue URI::InvalidURIError
            errors << "Agent exports: #{context}: invalid source URL"
          end
        end
        assert(labels.is_a?(Array) && !labels.empty? && labels.all? { |label| label.is_a?(String) && !label.strip.empty? }, "#{context}: source labels must be nonempty text", errors)
        assert(urls.is_a?(Array) && labels.is_a?(Array) && urls.length == labels.length, "#{context}: each source URL must have its own label", errors)
      end
      assert(titles.uniq == titles, "#{topic_id}: comparison titles must be distinct", errors)
    end
  end

  def expected_paper_comparisons(id, comparisons, methods, canonical)
    comparisons.each_with_object([]) do |(topic_id, notes), expected|
      method = methods.find { |item| item.fetch("id") == topic_id }
      notes.each do |note|
        next unless note.fetch("source_ids").include?(id)
        expected << note.merge("topic_id" => topic_id, "topic_label" => method.fetch("label"),
                               "topic_url" => "#{canonical.delete_suffix('/')}#{method.fetch('url')}")
      end
    end
  end

  def validate_comparison_record(record, expected, context, errors)
    if expected.empty?
      assert(!record.key?("method_comparisons"), "#{context}: unrelated paper received method comparisons", errors)
    else
      assert(record["method_comparisons"] == expected, "#{context}: method comparisons differ from source notes or topic metadata", errors)
    end
  end

  def validate_comparison_markdown(expected, markdown, all_titles, source_by_id, canonical, context, errors)
    rendered_titles = markdown.scan(/^\*\*(.+)\*\*$/).flatten.select { |title| all_titles.include?(title) }
    assert(rendered_titles == expected.map { |note| note.fetch("title") }, "#{context}: Markdown omits, duplicates, reorders or adds comparison notes", errors)
    expected.each do |note|
      block = markdown.split(/(?=^\*\*.+\*\*$)/).find { |part| part.start_with?("**#{note.fetch('title')}**\n") }.to_s
      assert(block.include?(note.fetch("text")), "#{context}: Markdown comparison text differs from source", errors)
      note.fetch("source_urls").each_with_index do |url, index|
        assert(block.include?("[#{note.fetch('source_labels')[index]}](#{url})"), "#{context}: comparison source lacks its matching Markdown label and URL", errors)
      end
      note.fetch("source_ids").each do |id|
        assert(block.include?("[#{source_by_id.fetch(id).fetch('title')}](#{canonical}papers/#{id}/)"), "#{context}: comparison omits named Markdown link to paper #{id}", errors)
      end
    end
  end

  def validate_comparison_html(expected, html, source_by_id, canonical, context, errors)
    blocks = html.scan(/<div\b[^>]*class="lit-method-comparison"[^>]*>.*?<\/div>/m)
    assert(blocks.length == expected.length, "#{context}: HTML omits or adds comparison notes", errors)
    expected.each_with_index do |note, index|
      block = blocks[index].to_s
      heading = block[/<h3\b[^>]*>.*?<\/h3>/m].to_s
      assert(visible_text(heading) == note.fetch("title"), "#{context}: comparison heading differs from source or is out of order", errors)
      assert(visible_text(block).include?(note.fetch("text").gsub(/\s+/, " ")), "#{context}: visible comparison text differs from source", errors)
      note.fetch("source_urls").each_with_index do |url, source_index|
        assert(named_link?(block, url, note.fetch("source_labels")[source_index], canonical), "#{context}: comparison source lacks its matching visible label and URL", errors)
      end
      note.fetch("source_ids").each do |id|
        assert(named_link?(block, "#{canonical}papers/#{id}/", source_by_id.fetch(id).fetch("title"), canonical), "#{context}: comparison omits named HTML link to paper #{id}", errors)
      end
    end
  end

  def validate_comparison_regressions(errors)
    canonical = "https://example.test/"
    papers = {"2301.00001" => {"title" => "First paper"}, "2401.00001" => {"title" => "Second paper"}}
    methods = [{"id" => "test-topic", "label" => "Test topic", "url" => "/topics/test/"}]
    note = {"title" => "Two methods", "text" => "A source-backed technical distinction.",
            "source_ids" => papers.keys, "source_urls" => ["https://example.test/first#S3", "https://example.test/second#S3"],
            "source_labels" => ["First paper, §3", "Second paper, §3"]}
    cases = [
      ["valid source", {}, true],
      ["missing title", {"title" => nil}, false],
      ["blank title", {"title" => "  "}, false],
      ["missing text", {"text" => nil}, false],
      ["blank text", {"text" => "\n"}, false],
      ["missing IDs", {"source_ids" => nil}, false],
      ["empty IDs", {"source_ids" => []}, false],
      ["unknown ID", {"source_ids" => ["9901.00001"]}, false],
      ["duplicate IDs", {"source_ids" => ["2301.00001", "2301.00001"]}, false],
      ["missing URLs", {"source_urls" => nil}, false],
      ["empty URLs", {"source_urls" => []}, false],
      ["relative URL", {"source_urls" => ["/source", "https://example.test/second#S3"]}, false],
      ["insecure URL", {"source_urls" => ["http://example.test/first", "https://example.test/second#S3"]}, false],
      ["duplicate URLs", {"source_urls" => ["https://example.test/first", "https://example.test/first"]}, false],
      ["missing labels", {"source_labels" => nil}, false],
      ["blank label", {"source_labels" => [" ", "Second paper, §3"]}, false],
      ["unpaired source label", {"source_labels" => ["First paper, §3"]}, false]
    ]
    cases.each do |name, changes, valid|
      observed = []
      validate_comparison_sources({"test-topic" => [note.merge(changes)]}, papers, methods, observed)
      assert(observed.empty? == valid, "comparison regression #{name}: source validation did not #{valid ? 'accept' : 'reject'} the fixture", errors)
    end

    expected = expected_paper_comparisons("2301.00001", {"test-topic" => [note]}, methods, canonical)
    records = [
      ["matching export", {"method_comparisons" => expected}, expected, true],
      ["changed export text", {"method_comparisons" => [expected.first.merge("text" => "Changed")]}, expected, false],
      ["missing topic metadata", {"method_comparisons" => [note]}, expected, false],
      ["unrelated record", {}, [], true],
      ["unrelated record with notes", {"method_comparisons" => expected}, [], false],
      ["unrelated record with empty field", {"method_comparisons" => []}, [], false]
    ]
    records.each do |name, record, notes, valid|
      observed = []
      validate_comparison_record(record, notes, name, observed)
      assert(observed.empty? == valid, "comparison regression #{name}: record parity did not #{valid ? 'accept' : 'reject'} the fixture", errors)
    end

    source_links = note.fetch("source_urls").each_with_index.map { |url, index| "<a href=\"#{url}\">#{note.fetch('source_labels')[index]}</a>" }.join(" ")
    paper_links = papers.map { |id, paper| "<a href=\"/papers/#{id}/\">#{paper.fetch('title')}</a>" }.join(" ")
    html = "<div class=\"lit-method-comparison\"><h3>#{note.fetch('title')}</h3><p>#{note.fetch('text')}</p>#{source_links}#{paper_links}</div>"
    {"matching HTML" => [html, true], "unnamed HTML source" => [html.sub("First paper, §3", ""), false],
     "wrong HTML source URL" => [html.sub("first#S3", "different#S3"), false],
     "wrong HTML paper link" => [html.sub("/papers/2301.00001/", "/papers/9901.00001/"), false]}.each do |name, (content, valid)|
      observed = []
      validate_comparison_html(expected, content, papers, canonical, name, observed)
      assert(observed.empty? == valid, "comparison regression #{name}: HTML checks did not #{valid ? 'accept' : 'reject'} the fixture", errors)
    end
    markdown = ["**#{note.fetch('title')}**", note.fetch("text"),
                note.fetch("source_urls").each_with_index.map { |url, index| "[#{note.fetch('source_labels')[index]}](#{url})" }.join(" · "),
                papers.map { |id, paper| "[#{paper.fetch('title')}](#{canonical}papers/#{id}/)" }.join(" · ")].join("\n\n")
    {"matching Markdown" => [markdown, true], "missing Markdown note" => [markdown.sub(note.fetch("text"), ""), false],
     "unnamed Markdown source" => [markdown.sub("First paper, §3", ""), false],
     "wrong Markdown paper link" => [markdown.sub("/papers/2301.00001/", "/papers/9901.00001/"), false]}.each do |name, (content, valid)|
      observed = []
      validate_comparison_markdown(expected, content, [note.fetch("title")], papers, canonical, name, observed)
      assert(observed.empty? == valid, "comparison regression #{name}: Markdown checks did not #{valid ? 'accept' : 'reject'} the fixture", errors)
    end
    pinned = "https://arxiv.org/html/2311.01460v1#S2.SS3"
    pinned_note = note.merge("source_urls" => [pinned], "source_labels" => ["2023 proposal, §2.3"])
    pinned_expected = expected_paper_comparisons("2301.00001", {"test-topic" => [pinned_note]}, methods, canonical)
    pinned_html = html.sub(source_links, "<a href=\"#{pinned}\">2023 proposal, §2.3</a>")
    pinned_markdown = markdown.sub(note.fetch("source_urls").each_with_index.map { |url, index| "[#{note.fetch('source_labels')[index]}](#{url})" }.join(" · "), "[2023 proposal, §2.3](#{pinned})")
    [pinned, pinned.sub("v1", ""), pinned.sub("#S2.SS3", ""), "https://arxiv.org/abs/2311.01460"].each_with_index do |url, index|
      observed = []
      validate_comparison_html(pinned_expected, pinned_html.sub(pinned, url), papers, canonical, "pinned source", observed)
      assert(observed.empty? == index.zero?, "comparison regression: HTML must preserve source version and section", errors)
      observed = []
      validate_comparison_markdown(pinned_expected, pinned_markdown.sub(pinned, url), [note.fetch("title")], papers, canonical, "pinned source", observed)
      assert(observed.empty? == index.zero?, "comparison regression: Markdown must preserve source version and section", errors)
    end
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

  def arxiv_source?(paper)
    paper.key?("arxiv") || (paper.key?("connection") && paper["id"].to_s.match?(/\A\d{4}\.\d{4,5}\z/) && paper["paper_url"] == "https://arxiv.org/abs/#{paper['id']}")
  end

  def full_text_links(paper)
    links = {}
    links["PDF"] = "https://arxiv.org/pdf/#{paper.fetch('id')}" if arxiv_source?(paper)
    links["HTML"] = paper["html_url"] if paper["html_url"]
    links
  end

  def validate_full_text_record(paper, record, context, errors)
    assert(record["paper_url"] == paper["paper_url"], "#{context}: primary source URL must remain the landing page", errors)
    expected = full_text_links(paper)
    %w[PDF HTML].each do |label|
      field = "#{label.downcase}_url"
      if expected[label]
        assert(record[field] == expected[label], "#{context}: #{field} differs from the source-specific full-text URL", errors)
      else
        assert(!record.key?(field), "#{context}: #{field} was invented for an unchecked format", errors)
      end
    end
    if paper["html_url"]
      assert(arxiv_source?(paper) && paper["html_url"].match?(%r{\Ahttps://arxiv\.org/html/#{Regexp.escape(paper.fetch('id'))}(?:v[1-9]\d*)?\z}), "#{context}: HTML link must identify this arXiv paper", errors)
    end
  end

  def validate_full_text_html(paper, html, context, errors)
    %w[PDF HTML].each do |label|
      expected = full_text_links(paper)[label]
      links = html.scan(/<a\b[^>]*>.*?<\/a>/m).select { |anchor| visible_text(anchor) == "#{label} ↗" }
      urls = links.flat_map { |anchor| attributes(anchor, "a").map { |attrs| attrs["href"] } }
      assert(urls == (expected ? [expected] : []), "#{context}: #{label} link must be separately labeled and use its matching full-text URL", errors)
    end
  end

  def validate_full_text_markdown(paper, markdown, context, errors)
    %w[PDF HTML].each do |label|
      expected = full_text_links(paper)[label]
      urls = markdown.scan(/\[#{label}\]\(([^)]+)\)/).flatten
      assert(urls == (expected ? [expected] : []), "#{context}: Markdown #{label} link must be separately labeled and use its matching full-text URL", errors)
    end
  end

  def validate_full_text_regressions(errors)
    paper = {"id" => "2311.01460", "arxiv" => "2311.01460", "paper_url" => "https://arxiv.org/abs/2311.01460", "html_url" => "https://arxiv.org/html/2311.01460v1"}
    valid = paper.merge("pdf_url" => "https://arxiv.org/pdf/2311.01460")
    doi = {"id" => "journal2026example", "doi" => "10.1234/example", "paper_url" => "https://doi.org/10.1234/example"}
    {
      "matching formats" => [paper, valid, true],
      "PDF as primary source" => [paper, valid.merge("paper_url" => valid["pdf_url"]), false],
      "legacy PDF suffix" => [paper, valid.merge("pdf_url" => valid["pdf_url"] + ".pdf"), false],
      "wrong PDF identity" => [paper, valid.merge("pdf_url" => "https://arxiv.org/pdf/2405.14838"), false],
      "missing PDF" => [paper, valid.reject { |key, _| key == "pdf_url" }, false],
      "changed HTML version" => [paper, valid.merge("html_url" => "https://arxiv.org/html/2311.01460"), false],
      "invented HTML" => [paper.reject { |key, _| key == "html_url" }, valid, false],
      "DOI without guessed formats" => [doi, doi, true],
      "DOI with guessed PDF" => [doi, doi.merge("pdf_url" => "https://arxiv.org/pdf/journal2026example"), false],
      "DOI with null PDF" => [doi, doi.merge("pdf_url" => nil), false]
    }.each do |name, (source, record, accepted)|
      observed = []
      validate_full_text_record(source, record, name, observed)
      assert(observed.empty? == accepted, "full-text regression #{name}: record check did not #{accepted ? 'accept' : 'reject'} fixture", errors)
    end
    html = full_text_links(paper).map { |label, url| "<a href=\"#{url}\">#{label} ↗</a>" }.join(" ")
    markdown = full_text_links(paper).map { |label, url| "[#{label}](#{url})" }.join(" · ")
    {"matching links" => [html, markdown, true],
     "unlabeled PDF" => [html.sub("PDF ↗", "Paper ↗"), markdown.sub("[PDF]", "[Paper]"), false],
     "suffix PDF" => [html.sub("/pdf/2311.01460", "/pdf/2311.01460.pdf"), markdown.sub("/pdf/2311.01460", "/pdf/2311.01460.pdf"), false],
     "changed HTML version" => [html.sub("01460v1", "01460v2"), markdown.sub("01460v1", "01460v2"), false]}.each do |name, (html_content, markdown_content, accepted)|
      observed = []
      validate_full_text_html(paper, html_content, name, observed)
      assert(observed.empty? == accepted, "full-text regression #{name}: HTML check did not #{accepted ? 'accept' : 'reject'} fixture", errors)
      observed = []
      validate_full_text_markdown(paper, markdown_content, name, observed)
      assert(observed.empty? == accepted, "full-text regression #{name}: Markdown check did not #{accepted ? 'accept' : 'reject'} fixture", errors)
    end
  end

  def validate_canonical_source(paper, publication, errors)
    id = paper.fetch("id")
    assert(PublicFiles.safe_paper_id?(id), "#{id}: unsafe record identifier", errors)
    if arxiv_source?(paper)
      assert(paper["paper_url"] == "https://arxiv.org/abs/#{id}" && (!paper.key?("arxiv") || paper["arxiv"] == id), "#{id}: arXiv identifier and source URL must agree", errors)
      return
    end
    validate_publication_source(id, publication, paper, errors)
    return unless publication.is_a?(Hash)

    assert(paper["doi"].to_s.match?(%r{\A10\.\d{4,9}/\S+\z}) && paper["doi"] == publication["doi"], "#{id}: DOI-only entry needs the verified publication DOI", errors)
    assert(paper["paper_url"] == publication["url"], "#{id}: DOI-only entry must link to its verified publication", errors)
    assert(paper["title"] == publication["title"] && paper["authors"].to_s.split(", ") == publication["author_names"], "#{id}: DOI-only title and authors must match the publication", errors)
    assert(paper.fetch("citation_date", paper["first_public"]).to_s[0, 4].to_i == publication["year"], "#{id}: DOI-only citation date must match publication year", errors)
  end

  def validate_citation_source_regressions(errors)
    paper = {"id" => "journal2026example", "title" => "Journal example", "authors" => "A. Author", "first_public" => "2026-01-01", "doi" => "10.1234/example", "paper_url" => "https://doi.org/10.1234/example"}
    publication = {"title" => paper["title"], "author_names" => ["A. Author"], "year" => 2026, "type" => "article-journal", "container_title" => "Example Journal", "doi" => paper["doi"], "url" => paper["paper_url"], "source_url" => paper["paper_url"], "verified_at" => "2026-01-01"}
    {
      "verified DOI source" => [paper, publication, true],
      "missing verified publication" => [paper, nil, false],
      "missing DOI" => [paper.reject { |key, _| key == "doi" }, publication, false],
      "wrong publication DOI" => [paper, publication.merge("doi" => "10.1234/other"), false],
      "wrong publication author" => [paper, publication.merge("author_names" => ["Other Author"]), false],
      "wrong publication URL" => [paper, publication.merge("url" => "https://example.org/other"), false],
      "invented arXiv ID" => [paper.merge("arxiv" => "2601.00001"), publication, false],
      "unsafe slug" => [paper.merge("id" => "../journal2026example"), publication, false],
      "arXiv source" => [{"id" => "2601.00001", "arxiv" => "2601.00001", "paper_url" => "https://arxiv.org/abs/2601.00001"}, nil, true],
      "legacy arXiv precursor" => [{"id" => "2601.00001", "connection" => "Background", "paper_url" => "https://arxiv.org/abs/2601.00001"}, nil, true]
    }.each do |name, (record, pub, valid)|
      observed = []
      validate_canonical_source(record, pub, observed)
      assert(observed.empty? == valid, "citation source regression #{name}: did not #{valid ? 'accept' : 'reject'} fixture", errors)
    end
    ["../escape", "/absolute", "a/b", "a\\b", "a..b", "a%2fb", "a\nb", "A-title", "-title", "title-"].each do |id|
      assert(!PublicFiles.safe_paper_id?(id), "unsafe record path accepted: #{id.inspect}", errors)
    end
  end

  def validate(repo_root, site_root)
    errors = []
    validate_comparison_regressions(errors)
    validate_dataset_regressions(errors)
    validate_citation_source_regressions(errors)
    validate_full_text_regressions(errors)
    papers = load_yaml(repo_root, "papers")
    precursors = load_yaml(repo_root, "precursors")
    methods = load_yaml(repo_root, "methods")
    meta = load_yaml(repo_root, "meta")
    publications = load_yaml(repo_root, "publications") || {}
    comparisons = load_yaml(repo_root, "comparisons") || {}
    demos = load_yaml(repo_root, "demos") || []
    records = papers + precursors
    source_by_id = records.each_with_object({}) { |paper, hash| hash[paper.fetch("id")] = paper }
    canonical = meta.fetch("canonical_url")
    validate_dataset_discovery(site_root, meta, errors)
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
    full_markdown = read_file(site_root, "data/reading-list.md", errors)
    recent_html = read_file(site_root, "recent/index.html", errors)
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
    before_comparison_validation = errors.length
    validate_comparison_sources(comparisons, source_by_id, methods, errors)
    return errors unless errors.length == before_comparison_validation
    comparison_titles = comparisons.values.flatten.map { |note| note.fetch("title") }
    validate_demo_sources(demos, source_by_id, methods, errors)
    validate_demo_discovery(demos, site_root, canonical, errors)
    validate_history_discovery(repo_root, site_root, canonical, errors)
    validate_alias_sources(source_by_id, errors)
    validate_proposal_discovery(source_by_id, comparisons, site_root, errors)

    records.each_with_index do |paper, index|
      id = paper.fetch("id")
      validate_canonical_source(paper, publications[id], errors)
      preprint = arxiv_source?(paper)
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

      validate_full_text_record(paper, record, id, errors)
      validate_full_text_html(paper, html, id, errors)
      validate_full_text_markdown(paper, markdown, id, errors)
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
      assert(csl.length == 1 && csl.first == aggregate_csl.find { |item| item["id"] == citation_key }, "#{id}: standalone CSL differs from the aggregate citation", errors)
      assert(csl.length == 1 && csl.first["title"] == paper["title"], "#{id}: citation title must remain the original paper title", errors)
      entries = bib_entries(bib)
      assert(entries.keys == [citation_key] && entries[citation_key] == aggregate_bib[citation_key], "#{id}: standalone BibTeX differs from aggregate citation", errors)
      unless preprint
        published = publication_csl.find { |item| item["id"] == citation_key + "_published" }
        assert(published && csl.first && csl.first.reject { |key, _| key == "id" } == published.reject { |key, _| key == "id" }, "#{id}: DOI-only canonical CSL differs from verified publication", errors)
        assert(entries[citation_key] == publication_bib[citation_key + "_published"], "#{id}: DOI-only canonical BibTeX differs from verified publication", errors)
        assert(bib.start_with?(publications.dig(id, "type") == "paper-conference" ? "@inproceedings{" : "@article{"), "#{id}: DOI-only BibTeX must use a publication type", errors)
        assert(!visible.match?(/arxiv|preprint citation/i) && !markdown.match?(/arxiv|\[Preprint (?:BibTeX|CSL-JSON)\]/i), "#{id}: DOI-only page invents an arXiv/preprint version", errors)
        assert(!bib.include?("archivePrefix") && !bib.include?("eprint =") && csl.first && !csl.first.key?("archive") && csl.first["genre"] != "Preprint", "#{id}: DOI-only citations contain preprint fields", errors)
      end
      related_terms = paper.fetch("related_terms", [])
      assert(record.fetch("related_terms", []) == related_terms, "#{id}: exported related terms differ from source", errors)
      row = old_index[/<article\b[^>]*id="#{Regexp.escape(prefix + id.tr('.', '-'))}"[^>]*>.*?<\/article>/m].to_s
      full_entry = full_markdown.split(/^### /).find { |entry| entry.start_with?("#{paper['first_public']} — #{paper['title']}\n") }.to_s
      validate_full_text_html(paper, row, "#{id} full list", errors)
      validate_full_text_markdown(paper, full_entry, "#{id} full list", errors)
      if paper["added_at"]
        recent_row = recent_html.scan(/<article\b[^>]*>.*?<\/article>/m).find { |entry| linked?(entry, paper["paper_url"], canonical) }.to_s
        validate_full_text_html(paper, recent_row, "#{id} recent additions", errors)
      end
      expected_comparisons = expected_paper_comparisons(id, comparisons, methods, canonical)
      validate_comparison_record(record, expected_comparisons, id, errors)
      validate_comparison_html(expected_comparisons, html, source_by_id, canonical, id, errors)
      validate_comparison_markdown(expected_comparisons, markdown, comparison_titles, source_by_id, canonical, id, errors)
      validate_comparison_markdown(expected_comparisons, full_entry, comparison_titles, source_by_id, canonical, "#{id} full reading list", errors)
      if expected_comparisons.empty?
        assert(!html.include?('class="lit-section lit-paper-comparisons"') && !markdown.include?("## Method comparisons"), "#{id}: unrelated paper received a comparisons section", errors)
      else
        assert(markdown.scan(/^## Method comparisons$/).length == 1, "#{id}: comparisons need one second-level Markdown heading", errors)
        assert(html.include?('class="lit-section lit-paper-comparisons"') && html.include?("<h2>Method comparisons</h2>"), "#{id}: visible comparisons need a named section", errors)
      end
      related_terms.each do |term|
        assert(visible.include?(term) && markdown.include?(term), "#{id}: related term #{term.inspect} is missing from the visible paper page or Markdown", errors)
        assert(visible_text(row).include?(term), "#{id}: related term #{term.inspect} is not visible in the paper list", errors)
        assert(full_entry.include?(term), "#{id}: full Markdown entry omits related term #{term.inspect}", errors)
      end
      expected_demos = demos.each_with_object([]) do |demo, selected|
        link = demo.fetch("paper_relationships").find { |item| item["paper_id"] == id }
        selected << demo.merge("relationship" => link.fetch("relationship")) if link
      end
      assert(record.fetch("demos", []) == expected_demos, "#{id}: demo links or direct/related relationships differ from source", errors)
      expected_demos.each do |demo|
        label = demo["relationship"] == "implementation" ? "Demo" : "Related-method demo"
        assert(visible.include?("#{label}: #{demo['title']}"), "#{id}: visible demo relationship differs from exported relationship", errors)
        %w[url model_url].each do |field|
          assert(linked?(html, demo.fetch(field), canonical) && markdown.include?(demo.fetch(field)), "#{id}: demo #{field} is not available in HTML and Markdown", errors)
        end
        assert(markdown.include?("#{label}: [#{demo['title']}]"), "#{id}: Markdown omits demo relationship", errors)
        assert(markdown.include?(demo["description"]) && markdown.include?(demo["limitations"]), "#{id}: Markdown omits demo description or limitations", errors)
        if demo["relationship"] == "related_method"
          assert(visible.include?("Related-method demos are not implementations of this paper"), "#{id}: related demo could be mistaken for this paper's implementation", errors)
        end
      end
      if expected_demos.empty?
        assert(!record.key?("demos") && !html.include?('class="lit-paper-demos"') && !markdown.include?("## Demos"), "#{id}: unrelated paper received a default demo", errors)
      end

      structured = json_ld(html, "#{path}/index.html", errors)
      page = structured.find { |item| item["@type"] == "WebPage" }
      assert(page && page["url"] == url && page["@context"] == "https://schema.org", "#{id}: WebPage structured data does not identify its canonical page", errors)
      article = page && page["mainEntity"]
      assert(!article.nil?, "#{id}: paper page lacks scholarly structured data", errors)
      if article
        assert(article["@type"] == "ScholarlyArticle" && article["name"] == paper["title"] && article["description"] == summary, "#{id}: structured article differs from visible title or summary", errors)
        assert(article["author"] == authors.map { |name| {"@type" => "Person", "name" => name} }, "#{id}: structured article authors differ from visible authors", errors)
        identifier = {"@type" => "PropertyValue", "propertyID" => preprint ? "arXiv" : "DOI", "value" => preprint ? id : paper["doi"]}
        assert(article["identifier"] == identifier, "#{id}: structured article identifier differs", errors)
        assert([paper["paper_url"], url].include?(article["url"]), "#{id}: structured article URL points at another work", errors)
        assert(article.fetch("keywords", []) == related_terms, "#{id}: scholarly keywords differ from the visible related terms", errors)
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
      validate_topic(method, methods, papers, source_by_id, generated_by_id, comparisons, demos, meta, canonical, site_root, errors)
    end

    errors
  end

  def validate_history_discovery(repo_root, site_root, canonical, errors)
    history = "Yuntian Deng and colleagues first proposed implicit chain-of-thought reasoning in 2023: training language models to reason through continuous hidden states rather than write out explicit intermediate steps. The paper's distillation method is one implementation of that proposal. Their 2024 work introduced step-by-step internalization."
    sources = {"2023" => "https://arxiv.org/html/2311.01460v1#S2.SS3",
               "distillation method" => "https://arxiv.org/html/2311.01460v1#S3",
               "2024 work" => "https://arxiv.org/abs/2405.14838"}
    %w[index.html topics/index.html].each do |path|
      html = read_file(site_root, path, errors)
      paragraph = html[/<p\b[^>]*class="[^"]*\blit-history\b[^"]*"[^>]*>.*?<\/p>/m].to_s
      history_text = CGI.unescapeHTML(paragraph.gsub(/<[^>]*>/, "")).gsub(/\s+/, " ").strip
      assert(history_text == history, "#{path}: visible history differs from the source-linked introduction", errors)
      %w[latent\ reasoning latent\ chain-of-thought].each do |term|
        assert(visible_text(html).include?(term), "#{path}: introduction omits related term #{term}", errors)
      end
      sources.each do |label, url|
        assert(linked?(paragraph, url, canonical), "#{path}: history omits the #{label} primary source", errors)
      end
      assert(html.index(paragraph).to_i < html.index("</header>").to_i, "#{path}: history must remain in the introductory header", errors) if path == "topics/index.html"
      assert(html.index(paragraph).to_i < html.index('class="lit-actions"').to_i, "#{path}: history must precede homepage browsing actions", errors) if path == "index.html"
    end
    {"llms.txt" => site_root, "data/reading-list.md" => site_root, "README.md" => repo_root}.each do |path, root|
      text = read_file(root, path, errors)
      paragraph = text.split(/\n\s*\n/).find { |part| part.start_with?("Yuntian Deng and colleagues") }.to_s
      plain_text = paragraph.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      assert(plain_text == history, "#{path}: history differs from the visible introduction", errors)
      %w[latent\ reasoning latent\ chain-of-thought].each do |term|
        assert(text.include?(term), "#{path}: guide omits related term #{term}", errors)
      end
      sources.each do |label, url|
        assert(paragraph.include?("[#{label}](#{url})"), "#{path}: history omits the #{label} primary source", errors)
      end
    end
    guide = read_file(site_root, "llms.txt", errors)
    assert(guide.include?("`related_terms`"), "agent guide does not explain the related_terms field", errors)
  end

  def validate_proposal_discovery(source_by_id, comparisons, site_root, errors)
    id = "2311.01460"
    title = "Implicit CoT: proposal and implementation"
    sources = ["https://arxiv.org/html/2311.01460v1#S2.SS3", "https://arxiv.org/html/2311.01460v1#S3"]
    paper = source_by_id.fetch(id)
    assert(paper["lens"] == ["internalized"] && paper["computation"] == ["depth-wise"],
           "#{id}: broader proposal credit must not reclassify the implemented method as recurrent state feedback", errors)

    note = Array(comparisons["continuous"]).find { |item| item["title"] == title }
    assert(!note.nil?, "continuous topic: missing the proposal-versus-implementation comparison", errors)
    return unless note

    text = note.fetch("text")
    assert(note.fetch("source_ids").include?(id) && (sources - note.fetch("source_urls")).empty?,
           "#{id}: proposal and implementation need their distinct original-paper section links", errors)
    assert(text.match?(/propos/i) && text.match?(/continuous hidden states/i) && text.match?(/implement/i) &&
           text.match?(/distill/i) && text.match?(/(?:across|through|different|successive)[^.]*layers|depth[- ]wise/i),
           "#{id}: comparison must distinguish the continuous-hidden-state proposal from across-layer distillation", errors)

    # General comparison checks below enforce complete text, labels and source
    # parity. These checks pin the discovery routes where this distinction must
    # remain available, without adding the implemented method to a new category.
    %w[topics/continuous-states/index.html data/topics/continuous-states.md papers/2311.01460/index.html papers/2311.01460/index.md].each do |path|
      rendered = read_file(site_root, path, errors)
      assert(rendered.include?(title) && sources.all? { |url| rendered.include?(url) },
             "#{path}: proposal-versus-implementation note or its original-paper sources are missing", errors)
    end
    {"data/topics/continuous-states.json" => "comparisons", "papers/2311.01460/record.json" => "method_comparisons"}.each do |path, field|
      json = read_json(site_root, path, errors)
      exported = json.is_a?(Hash) && Array(json[field]).find { |item| item["title"] == title }
      assert(exported && note.all? { |key, value| exported[key] == value },
             "#{path}: source-backed proposal-versus-implementation note is missing or changed", errors)
    end
  end

  def validate_alias_sources(source_by_id, errors)
    source_by_id.each do |id, paper|
      next unless paper.key?("related_terms")
      terms = paper["related_terms"]
      assert(terms.is_a?(Array) && !terms.empty? && terms.all? { |term| term.is_a?(String) && !term.strip.empty? } && terms.uniq == terms,
             "#{id}: related terms must be a nonempty array of distinct strings", errors)
    end
    {"2311.01460" => "Implicit Chain of Thought Reasoning via Knowledge Distillation",
     "2405.14838" => "From Explicit CoT to Implicit CoT: Learning to Internalize CoT Step by Step"}.each do |id, title|
      paper = source_by_id[id]
      assert(paper && paper["title"] == title, "#{id}: terminology aliases must not replace the original title", errors)
      expected = ["implicit CoT", "latent reasoning", "latent chain-of-thought", "latent CoT"]
      assert(paper && (expected - Array(paper["related_terms"])).empty?, "#{id}: implicit/latent terminology aliases are missing", errors)
    end
  end

  def validate_demo_sources(demos, source_by_id, methods, errors)
    assert(demos.map { |demo| demo["id"] }.uniq.length == demos.length, "demo IDs are not unique", errors)
    topic_ids = methods.map { |method| method["id"] }
    demos.each do |demo|
      id = demo["id"]
      %w[id title label description limitations model url model_url].each do |field|
        assert(demo[field].is_a?(String) && !demo[field].strip.empty?, "#{id}: demo lacks #{field}", errors)
      end
      %w[url model_url].each do |field|
        assert(demo[field].to_s.match?(%r{\Ahttps://[^/]+/}), "#{id}: demo #{field} must be HTTPS", errors)
      end
      assert(!Array(demo["topic_ids"]).empty? && (Array(demo["topic_ids"]) - topic_ids).empty?, "#{id}: demo topics are missing or unknown", errors)
      links = Array(demo["paper_relationships"])
      assert(!links.empty? && links.map { |link| link["paper_id"] }.uniq.length == links.length, "#{id}: demo paper relationships are empty or duplicated", errors)
      links.each do |link|
        assert(source_by_id.key?(link["paper_id"]) && %w[implementation related_method].include?(link["relationship"]), "#{id}: demo paper relationship is unknown", errors)
      end
      assert(links.any? { |link| link["relationship"] == "implementation" }, "#{id}: demo must identify its implemented method", errors)
    end
    # These examples implement stepwise internalization, not the earlier
    # knowledge-distillation method. Preserve that distinction across exports.
    {"multiplication" => ["gpt2-multiplication", "gpt2-implicit-cot-multiplication-20-digits"],
     "math-word-problems" => ["implicit-cot-math", "implicit-cot-math-mistral7b"]}.each do |id, paths|
      demo = demos.find { |item| item["id"] == id }
      assert(!demo.nil?, "expected demo #{id} is missing", errors)
      next unless demo
      expected_links = [{"paper_id" => "2405.14838", "relationship" => "implementation"},
                        {"paper_id" => "2311.01460", "relationship" => "related_method"}]
      assert(demo["paper_relationships"] == expected_links, "#{id}: stepwise internalization and related distillation relationships changed", errors)
      assert(demo["url"] == "https://huggingface.co/spaces/yuntian-deng/#{paths[0]}" && demo["model_url"] == "https://huggingface.co/yuntian-deng/#{paths[1]}", "#{id}: demo and model links do not match", errors)
    end
  end

  def validate_demo_discovery(demos, site_root, canonical, errors)
    html = read_file(site_root, "index.html", errors)
    shortcuts = html[/<p class="lit-demo-shortcuts">.*?<\/p>/m].to_s
    assert(!shortcuts.empty? && html.index('class="lit-actions"').to_i < html.index(shortcuts).to_i && html.index(shortcuts).to_i < html.index('class="lit-status"').to_i, "homepage demo links must follow the main actions, before status", errors)
    demos.each do |demo|
      assert(linked?(shortcuts, demo["url"], canonical) && visible_text(shortcuts).include?(demo["label"]), "homepage omits demo #{demo['id']}", errors)
    end
    assert(!html.match?(/<iframe\b/i), "homepage must not automatically embed demo inference", errors)
    guide = read_file(site_root, "llms.txt", errors)
    %w[demos paper_relationships implementation related_method].each do |term|
      assert(guide.include?("`#{term}`"), "agent guide omits demo field #{term}", errors)
    end
    reading_list = read_file(site_root, "data/reading-list.md", errors)
    demos.each do |demo|
      [demo["title"], demo["url"], demo["model_url"], demo["description"], demo["limitations"]].each do |text|
        assert(reading_list.include?(text), "full Markdown list omits demo #{demo['id']} metadata", errors)
      end
    end
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
    {"doi" => "DOI", "volume" => "volume", "issue" => "issue"}.each do |source_key, csl_key|
      assert(citation[csl_key] == publication[source_key], "#{id}: publication #{csl_key} differs from verified metadata", errors)
    end
    assert(citation["page"] == (publication["pages"] || publication["article_number"]), "#{id}: publication pages or article number differs", errors)
    assert(!citation.key?("archive") && !citation.key?("number") && citation["genre"] != "Preprint", "#{id}: publication citation incorrectly describes a preprint", errors)
    entry = entries.fetch(key, "")
    assert(entry.match?(/year\s*=\s*\{\s*#{publication['year']}\s*\}/), "#{id}: publication BibTeX year differs", errors)
    assert(entry.include?("url = {#{publication['url']}}"), "#{id}: publication BibTeX source identity differs", errors)
    downloads = arxiv_source?(paper) ? %w[publication.bib publication.csl.json] : %w[citation.bib citation.csl.json]
    downloads.each do |filename|
      assert(linked?(html, "#{canonical}#{path}/#{filename}", canonical), "#{id}: paper page omits publication download #{filename}", errors)
    end
    assert(linked?(html, publication["url"], canonical), "#{id}: publication source is not visible", errors)
    assert(visible_text(html).include?(publication["container_title"]) && visible_text(html).include?(publication["year"].to_s), "#{id}: verified publication venue and year are not visible", errors)
    assert(markdown.include?(publication["url"]) && markdown.include?(publication["container_title"]), "#{id}: Markdown omits verified publication version", errors)
  end

  def validate_topic(method, methods, papers, source_by_id, generated_by_id, comparisons, demos, meta, canonical, site_root, errors)
    id = method.fetch("id")
    slug = method.fetch("slug")
    selected = papers.select { |paper| paper.fetch("lens").include?(id) }
    expected = selected.map { |paper| generated_by_id.fetch(paper["id"]) }
    json = read_json(site_root, "data/topics/#{slug}.json", errors)
    markdown = read_file(site_root, "data/topics/#{slug}.md", errors)
    html = read_file(site_root, "#{method.fetch('url').sub(%r{\A/}, '')}index.html", errors)
    assert(json.is_a?(Hash) && json["papers"] == expected, "#{id}: topic export omits, duplicates, reorders or changes records", errors)
    topic_comparisons = comparisons.fetch(id, [])
    comparison_titles = comparisons.values.flatten.map { |note| note.fetch("title") }
    assert(json.is_a?(Hash) && json["comparisons"] == topic_comparisons, "#{id}: topic comparison JSON differs from source notes", errors)
    validate_comparison_html(topic_comparisons, html, source_by_id, canonical, "#{id} topic", errors)
    introduction = markdown.split(/^## Papers — oldest first$/, 2).first.to_s
    validate_comparison_markdown(topic_comparisons, introduction, comparison_titles, source_by_id, canonical, "#{id} topic introduction", errors)
    assert(!markdown.match?(/^## Method comparisons$/), "#{id}: per-paper comparisons escaped their Markdown paper section", errors)
    expected_demos = demos.select { |demo| demo.fetch("topic_ids").include?(id) }
    assert(json.is_a?(Hash) && json["demos"] == expected_demos, "#{id}: topic demos differ from source", errors)
    expected_demos.each do |demo|
      [demo["title"], demo["description"], demo["limitations"]].each do |text|
        assert(visible_text(html).include?(text) && markdown.include?(text), "#{id}: demo content differs between HTML and Markdown", errors)
      end
      %w[url model_url].each do |field|
        assert(linked?(html, demo[field], canonical) && markdown.include?(demo[field]), "#{id}: demo link missing in HTML or Markdown", errors)
      end
    end
    if expected_demos.empty?
      assert(!html.include?('class="lit-demo-card"') && !markdown.include?("## Try it"), "#{id}: topic received unrelated demos", errors)
    else
      assert(html.include?('id="topic-demos-title"') && !html.match?(/<iframe\b/i), "#{id}: demos must be linked examples, not automatic embeds", errors)
      assert(html.index('id="topic-demos-title"').to_i < html.index('class="lit-section lit-topic-comparisons"').to_i, "#{id}: demos should precede method comparisons", errors) unless Array(comparisons[id]).empty?
    end
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
      terms = paper.fetch("related_terms", [])
      row = html.scan(/<article\b[^>]*>.*?<\/article>/m).find { |entry| linked?(entry, paper["paper_url"], canonical) }.to_s
      entry = markdown.split(/^## /).find { |part| part.start_with?("#{paper['title']}\n") }.to_s
      validate_full_text_html(paper, row, "#{id} topic paper #{paper['id']}", errors)
      validate_full_text_markdown(paper, entry, "#{id} topic paper #{paper['id']}", errors)
      paper_comparisons = expected_paper_comparisons(paper.fetch("id"), comparisons, methods, canonical)
      validate_comparison_markdown(paper_comparisons, entry, comparison_titles, source_by_id, canonical, "#{id} topic paper #{paper['id']}", errors)
      expected_heading_count = paper_comparisons.empty? ? 0 : 1
      assert(entry.scan(/^### Method comparisons$/).length == expected_heading_count, "#{id}: paper #{paper['id']} comparisons must be nested under its Markdown heading", errors)
      terms.each do |term|
        assert(visible_text(row).include?(term) && entry.include?(term), "#{id}: paper #{paper['id']} related term #{term.inspect} is missing from the topic HTML or Markdown entry", errors)
      end
    end
    %w[json md].each do |extension|
      assert(linked?(html, "#{canonical}data/topics/#{slug}.#{extension}", canonical), "#{id}: topic page does not expose its #{extension} export", errors)
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
