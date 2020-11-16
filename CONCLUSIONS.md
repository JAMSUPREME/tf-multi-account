
# Tooling

- Terraform
- _(maybe Waypoint since we need containers)_

# Conventions

- As coded. Will clarify
- Also add bash helpers

# Code Promotion

- **DEV** picks up code changes automatically and builds new image
- `terraform apply` is run to update infrastructure and task definition
- appspec `AfterAllowTraffic` can be used to trigger e2e tests **lambda** once the deploy has succeeded and can receive traffic
- If tests pass, the lambda can send to SNS or trigger a lambda in **QA** to set off the build process for QA
- QA goes through the same steps as dev and **optionally** promotes to prod (we could potentially introduce a manual gating process if desired)

_Note:_ This may vary slightly if we use Waypoint/EKS

# Resource sharing

- Individual resources will go into the respective application repo
- Shared resources will go into a `shared-infrastructure` repo
- Shared resource identifiers can be passed into the `.tfvars` file and then accessed with `data` tags

# How will pipelines modify their own infrastructure?

- Each app will apply terraform on itself (excluding the initial setup) to ensure there is no drift

# Best Practices for multiple developers

This is a brief guide on how to use distinct workspaces with Terraform while multiple people modify the same environment.

## How to do it

- Copy `/terraform/config/backend-standalone.conf.example` and rename it to `backend-standalone-<NAME>.conf` where `<NAME>` is your name, e.g. `backend-standalone-justin.conf`
- Uncomment the values in `backend-standalone-<NAME>.conf` and set a unique `key` value (your name, for example)
- Run `terraform init -backend-config=config/backend-dev-standalone.conf`
  - When asked to copy state, answer `yes`
- Add/Import/etc. your new resources and run `terraform apply` accordingly.

Here's an example:
```
# file structure
/terraform
  /config
    backend-dev.conf
    backend-dev-justin.conf


# file contents
# backend-dev-justin.conf

# Make sure you are using the correct bucket for your env (dev, prod, etc.)
bucket = "dev-dot-sdc-regional-lambda-bucket-911061262852-us-east-1"
profile = "sdc"
# Change the following key to be a unique identifier for you (e.g. name)
key = "sdc-dot-waze-pipeline/terraform/terraform-justin.tfstate"
```

Once your infrastructure is stable, you should do the following:

- Switch back to the normal dev state: `terraform init -backend-config=config/backend-dev.conf`
  - When asked to copy state, ANSWER `NO` !!!!! _(It will not be good if you overwrite dev's state)_
- Use `terraform import` to pull in the resources you created in your custom state


## Shared resources

For certain shared resources, it won't be possible to create/modify them in isolation. If possible, you should update the resource in a standalone branch and merge into master as soon as possible so everyone can pull the change into their own branch.

## Unique environments

You may be doing a substantial rewrite to existing infrastructure, in which case copying state simply won't be useful since you will be modifying several existing resources.

If possible, in this scenario you should create an entirely new set of infrastructure that is distinct from the current stack.

For example, if you need to make substantial changes to `dev`, you would create a standalone `dev-justin` set of infrastructure that has its own state and entirely its own resources. You can then create/modify/destroy anything in this environment without affecting others.

Things to keep in mind with this approach:
- All resources must be uniquely named
- The new stack should not cause any side effects in the normal working environment (e.g. `dev`)
- If possible, there should be minimal or no manual provisioning involved to avoid blunders or botched cleanup
- You must remember to destroy this environment after completing your work