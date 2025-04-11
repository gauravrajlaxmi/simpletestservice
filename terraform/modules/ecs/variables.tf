variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "target_group_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}
