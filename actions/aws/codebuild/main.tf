resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-hello-world-role"

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

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-hello-world-policy"
  role = aws_iam_role.codebuild_role.id

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
      }
    ]
  })
}

resource "aws_codebuild_project" "hello_world" {
  name         = "hello-world-build"
  service_role = aws_iam_role.codebuild_role.arn
  description  = "A simple CodeBuild project that prints Hello world"

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
    buildspec = <<CODEBUILD
version: 0.2

phases:
  build:
    commands:
      - echo "Hello world"
CODEBUILD
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/hello-world-build"
      stream_name = "build-log"
    }
  }
}

action "aws_codebuild_start_build" "default" {
  config {
    project_name = aws_codebuild_project.hello_world.name
  }
}
