const { execSync } = require('child_process');

const core = require('@actions/core');
const github = require('@actions/github');
const fs = require('fs');

async function run() {
    try {
        let token = core.getInput('github-token');
        if (!token) {
            token = process.env.GITHUB_TOKEN;
        }
        if (!token) {
            throw new Error('GitHub token is required');
        }
        const outputPath = 'provenance.json';
        // const targetPath = core.getInput('target-path');
        const octokit = github.getOctokit(token);
        const context = github.context;

        // Verify the token by fetching the authenticated user
        const { data: user } = await octokit.rest.users.getAuthenticated();
        console.log(`Authenticated as: ${user.login}`);

        // Collect build information
        const buildInfo = {
            builder: {
                id: `https://github.com/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`
            },
            buildType: 'https://github.com/actions/runner',
            invocation: {
                configSource: {
                    uri: `git+https://github.com/${context.repo.owner}/${context.repo.repo}.git`,
                    digest: {
                        sha1: context.sha
                    },
                    entryPoint: context.workflow
                },
                parameters: {},
                environment: {
                    github_workflow: context.workflow,
                    github_action: context.action,
                    github_event_name: context.eventName,
                    github_ref: context.ref,
                    github_sha: context.sha,
                    github_run_id: context.runId,
                    github_run_number: context.runNumber,
                    github_actor: context.actor,
                    github_repository: context.repository
                }
            }
        };

        // Get repository information
        const repoResponse = await octokit.rest.repos.get({
            owner: context.repo.owner,
            repo: context.repo.repo
        });

        // Generate provenance document
        const provenance =  {
                buildDefinition: {
                    buildType: buildInfo.buildType,
                    externalParameters: {},
                    internalParameters: {},
                    resolvedDependencies: []
                },
                runDetails: {
                    builder: buildInfo.builder,
                    metadata: {
                        invocationId: context.runId.toString(),
                        startedOn: new Date().toISOString(),
                        finishedOn: new Date().toISOString()
                    },
                    byproducts: []
                }
        };

        // Write provenance to file
        fs.writeFileSync(outputPath, JSON.stringify(provenance, null, 2));
        core.setOutput('provenance-path', outputPath);

        // Upload provenance file using JFrog CLI
        execSync(`echo ${outputPath}`, { stdio: 'inherit' });

    } catch (error) {
        core.setFailed(error.message);
    }
}

run();