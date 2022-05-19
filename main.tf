data "aws_caller_identity" "current" {}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "local_file" "public_key" {
  filename = "/Users/ruan/.ssh/id_rsa.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = data.local_file.public_key.content
}

resource "aws_ebs_volume" "sdf" {
  availability_zone = random_shuffle.az.result[0]
  encrypted         = true
  size              = var.ebs_sdf_size_in_gb
  tags = {
    Name        = local.namespace
    Environment = var.environment_name
    ManagedBy   = var.tag_managedby
    Owner       = var.tag_owner
  }

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.sdf.id
  instance_id = aws_instance.ec2.id
  skip_destroy = true
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.latest_ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.public.id
  key_name                    = aws_key_pair.deployer.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  
  lifecycle {
    ignore_changes            = [subnet_id, ami]
  }

  user_data = file("${path.module}/userdata/bootstrap.sh")
  
  root_block_device {
      volume_type           = "gp2"
      volume_size           = var.ebs_root_size_in_gb
      encrypted             = true
      delete_on_termination = true
  }

  tags = {
    Name        = local.namespace
    Environment = var.environment_name
    ManagedBy   = var.tag_managedby
    Owner       = var.tag_owner
  }

}
