# ECS Fargate Module

This module provisions the ECS Cluster, Task Definitions, Fargate Services, and associated IAM Roles and Security Groups for the application.

## Resources Created

*   **AWS ECS Cluster**: The logical grouping of tasks.
*   **AWS ECS Service**: Manages the running tasks (Frontend and Backend).
*   **AWS ECS Task Definitions**: Describes the containers (Docker image, CPU/Memory, Env Vars).
*   **AWS CloudWatch Log Groups**: Centralized logging for containers.
*   **AWS IAM Roles**: Execution roles for Fargate tasks.
*   **AWS Security Groups**: Controls network access to the containers.
*   **AWS ALB Target Groups**: Integrates with the Load Balancer to route traffic to tasks.

## Configuration Highlights

### Health Checks

The Application Load Balancer (ALB) automatically checks the health of the containers to ensure requests are only routed to healthy instances.

*   **Frontend**: Checks `GET /health/` (expects 200 OK).
*   **Backend**: Checks `GET /health` (expects 200 OK).

### Timeouts & Lifecycle

To ensure zero-downtime deployments and graceful handling of scaling events, the following timeouts are configured:

*   **Health Check Grace Period**: `60 seconds`.
    *   This gives the application 60 seconds to start up and pass its first health check before ECS considers it unhealthy and kills it.
*   **Deregistration Delay**: `300 seconds` (5 minutes).
    *   When a task is stopped (e.g., during a deployment), the ALB waits 5 minutes before fully severing connections. This allows in-flight requests to complete gracefully.

## Inputs

| Variable | Description |
| :--- | :--- |
| `demo_app_cluster_name` | Name of the ECS Cluster. |
| `vpc_id` | ID of the VPC where resources are deployed. |
| `frontend_ecr_repo_url` | Full URL of the ECR repository for the frontend image. |
| `backend_ecr_repo_url` | Full URL of the ECR repository for the backend image. |
| `frontend_desired_count` | Number of frontend replicas. |
| `backend_desired_count` | Number of backend replicas. |

*(See `variables.tf` for the full list of inputs)*
