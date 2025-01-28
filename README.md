# MERNStackScalable IAC
Deploy a production-ready MERN stack on AWS with Terraform. Includes scalable infrastructure for ECS Fargate, RDS Aurora, S3, ECR, Auto Scaling, and ALB. Ideal for DevOps engineers and developers looking to automate cloud deployments using Infrastructure as Code (IaC).


# MERN Stack Infrastructure Deployment using Terraform

This repository contains Terraform configurations to deploy a scalable and secure infrastructure for a MERN stack application on AWS. The infrastructure includes a VPC, subnets, ECS cluster, RDS Aurora database, ECR repositories, S3 storage, Auto Scaling, and an Application Load Balancer.

## Features

- **VPC Setup**:
  - VPC with public and private subnets across two availability zones.
  - Internet Gateway and route tables for public access.
  
- **ECS Deployment**:
  - ECS cluster with Fargate launch type.
  - Task definitions and services for the backend and frontend.
  - Integrated Application Load Balancer (ALB) for backend traffic routing.

- **Database**:
  - Aurora MySQL RDS cluster for the backend.
  - Database subnet group for private subnets.

- **Storage**:
  - S3 bucket for serving static assets.
  - ECR repositories for backend and frontend container images.

- **Scaling**:
  - Auto Scaling group for frontend EC2 instances with scaling policies.
  - Fargate tasks for backend scalability.

- **Security**:
  - Security groups for ECS, ALB, and RDS with restricted access.
  - IAM roles for ECS task execution and permissions.

## Prerequisites

- AWS account with appropriate permissions.
- Terraform CLI installed ([Install Terraform](https://www.terraform.io/downloads)).
- AWS CLI installed and configured ([Install AWS CLI](https://aws.amazon.com/cli/)).
- Git installed ([Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)).

## File Structure

```
├── data-sources.tf          # AWS data sources configuration.
├── provider.tf              # AWS provider configuration.
├── resources.tf             # All resource definitions.
├── terraform.tfstate        # Terraform state file.
├── terraform.tfstate.backup # Backup of the state file.
├── terraform.tfvars         # Input variable values.
├── variables.tf             # Input variable definitions.
├── ecr-lifecycle-policy.json# ECR lifecycle policy file.
└── README.md                # Project documentation.
```

## Usage

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/mern-infra-deployment.git
cd mern-infra-deployment
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Format and Validate the Configuration
```bash
terraform fmt -recursive
terraform validate
```

### 4. Apply the Terraform Configuration
```bash
terraform apply
```

> Note: Review the plan and confirm the deployment by typing `yes`.

### 5. Generate a Plan File (Optional)
To generate a JSON execution plan:
```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

## Outputs

- ALB DNS Name: The endpoint for accessing the application.
- RDS Endpoint: The database connection endpoint.
- S3 Bucket Name: Name of the bucket for static assets.

## Cleanup

To destroy the infrastructure and clean up resources:
```bash
terraform destroy
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for enhancements or fixes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- **Abdul Fahad** - Cloud Solutions Architect & DevOps Engineer.
- **GitHub**: [Your GitHub Profile](https://github.com/abdulfahad661)
- **LinkedIn**: [Your LinkedIn Profile](https://www.linkedin.com/in/abdulfahad07)

---

**Disclaimer**: Ensure your AWS credentials and sensitive data are secured and excluded from version control.
