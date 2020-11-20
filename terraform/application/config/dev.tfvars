profile="tf_multi_dev"
deploy_env = "dev"
account_number = "813871934424"
# If no lower environment, maybe omit this or keep empty
lower_environment_account_number = ""
# Higher is for the next environment, i.e. "prod"
// Might not need this if we just use SNS arn
// higher_environment_account_number = "017016463659"

# On initial bootstrapping, the next env's topic won't exist,
# But I think that's OK
# This might later be an array, but for now just one topic to promote to
// build_success_topics = [

// ]
// build_promotion_sns_topic_arn = "arn:aws:sns:us-east-1:017016463659:app_build_trigger"

build_promotion_event_bus_arn = "arn:aws:events:us-east-1:017016463659:event-bus/default"