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

# lint with TFLint through the dsb CLI, which runs from the repository root
# load tf-helpers, make sure to be authenticated with GitHub cli in advance
pushd ../.. >/dev/null
source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;
tf-lint [BOOTSTRAP_VALUE_ENV_NAME]
popd >/dev/null

# plan should pass
terraform plan

# finally apply
terraform apply
```
