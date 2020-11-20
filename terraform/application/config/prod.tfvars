profile = "tf_multi_prod"
deploy_env = "prod"
account_number = "017016463659"
# Lower is for prior environment, i.e. "dev"
lower_environment_account_number = "813871934424"
# If no higher, omit or empty
// higher_environment_account_number = ""

# No need to notify an upstream environment, but maybe email dev team
# TODO: See if we can webhook to Teams or something
// build_success_topics = []
// prod won't promote anywhere
// build_promotion_sns_topic_arn = ""