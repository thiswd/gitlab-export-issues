class MilestoneManager
  attr_reader :source_gitlab_api, :destination_gitlab_api

  def initialize(source_gitlab_api, destination_gitlab_api)
    @source_gitlab_api = source_gitlab_api
    @destination_gitlab_api = destination_gitlab_api
  end

  def fetch_milestones(project_id)
    source_gitlab_api.get("/projects/#{project_id}/milestones")
  end

  def milestone_exists?(project_id, milestone_title)
    milestones = fetch_milestones(project_id)
    milestones.any? { |m| m['title'] == milestone_title }
  end

  def create_milestone(project_id, milestone)
    unless milestone_exists?(project_id, milestone['title'])
      destination_gitlab_api.post("/projects/#{project_id}/milestones", milestone)
    else
      puts "Milestone '#{milestone['title']}' already exists."
    end
  end
end
