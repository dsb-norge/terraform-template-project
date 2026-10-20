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

# lint with TFLint through the dsb CLI, once per env.*.tfvars file in "${envDir}"
# load tf-helpers, make sure to be authenticated with GitHub cli in advance
source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;
tf-lint-tfstate

# plan should pass
terraform -chdir="${envDir}" plan -var-file='env.[BOOTSTRAP_VALUE_ENV_NAME].tfvars'

# finally apply
terraform -chdir="${envDir}" apply -var-file='env.[BOOTSTRAP_VALUE_ENV_NAME].tfvars'
```

