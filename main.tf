resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }

}    

resource "aws_default_security_groupd" "default" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "default_security_group"
  }
  
}


resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.public_subnet_1a_cidr}"
  availability_zone = var.zone1
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_1a"
  }
  
}



resource "aws_subnet" "subnet2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.public_subnet_1b_cidr}"
  availability_zone = var.zone2
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_1b"
  }
  
}


resource "aws_subnet" "subnet3" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.private_subnet_1a_cidr}"
  availability_zone = var.zone1

  tags = {
    Name = "private_subnet_1a"
    kubernetes.io/role/internal-elb = "1"
    kubernetes.io/cluster/var.eks_cluster_name = "owned"

  }
  
}


resource "aws_subnet" "subnet4" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.private_subnet_1b_cidr}"
  availability_zone = var.zone2
  tags = {
    Name = "private_subnet_1b"
    kubernetes.io/role/internal-elb = "1"
    kubernetes.io/cluster/var.eks_cluster_name = "owned"
   
  }
  
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "main_internet_gateway"
  }
  
}


resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "public_route_table"
  }
  
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}


resource "aws_route_table_association" "public_subnet_1a_association" {
  subnet_id = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
  
}

resource "aws_route_table_association" "public_subnet_1b_association" {
  subnet_id = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
  
}


resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.main.id}"

route = {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

  tags = {
    Name = "private_route_table"
  }

}



resource "aws_route_table_association" "private_route_table_association1" {
  subnet_id = "${aws_subnet.subnet3.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
  
}


resource "aws_route_table_association" "private_route_table_association2" {
  subnet_id = "${aws_subnet.subnet4.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
  
}


resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id = "${aws_subnet.subnet1.id}"
  tags = {
    Name = "main_nat_gateway"
  }
   depends_on = [ aws_internet_gateway ] 
}