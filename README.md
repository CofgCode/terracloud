# Terracloud Infrastructure

> [!CAUTION]
> **DISCLAIMER**: This project is a **Lab/Testing Environment** and is **not intended for production use at scale** without significant hardening.

This directory contains the Terraform Infrastructure as Code (IaC) configuration for deploying the AWS microservices architecture. It is structured to support multiple environments (`dev`, `stag`, `prod`) using reusable modules.

## Project Structure

The project follows a modular structure to ensure consistency and reusability:

```text
terracloud/
├── modules/                  # Reusable Terraform logic
│   ├── sites/                # Networking & Load Balancing (VPC, ALB, NAT)
│   ├── ecs/                  # Compute & Services (Cluster, Fargate Tasks, ASG)
│   └── ecr/                  # Artifact Registry (Docker repositories)
├── dev/                      # Development Environment Configuration
├── stag/                     # Staging Environment Configuration
└── prod/                     # Production Environment Configuration
```

## Modules Overview

### 1. `modules/sites`
Handles the core network foundation:
*   **VPC**: Custom VPC with public and private subnets.
*   **Networking**: Internet Gateway, NAT Gateway (for private outbound access), and Routing Tables.
*   **Load Balancing**:
    *   **Public ALB**: Ingress for internet traffic (HTTP/HTTPS).
    *   **Internal ALB**: Private traffic between services.
*   **Security Groups**: Base security groups for ALBs.

### 2. `modules/ecs`
Manages the application compute layer:
*   **Cluster**: AWS ECS Cluster to host tasks.
*   **Task Definitions**: Blueprints for Fronend (React) and Backend (Node.js) containers.
*   **Fargate Services**: Manages the running tasks, auto-scaling, and health checks.
*   **Target Groups**: Connects the ALBs to the ECS Services.
*   **CloudWatch Logs**: Centralized logging for application output.

### 3. `modules/ecr`
*   **Repositories**: Creates ECR repositories for storing container images (`backend_repo`, `frontend_repo`).

## Cost Optimization & Redundancy Strategy

The infrastructure is designed with a **tier-based redundancy strategy** to balance cost and availability:

| Feature | Dev / Staging | Production | Reason |
| :--- | :--- | :--- | :--- |
| **Availability Zones** | **1 AZ** (`us-west-2a`) | **2 AZs** (`us-west-2a`, `us-west-2b`) | Saves inter-AZ data transfer costs and NAT Gateway costs in non-critical envs. |
| **Instance Count** | **1 Task** per service | **2 Tasks** per service | Provides High Availability (HA) and zero-downtime deployments for Prod. |

### How to Configure
This is controlled via variables in the environment's `main.tf`:

```hcl
module "sites" {
  # ...
  # Dev/Stag: Single AZ to reduce NAT Gateway hourly costs
  azs = ["us-west-2a"]
}

module "ecs" {
  # ...
  # Dev/Stag: Single instance
  frontend_desired_count = 1
  backend_desired_count  = 1
}
```


Each environment folder (`dev`, `stag`, `prod`) contains a `main.tf` file that acts as the entry point. This file instantiates the modules with environment-specific configuration.

**Key Configuration Parameters:**

*   **`environment`**: Object defining the environment name (e.g., `dev`) and network prefix (e.g., `10.0`).
    ```hcl
    environment = {
      name           = "dev"
      network_prefix = "10.0"
    }
    ```
*   **`ecs_service` / `task_family`**: Unique names for ECS resources to prevent collisions.

## Usage Guide

To deploy or update an environment (e.g., `dev`):

1.  **Navigate to the environment directory**:
    ```bash
    cd terracloud/dev
    ```

2.  **Initialize Terraform**:
    Downloads providers and modules.
    ```bash
    terraform init
    ```

3.  **Review the Plan**:
    Shows what will be created, modified, or destroyed.
    ```bash
    terraform plan
    ```

4.  **Apply Changes**:
    Executes the plan against AWS.
    ```bash
    terraform apply
    ```

## Terraform Cloud
This project is configured to work with Terraform Cloud (HCP Terraform) for state management. Ensure you have authenticated via `terraform login` or set the `TF_TOKEN_app_terraform_io` environment variable if running locally.
