# Notes

If you are starting from scratch, do:
- `waypoint init`
- Fill out the `waypoint.hcl` file accordingly
  - `service_port` must map to your app's hosted port within the container
- Run `waypoint init` again to actually initialize your file
- Run `waypoint up` to spin up the app


# Benefits

- Easy to spin up
- Gives HTTPS and DNS, so you don't have to worry about port collision
- Has a helpful UI, similar to k8s UI

# Docker/ECS or Kubernetes

- Appears that it can run against kubernetes regardless of location
- TODO: check if it can target ECS Fargate (appears so, but haven't tested)
- TODO: check how to run it against kub locally and in cloud


# Reference

- Docker Build configuration: https://www.waypointproject.io/plugins/docker#docker-builder
- ENV variables can be passed: https://www.waypointproject.io/docs/app-config