resource "aws_instance" "customer_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.fake_service_app.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.customer_public.id
  vpc_security_group_ids      = [aws_security_group.customer.id]

  tags = {
    Name = "customer-app-instance"
  }
}

resource "aws_instance" "account_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.fake_service_app.key_name
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.account_private.id
  vpc_security_group_ids      = [aws_security_group.account.id]

  tags = {
    Name = "account-app-instance"
  }
}

resource "aws_instance" "statement_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.fake_service_app.key_name
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.statement_private.id
  vpc_security_group_ids      = [aws_security_group.statement.id]

  tags = {
    Name = "statement-app-instance"
  }
}
