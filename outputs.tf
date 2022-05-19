output "id" {
  description = "The ec2 instance id"
  value       = aws_instance.ec2.id
}

output "ip" {
  description = "The ec2 instance public ip address"
  value       = aws_instance.ec2.public_ip
}

output "az" {
  description = "the availability zone where the instance will be placed in"
  value       = random_shuffle.az.result[0]
}

output "subnet" {
  description = "the subnet id which will be used"
  value       = data.aws_subnet.public.id
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  sensitive   = false
}

output "ansible_command" {
  value       = "ansible-playbook ansible/playbook.yml"
  sensitive   = false
}
