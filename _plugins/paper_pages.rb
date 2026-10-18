# frozen_string_literal: true

require "json"

module Literature
  module_function

  def absolute(site, path)
    site.config.fetch("url").sub(%r{/$}, "") + site.config["baseurl"].to_s.sub(%r{/$}, "") + path
  end

  def record(site, paper)
    precursor = site.data.fetch("precursors").any? { |item| item["id"] == paper["id"] }
    path = "/papers/#{paper.fetch('id')}/"
    prefix = precursor ? "precursor-" : "paper-"
    result = paper.merge(
      "author_names" => paper.fetch("authors").split(", "),
      "record_url" => absolute(site, path),
      "legacy_record_url" => absolute(site, "/papers/##{prefix}#{paper['id'].tr('.', '-')}"),
      "citation_date" => paper.fetch("citation_date", paper.fetch("first_public")),
      "json_url" => absolute(site, path + "record.json"),
      "markdown_url" => absolute(site, path + "index.md"),
      "bibtex_url" => absolute(site, path + "citation.bib"),
      "csl_url" => absolute(site, path + "citation.csl.json")
    )
    publication = site.data.fetch("publications", {})[paper["id"]]
    if publication
      result.merge!("publication" => publication,
                    "publication_bibtex_url" => absolute(site, path + "publication.bib"),
                    "publication_csl_url" => absolute(site, path + "publication.csl.json"))
    end
    result
  end

  def key(site, paper)
    prefix = site.data.fetch("precursors").any? { |item| item["id"] == paper["id"] } ? "lit_precursor_" : "lit_"
    prefix + paper.fetch("id").tr(".", "_")
  end

  def csl(site, paper, publication = nil)
    entry = record(site, paper)
    custom = {"record_url" => entry["record_url"], "first_public" => paper["first_public"],
              "collection" => key(site, paper).start_with?("lit_precursor_") ? "precursor" : "core"}
    if publication
      value = {"id" => key(site, paper) + "_published", "type" => publication.fetch("type"),
               "title" => publication.fetch("title"), "author" => publication.fetch("author_names").map { |name| {"literal" => name} },
               "issued" => {"date-parts" => [[publication.fetch("year")]]},
               "container-title" => publication.fetch("container_title"), "URL" => publication.fetch("url"),
               "custom" => custom.merge("citation_basis" => "Verified published version; distinct from the arXiv preprint.",
                                         "source_url" => publication.fetch("source_url"), "verified_at" => publication.fetch("verified_at"))}
      {"DOI" => "doi", "page" => "pages", "volume" => "volume", "publisher" => "publisher"}.each do |target, source|
        value[target] = publication[source] if publication[source]
      end
      value
    else
      {"id" => key(site, paper), "type" => "article", "title" => paper.fetch("title"),
       "author" => entry.fetch("author_names").map { |name| {"literal" => name} },
       "issued" => {"date-parts" => [entry.fetch("citation_date").split("-").map(&:to_i)]},
       "genre" => "Preprint", "archive" => "arXiv", "number" => "arXiv:#{paper['id']}", "URL" => paper.fetch("paper_url"),
       "custom" => custom.merge("citation_basis" => "ArXiv preprint, using its initial submission date; source URL is not version-pinned.")}
    end
  end

  def tex(value)
    value.to_s.gsub(/[&%_#$]/) { |char| "\\#{char}" }
  end

  def bib(site, paper, publication = nil)
    if publication
      kind = publication.fetch("type") == "paper-conference" ? "inproceedings" : "article"
      container = kind == "inproceedings" ? "booktitle" : "journal"
      fields = {"title" => " {#{tex(publication.fetch('title'))}} ", "author" => publication.fetch("author_names").map { |name| tex(name) }.join(" and "),
                "year" => publication.fetch("year"), container => tex(publication.fetch("container_title"))}
      %w[publisher volume pages doi].each { |field| fields[field] = tex(publication[field]) if publication[field] }
      fields["url"] = publication.fetch("url")
      citation_key = key(site, paper) + "_published"
    else
      kind = "misc"
      fields = {"title" => " {#{tex(paper.fetch('title'))}} ", "author" => paper.fetch("authors").split(", ").map { |name| tex(name) }.join(" and "),
                "year" => paper.fetch("citation_date", paper.fetch("first_public"))[0, 4], "note" => "arXiv preprint",
                "eprint" => paper.fetch("id"), "archivePrefix" => "arXiv", "url" => paper.fetch("paper_url")}
      citation_key = key(site, paper)
    end
    "@#{kind}{#{citation_key},\n" + fields.map { |name, value| "  #{name} = {#{value}}" }.join(",\n") + "\n}\n"
  end

  def markdown(site, paper)
    entry = record(site, paper)
    lines = ["# #{paper.fetch('title')}", "", "Authors: #{paper.fetch('authors')}.", "",
             paper["summary"] || paper.fetch("connection"), "", "First public: #{paper.fetch('first_public')}.",
             "ArXiv initial submission: #{entry.fetch('citation_date')}.", "",
             "[Original paper](#{paper.fetch('paper_url')}) · [Reading-list entry](#{entry.fetch('record_url')})",
             "[Preprint BibTeX](#{entry.fetch('bibtex_url')}) · [Preprint CSL-JSON](#{entry.fetch('csl_url')}) · [JSON record](#{entry.fetch('json_url')})"]
    lines << "[Code](#{paper['code_url']})" if paper["code_url"]
    lines << "\nDate note: #{paper['first_public_note']} [Source](#{paper['first_public_source']})." if paper["first_public_note"]
    if entry["publication"]
      pub = entry["publication"]
      lines += ["", "## Published version", "", "#{pub['title']}. #{pub['author_names'].join(', ')}. #{pub['container_title']}, #{pub['year']}.",
                "[Publication](#{pub['url']}) · [BibTeX](#{entry['publication_bibtex_url']}) · [CSL-JSON](#{entry['publication_csl_url']})",
                "Metadata checked #{pub['verified_at']} against [the publication record](#{pub['source_url']})."]
    end
    methods = site.data.fetch("methods").select { |method| Array(paper["lens"]).include?(method["id"]) }
    unless methods.empty?
      lines += ["", "## Approaches", ""] + methods.map { |method| "- [#{method['label']}](#{absolute(site, method['url'])}): #{method['definition']}" }
    end
    lines += ["", "Summary and categories are editorial. Read the original paper to verify claims and limitations. A citation to a paper does not, by itself, establish that a later method builds on it.",
              "", "Reading-list version #{site.data.fetch('meta').fetch('version')}; literature checked through #{site.data.fetch('meta').fetch('search_refreshed_at')}.\n"]
    lines.join("\n")
  end

  module Filters
    def lit_record(paper)
      Literature.record(@context.registers[:site], paper)
    end

    def lit_csl(paper)
      Literature.csl(@context.registers[:site], paper)
    end

    def lit_bib(paper)
      Literature.bib(@context.registers[:site], paper)
    end
  end

  class GeneratedPage < Jekyll::PageWithoutAFile
    def initialize(site, path, content, attributes = {})
      super(site, site.source, File.dirname(path), File.basename(path).end_with?(".md") ? "raw.txt" : File.basename(path))
      self.content = content
      self.data = {"layout" => nil, "sitemap" => false, "render_with_liquid" => false, "permalink" => "/#{path}"}.merge(attributes)
    end
  end

  class PaperPages < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      records = site.data.fetch("papers") + site.data.fetch("precursors")
      publications = site.data.fetch("publications", {})
      publication_bib, publication_csl = [], []
      records.each do |paper|
        raise "Unsafe paper identifier" unless paper.fetch("id").match?(/\A\d{4}\.\d{4,5}\z/)
        dir = "papers/#{paper.fetch('id')}/"
        entry = Literature.record(site, paper)
        publication = publications[paper["id"]]
        site.pages << GeneratedPage.new(site, dir + "index.html", "", {
          "layout" => "paper", "permalink" => "/#{dir}", "sitemap" => true,
          "title" => paper.fetch("title"), "share-description" => paper["summary"] || paper["connection"],
          "paper" => paper, "record" => entry, "publication" => publication,
          "show-avatar" => false, "nav-short" => true, "last_modified_at" => site.data.fetch("meta").fetch("updated_at")
        })
        {"record.json" => JSON.pretty_generate(entry) + "\n", "index.md" => Literature.markdown(site, paper),
         "citation.bib" => Literature.bib(site, paper), "citation.csl.json" => JSON.pretty_generate([Literature.csl(site, paper)]) + "\n"}.each do |file, content|
          site.pages << GeneratedPage.new(site, dir + file, content)
        end
        next unless publication

        bib = Literature.bib(site, paper, publication)
        csl = Literature.csl(site, paper, publication)
        publication_bib << bib
        publication_csl << csl
        site.pages << GeneratedPage.new(site, dir + "publication.bib", bib)
        site.pages << GeneratedPage.new(site, dir + "publication.csl.json", JSON.pretty_generate([csl]) + "\n")
      end
      site.pages << GeneratedPage.new(site, "data/publications.bib", "% Verified published versions only; this is a subset, not the full reading list.\n" + publication_bib.join("\n"))
      site.pages << GeneratedPage.new(site, "data/publications.csl.json", JSON.pretty_generate(publication_csl) + "\n")
      site.data.fetch("methods").each do |method|
        papers = site.data.fetch("papers").select { |paper| paper.fetch("lens").include?(method["id"]) }
        path = "data/topics/#{method.fetch('slug')}"
        metadata = site.data.fetch("meta").slice("version", "updated_at", "search_refreshed_at").merge(
          "topic_id" => method.fetch("id"), "name" => method.fetch("label"), "definition" => method.fetch("definition"),
          "record_count" => papers.length, "topic_url" => Literature.absolute(site, method.fetch("url")),
          "source_url" => Literature.absolute(site, "/data/papers.json"))
        comparisons = site.data.fetch("comparisons", {}).fetch(method["id"], [])
        data = {"metadata" => metadata, "comparisons" => comparisons, "papers" => papers.map { |paper| Literature.record(site, paper) }}
        text = ["# #{method['label']}", method.fetch("definition"), "Papers are ordered by first public date. Read the original sources before using a claim.",
                "For example: #{method.fetch('example')}",
                "Version #{metadata['version']}; literature checked through #{metadata['search_refreshed_at']}.",
                "[Topic guide](#{metadata['topic_url']}) · [JSON](#{Literature.absolute(site, '/' + path + '.json')})"]
        unless comparisons.empty?
          text << "## How these methods differ"
          comparisons.each do |comparison|
            text << comparison.fetch("text")
            text << comparison.fetch("source_ids").map { |id| "[Paper #{id}](#{Literature.absolute(site, '/papers/' + id + '/')})" }.join(" · ")
            text << comparison.fetch("source_urls").each_with_index.map { |url, index| "[Original source #{index + 1}](#{url})" }.join(" · ")
          end
        end
        text << "## Papers — oldest first"
        papers.each { |paper| text << Literature.markdown(site, paper).sub(/^# /, "## ").gsub(/^## (Published version|Approaches)/, '### \1') }
        site.pages << GeneratedPage.new(site, path + ".json", JSON.pretty_generate(data) + "\n")
        site.pages << GeneratedPage.new(site, path + ".md", text.join("\n\n") + "\n")
      end
    end
  end
end

Liquid::Template.register_filter(Literature::Filters)
