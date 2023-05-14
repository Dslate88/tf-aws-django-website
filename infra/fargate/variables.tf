variable "deploy_ecs_service" {
  type        = bool
  description = "Deploy ECS Service"
  default     = true
}

# export TF_VAR_alert_phone_number="+1<areacode>-<rest>"
# set via .bash_profile
variable "alert_phone_number" {
  description = "The phone number to send SMS alerts"
  type        = string
}
