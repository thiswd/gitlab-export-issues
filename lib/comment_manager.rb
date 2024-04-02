require_relative 'utils'

class CommentManager
  attr_reader :source_gitlab_api, :destination_gitlab_api

  def initialize(source_gitlab_api, destination_gitlab_api)
    @source_gitlab_api = source_gitlab_api
    @destination_gitlab_api = destination_gitlab_api
  end

  def fetch_comments(project_id, issue_iid)
    source_gitlab_api.get("/projects/#{project_id}/issues/#{issue_iid}/notes")
  end

  def create_comment(project_id, issue_iid, comment_body, original_author, original_created_at)
    formatted_date = Utils.format_date(original_created_at)
      comment = "Originally posted by #{original_author} on #{formatted_date}:\n\n#{comment_body}"
    destination_gitlab_api.post("/projects/#{project_id}/issues/#{issue_iid}/notes", { body: comment })
  end

  def create_initial_comment(project_id, issue_iid, original_author, original_created_at)
    formatted_date = Utils.format_date(original_created_at)
    message = "Originally created by #{original_author} on #{formatted_date}."
    destination_gitlab_api.post("/projects/#{project_id}/issues/#{issue_iid}/notes", { body: message })
  end
end
