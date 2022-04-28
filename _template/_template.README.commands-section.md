#### Environment: [BOOTSTRAP_VALUE_ENV_NAME]

```bash
# Log in to Azure and set subscription
az login
[BOOTSTRAP_VALUE_CMD_SEL_SUB]

# Init project, run fmt and validate
[BOOTSTRAP_VALUE_CMD_ROOT_INIT]
[BOOTSTRAP_VALUE_CMD_ROOT_FMT]
[BOOTSTRAP_VALUE_CMD_ROOT_VALIDATE]

# Lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
[BOOTSTRAP_VALUE_CMD_ROOT_LINT2]

# Plan should pass
[BOOTSTRAP_VALUE_CMD_ROOT_PLAN]

# Finally apply
[BOOTSTRAP_VALUE_CMD_ROOT_APPLY]
```
