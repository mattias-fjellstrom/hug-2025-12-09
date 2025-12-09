resource "aws_iam_role" "codebuild" {
  name = "codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters"
        ],
        Resource = aws_ssm_parameter.build.arn
      }
    ]
  })
}

resource "aws_codebuild_project" "build" {
  name         = "my-build-project"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = <<-CODEBUILD
      version: 0.2

      phases:
        build:
          commands:
            - echo "$API_KEY"
      CODEBUILD
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/hello-world-build"
      stream_name = "build-log"
    }
  }
}

ephemeral "random_password" "build" {
  length = 100
}

resource "aws_ssm_parameter" "build" {
  name             = "/build/parameter"
  description      = "Parameter used during build"
  type             = "SecureString"
  value_wo         = ephemeral.random_password.build.result
  value_wo_version = 2

  lifecycle {
    action_trigger {
      actions = [action.aws_codebuild_start_build.default]
      events  = [after_create, after_update]
    }
  }
}

action "aws_codebuild_start_build" "default" {
  config {
    project_name = aws_codebuild_project.build.name

    environment_variables_override {
      name  = "API_KEY"
      type  = "PARAMETER_STORE"
      value = aws_ssm_parameter.build.name
    }
  }
}
