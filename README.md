# Complete Terraform deployment of EC2 along with VPC

## Instructions
1. Open terraform-aws and locate resource "aws_key_pair". You must define the `public_key` variable with the key you want to use.
2. Run `terraform init`
3. Optionally, run `terraform plan` to view changes before applying
4. Run `terraform apply` and make a note of the public ip address.
5. Connect to the instance by entering `ssh -i private_key ubuntu@public_ip`
