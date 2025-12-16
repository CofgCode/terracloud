# Infrastructure Solution

> [!CAUTION]
> **DISCLAIMER**: This project is a **Lab/Testing Environment** and is **not intended for production use at scale** without significant hardening.
> While best practices are demonstrated, a real-world production deployment requires additional security controls, observability compliance, and operational governance (e.g., full Landing Zone implementation, hardened network appliances, comprehensive IAM boundaries).

This repository contains the Terraform Infrastructure as Code (IaC) solution for a scalable, secure, and automated cloud environment hosting a microservices-based application on AWS.

## Architecture Overview

The solution deploys a RESTful Backend and a Static Frontend using AWS ECS Fargate, orchestrated behind Application Load Balancers (ALB).

### Key Components

1.  **Computed (ECS Fargate)**:
    *   **Frontend Service**: Single replica running the React application.
    *   **Backend Service**: Two replicas (auto-scalable) running the Node.js application.
    *   Both run on serverless Fargate infrastructure, removing the need for EC2 management.

2.  **Networking**:
    *   **VPC**: Custom VPC with Public and Private subnets across 3 Availability Zones.
    *   **NAT Gateway**: Enabled for Private Subnets to allow secure outbound internet access for backend services (e.g., pulling images, external APIs).
    *   **Security Groups**: Strict ingress/egress rules ensuring least-privilege access.

3.  **Load Balancing**:
    *   **Public ALB**: Exposes the application to the internet.
        *   Maps `/frontend*` path to the Frontend Service.
        *   Maps `/api*` path to the Backend Service (Gateway pattern).
    *   **Internal ALB**: Handles internal service-to-service communication.
        *   The Backend Service is attached to this ALB for secure internal access.

4.  **Container Registry (ECR)**:
    *   Dedicated ECR repositories for storing Frontend and Backend Docker images.

## Terraform Modules

The infrastructure is modularized for reusability:

*   **`modules/sites`**: Core networking (VPC, Subnets, NAT), Public ALB, and Internal ALB.
*   **`modules/ecs`**: ECS Cluster, Task Definitions, Fargate Services, Target Groups, and IAM Roles.
*   **`modules/ecr`**: Elastic Container Registry repositories.
*   **`modules/shared`**: Used to store common resources that are used by multiple environments.

## Deployment

The `dev` directory contains the environment configuration which instantiates these modules.

### Deployment Steps

1.  **Prerequisites**:
    *   AWS CLI installed and configured.
    *   Terraform installed.
    *   Docker installed (for building and pushing images).

2.  **Environment Setup**:
    Navigate to the `dev` environment directory:
    ```bash
    cd terracloud/dev
    ```

3.  **Initialization**:
    Initialize Terraform to download providers and modules:
    ```bash
    terraform init
    ```

4.  **Plan and Apply**:
    Review and create the infrastructure:
    ```bash
    terraform plan
    terraform apply --auto-approve
    ```

5.  **Teardown**:
    To destroy the infrastructure:
    ```bash
    terraform destroy --auto-approve
    ```

## Architecture Details

This solution utilizes **AWS ECS Fargate**, a serverless compute engine for containers.

### Why ECS Fargate?

*   **Serverless**: Removes the overhead of provisioning, configuring, and scaling clusters of virtual machines (EC2).
*   **Microservices Ready**: Ideal for decoupling the Frontend and Backend into separate, independently scalable services.
*   **Consistency**: ensuring consistent behavior across Dev, Staging, and Production environments.
*   **Compliance & Operational Excellence**:
    *   **HIPAA Compliance**: Fargate operates in a shared responsibility model where AWS manages the underlying infrastructure security, simplifying compliance efforts.
    *   **Cost Optimization**: Can be extended to use **Fargate Spot** to save up to 70% on compute costs for fault-tolerant workloads.

### Architecture Diagram

```mermaid
graph TD
    User((User)) -->|HTTPS/443| PubALB[Public ALB]
    
    subgraph VPC
        subgraph Public_Subnets
            PubALB
            NatGW[NAT Gateway]
        end
        
        subgraph Private_Subnets
            subgraph ECS_Cluster
                FE_Service[Frontend Service<br/>(Fargate)]
                BE_Service[Backend Service<br/>(Fargate)]
            end
            IntALB[Internal ALB]
        end
    end
    
    PubALB -->|/frontend*| FE_Service
    PubALB -->|/api*| BE_Service
    
    FE_Service -.->|Internal API Calls| IntALB
    IntALB -->|/*| BE_Service
    
    BE_Service -->|Outbound| NatGW
    NatGW -->|Internet| ECR[AWS ECR]
```

