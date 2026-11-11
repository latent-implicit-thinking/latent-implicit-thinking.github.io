module Literature
  class LocalizedPages < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      localization = site.data.fetch("localizations")
      languages = localization.fetch("languages")
      pairs = localization.fetch("pages")
      papers = site.data.fetch("papers") + site.data.fetch("precursors")

      site.pages.each do |page|
        language = page.data["language"] || site.config["language"] || "en"
        locale = languages.fetch(language, languages.fetch("en"))
        page.data["lit_locale"] = locale
        path = page.url.sub(/index\.html\z/, "")
        pair = pairs.find { |translation| translation.value?(path) }
        other_language = language == "zh-Hans" ? "en" : "zh-Hans"
        page.data["language_switch"] = {
          "language" => other_language,
          "name" => languages.fetch(other_language).fetch("name"),
          "url" => pair ? pair.fetch(other_language) : languages.fetch(other_language).fetch("home")
        }
        if pair
          page.data["language_alternates"] = pair.map do |code, url|
            {"language" => code, "url" => url, "locale" => languages.fetch(code).fetch("locale")}
          end
          page.data["language_default_url"] = pair.fetch("en")
        end

        next unless page.data["paper_id"]

        paper = papers.find { |entry| entry.fetch("id") == page.data.fetch("paper_id") }
        raise "Unknown localized paper: #{page.data['paper_id']}" unless paper

        page.data["paper"] = paper
        page.data["record"] = Literature.record(site, paper)
        page.data["publication"] = site.data.fetch("publications", {})[paper.fetch("id")]
      end
    end
  end
end
