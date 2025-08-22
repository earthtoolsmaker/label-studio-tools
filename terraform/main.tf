## TODO: add permission to write to CLoudWatch Loggroup from the EC2 instance

resource "aws_s3_bucket" "label_studio_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_cors_configuration" "label_studio_bucket_cors" {
  bucket = aws_s3_bucket.label_studio_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers = [
      "x-amz-server-side-encryption",
      "x-amz-request-id",
      "x-amz-id-2"
    ]
    max_age_seconds = 3600
  }
}

resource "aws_db_instance" "label_studio_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.8"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.label_studio_db_sg.id]
}

data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "label_studio_role" {
  name = "label_studio_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "label_studio_policy" {
  name        = "label_studio_policy"
  description = "Policy for Label Studio to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.label_studio_bucket.bucket}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.label_studio_bucket.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "label_studio_attachment" {
  policy_arn = aws_iam_policy.label_studio_policy.arn
  role       = aws_iam_role.label_studio_role.name
}

resource "aws_iam_instance_profile" "label_studio_instance_profile" {
  name = "label_studio_instance_profile"
  role = aws_iam_role.label_studio_role.name
}

resource "aws_instance" "label_studio_server" {
  ami                         = data.aws_ami.latest_amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.label_studio_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.label_studio_instance_profile.name
  user_data                   = <<-EOF
#!/bin/bash
set -x

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

yum update -y

# Install Docker
amazon-linux-extras install docker -y

# Start the Docker service
service docker start

# Add the ec2-user to the docker group
usermod -a -G docker ec2-user

# Run Label Studio Docker container
docker run -p 80:8080 \
  -e LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK=true \
  -e LABEL_STUDIO_USERNAME=${var.labelstudio_username} \
  -e LABEL_STUDIO_PASSWORD=${var.labelstudio_password} \
  -e LABEL_STUDIO_USER_TOKEN=${var.labelstudio_token} \
  -e STORAGE_TYPE=s3 \
  -e STORAGE_AWS_REGION_NAME=${var.aws_region} \
  -e STORAGE_AWS_BUCKET_NAME=${aws_s3_bucket.label_studio_bucket.bucket} \
  -e STORAGE_AWS_FOLDER="labelstudio_storage" \
  -e DJANGO_DB=default \
  -e POSTGRE_NAME=${var.db_name} \
  -e POSTGRE_USER=${var.db_username} \
  -e POSTGRE_PASSWORD=${var.db_password} \
  -e POSTGRE_PORT=${var.db_port} \
  -e POSTGRE_HOST=${aws_db_instance.label_studio_db.address} \
  heartexlabs/label-studio:latest
EOF

  tags = {
    Name = "LabelStudioServer"
  }
}

resource "aws_security_group" "label_studio_db_sg" {
  name        = "label_studio_db_sg"
  description = "Allow access to the Label Studio database"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.label_studio_sg.id] # Allow access from the EC2 instance's security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "label_studio_sg" {
  name        = "label_studio_sg"
  description = "Allow HTTP traffic to Label Studio"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere (consider restricting this in production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere (consider restricting this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}
