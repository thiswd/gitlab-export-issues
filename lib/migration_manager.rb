require_relative 'gitlab_api'
require_relative 'issue_manager'
require_relative 'milestone_manager'
require_relative 'comment_manager'
require_relative '../config/settings'

class MigrationManager
  def initialize(source_project_id, destination_project_id)
    @source_project_id = source_project_id
    @destination_project_id = destination_project_id

    source_gitlab_api = GitlabApi.new(Settings::SOURCE_GITLAB_API_ENDPOINT,Settings::SOURCE_GITLAB_TOKEN)
    destination_gitlab_api = GitlabApi.new(Settings::DESTINATION_GITLAB_API_ENDPOINT, Settings::DESTINATION_GITLAB_TOKEN)

    @milestone_manager = MilestoneManager.new(source_gitlab_api, destination_gitlab_api)
    @issue_manager = IssueManager.new(source_gitlab_api, destination_gitlab_api)
    @comment_manager = CommentManager.new(source_gitlab_api,destination_gitlab_api)
  end

  def migrate
    migrate_milestones
    migrate_issues
    puts "Migration completed successfully!"
  end

  private

  def migrate_milestones
    milestones = @milestone_manager.fetch_milestones(@source_project_id)
    milestones.each do |milestone|
      next if @milestone_manager.milestone_exists?(@destination_project_id, milestone['title'])
      @milestone_manager.create_milestone(@destination_project_id, milestone)
    end
  end

  def migrate_issues
    issues = @issue_manager.fetch_issues(@source_project_id)
    issues.each do |issue|
      next if @issue_manager.issue_exists?(@destination_project_id, issue['title'])
      created_issue_iid = @issue_manager.create_issue(@destination_project_id, issue)

      original_author = issue['author']['name']
      original_created_at = issue['created_at']
      @comment_manager.create_initial_comment(@destination_project_id, created_issue_iid, original_author, original_created_at)

      migrate_comments(issue['iid'], created_issue_iid)
    end
  end

  def migrate_comments(source_issue_iid, destination_issue_iid)
    comments = @comment_manager.fetch_comments(@source_project_id, source_issue_iid)
    comments.each do |comment|
      original_author = comment['author']['name']
      original_created_at = comment['created_at']
      comment_body = comment['body']
      @comment_manager.create_comment(@destination_project_id, destination_issue_iid, comment_body, original_author, original_created_at)
    end
  end
end
