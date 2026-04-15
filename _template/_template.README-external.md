<!-- cSpell:ignore realpath chdir mapfile pushd popd apim strg terraformstate mktemp tflint -->
# TODO: set title for the project README here

TODO: Add brief project description here.

## About

TODO: Add relevant project information here.

## Project structure

```txt
.
├── README.md             <-- This file
├── envs                  <-- Separate sub-directory for each environment
│   ├── env1
│   ├── env2
│   └── ...
├── main                  <-- Main module for project, called by all environments
└── modules               <-- Local project modules goes here
```

## Prerequisites

The following tooling is required to work with this project:

- git - <https://git-scm.com/download>
- GitHub CLI - <https://cli.github.com/manual/installation>
- Azure CLI - <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>
- Terraform - <https://www.terraform.io/downloads>
- Bash - <https://www.gnu.org/software/bash/>

## Command invocations

Below are example command invocations for working with this project.

### Project resources

The following are example command invocations for managing resources for this project.

[BOOTSTRAP_VALUE_README_SEC_ENV_CMDS]
### Remove locally cached files

The DSB Terraform helpers script caches some files locally to speed up operations. To remove these files, run the following invocations:

```bash
# load tf-helpers, make sure to be authenticated with GitHub cli in advance
source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;

# clean up cached files in environment directories
tf-clean-all
```
