# The name of your project. A project typically maps 1:1 to a VCS repository.
# This name must be unique for your Waypoint server. If you're running in
# local mode, this must be unique to your machine.
project = "tf-multi-account"

# Labels can be specified for organizational purposes.
# labels = { "foo" = "bar" }

#
# TODO: Figure out if we could alter this file in terraform so that we add a registry
# TODO: Figure out how we could vary the deploy options for local/remote?
# NOTE: It appears waypoint isn't currently designed such that one file would apply to dev and prod,
#   so it would probably mean minor duplication
#

app "web" {
    # Build specifies how an application should be deployed. In this case,
    # we'll build using a Dockerfile and keeping it in a local registry.
    build {
        use "docker" {
            dockerfile = "Dockerfile"
        }
        
        # Uncomment below to use a remote docker registry to push your built images.
        #
        # registry {
        #   use "docker" {
        #     image = "registry.example.com/image"
        #     tag   = "latest"
        #   }
        # }

    }

    # Deploy to Docker
    deploy {
        use "docker" {
            service_port=80
        }
    }
}
