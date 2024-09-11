#### Environment: [BOOTSTRAP_VALUE_ENV_NAME]

```bash
[BOOTSTRAP_VALUE_CMD_SET_ENV]
rootDir="$(realpath .)"
envDir="${rootDir}/envs/${environment}"

# set Azure subscription
az account set --subscription "$(cat ${envDir}/.az-subscription)"
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# init project env
terraform -chdir="${envDir}" init -reconfigure

# init modules
function _init {
  cp -f "${envDir}/.terraform.lock.hcl" "${1}/.terraform.lock.hcl"
  TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true \
    terraform -chdir="${1}" init -input=false -plugin-dir="${envDir}/.terraform/providers" -backend=false -reconfigure
  rm "${1}/.terraform.lock.hcl"
}
mapfile -t moduleDirs < <(ls -d "${rootDir}"/modules/*/)
moduleDirs+=("${rootDir}/main")
for moduleDir in ${moduleDirs[@]}; do _init "${moduleDir}" "${envDir}"; done

# run fmt and validate
terraform fmt -check -recursive
terraform -chdir="${envDir}" validate

# lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
pushd "${envDir}" >/dev/null && lint && popd >/dev/null || popd >/dev/null

# plan should pass
terraform -chdir="${envDir}" plan

# finally apply
terraform -chdir="${envDir}" apply
```

