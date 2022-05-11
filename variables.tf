variable "aws_region" {
	default = "eu-west-1"
}

variable "vpc_cidr" {
	default = "10.160.102.0/23"
}

variable "panorama" {
	default = false
}

variable "coid" {
	default = "PROT"
}

variable "il_external" {
	default = "207.223.34.132"
}

variable "fl_external" {
	default = "62.103.97.241"
}

variable "subnets_cidr_public" {
	type = list
	default = ["10.160.102.128/25","10.160.103.128/25"]
}

variable "subnets_cidr_private" {
	default = ["10.160.102.0/25","10.160.103.0/25"]
}



variable "azs" {
	type = list
	default = ["eu-west-1a", "eu-west-1b"]
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "rules_inbound_private_sg" {
  default = [
    {
      port = 0
      proto = "-1"
      cidr_block = ["10.159.94.240/29","10.189.0.0/23"]
    }
    ]
}

variable "rules_outbound_private_sg" {
  default = [
    {
      port = 0
      proto = "-1"
      cidr_block = ["10.159.94.240/29","10.189.0.0/23"]
    }
    ]
}

variable "rules_inbound_public_sg" {
  default = [
    {
      port = 0
      proto = "-1"
      cidr_block = ["10.159.94.240/29","10.189.0.0/23"]
    }
    ]
}

variable "rules_outbound_public_sg" {
  default = [
	  {
      port = 443
      proto = "tcp"
      cidr_block = ["0.0.0.0/0"]
    },
	  {
      port = 80
      proto = "tcp"
      cidr_block = ["0.0.0.0/0"]
    },
	  {
      port = 53
      proto = "tcp"
      cidr_block = ["0.0.0.0/0"]
    },
	{
      port = 53
      proto = "udp"
      cidr_block = ["0.0.0.0/0"]
    },
	  {
      port = 123
      proto = "tcp"
      cidr_block = ["0.0.0.0/0"]
    },
	  {
      port = 123
      proto = "udp"
      cidr_block = ["0.0.0.0/0"]
    },
    ]
}

variable "rules_inbound_sg_pano" {
  default = [
    {
      port = 443
      proto = "tcp"
      cidr_block = ["192.168.0.0/16","10.159.94.0/23"]
    },
    {
      port = 80
      proto = "tcp"
      cidr_block = ["192.168.0.0/16","10.159.94.0/23"]
    },
    {
      port = 22
      proto = "tcp"
      cidr_block = ["192.168.0.0/16","10.159.94.0/23"]
    }
    ]
}
variable "instance_type_panorama" {
  description = "Instance Size - This is the default/standard used on our other deployments - 16-32"
  type        = string
  default     = "c5.4xlarge"
}

variable "ssh_key_name" {
  description = "AWS EC2 key pair name."
  type        = string
  default = "ack"
}

variable "private_ip_address" {
  description = "If provided, associates a private IP address to the Panorama instance."
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "If true, create an Elastic IP address for Panorama."
  type        = bool
  default     = false
}
