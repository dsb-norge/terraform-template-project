<!-- cSpell:ignore realpath chdir mapfile pushd popd apim strg terraformstate mktemp tflint -->
# terraform-template-project

Template project for terraform featuring scripted scaffolding and bootstrapping of remote state.

This project simplifies multiple processes:

1. Create scaffolding for a new terraform project, including config for multiple environments.
2. Bootstrap terraform remote state in Azure for all environments.
   - The remote state is handled in a separate "environment" called "_terraform-state", see `envs/_terraform-state/README.md` after scaffolding for more details.

<!-- omit in toc -->
## Table of Contents

- [Prerequisites](#prerequisites)
- [How to](#how-to)
- [Resulting project structure](#resulting-project-structure)
- [Maintainer documentation](#maintainer-documentation)

## Prerequisites

The following tooling must be installed in order for scaffolding and bootstrapping to succeed:

- jq - command-line JSON processor
  - `sudo apt-get update && sudo apt-get install -y jq`
- Azure CLI - <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>
- Terraform - <https://www.terraform.io/downloads>

## How to

This is how you scaffold and bootstrap this project into an empty terraform project:

1. Log in to yor Azure tenant using `az login`
2. From the root of the project run `step_1_scaffold.sh`
   - Supply information about environments and Azure subscriptions as requested.
   - The script will now generate a project structure for you based on the information given.
3. After the script completes edit the `env.ENV.tfvars` files as stated by the script execution output.
   - NOTE: the information you supply in the `env.ENV.tfvars` files are used for creating Azure resources for terraform state. The information is NOT used for creating project resources.
     - TIP: you can have terraform state for multiple environments in the same Azure subscription, just specify the same subscription for all environments.
4. From the root of the project run `step_2_bootstrap.sh`
   - The script will now create all configuration and Azure resources necessary for you project to have remote terraform state in Azure (using the azurerm backend provider) for the specified environments.
   - **NOTE:** the script WILL actually deploy resources to your Azure tenant as part of the bootstrapping project!
   - The script will update the README files with example commands to use during project development and maintenance.
     - TIP: The current contents of this file will be replaced.
5. From the root of the project run `step_3_remove_init_scripts.sh`
   - The script will remove all remaining files from the scaffolding and bootstrapping process.
   - Update this README with relevant information, tip: search for TODO.

## Resulting project structure

Example of resulting project structure (scaffolded for environments `env1` and `env2`):

```text
.
├── README.md
├── envs
│   ├── README.md
│   ├── _terraform-state
│   │   ├── README.md
│   │   ├── backend-config.env1.hcl
│   │   ├── backend-config.env2.hcl
│   │   ├── backend.tf
│   │   ├── env.env1.tfvars
│   │   ├── env.env2.tfvars
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── env1
│   │   ├── .az-subscription
│   │   ├── README.md
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── env2
│       ├── .az-subscription
│       ├── ...
├── main
│   ├── README.md
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
└── modules
    └── README.md
```

## Maintainer documentation

Some of the scripts supports a "test mode". Here is how to dry run the project:

```bash
#!/usr/bin/env bash

# create a temporary directory and store its path in a variable
temp_dir=$(mktemp -d)

# copy the contents of the current directory to the temporary directory
cp -r . $temp_dir

# change to the temporary directory
pushd $temp_dir

# run step 1
$(pwd)/step_1_scaffold.sh debug

# read json
cat bootstrap.json | jq

# run step 2
$(pwd)/step_2_bootstrap.sh debug

# open temp project in vscode
code $temp_dir

# change back to the original directory
popd

# remove the temporary directory
rm -rf $temp_dir
```
