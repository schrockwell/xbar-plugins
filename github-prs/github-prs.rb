#! /usr/bin/env ruby

#  <xbar.var>string(VAR_REPO_DIRECTORY="/"): The root directory of the Git repository</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_MINE=true): Include PRs that I have authored</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_REQUESTED=true): Include PRs that I have been requested to review</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_LABELS=true): Show label names</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_NUMBER=true): Show PR number</xbar.var>
#  <xbar.var>number(VAR_MAX_TITLE_LENGTH=60): Max title length</xbar.var>

require 'json'
require 'ostruct'

repo_dir = ENV['VAR_REPO_DIRECTORY']
show_mine = ENV['VAR_SHOW_MINE'] == 'true'
show_requested = ENV['VAR_SHOW_REQUESTED'] == 'true'
show_labels = ENV['VAR_SHOW_LABELS'] == 'true'
show_number = ENV['VAR_SHOW_NUMBER'] == 'true'
max_title_length = (ENV['VAR_MAX_TITLE_LENGTH'] || '60').to_i

REVIEW_ICONS = {
  'APPROVED' => '✅',
  'REVIEW_REQUIRED' => '👀'
}

unless repo_dir
  puts 'ERROR: Repo directory must be configured'
  exit
end

Dir.chdir(repo_dir)

sections = []
sections << OpenStruct.new(title: 'Mine', gh_args: '--author "@me"') if show_mine
sections << OpenStruct.new(title: 'My review requested', gh_args: '--search "user-review-requested:@me"') if show_requested
# sections << OpenStruct.new(title: 'Team review requested', gh_args: '--search "team-review-requested:KamanaHealth/reviewers"') if ENV['VAR_SHOW_REQUESTED'] == 'true'

sections.each do |section|
  section.prs = JSON.parse(`/opt/homebrew/bin/gh pr list #{section.gh_args} --json number,title,url,reviewDecision,labels`)
end

# Count PRs
pr_count = sections.map { |s| s.prs.count }.sum
menu_title = pr_count == 1 ? "1 PR" : "#{pr_count} PRs"

puts menu_title
puts '---'
puts '😎 No open PRs' if pr_count == 0

# Print menu items
sections.each do |section|
  next if section.prs.empty?
  
  puts section.title

  section.prs.each do |pr|
    pr_icon = REVIEW_ICONS[pr["reviewDecision"]] || 'ℹ️'
    pr_number = "[##{pr["number"]}]" if show_number
    pr_labels = pr["labels"].map { |l| "[#{l['name']}]" } if show_labels

    pr_title = pr["title"]
    pr_title = pr_title[0..(max_title_length - 1)] + "..." if pr_title.length > max_title_length

    item_text = [pr_icon, pr_number, pr_title, pr_labels].compact.join(' ').gsub('|','/')
    item_params = "href=#{pr["url"]}"

    puts "#{item_text} | #{item_params}"
  end

  puts '---'
end

puts "Refresh | refresh=true | key=super+r"
