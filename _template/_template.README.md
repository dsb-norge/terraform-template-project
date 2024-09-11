<!-- cSpell:ignore realpath chdir mapfile pushd popd apim strg terraformstate mktemp tflint -->
# TODO set title for the project README here

TODO Add relevant project information here.

## Prerequisites

The following tooling is required:

- git - <https://git-scm.com/download>
- Azure CLI - <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>
- Terraform - <https://www.terraform.io/downloads>
- jq and unzip command line tools (required for linting):
  - `sudo apt-get update && sudo apt-get install -y jq unzip`

## Project structure

```txt
.
├── README.md             <-- This file
├── envs                  <-- Separate sub-directory for each environment
│   ├── _terraform-state  <-- Holds everything related to terraform state
│   │   ├── README.md     <-- More info about terraform state resources
│   │   ├── ...
│   ├── env1
│   │   ├── ...
│   ├── env2
│   │   ├── ...
│   ├── ...
├── main      <-- Main module for project, called by all environments
│   ├── ...
└── modules   <-- Local project modules goes here
```

## Command invocations

Below are example command invocations for working with this project.

### Project resources

The following are example command invocations for managing resources for this project.

[BOOTSTRAP_VALUE_README_SEC_ENV_CMDS]
### Terraform state resources

The following are example command invocations for managing terraform backend state resources for this project.

For commands to issue locally in the `envs/_terraform-state` directory see [envs/_terraform-state/README.md](envs/_terraform-state/README.md).

[BOOTSTRAP_VALUE_README_SEC_STATE_CMDS]
### More about linting

#### Powershell

You can also lint with powershell.

```powershell
# Create a short hand invocation
$lint = { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_windows.ps1')) }

# Call the linting script
.$lint
```

#### Remove locally cached tflint files

Using the TFLint script(s) above installs som files locally, if you at some point want to remove the local installation of TFLint this can be achieved calling the same script(s) with an argument :

```bash
# bash
lint --uninstall
```

```powershell
# powershell
Invoke-Command `
  -ScriptBlock ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_windows.ps1')) -join "`n")) `
  -ArgumentList $false,$true,$false # Force = false, Remove = true, ExitWithCode = false
```

**Note**: This must be repeated for each directory from which linting was performed.
