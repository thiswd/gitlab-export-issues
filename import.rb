# Install the httparty gem first by running: gem install httparty
require 'httparty'
require 'json'
require 'date'

SOURCE_GITLAB_TOKEN = 'glpat-ZM2_ebB6SBx4yNi-Pznw'
DESTINATION_GITLAB_TOKEN = 'glpat-ZM2_ebB6SBx4yNi-Pznw'
SOURCE_GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'
DESTINATION_GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'

unless ARGV.length == 2
  puts "Usage: ruby import.rb SOURCE_PROJECT_ID DESTINATION_PROJECT_ID"
  exit(1)
end

SOURCE_PROJECT_ID, DESTINATION_PROJECT_ID = ARGV

def format_date(date_string)
  datetime = DateTime.parse(date_string)
  datetime.strftime("%B %d, %Y %H:%M")
end

def handle_response(response, source_project_id)
  unless response.code.between?(200, 299)
    puts "Error: #{response.code} - #{response.message} - #{source_project_id}"
    puts response.body
    exit(1)
  end
  JSON.parse(response.body)
rescue JSON::ParserError => e
  puts "Failed to parse JSON response: #{e.message}"
  exit(1)
end

def fetch_issues(source_project_id, token)
  response = HTTParty.get("#{SOURCE_GITLAB_API_ENDPOINT}/projects/#{source_project_id}/issues",
                          headers: { "PRIVATE-TOKEN" => token })
  handle_response(response, source_project_id)
end

def fetch_milestones(source_project_id, token)
  response = HTTParty.get("#{SOURCE_GITLAB_API_ENDPOINT}/projects/#{source_project_id}/milestones",
                          headers: { "PRIVATE-TOKEN" => token })
  handle_response(response, source_project_id)
end

def fetch_comments(source_project_id, issue_iid, token)
  response = HTTParty.get("#{SOURCE_GITLAB_API_ENDPOINT}/projects/#{source_project_id}/issues/#{issue_iid}/notes",
                          headers: { "PRIVATE-TOKEN" => token })
  handle_response(response, source_project_id)
end

def milestone_exists?(destination_project_id, token, milestone_title)
  milestones = fetch_milestones(destination_project_id, token)
  milestones.any? { |m| m['title'] == milestone_title }
end

def create_milestone_if_not_exists(destination_project_id, token, milestone)
  unless milestone_exists?(destination_project_id, token, milestone['title'])
    create_milestone(destination_project_id, token, milestone)
  else
    puts "Milestone '#{milestone['title']}' already exists in the destination project."
  end
end

def create_milestone(destination_project_id, token, milestone)
  response = HTTParty.post("#{DESTINATION_GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/milestones",
                headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                body: milestone.to_json)
  handle_response(response, destination_project_id)
end

def issue_exists?(destination_project_id, token, issue_title)
  issues = fetch_issues(destination_project_id, token)
  issues.any? { |issue| issue['title'] == issue_title }
end

def create_issue_if_not_exists(destination_project_id, token, issue)
  unless issue_exists?(destination_project_id, token, issue['title'])
    create_issue(destination_project_id, token, issue)
  else
    puts "Issue with title '#{issue['title']}' already exists in the destination project."
  end
end

def create_issue(destination_project_id, token, issue)
  issue_body = issue.reject { |k| k == 'state' }
  response = HTTParty.post("#{DESTINATION_GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/issues",
                          headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                          body: issue_body.to_json)
  created_issue = handle_response(response, destination_project_id)

  if issue['state'] == 'closed'
    close_issue(destination_project_id, created_issue['iid'], token)
  end

  created_issue['iid']
end

def close_issue(project_id, issue_iid, token)
  response = HTTParty.put("#{DESTINATION_GITLAB_API_ENDPOINT}/projects/#{project_id}/issues/#{issue_iid}",
                          headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                          body: { state_event: 'close' }.to_json)
  handle_response(response, project_id)
end

def create_comment(destination_project_id, issue_iid, token, comment, original_author, original_created_at)
  formatted_date = format_date(original_created_at)

  comment_body = "Originally posted by #{original_author} on #{formatted_date}:\n\n#{comment['body']}"

  response = HTTParty.post("#{DESTINATION_GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/issues/#{issue_iid}/notes",
                          headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                          body: { body: comment_body }.to_json)
  handle_response(response, destination_project_id)
end

def create_initial_comment(destination_project_id, issue_iid, token, original_author, original_created_at)
  formatted_date = format_date(original_created_at)
  message = "Originally created by #{original_author} on #{formatted_date}."

  HTTParty.post("#{DESTINATION_GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/issues/#{issue_iid}/notes",
                headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                body: { body: message }.to_json)
end

begin
  milestones = fetch_milestones(SOURCE_PROJECT_ID, SOURCE_GITLAB_TOKEN)
  milestones.each do |milestone|
    create_milestone_if_not_exists(DESTINATION_PROJECT_ID, DESTINATION_GITLAB_TOKEN, milestone)
  end

  issues = fetch_issues(SOURCE_PROJECT_ID, SOURCE_GITLAB_TOKEN)
  issues.each do |issue|
    created_issue_iid = create_issue_if_not_exists(DESTINATION_PROJECT_ID, DESTINATION_GITLAB_TOKEN, issue)

    original_author = issue['author']['name']
    original_created_at = issue['created_at']

    create_initial_comment(DESTINATION_PROJECT_ID, created_issue_iid, DESTINATION_GITLAB_TOKEN, original_author, original_created_at)

    comments = fetch_comments(SOURCE_PROJECT_ID, issue['iid'], SOURCE_GITLAB_TOKEN)
    comments.each do |comment|
      original_author = comment['author']['name']
      original_created_at = comment['created_at']
      create_comment(DESTINATION_PROJECT_ID, created_issue_iid, DESTINATION_GITLAB_TOKEN, comment, original_author, original_created_at)
    end
  end

  puts "Migration completed!"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