## Security Considerations

The architecture implements a "Secure by Design" approach:

1.  **Network Segmentation**:
    *   **Public Subnets**: Only for Load Balancers and NAT Gateways.
    *   **Private Subnets**: All application workloads (Frontend and Backend containers) run here. They have NO public IP addresses.
    *   **Internal Access**: The Backend is accessible internally via the Internal ALB, allowing for secure service-to-service communication if the architecture evolves (e.g. BFF pattern).

2.  **Access Control**:
    *   **Frontend**: Accessible only via the Public Load Balancer.
    *   **Backend**: 
        *   Accessible via Public ALB (Gateway route `/api`) for the client application.
        *   Accessible internally via Internal ALB.
        *   **NOT** directly accessible from the internet (no public IP).
    *   **Debugging**: Internal VPC access is permitted for debugging purposes ensuring developers can troubleshoot without exposing services publicly.

3.  **DevSecOps & Supply Chain Security**:
    *   **Image Scanning**: ECR is configured to scan images for vulnerabilities upon push.
    *   **Hardened Images**: It is recommended to use AWS ECR Public Gallery images (e.g., Amazon Linux 2, Alpine) and avoid unverified generic images.
    *   **Code Scanning**: Source code should be scanned in the CI/CD pipeline before building Docker images.

4.  **Future Enhancements**:
    *   **Data Subnet**: creating a dedicated isolated subnet for databases (RDS/DynamoDB) with Network ACLs blocking all internet access.
    *   **AWS cloud front and AWS Firewall**: Cloud front and AWS Firewall provide built-in DDoS mitigation and edge-based protection against common web exploits (OWASP Top 10), preserving backend resources for legitimate users only. That also allow protect the front end from common web attacks and provide a secure and cost-effective way to deliver content to users.




## AWS Landing Zone & Account Strategy

While this project is a foundational example, for enterprise-grade AWS environments, the **AWS Well-Architected Framework** is recommended.

*   **Landing Zone**: Establish a multi-account strategy.
    *   **Management Account**: Dedicated to governance (Organizations, SSO, SCPs). **No resources should be deployed here.**
    *   **Workload Accounts**: Dedicated accounts for each environment (e.g., `dev` account, `staging` account, `production` account) to ensure strict isolation and blast radius containment.
*   **Infrastructure as Code**: This Terraform structure is designed to be modular so it can be deployed across these separate accounts easily.

## Observability

**CloudWatch Logs** are integrated for better observability.
*   **ECS Fargate**: Both Frontend and Backend containers are configured to ship logs to CloudWatch Log Groups (`/ecs/prod-frontend-service`, `/ecs/prod-backend-service`).
*   **Drivers**: The `awslogs` driver is configured in the Task Definitions.

*   **AWS OTEL Collector**: This requires additional configuration to be added to the Task Definitions, it could be in gateway mode or sidecar mode.(more expensive) but it provides more features and better observability. All applications MUST BE instrumented with AWS OTEL.


## FinOps & Cost Allocation

To support **FinOps** practices and granular cost tracking:
*   **Tagging**: All resources are automatically tagged with `Environment` and `Project`.
*   **Cost Explorer**: You can activate these tags in the AWS Billing Console ("Cost Allocation Tags") to break down costs by environment (e.g., filter by `Environment = prod`).

## CI/CD Pipeline

This project embraces the **Multi-repo** approach recommended by HashiCorp for Infrastructure as Code stability and scalability.

### GitHub Actions & OIDC Security

**GitHub Actions** are used for continuous deployment. Long-lived AWS Access Keys ** must not** stored in GitHub Secrets. I used AWS Access keys only for demo purposes.

To ensure maximum security, **OpenID Connect (OIDC)** authentication must be used.  I used the following guide to set it up: [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).

**Why OIDC?**
*   **No Long-Lived Credentials**: Eliminates the risk of static keys being compromised.
*   **Granular Access**: You can restrict which GitHub repositories/branches can assume the AWS Role.
*   **Best Practice**: This is the security standard recommended by GitHub and AWS.

