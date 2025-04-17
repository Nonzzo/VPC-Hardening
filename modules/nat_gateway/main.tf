# Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}


# NAT Gateway in public subnet
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "nat-gateway"
  }
}

# Private route table (with NAT)
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags = {
    Name = "private-route-table"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

# Associate private subnets with NAT route table
resource "aws_route_table_association" "private_subnets" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id

  lifecycle {
    create_before_destroy = true
  }
}
