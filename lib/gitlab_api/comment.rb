require_relative 'base'

module GitLabAPI
  class Comment < Base
    def initialize(token, api_endpoint)
      super(token)
      self.class.base_uri(api_endpoint)
    end

    def fetch_comments(project_id, issue_iid)
      get("/projects/#{project_id}/issues/#{issue_iid}/notes")
    end

    def create_comment(project_id, issue_iid, comment_body, original_author, original_created_at)
      formatted_date = Utils.format_date(original_created_at)
      comment = "Originally posted by #{original_author} on #{formatted_date}:\n\n#{comment_body}"
      post("/projects/#{project_id}/issues/#{issue_iid}/notes", { body: comment })
    end

    def create_initial_comment(destination_project_id, issue_iid, original_author, original_created_at)
      formatted_date = Utils.format_date(original_created_at)
      message = "Originally created by #{original_author} on #{formatted_date}."
      post("/projects/#{project_id}/issues/#{issue_iid}/notes", { body: message })
    end
  end
end
