<!-- cSpell:ignore realpath chdir mapfile pushd popd apim strg terraformstate mktemp tflint -->
# terraform-template-project

Template project for terraform featuring scripted scaffolding and bootstrapping of remote state.

This project simplifies multiple processes:

1. Create scaffolding for a new terraform project, including config for multiple environments.
2. Bootstrap terraform remote state in Azure for all environments.
   - **Self-contained mode:** The remote state is created and managed in a separate "environment" called "_terraform-state", see `envs/_terraform-state/README.md` after scaffolding for more details.
   - **External mode:** The remote state is managed externally (e.g. by a platform team in a central repo). The project only references the pre-provisioned state containers.

<!-- omit in toc -->
## Table of Contents

- [Prerequisites](#prerequisites)
- [How to](#how-to)
  - [Self-contained state management](#self-contained-state-management)
  - [External state management](#external-state-management)
- [Resulting project structure](#resulting-project-structure)
- [Maintainer documentation](#maintainer-documentation)

## Prerequisites

The following tooling must be installed in order for scaffolding and bootstrapping to succeed:

- jq - command-line JSON processor
  - `sudo apt-get update && sudo apt-get install -y jq`
- Azure CLI - <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>
- Terraform - <https://www.terraform.io/downloads>
- GitHub CLI, authenticated - <https://cli.github.com/manual/installation>
  - used in the last step to load the dsb CLI, [terraform-helpers](https://github.com/dsb-norge/terraform-helpers)

## How to

### Self-contained state management

Use this mode when the project should create and manage its own terraform state containers in Azure.

1. Log in to your Azure tenant using `az login`
2. From the root of the project run `step_1_scaffold.sh`
   - Answer **yes** when asked if the project will manage its own state containers.
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
6. From the root of the project, supply the TFLint configurations with the dsb CLI:

   ```bash
   # load tf-helpers, make sure to be authenticated with GitHub cli in advance
   source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;

   # initialize every environment without backend, then lint every environment and envs/_terraform-state
   tf-init-all-offline
   tf-lint-all
   ```

   - The template ships no `.tflint.hcl`. `tf-lint-all` writes the default configuration into each environment directory and into `envs/_terraform-state`, then lints them.
   - Commit the `.tflint.hcl` files it wrote. Until they are committed, the lint in the project's CI workflow fails.

### External state management

Use this mode when terraform state containers are pre-provisioned and managed externally (e.g. by a platform team).

1. Log in to your Azure tenant using `az login`
2. From the root of the project run `step_1_scaffold.sh`
   - Answer **no** when asked if the project will manage its own state containers.
   - Supply information about environments and Azure subscriptions as requested.
3. From the root of the project run `step_2_bootstrap.sh`
   - The script will generate README files and create `backend.tf` files with placeholder values.
4. From the root of the project run `step_3_remove_init_scripts.sh`
   - The script will remove all remaining files from the scaffolding and bootstrapping process.
5. Edit the `backend.tf` file in each environment directory to point to the correct pre-provisioned state container.
   - Update this README with relevant information, tip: search for TODO.
6. From the root of the project, supply the TFLint configurations with the dsb CLI:

   ```bash
   # load tf-helpers, make sure to be authenticated with GitHub cli in advance
   source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;

   # initialize every environment without backend, then lint every environment
   tf-init-all-offline
   tf-lint-all
   ```

   - The template ships no `.tflint.hcl`. `tf-lint-all` writes the default configuration into each environment directory, then lints them.
   - Commit the `.tflint.hcl` files it wrote. Until they are committed, the lint in the project's CI workflow fails.

## Resulting project structure

### Self-contained mode

Example of resulting project structure (scaffolded for environments `env1` and `env2`):

```text
.
├── README.md
├── envs
│   ├── README.md
│   ├── _terraform-state
│   │   ├── .tflint.hcl
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
│   │   ├── .tflint.hcl
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

### External mode

Example of resulting project structure (scaffolded for environments `env1` and `env2`):

```text
.
├── README.md
├── envs
│   ├── README.md
│   ├── env1
│   │   ├── .az-subscription
│   │   ├── .tflint.hcl
│   │   ├── README.md
│   │   ├── backend.tf          <-- Edit to point to pre-provisioned state container
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

### Self-contained mode (debug)

```bash
#!/usr/bin/env bash

# create a temporary directory and store its path in a variable
temp_dir=$(mktemp -d)

# copy the contents of the current directory to the temporary directory
cp -r . $temp_dir

# change to the temporary directory
pushd $temp_dir

# run step 1 (self-contained state management)
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

### External mode (debug)

```bash
#!/usr/bin/env bash

# create a temporary directory and store its path in a variable
temp_dir=$(mktemp -d)

# copy the contents of the current directory to the temporary directory
cp -r . $temp_dir

# change to the temporary directory
pushd $temp_dir

# run step 1 (external state management)
$(pwd)/step_1_scaffold.sh debug-external

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
