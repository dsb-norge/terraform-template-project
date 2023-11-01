#!/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/_template"
ENVS_DIR="${ROOT_DIR}/envs"
TF_STATE_ENV_DIR="${ENVS_DIR}/_terraform-state"
ENV_TEMPLATE_DIR="${ENVS_DIR}/_template"
ENV_VARS_TEMPLATE_FILE="${TF_STATE_ENV_DIR}/_template.tfvars"
BOOTSTRAP_CONFIG_FILE="${ROOT_DIR}/bootstrap.json"

# Helper functions
function _jq { echo ${ENV_OBJ} | base64 --decode | jq -r ${*}; }
function _set-val { OUT_OBJ="$(echo "${OUT_OBJ}" | jq --arg name "${1}" --arg value "${2}" '.[$name] = $value')"; }
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
function _get-sub-for-env {
  local sub should_return
  should_return=0
  while [ "${should_return}" -ne 1 ]; do
    read -r -p "Enter subscription for environment '$1': " INPUT_SUB
    for sub in ${SUBS[@]}; do
      if [ "${sub}" == "${INPUT_SUB}" ]; then
        should_return=1
        break
      fi
    done
  done
}

echo "scaffold.sh: working directory: ${ROOT_DIR}"

echo "scaffold.sh: check prerequirements ..."
SHOULD_EXIT=0
if ! command -v jq --version &>/dev/null; then
  echo 'scaffold.sh: ERROR: Missing prerequsite: jq - command-line JSON processor. Please install manually.'
  SHOULD_EXIT=255
fi
if ! command -v az --version &>/dev/null; then
  echo 'scaffold.sh: ERROR: Missing prerequsite: az - Azure Command-Line Interface (CLI). Please install manually.'
  SHOULD_EXIT=255
fi
if ! command -v terraform -version &>/dev/null; then
  echo 'scaffold.sh: ERROR: Missing prerequsite: terraform - infrastructure as code software tool. Please install manually.'
  SHOULD_EXIT=255
fi
if [ ! -d "${TEMPLATE_DIR}" ]; then
  echo "scaffold.sh: ERROR: Missing scaffold template directory, expected at '${TEMPLATE_DIR}'"
  SHOULD_EXIT=255
fi
if [ "${SHOULD_EXIT}" -ne 0 ]; then
  echo "scaffold.sh: ERROR: Missing prerequsite(s). Aborting."
  exit "${SHOULD_EXIT}"
fi

echo "scaffold.sh: determine environments ..."
read -p "Enter your environment names separated by spaces, default [dev test prod]: " INPUT_ENVS
INPUT_ENVS=${INPUT_ENVS:-dev test prod}
UNIQ_ENVS=($(for ENV in "${INPUT_ENVS[@]}"; do echo "${ENV}"; done | sort -u))
echo "scaffold.sh: given environment names:"
for ENV in ${UNIQ_ENVS[@]}; do echo "scaffold.sh:   - ${ENV}"; done

echo "scaffold.sh: read available subscriptions ..."
SUBS="$(az account list --query "[].name | sort(@)" -o tsv)"
echo "scaffold.sh: subscriptions available:"
for SUB in ${SUBS[@]}; do echo "scaffold.sh:   - ${SUB}"; done

echo "scaffold.sh: determine subscriptions ..."
declare -A ENV_TO_SUB_MAP
for ENV in ${UNIQ_ENVS[@]}; do
  _get-sub-for-env "${ENV}"
  ENV_TO_SUB_MAP[${ENV}]="${INPUT_SUB}"
done

echo -e "\nscaffold.sh:\n  project will be scaffolded in '${ROOT_DIR}'\n  with the following configuration:"
for ENV in "${!ENV_TO_SUB_MAP[@]}"; do
  echo -e "    - ${ENV}\t-> ${ENV_TO_SUB_MAP[${ENV}]}"
done
_yes-or-no "Does this 🔼 look correct?" || exit 0

echo "scaffold.sh: templating project ..."
mv -f ${TEMPLATE_DIR}/* "${ROOT_DIR}"
mv -f "${TEMPLATE_DIR}/.gitignore" "${ROOT_DIR}/.gitignore"
rm -r "${TEMPLATE_DIR}"
declare -A ENV_TO_VARS_FILE_MAP
for ENV in "${!ENV_TO_SUB_MAP[@]}"; do
  echo "scaffold.sh: templating '${ENV}' environment ..."
  mkdir -p "${ENVS_DIR}/${ENV}"
  cp -r ${ENV_TEMPLATE_DIR}/* "${ENVS_DIR}/${ENV}"
  ENV_TO_VARS_FILE_MAP[${ENV}]="${TF_STATE_ENV_DIR}/env.${ENV}.tfvars"
  sed "s/\[SCAFFOLD_VALUE_ENVIRONMENT_NAME\]/$ENV/g" ${ENV_VARS_TEMPLATE_FILE} >"${ENV_TO_VARS_FILE_MAP[${ENV}]}"
done

echo "scaffold.sh: writing $(_rel-path "${BOOTSTRAP_CONFIG_FILE}") ..."
OUT_JSON='[]'
for ENV in "${!ENV_TO_SUB_MAP[@]}"; do
  OUT_OBJ="{}"
  _set-val "environment" "${ENV}"
  _set-val "subscription" "${ENV_TO_SUB_MAP[${ENV}]}"
  OUT_JSON=$(echo "${OUT_JSON}" | jq '. += '["${OUT_OBJ}"']')
done
echo "${OUT_JSON}" >"${BOOTSTRAP_CONFIG_FILE}"

echo "scaffold.sh: cleanup ..."
rm -rf "${ENV_TEMPLATE_DIR}"
rm "${ENV_VARS_TEMPLATE_FILE}"

echo -e "scaffold.sh: scaffolding complete.\n"
echo "scaffold.sh: next steps:"
echo "scaffold.sh:   1️⃣  Edit values in the following files:"
for VARS_FILE in "${ENV_TO_VARS_FILE_MAP[@]}"; do
  echo "scaffold.sh:     - $(_rel-path "${VARS_FILE}")"
done
echo "scaffold.sh:   2️⃣  Run step_2_bootstrap.sh to bootstrap terraform backend state for all envs in the project:"
echo -e "scaffold.sh:   3️⃣  Run step_3_remove_init_scripts.sh\n"
