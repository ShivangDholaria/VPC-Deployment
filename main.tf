resource "aws_vpc" "my-vpc-1" {
    cidr_block              = var.cidr-block

    tags = {
        Name                = "my-vpc"
    }
}

resource "aws_subnet" "my-vpc-subnet-1" {
    vpc_id                  = aws_vpc.my-vpc-1.id
    cidr_block              = "10.0.0.0/24"
    availability_zone       = "us-east-1a"   
    map_public_ip_on_launch = true
}

resource "aws_subnet" "my-vpc-subnet-2" {
    vpc_id                  = aws_vpc.my-vpc-1.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1b"   
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "my-vpc-gateway" {
    vpc_id                  = aws_vpc.my-vpc-1.id
}

resource "aws_route_table" "my-vpc-rt" {
    vpc_id                  = aws_vpc.my-vpc-1.id

    route {
        cidr_block          = "0.0.0.0/0"
        gateway_id          = aws_internet_gateway.my-vpc-gateway.id
    }
}

resource "aws_route_table_association" "my-vpc-rta1" {
    subnet_id               = aws_subnet.my-vpc-subnet-1.id
    route_table_id          = aws_route_table.my-vpc-rt.id
}

resource "aws_route_table_association" "my-vpc-rta2" {
    subnet_id               = aws_subnet.my-vpc-subnet-2.id
    route_table_id          = aws_route_table.my-vpc-rt.id
}

resource "aws_security_group" "my-vpc-sg" {
    name                    = "my-vpc-sg"
    vpc_id                  = aws_vpc.my-vpc-1.id

    ingress {
        description         = "HTTP from VPC"
        from_port           = 80
        to_port             = 80
        protocol            = "tcp"
        cidr_blocks         = ["0.0.0.0/0"]
    }
        
    ingress {
        description         = "SSH"
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_blocks         = ["0.0.0.0/0"]
    }
    
    egress {
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_blocks         = ["0.0.0.0/0"]
    }

    tags = {
        Name                = "my-vpc-sg"
    }
}

resource "aws_instance" "my-instance-1" {
    ami                     = var.ami-id
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.my-vpc-sg.id]
    subnet_id               = aws_subnet.my-vpc-subnet-1.id
    user_data               = base64encode(file("userdata_1.sh"))
}

resource "aws_instance" "my-instance-2" {
    ami                     = var.ami-id
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.my-vpc-sg.id]
    subnet_id               = aws_subnet.my-vpc-subnet-2.id
    user_data               = base64encode(file("userdata_2.sh"))
}

resource "aws_lb" "my-alb" {
    name                    = "my-alb"
    internal                = false
    load_balancer_type      = "application"

    security_groups         = [aws_security_group.my-vpc-sg.id]
    subnets                 = [aws_subnet.my-vpc-subnet-1.id, aws_subnet.my-vpc-subnet-2.id]

    tags = {
      Name                  = "My-ALB"
    }
}

resource "aws_alb_target_group" "my-alb-tg" {
    name                    = "my-alb-tg"
    port                    = 80
    protocol                = "HTTP"
    vpc_id                  = aws_vpc.my-vpc-1.id

    health_check {
        path                = "/"
        port                = "traffic-port"
    }
}

resource "aws_lb_target_group_attachment" "my-tg-attach-1" {
    target_group_arn        = aws_alb_target_group.my-alb-tg.arn
    target_id               = aws_instance.my-instance-1.id
    port                    = 80
}

resource "aws_lb_target_group_attachment" "my-tg-attach-2" {
    target_group_arn        = aws_alb_target_group.my-alb-tg.arn
    target_id               = aws_instance.my-instance-2.id
    port                    = 80
}

resource "aws_lb_listener" "my-alb-listener" {
    load_balancer_arn       = aws_lb.my-alb.arn
    port                    = 80
    protocol                = "HTTP"

    default_action {
      target_group_arn      = aws_alb_target_group.my-alb-tg.arn
      type                  = "forward"
    }
}

