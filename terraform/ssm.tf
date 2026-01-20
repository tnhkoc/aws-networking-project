data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app_ssm" {
  name               = "${local.name}-app-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name}-app-ssm-role"
  })
}

resource "aws_iam_role_policy_attachment" "app_ssm_core" {
  role       = aws_iam_role.app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_ssm" {
  name = "${local.name}-app-ssm-profile"
  role = aws_iam_role.app_ssm.name

  tags = merge(local.common_tags, {
    Name = "${local.name}-app-ssm-profile"
  })
}

output "app_ssm_instance_profile_name" {
  value = aws_iam_instance_profile.app_ssm.name
}