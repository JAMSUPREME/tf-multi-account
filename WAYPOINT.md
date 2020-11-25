# Notes

If you are starting from scratch, do:
- `waypoint init`
- Fill out the `waypoint.hcl` file accordingly
  - `service_port` must map to your app's hosted port within the container
- Run `waypoint init` again to actually initialize your file
- Run `waypoint up` to spin up the app

# Concerns

I have a few reservations about Waypoint:
- Currently investigating `Dockerfile` support
- Limited documentation/features. Most behavior is intentionally opaque.
- Limited guidance on big setups (e.g. multiple dependent applications, or even an app with a DB)
- The HTTPS support is via public DNS, and doesn't support non-HTTPS protocols (like db connections)

# Benefits

- Easy to spin up
- Gives HTTPS and DNS, so you don't have to worry about port collision
- Has a helpful UI, similar to k8s UI
- It can run against ECS/Fargate or Kubernetes

Good features:
- Can set base image or provide dockerfile: https://www.waypointproject.io/plugins/docker#docker-builder
- ENV variables can be passed: https://www.waypointproject.io/docs/app-config
- Minimal setup (downside is that there aren't many touchpoints for customization)

# Concluding thoughts on Waypoint

- Might be viable for local development, but has drawbacks for dependencies (e.g. database)
- Wouldn't recommend trying it out for a production app since we might hit issues with customizations that we cannot do
- It requires a long-lived waypoint server, which is also a drawback

# Reference

- Docker Build configuration: https://www.waypointproject.io/plugins/docker#docker-builder
- ENV variables can be passed: https://www.waypointproject.io/docs/app-config