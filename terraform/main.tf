provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "sentry-default" {
  cidr_block = "172.16.248.0/21"

  tags = {
    Name        = "Sentry VPC"
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

###
# Create an internet gateway to give our subnet access to the outside world
###

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.sentry-default.id}"
}

###
# Grant the VPC internet access on its main route table
###

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.sentry-default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

###
# Create a subnet to launch our instances into
###

resource "aws_subnet" "sentry-web" {
  vpc_id                  = "${aws_vpc.sentry-default.id}"
  cidr_block              = "172.16.254.0/24"
  map_public_ip_on_launch = true

  tags = {
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

resource "aws_subnet" "sentry-database" {
  vpc_id                  = "${aws_vpc.sentry-default.id}"
  cidr_block              = "172.16.253.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = false
  tags = {
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

resource "aws_subnet" "sentry-redis" {
  vpc_id                  = "${aws_vpc.sentry-default.id}"
  cidr_block              = "172.16.252.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${aws_subnet.sentry-web.availability_zone}"

  tags = {
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

resource "aws_elasticache_subnet_group" "sentry-redis" {
  name       = "sentry-redis-subnet"
  subnet_ids = ["${aws_subnet.sentry-redis.id}"]
}

###
# Sentry template for config.py
###

data "template_file" "config_yml" {
  template = "${file("${path.module}/templates/config_yml.tpl")}"
  vars = {
    redis_host = "${aws_elasticache_cluster.sentry-cache.cache_nodes.0.address}"
  }
}

###
# Sentry template for sentry.conf.py
###

data "template_file" "sentry_conf_py" {
  template = "${file("${path.module}/templates/sentry_conf_py.tpl")}"
  vars = {
    database_username = "${aws_db_instance.sentry-db.username}"
    database_password = "${aws_db_instance.sentry-db.password}"
    database_name     = "${aws_db_instance.sentry-db.name}"
    database_hostname = "${aws_db_instance.sentry-db.address}"
    redis_host        = "${aws_elasticache_cluster.sentry-cache.cache_nodes.0.address}"

  }
}


###
# Define Security Groups Here.
###

resource "aws_default_security_group" "sentry" {
  vpc_id = "${aws_vpc.sentry-default.id}"
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["162.243.66.218/32"]
  }
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_vpc.sentry-default.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###
# Database Security Group to include the application server
###

resource "aws_security_group" "sentry-db" {
  vpc_id = "${aws_vpc.sentry-default.id}"
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_vpc.sentry-default.cidr_block}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_subnet.sentry-database.cidr_block}"]
  }
}

###
# Redis Elasticache Security Group
###

resource "aws_security_group" "sentry-redis" {
  vpc_id = "${aws_vpc.sentry-default.id}"
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_vpc.sentry-default.cidr_block}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_subnet.sentry-database.cidr_block}"]
  }
}


###
# Redis Cache for in-state stuffs.
###

resource "aws_elasticache_cluster" "sentry-cache" {
  cluster_id           = "sentry-redis-cache"
  availability_zone    = "${aws_subnet.sentry-web.availability_zone}"
  subnet_group_name    = "${aws_elasticache_subnet_group.sentry-redis.name}"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.4"
  port                 = 6379
  tags = {
    Name        = "Sentry-redis-cache"
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

###
# Database Subnet Group...
###

resource "aws_db_subnet_group" "sentry-db" {
  name       = "sentry-db-subnetgroup"
  subnet_ids = ["${aws_subnet.sentry-web.id}", "${aws_subnet.sentry-database.id}"]
  tags = {
    Name        = "Sentry-db"
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

###
# Database for Sentry
###

resource "aws_db_instance" "sentry-db" {
  allocated_storage         = 20
  availability_zone         = "${aws_subnet.sentry-web.availability_zone}"
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "11.4"
  instance_class            = "db.t2.small"
  name                      = "sentry"
  username                  = "sentrydb"
  password                  = "sentrydb"
  final_snapshot_identifier = "sentry-db-snapshot"
  parameter_group_name      = "default.postgres11"
  vpc_security_group_ids    = ["${aws_security_group.sentry-db.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.sentry-db.name}"
  tags = {
    Name        = "Sentry-db"
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
}

###
# SSH Key for Deploying and configuring the application
###
resource "aws_key_pair" "iwilson" {
  key_name   = "iwilson-testing"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDiCNAUEQqA7ribG3sGBXhznlOvzLzI4GvqqeA6Q1OvcxZrA8EjXR3OW/fDiC7YVgjy5+9zn52QVTNIDdVYH3Ed4Hz07IqcT36fjEvzi83yW6btQ8S7es2Lu7VsNG+lukj+/Pj8VfXDwwZrnYRWEfdfxpLoiHNDS9yZrS0JOyJpRBmTTWuTVVzjIH3IYeL9K75cyeVbnZdrPhco3lZDTO8Fa364GyY+eLi43vBEwuUZtgdXTdVRiYRfkDGwEZAkJjWPCFeegIHDg58EkixJE237jiBkFaO0+wnXYk9C8VRQ2D2X7raZRlFAumunhDiaeYKcgW1lwdNKUopV+j2eyaXx"
}


###
# Applications server for sentry
###

resource "aws_instance" "sentry-web" {
  ami                     = "ami-07ea0cb93d76e939d"
  instance_type           = "t2.small"
  availability_zone       = "${aws_subnet.sentry-web.availability_zone}"
  key_name                = "${aws_key_pair.iwilson.key_name}"
  subnet_id               = "${aws_subnet.sentry-web.id}"
  monitoring              = false
  disable_api_termination = false
  ebs_optimized           = false
  tags = {
    Name        = "Sentry Server"
    managed_by  = "terraform"
    application = "sentry"
    owner       = "ian.wilson"
  }
  provisioner "file" {
    content     = "${data.template_file.config_yml}"
    destination = "/tmp/sentry-config.yml"
    connection {
      host        = "${aws_instance.sentry-web.public_ip}"
      user        = "ubuntu"
      private_key = "${file("${path.module}/iwilson-testing.pem")}"
    }

  }
  provisioner "file" {
    content     = "${data.template_file.sentry_conf_py}"
    destination = "/etc/sentry/sentry.conf.py"

    connection {
      user        = "ubuntu"
      host        = "${aws_instance.sentry-web.public_ip}"
      private_key = "${file("${path.module}/iwilson-testing.pem")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/sentry-config.yml /etc/sentry/config.yml",
      "sudo mv /tmp/sentry-conf.py /etc/sentry/sentry.conf.py"
    ]
    connection {
      user        = "ubuntu"
      host        = "${aws_instance.sentry-web.public_ip}"
      private_key = "${file("${path.module}/iwilson-testing.pem")}"
    }

  }
}
