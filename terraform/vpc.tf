#Create s3 bucket
resource "aws_s3_bucket" "transaction-data" {
  bucket = "trnx-data"

  tags = {
    Name        = "Titilope"
    Environment = "Production"
  }
}

#vpc setup
resource "aws_vpc" "redshift_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "redshift_vpc"
    Team = "Data Engineering Team"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.redshift_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"


  tags = {
    Name = "public-subnet"
  }

}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.redshift_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"



  tags = {
    Name = "private-subnet"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "redshift-igw"
  }
}

#Route table
resource "aws_route_table" "redshift_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "redshift-route-table"
  }
}


resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.redshift_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#Route table association
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.redshift_route_table.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.redshift_route_table.id
}

#Security group(ingresws_vpc.redshift_vpc.cidr_blocks and egress)
resource "aws_security_group" "redshift_security_group" {
  name        = "redshift_security_group"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.redshift_vpc.id

  tags = {
    Name = "allow_ssh"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.redshift_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5439
  ip_protocol       = "tcp"
  to_port           = 5439
}


resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.redshift_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Create SSM parameter

resource "aws_ssm_parameter" "redshift_username" {
  name  = "redshift_username"
  type  = "String"
  value = "titilope"
}

resource "random_password" "password" {
  length  = 8
  special = false

}

resource "aws_ssm_parameter" "redshift_password" {
  name  = "redshift_password"
  type  = "String"
  value = random_password.password.result

  tags = {
    Environment = "Production"
  }

}

# Terraform's "jsonencode" function converts a
# Terraform expression result to valid JSON syntax.
resource "aws_iam_role" "redshift_role" {
  name = "redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "redshift.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_policy" "redshift_policy" {
  name = "redshift_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowRedshiftS3Access",
        Effect = "Allow",
        Action = ["s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::trnx-data",
          "arn:aws:s3:::trnx-data/*"
        ]
      }
    ]
  })
}


