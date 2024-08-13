# Recro_demo
AWS Demo for Recro Webinar

The Terraform code directory contains the infra terraform code incluuding the cicd creation code. 
The Application code directory contains a demo python flask application code. 

The ECR arn link will need to be passed in thhe buildspec.yml file of the application code. 
The github repositiry name containing the application code needs to be passed in codepipeline.tf. Ensure the github repo is accessible from AWS using AWS connections 
(https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html)
Also ensure your IAM role (the credentials you will be using to connect to AWS) has all the necessary policies that terrafrom needs , including AWS Administrator, S3 full access & Codestar access.
