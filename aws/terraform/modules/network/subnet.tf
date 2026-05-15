resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs.public[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                     = "public-${var.azs[count.index]}-${local.name_base}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.app[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                              = "app-${var.azs[count.index]}-${local.name_base}"
    Tier                              = "app"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "data" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.data[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "data-${var.azs[count.index]}-${local.name_base}"
    Tier = "data"
  }
}
