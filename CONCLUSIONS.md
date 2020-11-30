
# Tooling

- Terraform
- _(maybe Waypoint since we need containers)_

# Conventions

- As coded. Will clarify
- Also add bash helpers
- Template files will have `.tpl` prepended to their file extension. For example, `file.tpl.json` or `file.tpl.xml`
- Place `locals` applicable to a single file at the top of the file
- Place global `locals` at the bottom of the `input_variables.tf` file
- TODO: naming conventions for resources
- TODO: linting?

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
bucket = "dev-bucket"
profile = "sdc"
# Change the following key to be a unique identifier for you (e.g. name)
key = "terraform-justin.tfstate"
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

# Local development vs. Remote

- If using docker-compose & ECS, the two configs will necessarily drift
- If using Kubernetes, it should be possible to run them locally and in the cloud with little to no drift 
- Regardless of tooling, there would likely be drift anyway given that we may use provider-specific tooling like RDS or Lambda. These concepts don't map directly to Waypoint, Kubernetes, etc. and therefore it's necessary to have something distinct for local development.

## Local options

docker-compose in **each application** that knows its dependencies
- Works for DB, cache, etc.
- Works **with assumptions/conventions** when doing multiple app development
- Dependencies are explicit during local development (as well as infrastructure)
- Some potential for redundancy when all apps intend to share a DB or cache locally

docker-compose in a **standalone** "local-development" repo
- One large docker-compose, so only one place to look for updates
- Can get unwieldy or tedious if you only care about one application
- Has **assumptions** that all repos will be checkedd out

**How will shared resources work?** - As much as possible, I would suggest we avoid sharing resources across applications if they introduce coupling. However, I think it would be possible to set up shared volumes or services if that was necessary.

For example, 
- If 2 apps logged to the same s3 bucket, that is OK and isn't tight coupling.
- If 2 apps read/write from the same database tables, that might be a sign of tight coupling or bad domain separation.


## Recommendations

Create a docker-compose for each application. Reasons are as follows:
- No need to worry about bugs in other apps breaking your own (if app has no dependencies)
- If/when there is a dependency on another app, it is explicitly documented in the docker-compose
- No need for any additional tooling aside from docker-compose (which is bundled with docker)

# Waypoint

Noted benefits/drawbacks of Waypoint in WAYPOINT.md

# Kubernetes

Noted benefits/drawbacks of Kubernetes in KUBERNETES.md