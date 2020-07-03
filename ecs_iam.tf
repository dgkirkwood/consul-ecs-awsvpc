# Create an IAM role for the ECS EC2 instances.
data "aws_iam_policy_document" "ecs_role_definition" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}
resource "aws_iam_role" "ecs_role" {
  name_prefix        = "${var.cluster_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_definition.json

  # Allows the role to be deleted and reacreated (when needed)
  force_detach_policies = true
}

# Create an IAM policy which allows the ECS agent to function inside EC2 instances
data "aws_iam_policy_document" "ecs_instance_role_policy_doc" {
  statement {
    actions = [
      # Requirements for ECS agent
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecs:StartTask",

      # Requirements for EC2 instances within the cluster to be able to pull ECR Docker images
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",

      # Allow EC2 instances to write to CloudWatch logs
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*",
    ]
  }
}
resource "aws_iam_policy" "ecs_role_permissions" {
  name_prefix = "${var.cluster_name}-ecs-policy"
  description = "These policies allow the ECS instances to do certain actions like pull images from ECR"
  path        = "/"
  policy      = data.aws_iam_policy_document.ecs_instance_role_policy_doc.json
}

# Attach the ECS agent IAM policy to the service Role that is assinged to each EC2 instance
resource "aws_iam_policy_attachment" "ecs_instance_role_policy_attachment" {
  name = "${var.cluster_name}-iam-policy-attachment"
  roles = [
    aws_iam_role.ecs_role.name
  ]
  policy_arn = aws_iam_policy.ecs_role_permissions.arn
}

# Allow EC2 instances to be launched using this role,
# allowing them to automatically gain the permissions that were present in this role
# (attached through policies to the Role)
resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  name_prefix = var.cluster_name
  role        = aws_iam_role.ecs_role.name
}
