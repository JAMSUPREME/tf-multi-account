
# Local options

There are a handful of options for running k8s locally: https://kubernetes.io/docs/tasks/tools/

There are also other tools like skaffold for making the development cycle easier.

# Do we need it?

In this particular scenario, I would compare the following combinations:

- docker-compose (local setup), terraform, ECS Fargate
- k8s + minikube (local setup), terraform, EKS

Benefits:
- Kubernetes offers a lot of features
- More elaborate support for various types of clustering and deployment
- Good handling for resource management and caps

Drawbacks:
- Kubernetes is fairly complicated
- Kubernetes (in my opinion) isn't particularly valuable for small-scale setups with no intention of federation or additional oversight
- Additional local tooling (k8s, minikube) to be set up on top of docker
- Additional learning for everyone to understand k8s basics
- Base templates
- Doesn't solve our problem of sharing configuration from local-to-prod since databases won't generally go into the cluster, and we also introduce some blurring of tooling for how we provision infrastructure (i.e. k8s dictating load balancer)