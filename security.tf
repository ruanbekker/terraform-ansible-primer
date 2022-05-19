resource "aws_security_group" "ec2" {
    name = "${local.namespace}-ec2-sg"
    description = "${local.namespace}-ec2-sg"
    vpc_id = data.aws_vpc.default.id

    tags = {
        Name        = "${local.namespace}-ec2-sg"
        Environment = var.environment_name
        Team        = var.team_name
        ManagedBy   = var.tag_managedby
        Owner       = var.tag_owner
    }
}

resource "aws_security_group_rule" "internal" {
    description       = "allows ssh traffic"
    security_group_id = aws_security_group.ec2.id
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress" {
    description       = "allows egress"
    security_group_id = aws_security_group.ec2.id
    type              = "egress"
    protocol          = "-1"
    from_port         = 0
    to_port           = 0
    cidr_blocks       = ["0.0.0.0/0"]
}