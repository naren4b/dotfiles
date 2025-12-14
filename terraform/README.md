To verify Terraform is really using the intended AWS profile, combine an explicit profile selection with an identity check.

## 1. Point Terraform at a specific profile

EITHER via environment variable in your shell:

```bash
export AWS_PROFILE=personal   # or corporate
export AWS_REGION=ap-south-1   # or your region
```

Terraform’s AWS provider uses the same profile/region resolution logic as the AWS SDK/CLI, so this will direct it to that named profile.[1][2][3]

OR via provider block:

```hcl
provider "aws" {
  profile = "corporate"        # or "personal"
  region  = "ap-south-1"
}
```


## 2. Add a quick identity check in Terraform

In your Terraform code, add:

```hcl
data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
```

This data source returns the AWS account and ARN that Terraform is authenticated as.[4][5]

Run:

```bash
terraform init
terraform plan
```

Terraform will print the `account_id` and `caller_arn` outputs, so you can see exactly which account/profile it is hitting.[6][4]

## 3. Cross‑check with AWS CLI

From the same shell (with `AWS_PROFILE` set if you’re using env‑based profiles), run:

```bash
aws sts get-caller-identity
```

Compare the `Account` and `Arn` from this CLI call with the Terraform outputs; they should match if Terraform is using the right profile.[7][8]

If they don’t match, fix either the `AWS_PROFILE`/`AWS_REGION` env vars or the `profile` argument in the `aws` provider and repeat the check.[9][10][11]
