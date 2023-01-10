#!/bin/bash
set -euo pipefail

# directories
ROOT_DIR="$(pwd)"
TF_STATE_ENV_DIR="${ROOT_DIR}/envs/_terraform-state"
TF_STATE_BACKEND_FILE="${TF_STATE_ENV_DIR}/backend.tf"

# boostrap config
BOOTSTRAP_CONFIG_FILE="${ROOT_DIR}/bootstrap.json"

# configuration template files
TF_STATE_BACKEND_TEMPLATE_FILE="${TF_STATE_ENV_DIR}/_template.backend.hcl"
TF_STATE_BACKEND_VARS_TEMPLATE_FILE="${TF_STATE_ENV_DIR}/_template.backend-config.hcl"

# readme base files
ROOT_README_FILE="${ROOT_DIR}/README.md"
ROOT_README_TEMPLATE_FILE="${ROOT_DIR}/_template.README.md"
ROOT_README_COMMANDS_TEMPLATE_FILE="${ROOT_DIR}/_template.README.commands-section.md"

# terraform state files that must be purged during init of tfstate for multiple envs
TF_STATE_REMOTE_STATE_FILES=(
  "${TF_STATE_ENV_DIR}/terraform.tfstate"
  "${TF_STATE_ENV_DIR}/terraform.tfstate.backup"
  "${TF_STATE_ENV_DIR}/.terraform/terraform.tfstate"
)

# Helper functions
function _jq { echo ${ENV_OBJ} | base64 --decode | jq -r ${*}; }
function _rel-path { realpath --quiet --relative-to="${ROOT_DIR}" "$1"; }
function _yes-or-no {
  while true; do
    read -r -p "$* [y/n]: " yn
    case ${yn} in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    esac
  done
}
function _record-commands-for-readme {
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "selectSub"]="az account set --subscription '${SUB_NAME}'"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "init"]="terraform -chdir='$(_rel-path "${ENV_DIR}")' init -reconfigure -upgrade"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "fmt"]="terraform -chdir='$(_rel-path "${ENV_DIR}")' fmt -check -recursive"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "validate"]="terraform -chdir='$(_rel-path "${ENV_DIR}")' validate"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "lint2"]="pushd '$(_rel-path "${ENV_DIR}")' >/dev/null && lint -f && popd >/dev/null || popd >/dev/null"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "plan"]="terraform -chdir='$(_rel-path "${ENV_DIR}")' plan"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "apply"]="terraform -chdir='$(_rel-path "${ENV_DIR}")' apply"

  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-selectSub"]="az account set --subscription '${SUB_NAME}'"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-init"]="terraform -chdir='$(_rel-path "${TF_STATE_ENV_DIR}")' init -reconfigure -upgrade -backend-config='${ENV_TF_STATE_BACKEND_VARS_FILE_NAME}'"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-fmt"]="terraform -chdir='$(_rel-path "${TF_STATE_ENV_DIR}")' fmt -check -recursive"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-validate"]="terraform -chdir='$(_rel-path "${TF_STATE_ENV_DIR}")' validate"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-lint2"]="pushd '$(_rel-path "${TF_STATE_ENV_DIR}")' >/dev/null && lint -f && popd >/dev/null || popd >/dev/null"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-plan"]="terraform -chdir='$(_rel-path "${TF_STATE_ENV_DIR}")' plan -var-file='${ENV_TFVARS_FILE_NAME}'"
  TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-apply"]="terraform -chdir='$(_rel-path "${TF_STATE_ENV_DIR}")' apply -var-file='${ENV_TFVARS_FILE_NAME}'"

  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "selectSub"]="az account set --subscription '${SUB_NAME}'"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "init"]="terraform init -reconfigure -upgrade"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "fmt"]="terraform fmt -check -recursive"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "validate"]="terraform validate"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "lint2"]="lint -f"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "plan"]="terraform plan"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "apply"]="terraform apply"

  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-selectSub"]="az account set --subscription '${SUB_NAME}'"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-init"]="terraform init -reconfigure -upgrade -backend-config='${ENV_TF_STATE_BACKEND_VARS_FILE_NAME}'"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-fmt"]="terraform fmt -check -recursive"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-validate"]="terraform validate"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-lint2"]="lint -f"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-plan"]="terraform plan -var-file='${ENV_TFVARS_FILE_NAME}'"
  TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-apply"]="terraform apply -var-file='${ENV_TFVARS_FILE_NAME}'"
}
function _create-cmd-to-tag-map {
  CMD_TO_TAG[selectSub]="BOOTSTRAP_VALUE_CMD_SEL_SUB"
  CMD_TO_TAG[init]="BOOTSTRAP_VALUE_CMD_ROOT_INIT"
  CMD_TO_TAG[fmt]="BOOTSTRAP_VALUE_CMD_ROOT_FMT"
  CMD_TO_TAG[validate]="BOOTSTRAP_VALUE_CMD_ROOT_VALIDATE"
  CMD_TO_TAG[lint2]="BOOTSTRAP_VALUE_CMD_ROOT_LINT2"
  CMD_TO_TAG[plan]="BOOTSTRAP_VALUE_CMD_ROOT_PLAN"
  CMD_TO_TAG[apply]="BOOTSTRAP_VALUE_CMD_ROOT_APPLY"
}
function _replace-tag-with-file {
  # $1 look for
  # $2 look in
  # $3 file to insert contents of
  sed -i \
    -e "/\[$1\]/ {" \
    -e "r $3" \
    -e 'd' \
    -e '}' "$2"
}

