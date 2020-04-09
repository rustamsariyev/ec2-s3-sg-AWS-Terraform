variable "region" {
  default = "us-east-1"
}

variable "shared_cred_file" {
  default = "~/.aws/credentials"
}

provider "aws" {
  region = "${var.region}"
  shared_credentials_file = "${var.shared_cred_file}"
  profile = "default"
}

resource "aws_instance" "web" {
  ami = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  key_name = "aws"

  user_data = <<-EOF
              #!/bin/bash
              sudo mkdir -p /var/www/html
              echo "Hello, World" | sudo tee -a /var/www/html/index.html
              sudo apt update && sudo apt install nginx -y && sudo apt install awscli -y
              sudo systemctl enable nginx && sudo systemctl restart nginx
              sudo sed -i 's/#Port 22/Port 2221/g' /etc/ssh/sshd_config
              sudo service sshd restart
              EOF
  

  tags = {
      Name = "Ubuntu 18.04"
  }
}
resource "aws_security_group" "instance" {
  name = "ec2-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2221
    to_port     = 2221
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

# S3 Bucket 
# Create a random id 

resource "random_id" "bucket_id" {
  byte_length = 2
}

# Create the bucket

resource "aws_s3_bucket" "empty_bucket" {
  bucket        = "rustamtest-s3-${random_id.bucket_id.dec}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "empty-bucket-name"
  }
}

output "public_ip" {
  value       = "${aws_instance.web.public_ip}"
  description = "The public IP of the web server"
}

output "bucket_id" {
  value       = "${aws_s3_bucket.empty_bucket.id}"
  description = "Bucket Name"
}
