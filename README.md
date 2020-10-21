# Reference Docs

- [Blog on OUs with AWS](https://aws.amazon.com/blogs/mt/best-practices-for-organizational-units-with-aws-organizations/)
- [OU Best Practices](https://aws.amazon.com/organizations/getting-started/best-practices/)

# Concept

For this prototype, the concept is to have the following environments:
- Dev
- Prod

The primary objectives are:
- Be able to easily promote code across environments
- Be able to configure infrastructure easily without a lot of spaghetti code

# High Level Architecture

## Breakdown

Accounts:
- Dev
- Prod
- Infrastructure

Folder structure:
```
/terraform
  /infrastructure
  /application
```

Generally, I'd recommend putting `/infrastructure` in its own repo. That way it can stand on its own as the general repo for CI/CD setup and any resources that are not application-specific. For the sake of prototyping, it will all be in one repo, but **2 distinct TF states**.

Comparing this to the AWS blog, this setup combines the "Infrastructure" and "Deployment" OUs into one entity for simplicity.

The blog doesn't explicitly recommending splitting by environment, but for simple clouds I don't think the elaborate breakdown is necessary.

## Benefits

For this setup, I imagine the benefits to be:
- IAM should be simpler than the alternative. Example:
```
# -> means "knows about"

# With infra account
Infra -> dev
      -> prod
      
dev -> Infra

prod -> Infra


# Without infra account
dev  -> prod
prod -> dev

# This doesn't look crazy, but when you add more environments it will get more cumbersome
dev -> test
test -> dev
     -> prod
prod -> test
```
- The billing and security controls should be easier to implement since the infra account has limited scope
- Central management of artifacts if desired (docker images, s3 zips, etc.)
- The TF recipes will be less redundant:
  - No need to duplicate the code pipeline in every environment. Infra can set up all the necessary CI/CD and have awareness of touch points in the app infrastructure (s3 bucket, lambda, or whatever is desired)
  - One place for managing the code promotion across envs
  
  
## Other good ideas

- A general security/logs account might be a good idea to centralize things like CloudTrail & GuardDuty
  
# Setup

Create the following setup for your local AWS config to verify you can utilize your master account and switch roles into your dev/prod/infra accounts under the primary OU:

In `~/.aws/config` (replace `12345` with correct account number):
```
[default]
region = us-east-1

[profile tf_multi]
region = us-east-1

[profile tf_multi_dev]
region = us-east-1
role_arn = arn:aws:iam::12345:role/OrganizationAccountAccessRole
source_profile = tf_multi

[profile tf_multi_prod]
region = us-east-1
role_arn = arn:aws:iam::12345:role/OrganizationAccountAccessRole
source_profile = tf_multi

[profile tf_multi_infra]
region = us-east-1
role_arn = arn:aws:iam::12345:role/OrganizationAccountAccessRole
source_profile = tf_multi
```

And in `~/.aws/credentials`
```
[tf_multi]
aws_access_key_id = BLAH123
aws_secret_access_key = blahkey123
```

If you are using 2-factor authentication, then you can use a helper similar to something here: https://github.com/JAMSUPREME/local-development-helpers/blob/master/aws-helpers.sh#L32 _(The only hardcoded part is the MFA ARN but you could put that in a custom file under `~/.aws` that matches per profile)_

**If you're using Windows**, I recommend using **Git Bash** since it is the closest to normal bash syntax while being aware of PATH and doesn't have too much weird powershell or linux subsytem goofiness.