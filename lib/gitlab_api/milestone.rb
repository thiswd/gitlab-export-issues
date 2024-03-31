require_relative 'base'

module GitLabAPI
  class Milestone < Base
    def initialize(token, api_endpoint)
      super(token)
      self.class.base_uri(api_endpoint)
    end

    def fetch_milestones(project_id)
      get("/projects/#{project_id}/milestones")
    end

    def create_milestone(project_id, milestone)
      post("/projects/#{project_id}/milestones", milestone)
    end

    def milestone_exists?(project_id, title)
      milestones = fetch_milestones(project_id)
      milestones.any? { |m| m['title'] == title }
    end
  end
end
