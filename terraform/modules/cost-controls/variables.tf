variable "project_name" {
  description = "Project name used for the budget"
  type        = string
}

variable "environment" {
  description = "Environment used as the AWS cost allocation tag filter"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Approved monthly cost alert threshold in USD; zero disables this budget"
  type        = number
}

variable "budget_alert_email" {
  description = "Email address for budget notifications"
  type        = string
}

variable "tags" {
  description = "Tags applied to the AWS Budget"
  type        = map(string)
  default     = {}
}
