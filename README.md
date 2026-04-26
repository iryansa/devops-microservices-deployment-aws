# Automated Multi-Tier Application Deployment 🚀

## 📖 Overview
This repository demonstrates a production-ready, fully automated CI/CD deployment pipeline for a multi-tier microservices application. The project takes a React.js frontend and a FastAPI backend from source code to a live, publicly accessible Amazon EC2 instance with zero manual intervention post-setup.

The infrastructure is provisioned using **Terraform** (IaC), the server is configured using **Ansible** (Configuration Management), and the microservices are orchestrated within a local **Kubernetes (MicroK8s)** cluster. Continuous Integration and Continuous Deployment are handled via **GitHub Actions** and **ArgoCD**, ensuring that every push to the `main` branch results in a zero-downtime deployment.

---

## 🏗️ Architecture & Tech Stack

### Application Layer
* **Frontend:** React.js (Containerized with Nginx Alpine)
* **Backend:** FastAPI (Python), Uvicorn
* **Containerization:** Docker & Docker Hub

### Infrastructure & Operations Layer
* **Cloud Provider:** Amazon Web Services (AWS)
* **Infrastructure as Code (IaC):** Terraform (VPC, Subnets, Internet Gateway, Route Tables, Security Groups, EC2 `t3.medium`)
* **Configuration Management:** Ansible (Automated dependency installation and cluster initialization)
* **Container Orchestration:** Kubernetes (MicroK8s)

### CI/CD Pipeline
* **Continuous Integration:** GitHub Actions (Automated Docker builds, pushing to registry, and manifest updating)
* **Continuous Deployment:** ArgoCD (GitOps controller polling GitHub and syncing the K8s cluster)

---

## 📂 Directory Structure

```text
project-root/
├── frontend/                 # React.js source code, Nginx routing config, and Dockerfile
├── backend/                  # FastAPI source code, requirements.txt, and Dockerfile
├── terraform/                # .tf files defining the AWS network and EC2 instance
├── ansible/                  # .yml playbooks and inventory for Ubuntu node configuration
├── k8s/                      # Kubernetes manifests (Deployments & NodePort Services)
├── .github/workflows/        # CI pipeline (deploy.yml)
└── README.md                 # Project documentation
```

---

## 🛠️ Prerequisites
Before deploying this project, ensure you have the following installed and configured:
* An active **AWS Account** with an IAM user provisioned with Administrator access.
* An AWS EC2 Key Pair (`.pem`) created in the `us-east-1` region.
* **Terraform CLI** installed locally.
* **Ansible** installed (via Windows Subsystem for Linux (WSL) if on Windows).
* **Docker Hub** account and credentials saved as GitHub Repository Secrets (`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`).
* GitHub Repository configured with **Read and Write permissions** for GitHub Actions.

---

## 🚀 Step-by-Step Deployment Guide

### Phase 1: Infrastructure Provisioning (Terraform)
We use Terraform to provision a secure network and compute instance on AWS.
1. Navigate to the `terraform` directory.
2. Ensure your AWS credentials are set in your environment.
3. Initialize and apply the configuration:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
4. Note the outputted `instance_public_ip`.

### Phase 2: Node Configuration (Ansible)
We use Ansible to prepare the raw Ubuntu server to host our Kubernetes cluster.
1. Copy your `.pem` key into your Linux/WSL environment and run `chmod 400 your_key.pem`.
2. Navigate to the `ansible` directory.
3. Update `inventory.ini` with your new EC2 Public IP.
4. Execute the playbook to install Snap, MicroK8s, and configure user groups:
   ```bash
   ansible-playbook -i inventory.ini setup.yml
   ```

### Phase 3: Continuous Integration (GitHub Actions)
The CI pipeline is defined in `.github/workflows/deploy.yml` and triggers on every push to the `main` branch. 
* It checks out the code and authenticates with Docker Hub.
* It builds immutable Docker images for the `frontend` and `backend` using the unique Git commit SHA as the tag.
* It uses `sed` to update the image tags in `k8s/frontend.yaml` and `k8s/backend.yaml`.
* It commits and pushes these updated manifests back to the repository.

### Phase 4: Continuous Deployment (ArgoCD)
ArgoCD implements the GitOps methodology. 
1. ArgoCD is installed within the MicroK8s cluster and exposed via a NodePort (`30081`).
2. An ArgoCD `Application` manifest is applied, pointing to this repository's `k8s/` directory.
3. As soon as GitHub Actions commits new image tags, ArgoCD detects the drift and automatically spins up the new Pods while gracefully terminating the old ones.

---

## 🌐 Accessing the Application
Once the pipeline completes, the application is accessible via the EC2 instance's public IP:
* **React Frontend:** `http://<EC2_PUBLIC_IP>:30080`
* **ArgoCD Dashboard:** `http://<EC2_PUBLIC_IP>:30081`

*Note: The frontend utilizes a custom `nginx.conf` reverse proxy to successfully route `/api/` requests to the internal Kubernetes DNS of the FastAPI backend service (`backend-svc.default.svc.cluster.local`).*

---

## 🛑 Teardown & Cleanup
To prevent unnecessary AWS billing for the `t3.medium` instance, the infrastructure must be destroyed when not in use.
1. Navigate to the `terraform` directory.
2. Execute the destroy command:
   ```bash
   terraform destroy -auto-approve
   ```
3. Verify that all resources (VPC, Subnets, Security Groups, EC2) have been successfully terminated.
