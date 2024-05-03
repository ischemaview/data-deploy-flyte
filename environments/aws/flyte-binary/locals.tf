locals {
  project     = "flyte-sandpit5"
  environment = "terraform" 
  name_prefix = "${local.project}-${local.environment}"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
}
