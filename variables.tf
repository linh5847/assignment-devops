variable "additional_tags" {
  description = "Add extra tags"
  type        = map(string)
  default = {
    Project = "DevOps"
    Cost    = "IaC"
  }
}