# frozen_string_literal: true

require "yaml"

module PublicFiles
  def self.safe_paper_id?(id)
    id.is_a?(String) && id.match?(/\A(?:\d{4}\.\d{4,5}|[a-z][a-z0-9]*(?:-[a-z0-9]+)*)\z/)
  end

  def self.expected(repo_root)
    files = File.readlines(File.join(repo_root, "scripts/site-files.txt"), chomp: true).reject(&:empty?)
    papers = YAML.safe_load(File.read(File.join(repo_root, "_data/papers.yml"))) + YAML.safe_load(File.read(File.join(repo_root, "_data/precursors.yml")))
    publications = YAML.safe_load(File.read(File.join(repo_root, "_data/publications.yml")))
    methods = YAML.safe_load(File.read(File.join(repo_root, "_data/methods.yml")))
    papers.each do |paper|
      raise "Unsafe paper identifier" unless safe_paper_id?(paper.fetch("id"))
      %w[index.html record.json index.md citation.bib citation.csl.json].each { |name| files << "papers/#{paper['id']}/#{name}" }
      if publications.key?(paper["id"])
        %w[publication.bib publication.csl.json].each { |name| files << "papers/#{paper['id']}/#{name}" }
      end
    end
    methods.each do |method|
      raise "Unsafe topic slug" unless method.fetch("slug").match?(/\A[a-z]+(?:-[a-z]+)*\z/)
      %w[json md].each { |extension| files << "data/topics/#{method['slug']}.#{extension}" }
    end
    files.sort
  end
end

puts PublicFiles.expected(File.expand_path("..", __dir__)) if $PROGRAM_NAME == __FILE__
