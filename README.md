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

## Workflow

I'll briefly explain the development lifecycle:

- Create/Modify `/infrastructure` and run `terraform apply` for the shared infrastructure from your local machine
  - _Note:_ For future modifications, it would be possible to automate modifying the infrastructure (i.e. another CodePipeline for infrastructure to modify itself), but you'd still probably want manual intervention since it could torch everything by accident.
- Create/Modify `/application`
- Application code gets picked up by the infrastructure CodePipeline (or jenkins, hooks, etc.)
- Infrastructure account will build artifacts and deploy to the application account

### Adhoc things

If for some reason you're seeing something unusual in any environment, you have AWS creds to them, so it is possible to manually run a `terraform plan` (or `apply`) to see unusual behavior, or make changes yourself from the console or CLI.

Since Terraform detects and fixes drift, you can safely let your changes get blown away with the next deploy.
  
# Setup

## Make the accounts

If you haven't already, turn on Organizations in AWS and create 3 accounts under the root:
- Dev
- Prod
- Infra

You can tie these all to the same email address as long as you add a `+` suffix.

For example:
`justin@gmail.com` (root)
`justin@gmail+dev.com` (dev)
`justin@gmail+prod.com` (prod)
`justin@gmail+infra.com` (infra)

## Make a user in the root account

Since root user shouldn't be used for normal stuff, we'll make another user for ourselves that can switch roles:

- Make an admin user in the root account for yourself.
- Log in with this user 
- Make sure you can "switch roles" to switch into the dev, prod, and infra accounts

## Set up local creds

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

**You can verify it works** by doing something like this:
```
export AWS_PROFILE=tf_multi_infra
aws s3 ls
```

And it should show you the buckets you have in your infrastructure account

# Local development

## Running the app locally

`./gradlew bootRun` should work for starting the app up. Then navigate to http://localhost:8090 (or whatever port you configure) and it should respond

## Building image

`docker build .` from root _(may change once I build useful TF)_

## Run image

`docker run -p 9090:80 67ebb619f0ff` (replace SHA with your build hash)

## Test via docker

Visit `http://localhost:9090`

# Terraform

## Infrastructure (Dev)

**Note:** Still considering if we want one terraform recipe per environment, or if each environment would share the same resources. At the moment, it seems like separating resources per environment will be a good idea so that builds and images don't get mixed up.

## Github token

If you pull from github, then you should copy the `secrets.tfvars.example` file and rename to `secrets.tfvars` and fill it with your token.

There is a `.gitignore` for `secrets.tfvars`

## Create s3 bucket

Create an s3 bucket in the `infra` account and name it something like `infra-dev-terraform-488905147906`

_**Important:** Remember to create the bucket in the correct account (not the root!)_

You can then do:
`terraform init -backend-config=config/backend-dev.conf`

And it should be possible to then do an apply:

`terraform apply -var-file="config/dev.tfvars"` _(`secrets.auto.tfvars` will be picked up automatically)_

# Other thoughts

## Account Mgmt

- A general security/logs account might be a good idea to centralize things like CloudTrail & GuardDuty

## Other Tooling

At the moment, if you're using lambda or s3 it seems fairly prudent to utilize Terraform to bootstrap the infrastructure and then in its CodePipeline setup it will pull the application code and run the application's Terraform.

If using containers, it may be worth using Hashicorp Waypoint to abstract the complexity of ECS/Kubernetes.