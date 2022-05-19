variable "aws_region" {
  default  = "af-south-1"
}

variable "team_name" {
  type    = string
  default = "devops"
}

variable "environment_name" {
   type    = string
   default = "dev"
}

variable "project_name" {
   type    = string
   default = "ephemeral"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "ebs_sdf_size_in_gb" {
  type    = number
  default = 20
}

variable "ebs_root_size_in_gb" {
  type    = number
  default = 20
}

variable "tags" {
    type = map(string)
    default = {
        true          = "Enabled"
        false         = "Disabled"
    }
}

variable "tag_purpose" {
   type    = string
   default = "poc"
}

variable "tag_owner" {
   type    = string
   default = "devops"
}

variable "tag_managedby" {
   type    = string
   default = "terraform"
}

variable "ssh_user" {
   default = "ubuntu"
}

variable "ssh_key_file" {
    type    = string
    default = "~/.ssh/id_rsa"
}

variable "ansible_user" {
    description = "the user that ansible will use to ssh"
    default     = "ubuntu"
}

