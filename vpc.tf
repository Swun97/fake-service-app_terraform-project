###################################################
# CUSTOMER PROFILE VPC
###################################################

resource "aws_vpc" "customer" {
  cidr_block           = var.customer_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "customer-profile-vpc"
  }
}

resource "aws_subnet" "customer_public" {
  vpc_id                  = aws_vpc.customer.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "cp-public-subnet"
  }
}

resource "aws_subnet" "customer_private" {
  vpc_id     = aws_vpc.customer.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "cp-private-subnet"
  }
}

resource "aws_internet_gateway" "customer" {
  vpc_id = aws_vpc.customer.id

  tags = {
    Name = "customer-igw"
  }
}

###################################################
# ACCOUNT VPC
###################################################

resource "aws_vpc" "account" {
  cidr_block           = var.account_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "account-vpc"
  }
}

resource "aws_subnet" "account_public" {
  vpc_id                  = aws_vpc.account.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "account-public-subnet"
  }
}

resource "aws_subnet" "account_private" {
  vpc_id     = aws_vpc.account.id
  cidr_block = "192.168.2.0/24"

  tags = {
    Name = "account-private-subnet"
  }
}

resource "aws_internet_gateway" "account" {
  vpc_id = aws_vpc.account.id

  tags = {
    Name = "account-igw"
  }
}

resource "aws_eip" "account_nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "account" {
  allocation_id = aws_eip.account_nat.id
  subnet_id     = aws_subnet.account_public.id

  depends_on = [aws_internet_gateway.account]
}

###################################################
# STATEMENT VPC
###################################################

resource "aws_vpc" "statement" {
  cidr_block           = var.statement_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "statement-vpc"
  }
}

resource "aws_subnet" "statement_public" {
  vpc_id                  = aws_vpc.statement.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "statement-public-subnet"
  }
}

resource "aws_subnet" "statement_private" {
  vpc_id     = aws_vpc.statement.id
  cidr_block = "172.16.2.0/24"

  tags = {
    Name = "statement-private-subnet"
  }
}

resource "aws_internet_gateway" "statement" {
  vpc_id = aws_vpc.statement.id

  tags = {
    Name = "statement-igw"
  }
}

resource "aws_eip" "statement_nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "statement" {
  allocation_id = aws_eip.statement_nat.id
  subnet_id     = aws_subnet.statement_public.id

  depends_on = [aws_internet_gateway.statement]
}

###################################################
# SECURITY GROUPS
###################################################

resource "aws_security_group" "customer" {
  name   = "customer-sg"
  vpc_id = aws_vpc.customer.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["2.49.136.161/32"]
  }

  ingress {
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow response traffic from account-vpc
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.account_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "customer-sg"
  }
}

resource "aws_security_group" "account" {
  name   = "account-sg"
  vpc_id = aws_vpc.account.id

  # Accept from customer-vpc
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.customer_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.customer_vpc_cidr]
  }

  # Accept response traffic from statement-vpc
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.statement_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "account-sg"
  }
}

resource "aws_security_group" "statement" {
  name   = "statement-sg"
  vpc_id = aws_vpc.statement.id

  # Accept from account-vpc
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.account_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.account_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "statement-sg"
  }
}

###################################################
# VPC PEERING
###################################################

resource "aws_vpc_peering_connection" "customer_account" {
  vpc_id      = aws_vpc.customer.id
  peer_vpc_id = aws_vpc.account.id
  auto_accept = true

  tags = {
    Name = "customer-account-peer"
  }
}

resource "aws_vpc_peering_connection" "account_statement" {
  vpc_id      = aws_vpc.account.id
  peer_vpc_id = aws_vpc.statement.id
  auto_accept = true

  tags = {
    Name = "account-statement-peer"
  }
}

###################################################
# ROUTE TABLES
###################################################

resource "aws_route_table" "customer_public" {
  vpc_id = aws_vpc.customer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.customer.id
  }

  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.customer_account.id
  }
}

resource "aws_route_table_association" "customer_public" {
  subnet_id      = aws_subnet.customer_public.id
  route_table_id = aws_route_table.customer_public.id
}

resource "aws_route_table" "account_public" {
  vpc_id = aws_vpc.account.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.account.id
  }

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.customer_account.id
  }
}

resource "aws_route_table" "account_private" {
  vpc_id = aws_vpc.account.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.account.id
  }

  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.account_statement.id
  }

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.customer_account.id
  }
}

resource "aws_route_table_association" "account_public" {
  subnet_id      = aws_subnet.account_public.id
  route_table_id = aws_route_table.account_public.id
}

resource "aws_route_table_association" "account_private" {
  subnet_id      = aws_subnet.account_private.id
  route_table_id = aws_route_table.account_private.id
}

resource "aws_route_table" "statement_public" {
  vpc_id = aws_vpc.statement.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.statement.id
  }
}

resource "aws_route_table" "statement_private" {
  vpc_id = aws_vpc.statement.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.statement.id
  }

  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.account_statement.id
  }
}

resource "aws_route_table_association" "statement_public" {
  subnet_id      = aws_subnet.statement_public.id
  route_table_id = aws_route_table.statement_public.id
}

resource "aws_route_table_association" "statement_private" {
  subnet_id      = aws_subnet.statement_private.id
  route_table_id = aws_route_table.statement_private.id
}
