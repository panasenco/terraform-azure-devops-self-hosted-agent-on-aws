resource "aws_iam_role" "agent_role" {
  name                 = "${var.name}-agent-role-${data.aws_region.current.name}"
  path                 = "/"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-agent-role-${var.cluster_name}"
  })
}

resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.name}-agent-${data.aws_region.current.name}"
  role = aws_iam_role.agent_role.name

  tags = merge(var.tags, {
    Name = "${var.name}-agent-${var.cluster_name}"
  })
}

# Required policy for SSM Session Manager & basic EC2 operations
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Required policy for CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Required policy for Secret Manager
resource "aws_iam_role_policy_attachment" "secretmanager_core" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Allow instances to signal lifecycle hook completion during ASG instance refresh
resource "aws_iam_role_policy" "lifecycle_hook" {
  name = "${var.name}-lifecycle-hook"
  role = aws_iam_role.agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "autoscaling:CompleteLifecycleAction"
      Resource = aws_autoscaling_group.agent_asg.arn
    }]
  })
}