#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require_relative "release_history"

module ReleaseHistoryTests
  module_function

  def run
    id = "2301.00001"
    original = {"id" => id}
    added = original.merge("added_at" => "2026-10-01")
    restored = original.merge("added_at" => "2026-10-03")
    add = {"version" => "1.0", "date" => "2026-10-01", "added_papers" => [id]}
    remove = {"version" => "1.1", "date" => "2026-10-02", "removed_papers" => [id]}
    restore = {"version" => "1.2", "date" => "2026-10-03", "added_papers" => [id]}
    cases = [
      ["initial untracked collection", [], [original], true],
      ["new addition", [add], [added], true],
      ["initial baseline removal", [remove], [], true],
      ["tracked addition then removal", [remove, add], [], true],
      ["tracked add/remove/re-add", [restore, remove, add], [restored], true],
      ["initial removal and restoration", [restore, remove], [restored], true],
      ["restoration uses latest addition date", [restore, remove, add], [added], false],
      ["restoration requires added_at", [restore, remove], [original], false],
      ["duplicate active addition", [restore, add], [restored], false],
      ["duplicate removal", [remove.merge("version" => "1.2", "date" => "2026-10-03"), remove], [], false],
      ["duplicate ID within an event", [add.merge("added_papers" => [id, id])], [added], false],
      ["same-event add and removal", [add.merge("removed_papers" => [id])], [], false],
      ["removed record remains current", [remove, add], [added], false],
      ["missing current addition", [add], [], false],
      ["malformed event field", [add.merge("added_papers" => id)], [added], false],
      ["malformed paper ID", [add.merge("added_papers" => ["../private"])], [], false],
      ["invalid release date", [add.merge("date" => "2026-02-31")], [added], false],
      ["out-of-order release dates", [add, remove], [], false],
      ["same-date releases preserve order", [restore.merge("date" => "2026-10-02"), remove, add], [original.merge("added_at" => "2026-10-02")], true]
    ]
    cases.each do |name, releases, papers, valid|
      errors = ReleaseHistory.validate(releases, papers)
      raise "#{name}: expected #{valid ? 'valid' : 'invalid'} history, got #{errors.inspect}" unless errors.empty? == valid
    end
    cases.length
  end
end

if $PROGRAM_NAME == __FILE__
  count = ReleaseHistoryTests.run
  root = File.expand_path("..", __dir__)
  releases = YAML.safe_load(File.read(File.join(root, "_data/releases.yml")), aliases: false)
  papers = YAML.safe_load(File.read(File.join(root, "_data/papers.yml")), aliases: false)
  errors = ReleaseHistory.validate(releases, papers)
  abort(errors.join("\n")) unless errors.empty?
  puts "Validated #{count} release-history regression cases and the current collection history."
end