echo "bootstrap.sh: working directory: ${ROOT_DIR}"
echo "bootstrap.sh:   - terraform state env directory: $(_rel-path "${TF_STATE_ENV_DIR}")"
echo "bootstrap.sh:   - terraform state env backend file: $(_rel-path "${TF_STATE_BACKEND_FILE}")"

echo "bootstrap.sh: check prerequirements ..."
SHOULD_EXIT=0
if ! command -v jq --version &>/dev/null; then
  echo 'bootstrap.sh: ERROR: Missing prerequsite: jq - command-line JSON processor. Please install manually.'
  SHOULD_EXIT=255
fi
if ! command -v az --version &>/dev/null; then
  echo 'bootstrap.sh: ERROR: Missing prerequsite: az - Azure Command-Line Interface (CLI). Please install manually.'
  SHOULD_EXIT=255
fi
if ! command -v terraform -version &>/dev/null; then
  echo 'bootstrap.sh: ERROR: Missing prerequsite: terraform - infrastructure as code software tool. Please install manually.'
  SHOULD_EXIT=255
fi
if [ ! -d "${TF_STATE_ENV_DIR}" ]; then
  echo "bootstrap.sh: ERROR: Missing terraform state env directory, expected at '${TF_STATE_ENV_DIR}'"
  SHOULD_EXIT=255
fi
if [ ! -f "${BOOTSTRAP_CONFIG_FILE}" ]; then
  echo "bootstrap.sh: ERROR: Missing bootstrap configuration file, expected at '${BOOTSTRAP_CONFIG_FILE}'"
  SHOULD_EXIT=255
fi
if [ "${SHOULD_EXIT}" -ne 0 ]; then
  echo "bootstrap.sh: ERROR: Missing prerequsite(s). Aborting."
  exit "${SHOULD_EXIT}"
fi

echo "bootstrap.sh: read bootstrap configuration file, at $(_rel-path "${BOOTSTRAP_CONFIG_FILE}")"
BOOTSTRAP_CONFIG_JSON=$(cat "${BOOTSTRAP_CONFIG_FILE}")

echo "bootstrap.sh: verify that all subscriptions are available ..."
for ENV_OBJ in $(echo "${BOOTSTRAP_CONFIG_JSON}" | jq -r '.[] | @base64'); do
  SUB_NAME="$(_jq '.subscription')"
  ENV_NAME="$(_jq '.environment')"
  echo "bootstrap.sh:   - subscription: ${SUB_NAME} -> environment dir: ${ENV_NAME}"
  az account set --subscription "${SUB_NAME}"
done

_yes-or-no "Ready to bootstrap project, does the above 🔼 look correct?" || exit 0

