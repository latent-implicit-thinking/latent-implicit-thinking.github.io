#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "cgi"
require "json"
require "rexml/document"
require "uri"
require "yaml"
require_relative "public_files"
require_relative "test_agent_exports"
require_relative "release_history"
require_relative "test_release_history"

def validate_against_schema(value, schema, root_schema, path, errors)
  if schema["$ref"]
    target = schema["$ref"].delete_prefix("#/").split("/").reduce(root_schema) { |node, key| node.fetch(key.gsub("~1", "/").gsub("~0", "~")) }
    return validate_against_schema(value, target, root_schema, path, errors)
  end

  errors << "#{path} is outside the declared enum" if schema["enum"] && !schema["enum"].include?(value)

  case schema["type"]
  when "object"
    unless value.is_a?(Hash)
      errors << "#{path} is not an object"
      return
    end
    Array(schema["required"]).each { |key| errors << "#{path}.#{key} is required" unless value.key?(key) }
    if schema["additionalProperties"] == false
      extras = value.keys - schema.fetch("properties", {}).keys
      errors << "#{path} has undeclared properties: #{extras.join(', ')}" unless extras.empty?
    end
    value.each do |key, child|
      child_schema = schema.fetch("properties", {})[key]
      validate_against_schema(child, child_schema, root_schema, "#{path}.#{key}", errors) if child_schema
    end
  when "array"
    unless value.is_a?(Array)
      errors << "#{path} is not an array"
      return
    end
    errors << "#{path} has too few items" if schema["minItems"] && value.length < schema["minItems"]
    errors << "#{path} contains duplicates" if schema["uniqueItems"] && value.uniq.length != value.length
    value.each_with_index { |child, index| validate_against_schema(child, schema["items"], root_schema, "#{path}[#{index}]", errors) } if schema["items"]
  when "string"
    unless value.is_a?(String)
      errors << "#{path} is not a string"
      return
    end
    errors << "#{path} does not match its pattern" if schema["pattern"] && !Regexp.new(schema["pattern"]).match?(value)
    if schema["format"] == "date"
      begin
        Date.iso8601(value)
      rescue Date::Error
        errors << "#{path} is not an ISO date"
      end
    elsif %w[uri uri-reference].include?(schema["format"])
      begin
        parsed = URI.parse(value)
        errors << "#{path} is not an absolute URI" if schema["format"] == "uri" && parsed.scheme.nil?
      rescue URI::InvalidURIError
        errors << "#{path} is not a valid URI"
      end
    end
  when "integer"
    errors << "#{path} is not an integer" unless value.is_a?(Integer)
    errors << "#{path} is below its minimum" if value.is_a?(Integer) && schema["minimum"] && value < schema["minimum"]
  end
end

repo_root = File.expand_path("..", __dir__)
site_root = File.expand_path(ARGV.fetch(0, "_site"), repo_root)
errors = []

allowed_files = PublicFiles.expected(repo_root).sort
actual_files = Dir.glob(File.join(site_root, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) || File.symlink?(path) }
actual_files.each { |path| errors << "Deployment contains a symlink: #{path}" if File.symlink?(path) }
actual_paths = actual_files.map { |path| path.delete_prefix(site_root + "/") }.sort
(actual_paths - allowed_files).each { |path| errors << "Unexpected deployment file: #{path}" }
(allowed_files - actual_paths).each { |path| errors << "Missing deployment file: #{path}" }

papers = YAML.safe_load(File.read(File.join(repo_root, "_data/papers.yml")), permitted_classes: [Date], aliases: false)
precursors = YAML.safe_load(File.read(File.join(repo_root, "_data/precursors.yml")), permitted_classes: [Date], aliases: false)
meta = YAML.safe_load(File.read(File.join(repo_root, "_data/meta.yml")), permitted_classes: [Date], aliases: false)

required_paper_fields = %w[id title authors first_public venue paper_url lens representation computation training questions evidence modality summary provenance]
array_fields = %w[lens representation computation training questions evidence modality]

errors << "paper IDs are not unique" unless papers.map { |paper| paper["id"] }.uniq.length == papers.length
errors << "precursor IDs are not unique" unless precursors.map { |paper| paper["id"] }.uniq.length == precursors.length
errors << "an ID appears in both core and precursor collections" unless (papers.map { |paper| paper["id"] } & precursors.map { |paper| paper["id"] }).empty?
errors << "papers are not ordered by first_public and ID" unless papers == papers.sort_by { |paper| [paper["first_public"].to_s, paper["id"]] }
errors << "precursors are not ordered by first_public and ID" unless precursors == precursors.sort_by { |paper| [paper["first_public"].to_s, paper["id"]] }

