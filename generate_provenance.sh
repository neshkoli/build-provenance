#!/bin/bash

# Verify jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Set install-jq to 'true' or pre-install jq."
    exit 1
fi

artifact_sha=$1
build_timestamp=$2

# Extract workflow path and ref
workflow_path=$(echo "$GITHUB_WORKFLOW_REF" | cut -d'@' -f1 | sed 's|^[^/]\+/[^/]\+/||')
workflow_ref=$(echo "$GITHUB_WORKFLOW_REF" | cut -d'@' -f2)

jq -n \
  --arg buildTimestamp "$build_timestamp" \
  --arg buildUrl "$BUILD_URL" \
  --arg repo "$GITHUB_REPOSITORY" \
  --arg sha "$GITHUB_SHA" \
  --arg runId "$GITHUB_RUN_ID" \
  --arg artifactSha "$artifact_sha" \
  --arg builderImage "$BUILDER_IMAGE" \
  --arg ref "$GITHUB_REF" \
  --arg eventName "$GITHUB_EVENT_NAME" \
  --arg repoId "$GITHUB_REPOSITORY_ID" \
  --arg repoOwnerId "$GITHUB_REPOSITORY_OWNER_ID" \
  --arg runnerEnv "$RUNNER_ENVIRONMENT" \
  --arg gitCommit "$GITHUB_SHA" \
  --arg builderId "$GITHUB_WORKFLOW_REF" \
  --arg invocationId "https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/attempts/1" \
  --arg workflowPath "$workflow_path" \
  --arg workflowRef "$workflow_ref" \
  '{
      "buildDefinition": {
        "buildType": "https://actions.github.io/buildtypes/workflow/v1",
        "externalParameters": {
          "workflow": {
            "ref": $workflowRef,
            "repository": "https://github.com/\($repo)",
            "path": $workflowPath
          }                 
        },
        "internalParameters": {
          "github": {
            "event_name": $eventName,
            "repository_id": $repoId,
            "repository_owner_id": $repoOwnerId,
            "runner_environment": $runnerEnv
          }
        },
        "resolvedDependencies": [
          {
            "uri": "git+https://github.com/\($repo)@\($ref)",
            "digest": {
              "gitCommit": $gitCommit
            }
          }
        ]
      },
      "runDetails": {
        "builder": {
          "id": $builderId
        },
        "metadata": {
          "invocationId": $invocationId,
          "startedOn": $buildTimestamp,
          "finishedOn": $buildTimestamp
        }
      }
  }' > "$OUTPUT_PATH"