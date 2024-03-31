#!/usr/bin/env ruby

require_relative '../lib/migration_manager'

unless ARGV.length == 2
  puts "Usage: #{__FILE__} SOURCE_PROJECT_ID DESTINATION_PROJECT_ID"
  exit(1)
end

source_project_id, destination_project_id = ARGV
migration_manager = MigrationManager.new(source_project_id, destination_project_id)
migration_manager.migrate