papers.each do |paper|
  missing = required_paper_fields.reject { |field| paper.key?(field) && !paper[field].nil? && paper[field] != "" }
  errors << "#{paper['id'] || '(missing ID)'} lacks #{missing.join(', ')}" unless missing.empty?
  errors << "#{paper['id']} has a malformed date" unless paper["first_public"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
  errors << "#{paper['id']} has a malformed paper URL" unless paper["paper_url"].to_s.match?(/\Ahttps:\/\//)
  array_fields.each do |field|
    values = paper[field]
    errors << "#{paper['id']} #{field} must be a nonempty unique array" unless values.is_a?(Array) && !values.empty? && values.uniq.length == values.length
  end
end

latest_date = papers.map { |paper| paper["first_public"].to_s }.max
errors << "latest_included_first_public should be #{latest_date}" unless meta["latest_included_first_public"].to_s == latest_date
%w[updated_at search_refreshed_at addition_tracking_started_at].each do |field|
  value = meta[field].to_s
  errors << "#{field} must be an ISO date no later than today" unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/) && value <= Date.today.iso8601
end
errors << "literature check is newer than the website update" if meta["search_refreshed_at"] > meta["updated_at"]
errors << "newest paper is later than literature coverage" if latest_date > meta["search_refreshed_at"]
tracked_papers = papers.select { |paper| paper.key?("added_at") }
tracked_papers.each do |paper|
  added = paper["added_at"].to_s
  errors << "#{paper['id']}: invalid addition date" unless added.match?(/\A\d{4}-\d{2}-\d{2}\z/) && added >= meta["addition_tracking_started_at"] && added <= meta["updated_at"] && added >= paper["first_public"]
end

generated_corpus = JSON.parse(File.read(File.join(site_root, "data/papers.json")))
ontology = JSON.parse(File.read(File.join(site_root, "data/ontology.json")))
schema = JSON.parse(File.read(File.join(site_root, "data/schema.json")))
JSON.parse(File.read(File.join(site_root, "data/changes.json")))
validate_against_schema(generated_corpus, schema, schema, "$", errors)

errors << "generated core count does not match YAML" unless generated_corpus.dig("metadata", "core_record_count") == papers.length && generated_corpus["papers"].length == papers.length
errors << "generated precursor count does not match YAML" unless generated_corpus.dig("metadata", "precursor_record_count") == precursors.length && generated_corpus["precursors"].length == precursors.length

ontology_values = {
  "lens" => ontology.fetch("research_lenses").map { |entry| entry.fetch("id") },
  "representation" => ontology.dig("axes", "representation", "values"),
  "computation" => ontology.dig("axes", "computation", "values"),
  "training" => ontology.dig("axes", "training", "values"),
  "questions" => ontology.dig("axes", "questions", "values"),
  "evidence" => ontology.dig("axes", "evidence", "values"),
  "modality" => ontology.dig("axes", "modality", "values")
}

schema_defs = {
  "lens" => "lensValues",
  "representation" => "representationValues",
  "computation" => "computationValues",
  "training" => "trainingValues",
  "questions" => "questionValues",
  "evidence" => "evidenceValues",
  "modality" => "modalityValues"
}

ontology_values.each do |field, allowed|
  schema_allowed = schema.dig("$defs", schema_defs.fetch(field), "items", "enum")
  errors << "schema and ontology disagree for #{field}" unless schema_allowed == allowed
  papers.each do |paper|
    invalid = paper.fetch(field, []) - allowed
    errors << "#{paper['id']} has invalid #{field}: #{invalid.join(', ')}" unless invalid.empty?
  end
end

bibtex = File.read(File.join(site_root, "data/papers.bib"))
expected_bib_keys = papers.map { |paper| "lit_#{paper['id'].tr('.', '_')}" } + precursors.map { |paper| "lit_precursor_#{paper['id'].tr('.', '_')}" }
actual_bib_keys = bibtex.scan(/^@\w+\{([^,]+),/).flatten
errors << "BibTeX record keys do not match core and precursor collections" unless actual_bib_keys == expected_bib_keys
all_records = papers + precursors
all_generated = generated_corpus.fetch("papers") + generated_corpus.fetch("precursors")
csl = JSON.parse(File.read(File.join(site_root, "data/papers.csl.json")))
errors << "CSL citation keys do not match core and precursor collections" unless csl.map { |item| item["id"] } == expected_bib_keys
bib_entries = bibtex.scan(/^@\w+\{([^,]+),\n(.*?)^\}/m).to_h
paper_html = File.read(File.join(site_root, "papers/index.html"))
reading_list = File.read(File.join(site_root, "data/reading-list.md"))
errors << "Markdown reading list was converted to HTML" unless reading_list.start_with?("# Implicit Chain-of-Thought") && !reading_list.include?("<html")

all_records.each_with_index do |paper, index|
  collection = index < papers.length ? "core" : "precursor"
  prefix = collection == "core" ? "paper-" : "precursor-"
  anchor = "#{prefix}#{paper.fetch('id').tr('.', '-')}"
  expected_url = "#{meta.fetch('canonical_url')}papers/#{paper.fetch('id')}/"
  legacy_url = "#{meta.fetch('canonical_url')}papers/##{anchor}"
  authors = paper.fetch("authors").split(", ")
  citation_date = paper.fetch("citation_date", paper.fetch("first_public"))
  date_parts = citation_date.split("-").map(&:to_i)
  key = expected_bib_keys.fetch(index)
  generated = all_generated.fetch(index)
  citation = csl.fetch(index, {})
  bib_entry = bib_entries.fetch(key, "")

  paper.each { |field, value| errors << "#{key}: generated #{field} differs from source" unless generated[field] == value }
  errors << "#{key}: generated authors are not lossless and ordered" unless generated["author_names"] == authors
  errors << "#{key}: generated record URL is incorrect" unless generated["record_url"] == expected_url
  errors << "#{key}: generated legacy record URL is incorrect" unless generated["legacy_record_url"] == legacy_url
  errors << "#{key}: generated citation date is incorrect" unless generated["citation_date"] == citation_date
  errors << "#{key}: map record anchor missing" unless paper_html.include?("id=\"#{anchor}\"")
  errors << "#{key}: Markdown reading list omits title, authors, source or record" unless [paper["title"], paper["authors"], paper["paper_url"], expected_url].all? { |value| reading_list.include?(value) }
  errors << "#{key}: CSL title or source differs" unless citation["title"] == paper["title"] && citation["URL"] == paper["paper_url"]
  errors << "#{key}: CSL authors are not lossless and ordered" unless citation["author"] == authors.map { |name| {"literal" => name} }
  errors << "#{key}: CSL date differs from citation version" unless citation.dig("issued", "date-parts") == [date_parts]
  errors << "#{key}: CSL collection or record URL differs" unless citation.dig("custom", "collection") == collection && citation.dig("custom", "record_url") == expected_url
  errors << "#{key}: CSL chronology differs from source" unless citation.dig("custom", "first_public") == paper["first_public"]
  errors << "#{key}: citation source is not the declared arXiv version" unless paper["paper_url"] == "https://arxiv.org/abs/#{paper['id']}" && citation["number"] == "arXiv:#{paper['id']}" && citation["archive"] == "arXiv"
  errors << "#{key}: BibTeX year differs from citation version" unless bib_entry.match?(/year\s*=\s*\{\s*#{date_parts.first}\s*\}/)
  errors << "#{key}: BibTeX authors differ" unless bib_entry.include?("author = {#{authors.join(' and ')}}")
  errors << "#{key}: BibTeX source identity differs" unless bib_entry.include?("eprint = {#{paper['id']}}") && bib_entry.include?("url = {#{paper['paper_url']}}") && bib_entry.include?("note = {arXiv preprint}")
  escaped_title = paper.fetch("title").gsub(/[&%_#$]/) { |char| "\\#{char}" }
  errors << "#{key}: BibTeX title or capitalization protection differs" unless bib_entry.include?("title = { {#{escaped_title}} }")

  if paper["citation_date"] && paper["citation_date"] != paper["first_public"]
    errors << "#{key}: chronology/citation difference lacks a source note" unless paper["first_public_source"] && paper["first_public_note"]
  end
  next unless collection == "core"

  row = paper_html.match(/<article\s+id="#{Regexp.escape(anchor)}"(.*?)<\/article>/m)&.[](1).to_s
  searchable = CGI.unescapeHTML(row[/data-search="([^"]*)"/, 1].to_s)
  [paper["id"], "arXiv:#{paper['arxiv']}", paper["venue"], paper["title"], paper["authors"]].each do |term|
    errors << "#{key}: search index omits #{term}" unless searchable.include?(term.downcase)
  end
  Array(paper["previous_titles"]).each do |title|
    errors << "#{key}: previous title is not searchable" unless searchable.include?(title.downcase)
  end
  errors << "#{key}: addition sort date differs from source" unless row.include?("data-added=\"#{paper['added_at']}\"")
end

methods = YAML.safe_load(File.read(File.join(repo_root, "_data/methods.yml")), aliases: false)
home_html = File.read(File.join(site_root, "index.html"))
topic_html = File.read(File.join(site_root, "topics/index.html"))
home_routes = home_html[/<div class="lit-route-grid".*?<\/div>/m].to_s
errors << "Homepage must have one set of topic links" unless home_html.scan('class="lit-route-grid"').length == 1 && home_routes.scan(/<a href=/).length == methods.length
errors << "Beginner guide omits its concrete example" unless topic_html.include?('id="example-title"') && topic_html.include?("booking fee")
errors << "Acknowledgment missing from homepage" unless home_html.include?("https://github.com/EIT-NLP/Awesome-Latent-CoT")
advanced_html = paper_html[/<details id="paper-advanced".*?<\/details>/m].to_s
%w[question evidence].each do |filter|
  errors << "#{filter} must be inside More filters" unless advanced_html.include?("data-filter-set=\"#{filter}\"")
end
errors << "Approach filters must remain visible" if advanced_html.include?('data-filter-set="lens"')
errors << "Advanced filter count is missing" unless advanced_html.include?('id="paper-advanced-count"')
methods.each do |method|
  method_html = File.read(File.join(site_root, method.fetch("url").sub(%r{\A/}, ""), "index.html"))
  example_offset = method_html.index('class="lit-method-example"')
  papers_offset = method_html.index('class="lit-paper-list lit-method-paper-list"')
  errors << "#{method['id']}: example must precede papers" unless example_offset && papers_offset && example_offset < papers_offset
  errors << "#{method['id']}: visible label missing from guide" unless method_html.include?("<h1>#{method['label']}</h1>")
  errors << "#{method['id']}: abstract questions returned to the guide" if method_html.include?('class="lit-method-questions"')
  errors << "#{method['id']}: homepage label differs" unless home_routes.include?(method.fetch("label"))
  papers.select { |paper| paper.fetch("lens").include?(method.fetch("id")) }.each do |paper|
    row = paper_html.match(/<article\s+id="paper-#{Regexp.escape(paper['id'].tr('.', '-'))}"(.*?)<\/article>/m)&.[](1).to_s
    searchable = CGI.unescapeHTML(row[/data-search="([^"]*)"/, 1].to_s)
    errors << "#{paper['id']}: visible category is not searchable" unless searchable.include?(method.fetch("label").downcase)
  end
end
releases = JSON.parse(File.read(File.join(site_root, "data/changes.json")))
errors << "Release history omits current version" unless JSON.generate(releases).include?(meta.fetch("version"))
release_entries = releases.fetch("releases")
errors << "Newest release does not match current version" unless release_entries.first["version"] == meta["version"]
errors.concat(ReleaseHistory.validate(release_entries, papers))
ReleaseHistoryTests.run
release_entries.each do |release|
  Array(release["updated_papers"]).each do |update|
    errors << "Malformed updated-paper entry in #{release['version']}" unless update.is_a?(Hash) && update["id"].to_s.match?(/\A\d{4}\.\d{4,5}\z/) && update["fields"].is_a?(Array) && !update["fields"].empty? && update["fields"].all? { |field| field.is_a?(String) && !field.empty? }
  end
end
recent_html = File.read(File.join(site_root, "recent/index.html"))
recent_ids = recent_html.scan(/data-paper-id="([^"]+)"/).flatten
expected_recent_ids = tracked_papers.sort_by { |paper| [paper["added_at"], paper["first_public"], paper["id"]] }.reverse.map { |paper| paper["id"] }
errors << "Recent additions are missing, duplicated, or out of order" unless recent_ids == expected_recent_ids
tracked_papers.each do |paper|
  errors << "#{paper['id']}: recent addition omits title, summary or source" unless [CGI.escapeHTML(paper["title"]), CGI.escapeHTML(paper["summary"]), paper["paper_url"]].all? { |value| recent_html.include?(value) }
end
errors << "Recent additions view is not linked from homepage" unless home_html.include?('href="/recent/"')
errors << "Recent additions sorting is missing" unless paper_html.include?('value="added-desc"')
collection_pages = {"papers/index.html" => papers}
methods.each do |method|
  collection_pages[File.join(method.fetch("url").sub(%r{\A/}, ""), "index.html")] = papers.select { |paper| paper.fetch("lens").include?(method.fetch("id")) }
end

feed = REXML::Document.new(File.read(File.join(site_root, "feed.xml")))
REXML::XPath.each(feed, "/rss/channel/item/description") do |description|
  errors << "RSS contains an empty paper entry" if description.text.to_s.include?("()") || description.text.to_s.include?("Added papers: .")
end

Dir[File.join(site_root, "**", "*.html")].each do |html_file|
  html = File.read(html_file)
  relative_path = html_file.delete_prefix(site_root + "/")
  json_ld = html.scan(/<script\s+type="application\/ld\+json"[^>]*>(.*?)<\/script>/m).flatten.map do |content|
    begin
      JSON.parse(content)
    rescue JSON::ParserError => error
      errors << "Invalid JSON-LD in #{relative_path}: #{error.message}"
      {}
    end
  end
  if collection_pages.key?(relative_path)
    expected_records = collection_pages.fetch(relative_path)
    collection = json_ld.find { |item| item["@type"] == "CollectionPage" } || {}
    items = collection.dig("mainEntity", "itemListElement") || []
    errors << "#{relative_path}: structured record count differs from visible collection" unless items.length == expected_records.length && collection.dig("mainEntity", "numberOfItems") == expected_records.length
    items.each_with_index do |item, index|
      source = expected_records[index] || {}
      scholarly = item["item"] || {}
      expected_authors = source.fetch("authors", "").split(", ").map { |name| {"@type" => "Person", "name" => name} }
      errors << "#{relative_path}: scholarly record #{index} differs from visible source" unless item["position"] == index + 1 && scholarly["@type"] == "ScholarlyArticle" && scholarly["name"] == source["title"] && scholarly["url"] == source["paper_url"] && scholarly["@id"] == source["paper_url"] && scholarly["author"] == expected_authors && scholarly["description"] == source["summary"] && scholarly.dig("identifier", "value") == source["id"]
    end
    errors << "#{relative_path}: related concepts are incorrectly marked as synonyms" if collection.dig("about", "alternateName")
  end
  html.scan(/(?:href|src)=["']([^"']+)["']/i).flatten.each do |raw|
    next if raw.empty? || raw.start_with?("//") || raw.match?(/\A(?:https?:|mailto:|tel:|javascript:|data:)/i)

    path, fragment_separator, fragment = raw.partition("#")
    fragment = nil if fragment_separator.empty?
    path, _, query = path.partition("?")
    if path.match?(/\.(?:css|js)\z/i)
      version = URI.decode_www_form(query).to_h["v"]
      errors << "#{relative_path}: unversioned or stale local asset #{raw}" unless version == meta.fetch("version")
    end
    target = if path.empty?
               html_file
             elsif path.start_with?("/")
               File.join(site_root, URI.decode_www_form_component(path.sub(%r{\A/+}, "")))
             else
               File.expand_path(URI.decode_www_form_component(path), File.dirname(html_file))
             end
    candidates = [target]
    candidates << File.join(target, "index.html") if File.extname(target).empty? || target.end_with?("/")
    resolved = candidates.find { |candidate| File.file?(candidate) }
    unless resolved
      errors << "missing internal target #{raw} from #{html_file.delete_prefix(site_root + '/')}"
      next
    end
    if fragment && !fragment.empty? && resolved.end_with?(".html")
      target_html = File.read(resolved)
      escaped_fragment = Regexp.escape(URI.decode_www_form_component(fragment))
      errors << "missing fragment ##{fragment} in #{resolved.delete_prefix(site_root + '/')}" unless target_html.match?(/(?:id|name)=["']#{escaped_fragment}["']/)
    end
  end
end

errors.concat(AgentExports.validate(repo_root, site_root))
abort(errors.uniq.sort.join("\n")) unless errors.empty?
puts "Validated #{papers.length} core papers, #{precursors.length} precursors, source/export parity, preprint and publication citations, individual paper pages, topic exports, Markdown coverage, identifier search data, scholarly JSON-LD, schema, feed, ontology, and internal links."
