# Install the httparty gem first by running: gem install httparty
require 'httparty'
require 'json'

SOURCE_GITLAB_TOKEN = 'glpat-ZM2_ebB6SBx4yNi-Pznw'
DESTINATION_GITLAB_TOKEN = 'glpat-ZM2_ebB6SBx4yNi-Pznw'
SOURCE_PROJECT_ID = '56077888'
DESTINATION_PROJECT_ID = '56114870'
GITLAB_API_ENDPOINT = 'https://gitlab.com/api/v4'

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
  response = HTTParty.get("#{GITLAB_API_ENDPOINT}/projects/#{source_project_id}/issues",
                          headers: { "PRIVATE-TOKEN" => token })
  handle_response(response, source_project_id)
end

def fetch_milestones(source_project_id, token)
  response = HTTParty.get("#{GITLAB_API_ENDPOINT}/projects/#{source_project_id}/milestones",
                          headers: { "PRIVATE-TOKEN" => token })
  handle_response(response, source_project_id)
end

def create_milestone(destination_project_id, token, milestone)
  response = HTTParty.post("#{GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/milestones",
                headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                body: milestone.to_json)
  handle_response(response, destination_project_id)
end

def create_issue(destination_project_id, token, issue)
  response = HTTParty.post("#{GITLAB_API_ENDPOINT}/projects/#{destination_project_id}/issues",
                headers: { "Content-Type" => "application/json", "PRIVATE-TOKEN" => token },
                body: issue.to_json)
  handle_response(response, destination_project_id)
end

begin
  # Export and Import Milestones
  milestones = fetch_milestones(SOURCE_PROJECT_ID, SOURCE_GITLAB_TOKEN)
  milestones.each do |milestone|
    create_milestone(DESTINATION_PROJECT_ID, DESTINATION_GITLAB_TOKEN, milestone)
  end

  # Export and Import Issues
  issues = fetch_issues(SOURCE_PROJECT_ID, SOURCE_GITLAB_TOKEN)
  issues.each do |issue|
    create_issue(DESTINATION_PROJECT_ID, DESTINATION_GITLAB_TOKEN, issue)
  end

  puts "Migration completed!"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
