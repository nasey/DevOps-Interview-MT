# Infrastructure – DevOps Assignment

Terraform IaC for deploying the Dockerized Rails + Nginx application on AWS (ECS Fargate, ALB, RDS Postgres, S3). All application resources run in **private subnets**; only the **Application Load Balancer** is in public subnets.

---

## Assignment steps covered

| Step | Requirement | Status |
|------|-------------|--------|
| 1 | Build process: build Docker images, upload to ECR | See [Build and push to ECR](#1-build-and-push-docker-images-to-ecr) below |
| 2 | `infrastructure` folder with IaC code | ✅ This folder |
| 3 | ECS/EKS with ECR image, ELB, resources in private subnet, LB in public | ✅ ECS Fargate, ALB in public subnets |
| 4 | RDS + S3 as ENV in ECS; S3 via IAM role; RDS via credentials | ✅ See [Environment variables](#environment-variables) |
| 5 | README with how to use and create infrastructure | ✅ This file |
| 6 | Architecture diagram, deployment steps | ✅ [ARCHITECTURE.md](ARCHITECTURE.md) |
| 7 | Share repo with Docme Cloud, email HR | Your action |

---

## Prerequisites

- AWS CLI configured (e.g. `aws configure`) with permissions to create VPC, ECS, ALB, RDS, S3, IAM, CloudWatch.
- Terraform >= 1.x.
- Docker (for building and pushing images to ECR).
- From repo root, `infrastructure` is the working directory for all Terraform commands.

---

## 1. Build and push Docker images to ECR

The ECS task definition expects two images in ECR:

- `rails_app:latest`
- `webserver:latest`

Use your own AWS account ID and region if different.

### 1.1 Create ECR repositories (one-time)

```bash
aws ecr create-repository --repository-name rails_app    --region ap-south-1
aws ecr create-repository --repository-name webserver    --region ap-south-1
```

### 1.2 Authenticate Docker to ECR

```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

Replace `<YOUR_AWS_ACCOUNT_ID>` with your 12-digit account ID (same as in `ecs_task.tf` image URLs).

### 1.3 Build and push from repo root

**Rails app image:**

```bash
docker build -t rails_app:latest -f docker/app/Dockerfile .
docker tag rails_app:latest <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/rails_app:latest
docker push <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/rails_app:latest
```

**Nginx (webserver) image:**

```bash
docker build -t webserver:latest -f docker/nginx/Dockerfile .
docker tag webserver:latest <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/webserver:latest
docker push <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/webserver:latest
```

**Note:** Build context must be the **repository root** (`.`), so that paths like `docker/nginx/default.conf` and `Gemfile` resolve correctly.

---

## 2. Create infrastructure with Terraform

Run from the `infrastructure` directory.

### 2.1 Initialize and plan

```bash
cd infrastructure
terraform init
terraform plan
```

### 2.2 Apply

```bash
terraform apply
```

Confirm when prompted. Note the outputs (ALB DNS name, RDS endpoint, etc.).

### 2.3 Outputs

After apply:

- **ALB endpoint:** `terraform output` or AWS Console → EC2 → Load Balancers → `loyaltri-alb` → DNS name. Use this as `LB_ENDPOINT` (without `http://`) in the app; it is already set in the ECS task definition.
- **RDS endpoint:** `terraform output rds_endpoint`
- **RDS password:** `terraform output -raw rds_password` (sensitive; used by ECS task definition automatically).

---

## 3. After deployment

- **Application URL:** `http://<alb-dns-name>` (from ALB DNS name).
- **Logs:** CloudWatch Log group `/ecs/loyaltri-app` (streams: `rails`, `nginx`).
- **Scaling:** Change `desired_count` in `ecs_service.tf` and run `terraform apply`, or scale via AWS Console.

---

## Environment variables

The Rails container receives these from Terraform (no manual ENV needed for ECS):

| Variable | Source |
|----------|--------|
| `RDS_DB_NAME` | Fixed: `rails` |
| `RDS_USERNAME` | Fixed: `postgres` |
| `RDS_PASSWORD` | Terraform `random_password.db_password` |
| `RDS_HOSTNAME` | RDS instance address |
| `RDS_PORT` | `5432` |
| `S3_BUCKET_NAME` | Terraform-created S3 bucket name |
| `S3_REGION_NAME` | `ap-south-1` |
| `LB_ENDPOINT` | ALB DNS name |

S3 access uses the **ECS task IAM role** (no Access Key/Secret Key). RDS uses the credentials above.

---

## Destroying infrastructure

```bash
cd infrastructure
terraform destroy
```

Confirm when prompted. This removes ECS service, ALB, RDS, S3 bucket, VPC, and related resources.
