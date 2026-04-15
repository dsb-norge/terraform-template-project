<!-- cSpell:ignore realpath chdir mapfile pushd popd apim strg terraformstate mktemp tflint -->
# The [BOOTSTRAP_VALUE_ENV_NAME] environment

This directory holds code for creating and managing resources in the [BOOTSTRAP_VALUE_ENV_NAME] environment.

**Note:** The actual Azure resources for the remote state are managed externally. Update the backend configuration in `backend.tf` to point to the pre-provisioned state container.

## Command invocations in this environment

Below are example command invocations for working with this environment.

[BOOTSTRAP_VALUE_README_SEC_ENV_CMDS]