# Loop over envs and bootstrap
pushd "${TF_STATE_ENV_DIR}" >/dev/null
declare -A TF_COMMANDS_FROM_ENV_DIR
declare -A TF_COMMANDS_FROM_ROOT_DIR
for ENV_OBJ in $(echo "${BOOTSTRAP_CONFIG_JSON}" | jq -r '.[] | @base64'); do
  SUB_NAME="$(_jq '.subscription')"
  ENV_NAME="$(_jq '.environment')"

  ENV_DIR="${ROOT_DIR}/envs/${ENV_NAME}"
  ENV_BACKEND_FILE="${ENV_DIR}/backend.tf"
  ENV_BACKEND_TEMPLATE_FILE="${ENV_DIR}/_template.backend.hcl"

  ENV_TFVARS_FILE_NAME="env.${ENV_NAME}.tfvars"
  ENV_TF_STATE_BACKEND_VARS_FILE_NAME="backend-config.${ENV_NAME}.hcl"
  ENV_TFVARS_FILE="${TF_STATE_ENV_DIR}/${ENV_TFVARS_FILE_NAME}"
  ENV_TF_STATE_BACKEND_VARS_FILE="${TF_STATE_ENV_DIR}/${ENV_TF_STATE_BACKEND_VARS_FILE_NAME}"

  echo "bootstrap.sh: bootstrapping environment '${ENV_NAME}' ..."
  echo "bootstrap.sh:   - subscription name: ${SUB_NAME}"
  echo "bootstrap.sh:   - tfvars file: $(_rel-path "${ENV_TFVARS_FILE}")"
  echo "bootstrap.sh:   - backend file: $(_rel-path "${ENV_BACKEND_FILE}")"
  echo "bootstrap.sh:   - tfstate backend file: $(_rel-path "${ENV_TF_STATE_BACKEND_VARS_FILE}")"

  if [ ! -f "${ENV_TFVARS_FILE}" ]; then
    echo "bootstrap.sh:   aborting, as tfvars file for environment '${ENV_NAME}' does not exist at '$(_rel-path "${ENV_TFVARS_FILE}")'"
    exit 1
  fi

  if [ -f "${ENV_BACKEND_FILE}" ]; then
    echo "bootstrap.sh:   skipping, as backend file for environment '${ENV_NAME}' allready exists at '$(_rel-path "${ENV_BACKEND_FILE}")'"
    continue # with next environment
  fi

  if [ -f "${TF_STATE_BACKEND_FILE}" ]; then
    echo "bootstrap.sh:   removing backend.tf (created during bootstraping of previous environment) at '$(_rel-path "${TF_STATE_BACKEND_FILE}")'"
    rm "${TF_STATE_BACKEND_FILE}"
  fi

  # While iterating envs we generate commands for each env to later put in README
  _record-commands-for-readme

  echo "bootstrap.sh:   select subscription ..."
  az account set --subscription "${SUB_NAME}"

  echo "bootstrap.sh:   terraform init '${ENV_NAME}' environment ..."
  terraform init -reconfigure

  echo "bootstrap.sh:   terraform apply '${ENV_NAME}' environment ..."
  terraform apply -var-file="${ENV_TFVARS_FILE}"

  echo "bootstrap.sh:   read terraform outputs for '${ENV_NAME}' environment ..."
  declare -A TF_OUTPUTS
  TF_OUTPUTS[resource_group_name]="$(terraform output -json | jq -r '.resource_group_name.value')"
  TF_OUTPUTS[storage_account_name]=$(terraform output -json | jq -r '.storage_account_name.value')
  TF_OUTPUTS[container_name]=$(terraform output -json | jq -r '.container_name.value')

  echo "${TF_OUTPUTS[@]}"

  echo "bootstrap.sh:   create terraform backend config for ${ENV_NAME} environment at '$(_rel-path "${ENV_BACKEND_FILE}")'"
  mv "${ENV_BACKEND_TEMPLATE_FILE}" "${ENV_BACKEND_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_RG_NAME\]/${TF_OUTPUTS[resource_group_name]}/g" "${ENV_BACKEND_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_STRG_ACC_NAME\]/${TF_OUTPUTS[storage_account_name]}/g" "${ENV_BACKEND_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_STATE_NAME\]/${TF_OUTPUTS[container_name]}/g" "${ENV_BACKEND_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${ENV_BACKEND_FILE}"

  echo "bootstrap.sh:   create terraform backend config for terraform-state in ${ENV_NAME} environment at '$(_rel-path "${ENV_TF_STATE_BACKEND_VARS_FILE}")'"
  cp "${TF_STATE_BACKEND_VARS_TEMPLATE_FILE}" "${ENV_TF_STATE_BACKEND_VARS_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_RG_NAME\]/${TF_OUTPUTS[resource_group_name]}/g" "${ENV_TF_STATE_BACKEND_VARS_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_STRG_ACC_NAME\]/${TF_OUTPUTS[storage_account_name]}/g" "${ENV_TF_STATE_BACKEND_VARS_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_STATE_NAME\]/${TF_OUTPUTS[container_name]}/g" "${ENV_TF_STATE_BACKEND_VARS_FILE}"
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${ENV_TF_STATE_BACKEND_VARS_FILE}"

  echo "bootstrap.sh:   create terraform state project backend file at '$(_rel-path "${TF_STATE_BACKEND_FILE}")'"
  cp -f "${TF_STATE_BACKEND_TEMPLATE_FILE}" "${TF_STATE_BACKEND_FILE}"

  echo "bootstrap.sh:   migrate state for terraform state project to remote container ..."
  terraform init -backend-config="${ENV_TF_STATE_BACKEND_VARS_FILE}" -migrate-state -force-copy

  echo "bootstrap.sh:   removing state files ..."
  for STATE_FILE in "${TF_STATE_REMOTE_STATE_FILES[@]}"; do
    if [ -f "${STATE_FILE}" ]; then
      echo "bootstrap.sh:     - at '$(_rel-path "${STATE_FILE}")'"
      rm -f "${STATE_FILE}"
    fi
  done

