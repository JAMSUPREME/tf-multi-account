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

# Conclusion

I've concluded it's a better idea to do the following:

**Accounts:**
- Dev
- Prod

**Repositories:**
- App1
- App2
- Shared Infrastructure

This allows us to shared resources across apps if desired (VPC, CodeBuild, s3, SNS, etc.) while keeping all the app-specific code in the respective application.

## Why no Infrastructure Account?

Ran into a few issues that made development more problematic than it was worth:
- When talking about `infrastructure` it wouldn't be clear if we are discussing shared infrastructure, or the actual "infrastructure" account
- If we need shared infrastructure, we end up with multiple repos and their purposes (and accounts) aren't clearly defined, e.g.
```
/app1         (dev, prod)
/shared-infra (dev, prod)
/infra        (infra)
```
- It may or may not be practical to have a shared CodeBuild/CodePipeline in the infrastructure repo. If apps need unexpected customizations, we'll be cluttering both repos and introducing confusion.
- The promotion model can be made fairly simple by using SNS, so we won't be tightly coupling environments (see "Benefits" below for my earlier thoughts)
- The problem of a central ECR repo (or any other resource) can be solved by a distinct `shared-infra` repo, and there is no need for a distinct AWS account

## How is infrastructure created?

My thoughts:
- Initially it would be bootstrapped by a developer
- Once bootstrapped _(your CodeBuild exists)_ we can then automatically let Terraform apply itself if desired. I think this would be the most practical option since the infrastructure and code are often dependent on one another
- Once an app gets a new PR, we can run whatever needs to happen in a `buildspec.yml` for the app (e.g. making the container or JAR)
- Once the app has built, we can run terraform to update the infrastructure (best practice to make sure no drift)

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

**NOTE:** I'm recanting this idea - the coupling will be fairly minimal, and less problematic than coupling to a limited-use infrastructure account.

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

## Where does my TF code go?

Thoughts:
- If an app needs to build differently, is it sufficient that it gets its own buildspec? Or would we need further customization?
- What belongs in "infrastructure" vs. "application" ?
  - Infrastructure is a standalone account, so it would be responsible for provisioning cross-app shared infrastructure
  - A separate repo would be required for init infrastructure (VPC, etc.)
  - Perhaps better to have a shared infrastructure repo and omit the account?

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
`justin+dev@gmail.com` (dev)
`justin+prod@gmail.com` (prod)
`justin+infra@gmail.com` (infra)

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

## Docker token

In order to mitigate docker's image pull throttling, you should authenticate with docker. Create an access token and then paste it into `secrets.tfvars`

## Create s3 bucket

Create an s3 bucket in the `infra` account and name it something like `infra-dev-terraform-488905147906`

_**Important:** Remember to create the bucket in the correct account (not the root!)_

You can then do:
`terraform init -backend-config=config/backend-dev.conf`

And it should be possible to then do an apply:

`terraform apply -var-file="config/dev.tfvars"` _(`secrets.auto.tfvars` will be picked up automatically)_

# Using CDK TF

I'm initially trying this out with Typescript for a couple reasons:
- The brunt of TF CDK (and in fact, AWS CDK) seems to be written in typescript
- The documentation is very sparse, and it is hard to find how the resources are represented in code
- There are more examples and support in TS

Do:
```
# generate stuff
cdktf init --template=typescript

# export desired profile
export AWS_PROFILE=tf_multi_dev

# install deps
cdktf get
```

After you've installed the dependencies, you'll be able to view all the objects you can work with under `.gen/providers/aws`.

For example, if you want to see how to configure `AwsProvider`, view the `.gen/providers/aws/aws-provider.ts` file.

Now let's try deploying:
`cdktf deploy`

## Using s3 state

By default we are using the Terraform Cloud state. While it's possible you want to use Terraform's cloud offering, it's more likely that you just want to stuff your state into an s3 bucket.

Refer to `main.ts` to see that the `RemoteBackend` has been replaced with an S3 one.

## Hybrid CDK Terraform usage

Since the `synth` command just generates a JSON file, we can easily use this in conjunction with an existing Terraform setup. 

For example, I dropped the `cdk.tf.json` file directly from the CDK directory into our Terraform app root (`/terraform/application/cdk.tf.json`) and upon running `terraform plan` it will read configuration from that file and accordingly provision those resources.

Compared to vanilla Terraform, this introduces an additional synthesis step, but it's a nice feature that they can coexist if desired.

## Thoughts

- The CDK doesn't automatically keep all resources in scope (must explicitly pass variables as outputs)
- The diff report `cdktf diff` is not as detailed as the normal `terraform plan`
- You could use composition or inheritance in a much simpler way (compared to modules)
- Looping is much simpler (compared to HCL)
- It **should** be possible to follow similar conventions for both styles

## Trying Python

Make sure you have CDK TF installed: https://learn.hashicorp.com/tutorials/terraform/cdktf-install
Also install pipenv: https://pipenv.pypa.io/en/latest/ (`brew install pipenv`)

I wanted to try Python largely because Boto (https://docs.aws.amazon.com/pythonsdk/?id=docs_gateway) is in python and I think it may be useful to leverage the 2 in conjunction. 

Initialize:
`cdktf init --template="python"`



# Other thoughts

## Account Mgmt

- A general security/logs account might be a good idea to centralize things like CloudTrail & GuardDuty

## Other Tooling

At the moment, if you're using lambda or s3 it seems fairly prudent to utilize Terraform to bootstrap the infrastructure and then in its CodePipeline setup it will pull the application code and run the application's Terraform.

If using containers, it may be worth using Hashicorp Waypoint to abstract the complexity of ECS/Kubernetes.