provider "aws" {
  region = "eu-west-1"
  access_key = "XXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXX"
}

# Create VPC, Subnet, Security Group, and ELB
resource "aws_vpc" "Altschool" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

   tags = {
    Name = "Altschool"
  }
  
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.Altschool.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public_subnet"
  }
}

# Create private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.Altschool.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b" 
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "Alt_gate" {
  vpc_id = aws_vpc.Altschool.id

  tags = {
    Name = "Alt_gate"
  }  
}

resource "aws_security_group" "Alt_sg" {
  vpc_id = aws_vpc.Altschool.id
}

resource "aws_security_group_rule" "Alt_sg_ingress" {
  security_group_id = aws_security_group.Alt_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_elb" "Altschool_elb" {
  name               = "Altschool-elb"
  #availability_zones = ["eu-west-1a"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  security_groups    = [aws_security_group.Alt_sg.id] 
  instances = aws_instance.Altschool_instances[*].id
  subnets = [aws_subnet.public_subnet.id]
  
}

# Create EC2 instances
resource "aws_instance" "Altschool_instances" {
  count         = 3
  ami           = "ami-0905a3c97561e0b69"  
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Alt_sg.id] 
  key_name = "ope1-key"
  subnet_id     = aws_subnet.public_subnet.id
    
  tags = {
    Name = "Altschool-instance-${count.index + 1}"
  }

}

output "public_ips" {
  value = aws_instance.Altschool_instances[*].public_ip
  description = "Public IP addresses of the instances"
}

# Save the public IPs to a file after apply
resource "null_resource" "save_public_ips" {
  provisioner "local-exec" {
    command = "echo '${join("\n", aws_instance.Altschool_instances[*].public_ip)}' > host-inventory"
  }

  depends_on = [aws_instance.Altschool_instances]
}
