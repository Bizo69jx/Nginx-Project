# Create a VPC(Nginx)
resource "aws_vpc" "nginx_vpc" {
  cidr_block = var.cidr_vpc
  tags = var.tags_vpc
}

# Create an igw and attach to vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.nginx_vpc.id

  tags = var.tags_igw
}

# Create sub1
resource "aws_subnet" "sub-1" {
  vpc_id                  = aws_vpc.nginx_vpc.id
  cidr_block              = var.cidr_subnets[0]  # Replace with your desired subnet CIDR block
  availability_zone       = var.az[0]  # Replace with your desired availability zone
#   map_public_ip_on_launch = true

  tags = var.tags_sub1
}

# Create RT
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.nginx_vpc.id

  route {
    cidr_block = var.cidr_rt
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = var.tags_rt
}


# Create RT Association for sub1
resource "aws_route_table_association" "pubass1" {
  subnet_id = aws_subnet.sub-1.id
  route_table_id = aws_route_table.pubrt.id
}

# Create sub2
resource "aws_subnet" "sub-2" {
  vpc_id                  = aws_vpc.nginx_vpc.id
  cidr_block              = var.cidr_subnets[1]  # Replace with your desired subnet CIDR block
  availability_zone       = var.az[1]  # Replace with your desired availability zone
#   map_public_ip_on_launch = true

  tags = var.tags_sub2
}

# Create RT Association for sub2
resource "aws_route_table_association" "pubass2" {
  subnet_id = aws_subnet.sub-2.id
  route_table_id = aws_route_table.pubrt.id
}
# Create a security group for the EC2 instance
resource "aws_security_group" "instance_sg" {
  name        = "nginx-instance-sg"
  description = "Security group for EC2 instance running Nginx"
  vpc_id = aws_vpc.nginx_vpc.id
  
  ingress {
    # Allow inbound traffic from the Application Load Balancer
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # security_groups = [aws_security_group.alb_sg.id]
    cidr_blocks = var.cidr_sg 
  }
  
  # Allow outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_sg
  }
}

# Create a security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "nginx-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id = aws_vpc.nginx_vpc.id
  
  # Allow inbound HTTP traffic from the internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_sg
  }
  
  # Allow outbound traffic to the EC2 instance
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    # security_groups = [aws_security_group.instance_sg.id]
    cidr_blocks = var.cidr_sg
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
# Create an EC2 instance
resource "aws_instance" "nginx_instance" {
  ami           = var.ami_instance 
  instance_type = var.ami_instance_type
  key_name      = aws_key_pair.deployer.key_name
  subnet_id = aws_subnet.sub-1.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  
  # User data script to install Nginx on the instance
  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y &&
            sudo apt install -y nginx
            service nginx start
            chkconfig nginx on
            cat <<EOF > /var/www/html/index.html
            <!DOCTYPE html>
            <html>
            <head>
                <title>My Nginx Server</title>
                <style>
                    body {
                      font-size: 24px;
                    }
                </style>
            </head>
            <body>
                <h1>Welcome to My Nginx Server!</h1>
                <p>This is a sample Nginx server with custom content.</p>
            </body>
            </html>
            sudo apt reload nginx
            EOF
      
            

  # Disable public IP assignment to prevent direct access to the instance
  associate_public_ip_address = true
  tags = var.tags_instance
}

# Create an Application Load Balancer
resource "aws_lb" "nginx_alb" {
  name               = "nginx-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.sub-1.id, aws_subnet.sub-2.id] # Specify the appropriate subnet IDs
}

# Create a target group for the ALB
resource "aws_lb_target_group" "nginx_target_group" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nginx_vpc.id
  
  # Register the EC2 instance as a target for the target group
  health_check {
    path = "/"
  }
  
  target_type = "instance"
#   targets     = [aws_instance.nginx_instance.id]
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.nginx_target_group.arn
  target_id        = aws_instance.nginx_instance.id
#   port             = 80
}

# Create a listener for the ALB
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}
