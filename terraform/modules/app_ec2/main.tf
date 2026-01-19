data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.app_sg_id]

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf -y update
              dnf -y install nginx
              systemctl enable nginx
              systemctl start nginx
              echo "hello from ${var.name}" > /usr/share/nginx/html/index.html
              EOF

  tags = merge(var.tags, {
    Name = "${var.name}-app"
  })
}