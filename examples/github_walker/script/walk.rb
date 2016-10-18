# NAME
#   walk — Walk GitHub's GraphQL API, starting with your user.
#
# SYNOPSIS
#   script/walk
#
# DESCRIPTION
#   Starting from your user, walk the GitHub GraphQL API, following all
#   accessible connections. A GitHub API token must be provided in the
#   `GITHUB_ACCESS_TOKEN` environment variable.
#

require "json"

unless ENV["GITHUB_ACCESS_TOKEN"]
  lines = File.read(__FILE__).split("\n")
  help = []
  help << lines.shift[2..-1] while lines.first.start_with?("#")
  puts help.join("\n")
  exit(1)
end

puts "Loading GitHub Schema"
$:.unshift File.expand_path('../../lib', __FILE__)
require "github_walker"

stats = {
  :depth  => Hash.new { |h,k| h[k] = 0 },
  :total  => 0
}

def frame_depth(frame, depth=1)
  if frame.parent
    frame_depth(frame.parent, depth + 1)
  else
    depth
  end
end

puts "Starting walking"
GitHubWalker.walk do |frame|
  stats[:total] += 1
  stats[:depth][frame_depth(frame)] += 1

  if stats[:total] % 100 == 0
    puts JSON.pretty_generate(stats)
    puts
  end

  if frame.context[:response].errors.any?
    puts frame.context[:response].errors.values.flatten.uniq.join("\n")
  end
end
