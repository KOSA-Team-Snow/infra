resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = {
    Name = "eip-nat-${var.azs[count.index]}-${local.name_base}"
    Mode = var.dr_active ? "dr-active" : "steady"
  }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-${var.azs[count.index]}-${local.name_base}"
    Mode = var.dr_active ? "dr-active" : "steady"
  }

  depends_on = [aws_internet_gateway.this]
}
