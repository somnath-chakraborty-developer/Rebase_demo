# S3 Bucket for CodePipeline Artifacts

# S3 Bucket
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "my-codepipeline-artifacts-reco-demo"
#  acl    = "private"  # You can use ACL here, but if the bucket is configured for Object Ownership, it should be removed.
}

resource "aws_s3_bucket_versioning" "codepipeline_bucket_versioning" {
  bucket = aws_s3_bucket.codepipeline_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "codepipeline_bucket_policy" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:*",
        Resource = ["${aws_s3_bucket.codepipeline_bucket.arn}/*", 
                    "${aws_s3_bucket.codepipeline_bucket.arn}"]
      }
    ]
  })
}




#Codebuild project
resource "aws_codebuild_project" "my_service_build" {
  name          = "my-service-build"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true  # Required for Docker in Docker (DIND)
    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.my_service_repo.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2

      phases:
        install:
          commands:
            - echo Installing dependencies...

        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $REPOSITORY_URI

        build:
          commands:
            - echo Build started on `date`
            - echo Building the Docker image...
            - docker build -t $REPOSITORY_URI:latest .
            - docker push $REPOSITORY_URI:latest

        post_build:
          commands:
            - echo Build completed on `date`
            - echo Writing imagedefinitions.json file...
            - printf '[{"name":"my_service","imageUri":"%s"}]' $REPOSITORY_URI:latest > imagedefinitions.json

      artifacts:
        files:
          - imagedefinitions.json
          - '**/*'
        discard-paths: yes
      EOF
  }
}



#Codepipeline
resource "aws_codepipeline" "my_service_pipeline" {
  name     = "my-service-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"  # Use the GitHub version 2 action
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = var.repository
        BranchName = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.my_service_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["build_output"]
      version          = "1"

      configuration = {
        ClusterName        = aws_ecs_cluster.demo_cluster.id
        ServiceName        = aws_ecs_service.my_service.id
        FileName           = "imagedefinitions.json"
      }
    }
  }

  # Ensure the ECR repository is created before CodePipeline
  depends_on = [
    aws_ecr_repository.my_service_repo
  ]
}
