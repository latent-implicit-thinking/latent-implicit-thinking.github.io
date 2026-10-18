# frozen_string_literal: true

require "date"

module ReleaseHistory
  module_function

  # Releases are stored newest first. The first collection predates addition
  # tracking, so a paper's first recorded removal can refer to that baseline.
  # Replaying later events allows reviewed restorations without editing history.
  def validate(releases, papers)
    errors = []
    current = papers.to_h { |paper| [paper.fetch("id"), paper] }
    chronological = releases.reverse
    first_events = {}
    previous_date = nil

    chronological.each do |release|
      label = release["version"] || "unknown release"
      begin
        date_text = release.fetch("date").to_s
        raise ArgumentError, "expected YYYY-MM-DD" unless date_text.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        date = Date.iso8601(date_text)
        errors << "Release history dates are not newest first" if previous_date && date < previous_date
        previous_date = date
      rescue KeyError, ArgumentError
        errors << "Invalid release date in #{label}"
      end
      %w[added_papers removed_papers].each do |field|
        values = release.fetch(field, [])
        unless values.is_a?(Array)
          errors << "#{field} must be an array in #{label}"
          next
        end
        errors << "Duplicate #{field} IDs in #{label}" unless values.uniq == values
        values.each do |id|
          unless id.is_a?(String) && id.match?(/\A\d{4}\.\d{4,5}\z/)
            errors << "Malformed #{field} ID in #{label}"
            next
          end
          first_events[id] ||= field
        end
      end
      if release.fetch("added_papers", []).is_a?(Array) && release.fetch("removed_papers", []).is_a?(Array)
        errors << "The same paper is added and removed in #{label}" unless (release.fetch("added_papers", []) & release.fetch("removed_papers", [])).empty?
      end
    end
    return errors unless errors.empty?

    # nil denotes an original, untracked entry; a date denotes the most recent
    # addition event. Inactive entries are deleted rather than tombstoned.
    active = papers.reject { |paper| paper.key?("added_at") }.to_h { |paper| [paper.fetch("id"), nil] }
    first_events.each { |id, event| active[id] = nil if event == "removed_papers" }
    chronological.each do |release|
      Array(release["added_papers"]).each do |id|
        if active.key?(id)
          errors << "#{id}: addition in #{release['version']} duplicates an active entry"
        else
          active[id] = release.fetch("date").to_s
        end
      end
      Array(release["removed_papers"]).each do |id|
        if active.key?(id)
          active.delete(id)
        else
          errors << "#{id}: removal in #{release['version']} refers to an inactive entry"
        end
      end
    end

    errors << "Release membership differs from the current collection" unless active.keys.sort == current.keys.sort
    active.each do |id, latest_addition|
      next unless current[id]
      if latest_addition
        errors << "#{id}: added_at differs from the latest addition event" unless current[id]["added_at"].to_s == latest_addition
      elsif current[id].key?("added_at")
        errors << "#{id}: tracked entry has no matching addition event"
      end
    end
    errors
  end
end
