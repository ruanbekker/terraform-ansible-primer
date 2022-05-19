resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.tmpl", {
    ansible_user  = var.ansible_user,
    instance_name = local.namespace,
    instance_ip   = aws_instance.ec2.public_ip,
    instance_id   = aws_instance.ec2.id,
    ssh_key_file  = var.ssh_key_file,
  }
 )
 filename         = "${path.module}/ansible/inventory"
}