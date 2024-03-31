require_relative 'gitlab_api/issue'
require_relative 'gitlab_api/comment'
require_relative 'gitlab_api/milestone'
require_relative '../config/settings'

class MigrationManager
  def initialize(source_project_id, destination_project_id)
    @source_project_id = source_project_id
    @destination_project_id = destination_project_id

    # Source Managers
    @source_issue_manager = GitLabAPI::Issue.new(Settings::SOURCE_GITLAB_TOKEN, Settings::SOURCE_GITLAB_API_ENDPOINT)
    @source_milestone_manager = GitLabAPI::Milestone.new(Settings::SOURCE_GITLAB_TOKEN, Settings::SOURCE_GITLAB_API_ENDPOINT)
    @source_comment_manager = GitLabAPI::Comment.new(Settings::SOURCE_GITLAB_TOKEN, Settings::SOURCE_GITLAB_API_ENDPOINT)

    # Destination Managers
    @destination_issue_manager = GitLabAPI::Issue.new(Settings::DESTINATION_GITLAB_TOKEN, Settings::DESTINATION_GITLAB_API_ENDPOINT)
    @destination_milestone_manager = GitLabAPI::Milestone.new(Settings::DESTINATION_GITLAB_TOKEN, Settings::DESTINATION_GITLAB_API_ENDPOINT)
    @destination_comment_manager = GitLabAPI::Comment.new(Settings::DESTINATION_GITLAB_TOKEN, Settings::DESTINATION_GITLAB_API_ENDPOINT)
  end

  def migrate
    migrate_milestones
    migrate_issues
    puts "Migration completed successfully!"
  end

  private

  def migrate_milestones
    milestones = @source_milestone_manager.fetch_milestones(@source_project_id)
    milestones.each do |milestone|
      next if @destination_milestone_manager.milestone_exists?(@destination_project_id, milestone['title'])
      @destination_milestone_manager.create_milestone(@destination_project_id, milestone)
    end
  end

  def migrate_issues
    issues = @source_issue_manager.fetch_issues(@source_project_id)
    issues.each do |issue|
      next if @destination_issue_manager.issue_exists?(@destination_project_id, issue['title'])
      created_issue_iid = @destination_issue_manager.create_issue(@destination_project_id, issue)

      original_author = issue['author']['name']
      original_created_at = issue['created_at']
      @source_comment_manager.create_initial_comment(@destination_project_id, created_issue_iid, original_author, original_created_at)

      migrate_comments(issue['iid'], created_issue_iid)
    end
  end

  def migrate_comments(source_issue_iid, destination_issue_iid)
    comments = @source_comment_manager.fetch_comments(@source_project_id, source_issue_iid)
    comments.each do |comment|
      original_author = comment['author']['name']
      original_created_at = comment['created_at']
      comment_body = comment['body']
      @destination_comment_manager.create_comment(@destination_project_id, destination_issue_iid, comment_body, original_author, original_created_at)
    end
  end
end
