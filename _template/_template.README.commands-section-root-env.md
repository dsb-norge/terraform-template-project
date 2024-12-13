#### Environment: [BOOTSTRAP_VALUE_ENV_NAME]

```bash
# load tf-helpers, make sure to be authenticated with GitHub cli in advance
source <(gh api -H "Accept: application/vnd.github.v3.raw" /repos/dsb-norge/terraform-helpers/contents/dsb-tf-proj-helpers.sh) ;

# init, fmt, validate, lint and plan project
tf-set-env [BOOTSTRAP_VALUE_ENV_NAME] && \
tf-init && \
tf-fmt-fix && \
tf-validate && \
tf-lint && \
tf-plan

# when ready to apply
tf-apply
```