done # Loop over envs
popd >/dev/null 2>&1 || :

echo "bootstrap.sh: build README files ..."

# final readme for tfstate
TFSTATE_README="${TF_STATE_ENV_DIR}/README.md"

# temp files to build readme blocks when looping throughenvs
TFSTATE_CMD_FILE="${TF_STATE_ENV_DIR}/_temp.all-commands.README.md"          # tstate readme all envs
TFSTATE_ENV_CMD_FILE="${TF_STATE_ENV_DIR}/_temp.commands.README.md"          # tstate readme current env
ROOT_TFSTATE_CMD_FILE="${ROOT_DIR}/_temp.tfstate-all-commands.README.md"     # root tfstate readme all envs
ROOT_TFSTATE_ENV_CMD_FILE="${ROOT_DIR}/_temp.tfstate-env-commands.README.md" # root tfstate readme current env
ROOT_CMD_FILE="${ROOT_DIR}/_temp.all-commands.README.md"                     # root readme all envs
ROOT_ENV_CMD_FILE="${ROOT_DIR}/_temp.env-commands.README.md"                 # root readme current env

# types of commands to put in readme with mapping to tags in template file
COMMANDS=(selectSub init fmt validate lint2 plan apply)
declare -A CMD_TO_TAG
_create-cmd-to-tag-map

