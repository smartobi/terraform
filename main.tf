# provisioning VPC for the development enviroment.
resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

# provisioning public subnet
resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id # vpc id reffrence
  cidr_block              = "10.100.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "dev-public"
  }
}
# provisioning internete gateway
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}
 # provisioning route table 
resource "aws_route_table" "mtc-public-rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mtc_internet_gateway.id

  }

  tags = {
    Name = "dev-route-table"
  }
}
# provisioning route table association to a specific subnet 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc-public-rt.id


}

# provisioning security_group named mtc-sg for both ingress and egress
resource "aws_security_group" "mtc-sg" {
  name        = "dev-sg"
  description = "allow all port and all source to access the enviroment for now"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["102.89.23.206/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg"
  }
}

# provisioning keypair named mtckey
resource "aws_key_pair" "mtc_auth" {
  key_name = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
  tags = {
    Name = "dev-key-linux_only"
  }
}
# provisioning keypair named mtckey01
resource "aws_key_pair" "mtc_auth01" {
  key_name = "mtckey01"
  public_key = file("~/.ssh/mtckey01.pub")
   tags = {
    Name = "dev-key-linux_and_windows"
  }
}
# provisioning a ubuntu Linux machine 
 resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.server_ami.id
  key_name = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc-sg.id]
  subnet_id = aws_subnet.mtc_public_subnet.id
  user_data = file("userdata.tpl")
   root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev_node"

  }
  # provisioning for remote login to the machine
  provisioner "local-exec" {
  command = templatefile("${var.host_os}-ssh-config.tpl", {
    hostname = self.public_ip,
    user = "ubuntu",
    identityfile = "~/.ssh/mtckey"
  })
  interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"] 

}

 
 }

