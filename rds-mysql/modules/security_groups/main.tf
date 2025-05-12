resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg"
  description = "Security group for MySQL RDS"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "ingress_from_cidr" {

  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = [var.vpc_cidr]
}
