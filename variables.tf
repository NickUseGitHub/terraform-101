variable "credentials" {
  type        = string
  description = "Location of the credentials keyfile."
}

variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

variable "region" {
  type        = string
  description = "The region to host the cluster in."
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in."
}

variable "name" {
  type        = string
  description = "The name of the cluster."
}

variable "general_purpose_machine_type" {
  type        = string
  description = "machine type"
}

variable "general_purpose_min_node_count" {
  type        = number
}

variable "general_purpose_max_node_count" {
  type        = number
}

