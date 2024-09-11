### Environment: [BOOTSTRAP_VALUE_ENV_NAME]

```bash
# set Azure subscription
[BOOTSTRAP_VALUE_CMD_SEL_SUB]
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# init project env
terraform init -reconfigure

# run fmt and validate
terraform fmt -check -recursive
terraform validate

# lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
lint

# plan should pass
terraform plan

# finally apply
terraform apply
```
