# Attempting to add some additional rules
# See docs: https://github.com/terraform-linters/tflint/blob/master/docs/guides/config.md
# See rules: https://github.com/terraform-linters/tflint/tree/master/docs/rules

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}