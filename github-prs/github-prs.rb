#! /usr/bin/env ruby

#  <xbar.var>string(VAR_REPO_DIRECTORY="/"): The root directories of the Git repositories, separated by commas</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_MINE=true): Include PRs that I have authored</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_REQUESTED=true): Include PRs that I have been requested to review</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_LABELS=true): Show label names</xbar.var>
#  <xbar.var>boolean(VAR_SHOW_NUMBER=true): Show PR number</xbar.var>
#  <xbar.var>number(VAR_MAX_TITLE_LENGTH=60): Max title length</xbar.var>

require 'json'
require 'ostruct'

repo_dirs = ENV['VAR_REPO_DIRECTORY'].to_s.split(',')

if repo_dirs == []
  puts 'ERROR: Repo directory is required'
  exit
end

has_multiple_repos = (repo_dirs.count > 1)
total_pr_count = 0
output = []

repo_dirs.each do |repo_dir|
  show_mine = ENV['VAR_SHOW_MINE'] == 'true'
  show_requested = ENV['VAR_SHOW_REQUESTED'] == 'true'
  show_labels = ENV['VAR_SHOW_LABELS'] == 'true'
  show_number = ENV['VAR_SHOW_NUMBER'] == 'true'
  max_title_length = (ENV['VAR_MAX_TITLE_LENGTH'] || '60').to_i

  REVIEW_ICONS = {
    'APPROVED' => '✅',
    'REVIEW_REQUIRED' => '👀'
  }

  SUBSTITUTIONS = {
    ':shipit:' => '🐿️'
  }

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
  total_pr_count += pr_count

  if has_multiple_repos
    output << "—— #{File.basename(repo_dir)} —— | size=16"
  end

  if pr_count == 0
    output << '😎 No open PRs' 
    output << '---'
  end

  # Print menu items
  sections.each do |section|
    next if section.prs.empty?
    
    output << section.title

    section.prs.each do |pr|
      pr_icon = REVIEW_ICONS[pr["reviewDecision"]] || 'ℹ️'
      pr_number = "[##{pr["number"]}]" if show_number
      pr_labels = pr["labels"].map { |l| "[#{l['name']}]" } if show_labels

      pr_title = pr["title"]
      pr_title = pr_title[0..(max_title_length - 1)] + "..." if pr_title.length > max_title_length

      item_text = [pr_icon, pr_number, pr_title, pr_labels].compact.join(' ').gsub('|','/')
      SUBSTITUTIONS.each { |k, v| item_text.gsub!(k, v) }
      
      item_params = "href=#{pr["url"]}"

      output << "#{item_text} | #{item_params}"
    end

    output << '---'
  end
end

menu_title = total_pr_count == 1 ? "1 PR" : "#{total_pr_count} PRs"
puts menu_title
puts '---'

output.each { |line| puts line }

puts "Refresh | refresh=true | key=super+r"