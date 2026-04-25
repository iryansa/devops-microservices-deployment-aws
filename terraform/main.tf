provider "aws" {
  region = "us-east-1" 
}

# Networking & Security
resource "aws_vpc" "main" { 
  cidr_block = "10.0.0.0/16" 
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" { 
  vpc_id = aws_vpc.main.id 
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route { 
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.main.id
  name   = "k8s_cluster_sg"

  # SSH
  ingress { 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # HTTP/HTTPS
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  ingress { 
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # Kubernetes NodePorts (For frontend, backend, ArgoCD)
  ingress { 
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  egress { 
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# AWS Provisioning (EC2)
resource "aws_instance" "cluster_node" {
  ami                    = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (us-east-1)
  instance_type          = "t3.medium"
  key_name               = "project3-key" 
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  subnet_id              = aws_subnet.public.id

  tags = { 
    Name = "K8s-Microservices-Node" 
  }
}

output "instance_public_ip" {
  value = aws_instance.cluster_node.public_ip
}