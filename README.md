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

## Terraform Cloud Setup

This project is configured to use **Terraform Cloud (HCP Terraform)** for state management. 

### Prerequisites
1.  **Organization**: Ensure you have an Organization created in TFC (referenced as `myiacterracloud` in the code, or update the `cloud` block to match your org).
2.  **CLI Authentication**: Authenticate your local terminal with TFC:
    ```bash
    terraform login
    ```

### Required Workspaces
You must create the following Workspaces in Terraform Cloud before running `terraform init`:

| Environment | Directory | TFC Workspace Name | Workflow Type |
| :--- | :--- | :--- | :--- |
| **Development** | `terracloud/dev` | `wsterracloud-dev` | CLI-driven |
| **Staging** | `terracloud/stag` | `wsterracloud-stag` | CLI-driven |
| **Production** | `terracloud/prod` | `wsterracloud-prod` | CLI-driven |

*> **Note**: The workspace names are defined in the `cloud` block of each environment's configuration. If you name them differently in TFC, you must update the `workspaces { name = "..." }` block in the respective `main.tf`.*
