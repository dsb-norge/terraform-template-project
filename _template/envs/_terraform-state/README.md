# `./envs/_terraform-state` directory

This directory holds code for creating and managing remote state resources for terraform in Azure.

Terraform state resources for all environments in the project are managed here. Each environment has its own separate variables in `env.ENV.tfvars` and terraform backend definition in `backend-config.ENV.hcl`.

## Command invocations

The following are example command invocations for managing terraform backend state resources for this project.

[BOOTSTRAP_VALUE_README_SEC_STATE_CMDS]
