# GitLab Project Migration Tool

This Ruby script facilitates the migration of issues, milestones, and comments from one GitLab project to another.

## Features

- Migrate milestones.
- Migrate issues, including:
  - The state of the issue (open or closed) and labels.
  - All comments associated with each issue, referencing the original author and the creation date.

## Requirements

- Ruby environment.
- The `httparty` gem. Install it by running `gem install httparty`.
- Personal Access Tokens for the source and destination GitLab instances with the appropriate permissions to read from the source project and write to the destination project.

## Configuration

Before running the script, you need to set up a few variables within the script:

- `SOURCE_GITLAB_TOKEN`: Your Personal Access Token for the source GitLab instance.
- `DESTINATION_GITLAB_TOKEN`: Your Personal Access Token for the destination GitLab instance.
- `SOURCE_GITLAB_API_ENDPOINT` and `DESTINATION_GITLAB_API_ENDPOINT`: The API endpoints for your source and destination GitLab instances.

Additionally, the source and destination project IDs need to be passed as arguments when running the script.

## Usage

1. Open the script in a text editor and configure the personal access tokens and API endpoints as described in the Configuration section.
2. Save the script, and then run it from the terminal or command prompt as follows:

```sh
ruby import.rb SOURCE_PROJECT_ID DESTINATION_PROJECT_ID
```

Replace `SOURCE_PROJECT_ID` and `DESTINATION_PROJECT_ID` with the actual project IDs for your source and destination projects.

## Important Notes

- This script checks if milestones or issues already exist in the destination project by title before creating them to avoid duplicates.
- The script assumes that comments cannot be created under the name of the original author. Instead, it adds a notation to the comment text indicating the original author and the date it was created.
