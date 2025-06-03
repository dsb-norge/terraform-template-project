#### Terraform state environment: [BOOTSTRAP_VALUE_ENV_NAME]

```bash
envDir='envs/_terraform-state'

# set Azure subscription
[BOOTSTRAP_VALUE_CMD_SEL_SUB]
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# init project env
terraform -chdir="${envDir}" init -reconfigure -backend-config='backend-config.[BOOTSTRAP_VALUE_ENV_NAME].hcl'

# run fmt and validate
terraform fmt -check -recursive
terraform -chdir="${envDir}" validate

# lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
pushd "${envDir}" >/dev/null && lint && popd >/dev/null || popd >/dev/null

# plan should pass
terraform -chdir="${envDir}" plan -var-file='env.[BOOTSTRAP_VALUE_ENV_NAME].tfvars'

# finally apply
terraform -chdir="${envDir}" apply -var-file='env.[BOOTSTRAP_VALUE_ENV_NAME].tfvars'
```

