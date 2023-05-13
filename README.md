# Integrating Jenkins with AWS CodeBuild and CodeDeploy

## Requirements 
* Docker
* An AWS account
* Terraform

## jenkins.tf
Create and start a Jenkins container using Terraform. 

jenkins-plugins.txt: contains a list of plugins to be installed when terraform apply is executed.
```
mailer:latest
ldap:latest
ssh-slaves:latest
timestamper:latest
codedeploy:latest
aws-codebuild:latest
http_request:latest
file-operations:latest
pipeline-aws:1.43

```

## awscodebuild/awscodebuild.tf
This file neatly installs the necessary resources to enable the seamless usage of CodeBuild, CodeDeploy, and Jenkins: buckets, policies, permissions, roles, etc.


Apply
```
terraform apply -auto-approve
```