for ENV_OBJ in $(echo "${BOOTSTRAP_CONFIG_JSON}" | jq -r '.[] | @base64'); do
  ENV_NAME="$(_jq '.environment')"
  ENV_DIR="${ROOT_DIR}/envs/${ENV_NAME}"

  # final readme for env
  ENV_README="${ENV_DIR}/README.md"

  # template readme for env
  ENV_README_TEMPLATE="${ENV_DIR}/_template.README.md"

  echo "bootstrap.sh:   - $(_rel-path "${ENV_README}")"

  # new empty temp files for current env
  # based of _template.README.commands-section.md in root dir
  ENV_CMD_FILE="${ENV_DIR}/_temp.env-commands.README.md"
  cp -f "${ROOT_README_COMMANDS_TEMPLATE_FILE}" "${ENV_CMD_FILE}"              # env readme
  cp -f "${ROOT_README_COMMANDS_TEMPLATE_FILE}" "${TFSTATE_ENV_CMD_FILE}"      # tfstate readme
  cp -f "${ROOT_README_COMMANDS_TEMPLATE_FILE}" "${ROOT_TFSTATE_ENV_CMD_FILE}" # root tfstate readme
  cp -f "${ROOT_README_COMMANDS_TEMPLATE_FILE}" "${ROOT_ENV_CMD_FILE}"         # root tfstate readme

  # Build command blocks in temp files
  for CMD in "${COMMANDS[@]}"; do
    REPLACE="${CMD_TO_TAG[${CMD}]}"

    # all commands -> env readme
    ESCAPED_REPLACE_WITH=$(printf '%s\n' "${TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "${CMD}"]}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\[${REPLACE}\]/${ESCAPED_REPLACE_WITH}/g" "${ENV_CMD_FILE}"

    # all commands -> tfstate readme
    ESCAPED_REPLACE_WITH=$(printf '%s\n' "${TF_COMMANDS_FROM_ENV_DIR[${ENV_NAME}, "state-${CMD}"]}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\[${REPLACE}\]/${ESCAPED_REPLACE_WITH}/g" "${TFSTATE_ENV_CMD_FILE}"

    # all commands -> root tfstate readme
    ESCAPED_REPLACE_WITH=$(printf '%s\n' "${TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "state-${CMD}"]}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\[${REPLACE}\]/${ESCAPED_REPLACE_WITH}/g" "${ROOT_TFSTATE_ENV_CMD_FILE}"

    # all commands -> root readme
    ESCAPED_REPLACE_WITH=$(printf '%s\n' "${TF_COMMANDS_FROM_ROOT_DIR[${ENV_NAME}, "${CMD}"]}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\[${REPLACE}\]/${ESCAPED_REPLACE_WITH}/g" "${ROOT_ENV_CMD_FILE}"
  done

  # Write readme for current env
  sed \
    -e '/\[BOOTSTRAP_VALUE_README_SEC_ENV_CMDS\]/ {' \
    -e "r ${ENV_CMD_FILE}" \
    -e 'd' \
    -e '}' "${ENV_README_TEMPLATE}" >"${ENV_README}"
  rm "${ENV_CMD_FILE}"

  # Add env name to readmes
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${ENV_README}"                # env name -> env readme
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${TFSTATE_ENV_CMD_FILE}"      # env name -> tfstate readme
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${ROOT_TFSTATE_ENV_CMD_FILE}" # env name -> root tfstate readme
  sed -i "s/\[BOOTSTRAP_VALUE_ENV_NAME\]/${ENV_NAME}/g" "${ROOT_ENV_CMD_FILE}"         # env name -> root readme

  # Remove template readme for env
  rm "${ENV_README_TEMPLATE}"

  # collect command blocks for all envs in common temp files
  cat "${TFSTATE_ENV_CMD_FILE}" >>"${TFSTATE_CMD_FILE}"           # tstate readme current env -> tstate readme all envs
  cat "${ROOT_TFSTATE_ENV_CMD_FILE}" >>"${ROOT_TFSTATE_CMD_FILE}" # tstate readme current env -> root tstate readme all envs
  cat "${ROOT_ENV_CMD_FILE}" >>"${ROOT_CMD_FILE}"                 # readme current env -> root readme all envs

  # remove intermediate env temp files
  rm "${TFSTATE_ENV_CMD_FILE}"
  rm "${ROOT_TFSTATE_ENV_CMD_FILE}"
  rm "${ROOT_ENV_CMD_FILE}"

done

# Write readme for tfstate
echo "bootstrap.sh:   - $(_rel-path "${TFSTATE_README}")"
_replace-tag-with-file 'BOOTSTRAP_VALUE_README_SEC_STATE_CMDS' "${TFSTATE_README}" "${TFSTATE_CMD_FILE}"

# Write root readme: root template + env commands + tfstate commands
echo "bootstrap.sh:   - $(_rel-path "${TFSTATE_README}")"
cp -f "${ROOT_README_TEMPLATE_FILE}" "${ROOT_README_FILE}"
_replace-tag-with-file 'BOOTSTRAP_VALUE_README_SEC_ENV_CMDS' "${ROOT_README_FILE}" "${ROOT_CMD_FILE}"
_replace-tag-with-file 'BOOTSTRAP_VALUE_README_SEC_STATE_CMDS' "${ROOT_README_FILE}" "${ROOT_TFSTATE_CMD_FILE}"

# remove intermediate temp files
rm "${TFSTATE_CMD_FILE}"
rm "${ROOT_TFSTATE_CMD_FILE}"
rm "${ROOT_CMD_FILE}"

echo "bootstrap.sh: cleanup ..."
CLEAN_FILES=(
  "${TF_STATE_BACKEND_VARS_TEMPLATE_FILE}"
  "${TF_STATE_BACKEND_TEMPLATE_FILE}"
  "${ROOT_README_TEMPLATE_FILE}"
  "${ROOT_README_COMMANDS_TEMPLATE_FILE}"
)
for FILE in "${CLEAN_FILES[@]}"; do
  if [ -f "${FILE}" ]; then
    echo "bootstrap.sh:   - $(_rel-path "${FILE}")"
    rm -f "${FILE}"
  fi
done

echo -e "bootstrap.sh: bootstrapping complete.\n"
echo "bootstrap.sh: next steps:"
echo "bootstrap.sh:   1️⃣  Run step_3_remove_init_scripts.sh to remove files remaining from the process."
echo "bootstrap.sh:   2️⃣  Update project README.md in the root  directory with relevant information."
echo -e "bootstrap.sh:   3️⃣  Start developing your terraform project 😁\n"