**Setup Instructions**:
To enable the pipeline, you must configure an OIDC Identity Provider in AWS IAM and create a Role that trusts the GitHub Action.

1.  **Documentation**: Follow the official guide: [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).
2.  **Reference Video**: [Connect GitHub Actions to AWS using OIDC](https://www.youtube.com/watch?v=aOoRaVuh8Lc).
3.  **Secrets**: Store the ARN of the role you created in a GitHub Secret named `AWS_ROLE_TO_ASSUME`.

### Pipeline Configuration

The GitHub Actions workflows are designed to be generic and reusable across environments (dev, staging, production). They rely on **GitHub Environment Variables** (`vars`) and **Secrets**.

#### Required Secrets
*   `AWS_ROLE_TO_ASSUME`: The ARN of the IAM Role for OIDC authentication.

#### Required Environment Variables
Configure the following variables in your GitHub Repository Environments (e.g., `production`):

| Variable Name | Description | Example Value |
| :--- | :--- | :--- |
| `AWS_REGION` | AWS Region where resources are deployed | `us-west-2` |
| `ECR_REPOSITORY` | Name of the ECR Repository | `prod-backend-repo` |
| `ECS_SERVICE` | Name of the ECS Service | `prod-backend-service` |
| `ECS_CLUSTER` | Name of the ECS Cluster | `prod-cluster` |
| `ECS_TASK_DEFINITION_FAMILY` | Name of the Task Definition Family | `prod-backend-task` |
| `CONTAINER_NAME` | Name of the Container in the Task Definition | `backend-container` |

## Value of Terraform Cloud (HCP Terraform)

This implementation leverages **Terraform Cloud (HCP Terraform)** to provide a robust, secure, and compliant foundation for Infrastructure as Code.

1.  **Managed State & Security**:
    *   **No S3/DynamoDB Boilerplate**: State files are managed securely by HashiCorp, eliminating the need to provision and secure S3 buckets and DynamoDB tables for locking manually.
    *   **Secure Access**: Access to state files is strictly controlled via Terraform Cloud's RBAC, rather than broad AWS IAM permissions.

2.  **Governance & Compliance (Regulated Environments)**:
    *   **Auditability**: Every infrastructure change is logged, versioned, and auditable, which is a critical requirement for frameworks like **PCI, HIPAA, and ISO 27001**.
    *   **Isolation**: Changes to the IaC are isolated within Terraform Cloud, preventing direct, un-audited manipulation of infrastructure state.

3.  **Governance & Team Management**:
    *   **Role-Based Access Control (RBAC)**: Teams can be structured with granular permissions (e.g., a "Platform Team" manages `prod`, while "Developers" manage `dev`).
    *   **Workspace Separation**: Each environment (`dev`, `staging`, `prod`) lives in its own Workspace, ensuring logical and security boundaries between data and configurations.

4.  **Operational Safety**:
    *   **Remote Execution**: Runs occur in consistent, remote environments, avoiding "it works on my machine" issues.
    *   **State Locking**: Built-in state locking prevents race conditions and corruption during concurrent runs, a risk when relying on local files or improperly configured backends.

5.  **Multi-Repo Strategy Synergy**:
    *   Using Terraform Cloud supports the **Multi-repo** approach by decoupling the lifecycle of different infrastructure components.
    *   This reduces the "blast radius" of changes and allows teams to iterate on individual components independently without locking the entire monolithic state.

---

# Sample Node.js Backend and React Frontend Project

This project is a sample two-application setup with a Node.js backend and a React frontend. Both applications are designed to be independently deployable and scalable.

## Project Structure

The project is organized into two main directories:

- `/backend`: A Node.js Express application that serves a RESTful API.
- `/frontend`: A React application built with Vite that consumes the backend API.

Each directory contains its own `package.json`, `Dockerfile`, and other configuration files, making them independent and ready to be extracted into their own Git repositories.

## Architecture

The applications are designed to be served under a single domain with path-based routing:

- `/api`: All requests to this path are routed to the backend application.
- `/frontend`: All requests to this path are routed to the frontend application.

This setup is commonly used with a reverse proxy or an API gateway in a cloud environment. The backend is expected to be deployed with two replicas behind a load balancer for high availability.

### Environment Variables

Both applications use environment variables for configuration. Example `.env.example` files are provided in each application's directory.

- **Backend:** The backend uses `PORT` and `CORS_ORIGIN` environment variables.
- **Frontend:** The frontend uses `VITE_API_URL` to define the base URL for the backend API. In a production environment, this would be set to `/api` to match the path-based routing.

## Local Development

To run the applications locally, you will need to have Node.js and npm installed.

### Backend

1.  Navigate to the `backend` directory:
    ```sh
    cd backend
    ```

2.  Install the dependencies:
    ```sh
    npm install
    ```

3.  Create a `.env` file from the example:
    ```sh
    cp .env.example .env
    ```
    You can modify the `.env` file if needed.

4.  Start the backend server:
    ```sh
    npm start
    ```
    The backend will be running at `http://localhost:3001`.

### Frontend

1.  Navigate to the `frontend` directory:
    ```sh
    cd frontend
    ```

2.  Install the dependencies:
    ```sh
    npm install
    ```

3.  Create a `.env` file from the example:
    ```sh
    cp .env.example .env
    ```
    For local development, you should change `VITE_API_URL` to point to the local backend server:
    ```
    VITE_API_URL=http://localhost:3001
    ```

4.  Start the frontend development server:
    ```sh
    npm run dev
    ```
    The frontend will be running at `http://localhost:3000`.

## Manual ECR Deployment

If you need to manually push images to ECR (e.g., for initial setup or debugging), follow these steps.

**Prerequisites:**
*   AWS CLI installed and configured with `aws configure`.
*   Docker running locally.

**1. Authenticate Docker to ECR:**
Retreive an authentication token and authenticate your Docker client to your registry (replace `<region>` and `<account-id>`):
```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

**2. Backend Image:**
```bash
# Navigate to backend
cd backend

# Build
docker build -t prod-backend-repo .

# Tag (replace with your ECR URI)
docker tag prod-backend-repo:latest <account-id>.dkr.ecr.<region>.amazonaws.com/prod-backend-repo:latest

# Push
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/prod-backend-repo:latest
```

**3. Frontend Image:**
```bash
# Navigate to frontend
cd frontend

# Build
docker build -t prod-frontend-repo .

# Tag (replace with your ECR URI)
docker tag prod-frontend-repo:latest <account-id>.dkr.ecr.<region>.amazonaws.com/prod-frontend-repo:latest

# Push
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/prod-frontend-repo:latest
```

## Docker

Both applications are containerized using Docker.

### Backend

To build and run the backend Docker container:

1.  Navigate to the `backend` directory.
2.  Build the Docker image:
    ```sh
    docker build -t backend-app .
    ```
3.  Run the Docker container:
    ```sh
    docker run -p 3001:3001 -d backend-app
    ```

### Frontend

To build and run the frontend Docker container:

1.  Navigate to the `frontend` directory.
2.  Build the Docker image:
    ```sh
    docker build -t frontend-app .
    ```
3.  Run the Docker container:
    ```sh
    docker run -p 8080:80 -d frontend-app
    ```
    The frontend will be accessible at `http://localhost:8080`.

## Testing with Docker Compose

To test the complete application stack locally, you can use the `docker-compose.yml` file located in the root directory. This will run the backend, frontend, and a reverse proxy, simulating the intended production architecture.

1.  **Create the backend environment file:**
    If you haven't already, navigate to the `backend` directory and create a `.env` file from the example:
    ```sh
    cd backend
    cp .env.example .env
    cd ..
    ```

2.  **Run Docker Compose:**
    In the root directory (`D:\devworld\terraform2026`), run the following command:
    ```sh
    docker-compose up --build
    ```
    This command will build the Docker images for the frontend and backend (if they don't exist) and start all three containers (`backend`, `frontend`, and `proxy`).

3.  **Access the application:**
    Once the containers are running, you can access the application in your browser at:
    [http://localhost:8080](http://localhost:8080)

    The Nginx proxy will route traffic to the frontend, and API calls to `/api` will be correctly forwarded to the backend.

To stop the containers, press `Ctrl+C` in the terminal where `docker-compose` is running, or run `docker-compose down` from the root directory.
