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
  
  
# Other good ideas

- A general security/logs account might be a good idea to centralize things like CloudTrail & GuardDuty
  

# Running the app locally

`./gradlew bootRun` should work for starting the app up. Then navigate to http://localhost:8090 (or whatever port you configure) and it should respond

# Building image

`docker build .` from root _(may change once I build useful TF)_

# Run image

`docker run -p 9090:80 67ebb619f0ff` (replace SHA with your build hash)

# Test via docker

Visit `http://localhost:9090`