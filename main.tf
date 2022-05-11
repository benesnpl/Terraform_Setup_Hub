provider "aws" {
  region = var.aws_region
}


# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block       					         = "10.160.102.0/23"
  instance_tenancy 					         = var.instance_tenancy
  enable_dns_hostnames             	= var.enable_dns_hostnames
  enable_dns_support              	= var.enable_dns_support
  tags = {
    Name = join("", [var.coid, "-VPC"])
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = join("", [var.coid, "-TGW"])
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Private SG"
  vpc_id      = aws_vpc.main_vpc.id

  dynamic "ingress" {
    for_each = var.rules_inbound_private_sg
    content {
      from_port = ingress.value["port"]
      to_port = ingress.value["port"]
      protocol = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr_block"]
    }
  }
  dynamic "egress" {
    for_each = var.rules_outbound_private_sg
    content {
      from_port = egress.value["port"]
      to_port = egress.value["port"]
      protocol = egress.value["proto"]
      cidr_blocks = egress.value["cidr_block"]
    }
  }
  tags = {
    Name = join("", [var.coid, "-Private-sg"])
  }
}


resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "public SG"
  vpc_id      = aws_vpc.main_vpc.id

  dynamic "ingress" {
    for_each = var.rules_inbound_public_sg
    content {
      from_port = ingress.value["port"]
      to_port = ingress.value["port"]
      protocol = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr_block"]
    }
  }
  dynamic "egress" {
    for_each = var.rules_outbound_public_sg
    content {
      from_port = egress.value["port"]
      to_port = egress.value["port"]
      protocol = egress.value["proto"]
      cidr_blocks = egress.value["cidr_block"]
    }
  }
  tags = {
    Name = join("", [var.coid, "-Public-sg"])
  }
}

resource "aws_subnet" "public" {
  count = length(var.subnets_cidr_public)
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = element(var.subnets_cidr_public,count.index)
  availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = join("",[var.coid,"Subnet-Public-${count.index+1}"])
  }
}

resource "aws_subnet" "private" {
  count = length(var.subnets_cidr_private)
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = element(var.subnets_cidr_private,count.index)
  availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = join("",[var.coid,"Subnet-Private-${count.index+1}"])
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = join("", [var.coid, "-Public-rt"])
  }
}
 

resource "aws_route_table_association" "a" {
  count = length(var.subnets_cidr_public)
  subnet_id      = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.public_rt.id
}

  
resource "aws_route_table_association" "b" {
  count = length(var.subnets_cidr_private)
  subnet_id      = element(aws_subnet.private.*.id,count.index)
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat" {
  vpc              = true
}



resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = join("", [var.coid, "-NGW"])
  }

  depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_ec2_transit_gateway" "main_tgw" {
  description = "TGW"
  auto_accept_shared_attachments = "enable"
  tags = {
   Name = join("", [var.coid, "-TGW"])
  }
}


resource "aws_ec2_transit_gateway_vpc_attachment" "example" {
  depends_on = [aws_subnet.public,aws_subnet.private]
  subnet_ids         = "${aws_subnet.private.*.id}"
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = aws_vpc.main_vpc.id
  appliance_mode_support = "enable"
}


resource "aws_customer_gateway" "oakbrook" {
  bgp_asn    = 65000
  ip_address = var.il_external
  type       = "ipsec.1"

  tags = {
    Name = join("", [var.coid, "-Oakbrook-CGW"])
  }
}

resource "aws_customer_gateway" "miami" {
  bgp_asn    = 65000
  ip_address = var.fl_external
  type       = "ipsec.1"

  tags = {
    Name = join("", [var.coid, "-Miami-CGW"])
  }
}

resource "aws_vpn_connection" "Oakbrook" {
  transit_gateway_id  = aws_ec2_transit_gateway.main_tgw.id
  customer_gateway_id = aws_customer_gateway.oakbrook.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = join("", [var.coid, "-Oakbrook-ipsec"])
  }
  
}

resource "aws_vpn_connection" "Miami" {
  transit_gateway_id  = aws_ec2_transit_gateway.main_tgw.id
  customer_gateway_id = aws_customer_gateway.miami.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = join("", [var.coid, "-Oakbrook-ipsec"])
  }
}


data "aws_ec2_transit_gateway_vpn_attachment" "oak_attach" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpn_connection_id  = aws_vpn_connection.Oakbrook.id
}

data "aws_ec2_transit_gateway_vpn_attachment" "miami_attach" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpn_connection_id  = aws_vpn_connection.Miami.id
}

resource "aws_ec2_transit_gateway_route" "oak_vpn" {
  destination_cidr_block         = "10.159.94.0/23"
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.oak_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main_tgw.association_default_route_table_id
  blackhole                      = false
}

resource "aws_ec2_transit_gateway_route" "mia_vpn" {
  destination_cidr_block         = "10.189.0.0/23"
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.miami_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main_tgw.association_default_route_table_id
  blackhole                      = false
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  depends_on = [aws_internet_gateway.main_igw,aws_ec2_transit_gateway.main_tgw,aws_nat_gateway.main_nat,aws_ec2_transit_gateway_route.mia_vpn,aws_ec2_transit_gateway_route.oak_vpn,aws_vpn_connection.Oakbrook,aws_vpn_connection.Miami]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main_nat.id
  }
  
   route {
    cidr_block = "192.168.0.0/16"
    gateway_id = aws_ec2_transit_gateway.main_tgw.id
  }
  
   route {
    cidr_block = "172.16.0.0/12"
    gateway_id = aws_ec2_transit_gateway.main_tgw.id
  }
  
   route {
    cidr_block = "10.0.0.0/8"
    gateway_id = aws_ec2_transit_gateway.main_tgw.id
  }
  
  tags = {
    Name = join("", [var.coid, "-Private-rt"])
  }
} 

data "aws_ami" "panorama_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Panorama-AWS-*"]
  }
} 

resource "aws_security_group" "panorama_SG" {
  name        = "panorama_sg"
  description = "Basic communication for Panorama"
  vpc_id      = aws_vpc.main_vpc.id

  dynamic "ingress" {
    for_each = var.rules_inbound_sg_pano
    content {
      from_port = ingress.value["port"]
      to_port = ingress.value["port"]
      protocol = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr_block"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = join("", [var.coid, "-Panorama-sg"])
  }
}


resource "aws_instance" "Panorama" {
  ami                                  = data.aws_ami.panorama_ami.id
  count                                = var.panorama ? 1 : 0
  instance_type                        = var.instance_type_panorama
  availability_zone                    = var.azs[1]
  key_name                             = var.ssh_key_name
  private_ip                           = var.private_ip_address
  subnet_id                            = aws_subnet.private[1].id
  vpc_security_group_ids               = [aws_security_group.panorama_SG.id]
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  monitoring                           = false
  tags = {
    Name = join("", [var.coid, "PAP00"])
  }

  root_block_device {
    delete_on_termination = true
  }

}
