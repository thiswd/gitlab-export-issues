require_relative 'base'

module GitLabAPI
  class Issue < Base
    def initialize(token, api_endpoint)
      super(token)
      self.class.base_uri(api_endpoint)
    end

    def fetch_issues(project_id)
      get("/projects/#{project_id}/issues")
    end

    def create_issue(project_id, issue_data)
      post("/projects/#{project_id}/issues", issue_data)
    end

    def issue_exists?(project_id, issue_title)
      issues = fetch_issues(project_id)
      issues.any? { |issue| issue['title'] == issue_title }
    end

    def close_issue(project_id, issue_iid)
      put("/projects/#{project_id}/issues/#{issue_iid}", { state_event: 'close' })
    end
  end
end
