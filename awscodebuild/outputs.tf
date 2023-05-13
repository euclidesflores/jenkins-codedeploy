output "bucket_name" {
  value = aws_s3_bucket.jenkins.arn
}

output "project_name" {
  value = aws_codebuild_project.jenkins.name
}