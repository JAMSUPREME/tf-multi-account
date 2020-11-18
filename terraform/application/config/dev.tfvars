profile="tf_multi_dev"
deploy_env = "dev"
account_number = "813871934424"
# If no lower environment, maybe omit this or keep empty
lower_environment_account_number = ""
# Higher is for the next environment, i.e. "prod"
higher_environment_account_number = "017016463659"

# On initial bootstrapping, the next env's topic won't exist,
# But I think that's OK
build_success_topics = []