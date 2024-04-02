class IssueManager
  attr_reader :source_gitlab_api, :destination_gitlab_api

  def initialize(source_gitlab_api, destination_gitlab_api)
    @source_gitlab_api = source_gitlab_api
    @destination_gitlab_api = destination_gitlab_api
  end

  def fetch_issues(project_id)
    source_gitlab_api.get("/projects/#{project_id}/issues")
  end

  def issue_exists?(project_id, issue_title)
    issues = fetch_issues(project_id)
    issues.any? { |issue| issue['title'] == issue_title }
  end

  def create_issue(project_id, issue)
    unless issue_exists?(project_id, issue['title'])
      created_issue = destination_gitlab_api.post("/projects/#{project_id}/issues", issue)

      if issue['state'] == 'closed'
        close_issue(project_id, created_issue['iid'])
      end

      created_issue['iid']
    else
      puts "Issue with title '#{issue['title']}' already exists."
    end
  end

  private

  def close_issue(project_id, issue_iid)
    destination_gitlab_api.put("/projects/#{project_id}/issues/#{issue_iid}", { state_event: 'close' })
  end
end
