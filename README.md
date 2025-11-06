# 🤖 Robusta Alerting Automation with Holmes GPT

<div align="center">

![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Flux](https://img.shields.io/badge/Flux-5468FF?style=for-the-badge&logo=flux&logoColor=white)
![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)

**AI-Powered Kubernetes Monitoring, Alerting & Troubleshooting on Azure AKS**

[Features](#-features) • [Architecture](#-architecture) • [Quick Start](#-quick-start) • [Documentation](#-detailed-setup-guide)

</div>

---

## 📖 Overview

This repository provides a complete Infrastructure as Code (IaC) solution for deploying an intelligent Kubernetes monitoring and troubleshooting system on Azure. It combines **Robusta** for real-time alerting, **Holmes GPT** for AI-powered diagnostics, and a custom **Slack bot** for interactive troubleshooting—all deployed via GitOps using Flux CD.

### 🎯 What This Solves

- **Automatic Incident Detection**: Robusta monitors your AKS cluster 24/7 and alerts on pod crashes, resource issues, and deployment failures
- **AI-Powered Root Cause Analysis**: Holmes GPT uses Azure OpenAI GPT-4o to automatically investigate issues and provide actionable insights
- **Interactive Slack Troubleshooting**: Ask Holmes questions directly in Slack about your cluster issues
- **Secure Secret Management**: All credentials stored in Azure Key Vault, accessed via Workload Identity (no secrets in cluster)
- **GitOps Deployment**: Entire stack managed through Git with Flux CD for reproducible, auditable deployments

---

## 🏗️ Architecture

![Architecture Diagram](diagrams/robusta-holmes.png)

### Infrastructure Components

<details>
<summary><b>☁️ Azure Resources</b></summary>

| Resource | Name | Purpose |
|----------|------|---------|
| **AKS Cluster** | `YOUR_AKS_CLUSTER_NAME` (e.g., aks-dev) | Kubernetes cluster with workload identity & OIDC enabled |
| **Key Vault** | `YOUR_KEYVAULT_NAME` (e.g., kv-robusta-dev) | Secure storage for Slack tokens, API keys |
| **Container Registry** | `acrrobustadev.azurecr.io` | Private registry for Slack Holmes bot image |
| **Managed Identity** | `id-workload-dev` | Shared identity for Key Vault access (Client ID: output from Terraform) |
| **Federated Credentials** | 3 credentials | Maps K8s service accounts to Azure managed identity |
| **Azure OpenAI** | GPT-4o deployment | AI model for Holmes analysis (128K context, 30K TPM) |
| **VNet & Subnets** | Regional network | Private networking for AKS and Azure services |

**Federated Identity Credentials:**
```
1. robusta-sa-credential         → system:serviceaccount:robusta:robusta-sa
2. holmesgpt-sa-credential       → system:serviceaccount:holmesgpt:holmesgpt-holmes-service-account
3. slack-holmes-bot-sa-credential → system:serviceaccount:slack-holmes-bot:slack-holmes-bot-sa
```

</details>

<details>
<summary><b>⚙️ Kubernetes Namespaces & Applications</b></summary>

### `flux-system` namespace
**GitOps Control Plane**
- GitRepository: Watches `main` branch of this repo
- Kustomization controllers for each application
- Flux Operator, source-controller, kustomize-controller, helm-controller

### `robusta` namespace
**Kubernetes Monitoring & Alerting**
- **Pods**: `robusta-runner` (monitors cluster), `robusta-forwarder` (sends alerts)
- **Chart Version**: 0.29.0
- **Integration**: Slack alerts on pod crashes, deployment failures, resource issues
- **Authentication**: Service account `robusta-sa` with workload identity
- **Secrets**: `robusta-slack-token` synced from Key Vault via CSI driver

### `holmesgpt` namespace
**AI-Powered Troubleshooting Engine**
- **Pod**: `holmesgpt-holmes` (exposes investigation API)
- **Service**: ClusterIP on port 80
- **Model**: Azure OpenAI GPT-4o (128K context window)
- **Toolsets**: kubernetes/core, core_investigation, internet, kubernetes/logs, git
- **Authentication**: Service account `holmesgpt-holmes-service-account`

### `slack-holmes-bot` namespace
**Interactive Slack Bot**
- **Pod**: `slack-holmes-bot` (custom Python bot from ACR)
- **Image**: `acrrobustadev.azurecr.io/slack-holmes-bot:latest`
- **Function**: Receives Slack messages, queries Holmes GPT, responds with analysis
- **Authentication**: Service account `slack-holmes-bot-sa`
- **Secrets**: `slack-bot-token`, `slack-app-token` synced from Key Vault

</details>

<details>
<summary><b>🔄 Data Flows</b></summary>

### 1️⃣ GitOps Deployment Flow (Blue)
```
GitHub (main branch)
  → Flux GitRepository
    → Flux Kustomizations
      → Deploy manifests to namespaces
```

### 2️⃣ Secret Synchronization Flow (Green)
```
Azure Key Vault
  → Workload Identity authentication (OIDC token exchange)
    → CSI Secret Store Driver
      → Mount secrets to pods
        → Create Kubernetes secrets
```

### 3️⃣ Alert Flow (Red)
```
K8s Event (pod crash, etc.)
  → Robusta Runner (detects & analyzes)
    → Robusta Forwarder
      → Slack API
        → Slack channel notification
```

### 4️⃣ User Troubleshooting Flow (Purple)
```
User mentions @Holmes Bot in Slack thread
  → Slack Holmes Bot receives event
    → Calls Holmes GPT Service (http://holmesgpt-holmes.holmesgpt.svc.cluster.local:80)
      → Holmes analyzes using:
        - Kubernetes API (kubectl commands)
        - Git repository access (code context)
        - Azure GPT-4o (AI reasoning)
      → Returns analysis
    → Slack Holmes Bot posts response to thread
```

### 5️⃣ Authentication Flow (Orange)
```
Pod with service account
  → Requests Azure AD token (OIDC)
    → Federated credential validates subject
      → Returns access token
        → Pod accesses Key Vault
```

</details>

---

## ✨ Features

### 🚨 Robusta Monitoring
- **Real-time Cluster Monitoring**: Detects pod crashes, OOMKills, deployment failures
- **Intelligent Alerting**: Context-rich Slack notifications with pod logs, events, and recommendations
- **Auto-Remediation**: Configurable playbooks for automatic issue resolution
- **Multi-Sink Support**: Slack, PagerDuty, Teams, webhooks

### 🧠 Holmes GPT AI Analysis
- **Root Cause Analysis**: AI investigates issues using kubectl commands and cluster context
- **Natural Language Insights**: Explains technical problems in clear, actionable terms
- **Code Context Integration**: Reads your Git repo to understand application-specific issues
- **Investigation API**: RESTful API for programmatic troubleshooting

### 💬 Slack Holmes Bot
- **Interactive Troubleshooting**: Ask questions about alerts directly in Slack
- **Thread-Based Conversations**: Maintains context across multiple questions
- **Automatic Analysis**: Analyzes Robusta alerts and provides AI insights
- **Custom Image from ACR**: Deployed as containerized app from Azure Container Registry

### 🔐 Security & Best Practices
- **Workload Identity**: Federated credentials eliminate static secrets
- **Key Vault Integration**: All sensitive data stored in Azure Key Vault
- **Private Endpoints**: Azure OpenAI accessible only via VNet
- **GitOps Workflow**: Auditable, version-controlled deployments
- **RBAC**: Azure AD integration with role-based access control

---

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
- Azure CLI (authenticated)
- Terraform >= 1.3.0
- kubectl
- Flux CLI
- Docker (for building Slack bot image)
- GitHub account
```

### 1. Deploy Infrastructure

```bash
cd terraform

# Initialize and deploy
terraform init
terraform apply -var-file="environments/dev.tfvars"

# Save the workload identity client ID (you'll need this!)
terraform output workload_identity_client_id
```

### 2. Configure kubectl

```bash
az aks get-credentials \
  --resource-group YOUR_RESOURCE_GROUP \
  --name YOUR_AKS_CLUSTER_NAME \
  --overwrite-existing
```

### 3. Add Secrets to Key Vault

```bash
# Slack bot token for Robusta
az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name slack-bot-token \
  --value "xoxb-YOUR-SLACK-BOT-TOKEN"

# Slack app token for Holmes bot
az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name slack-app-token \
  --value "xapp-YOUR-SLACK-APP-TOKEN"

# Holmes bot secret token (combined token)
az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name holmes-bot-secret-token \
  --value "xoxb-YOUR-BOT-TOKEN"

# Azure OpenAI API key (auto-retrieved and stored)
OPENAI_KEY=$(az cognitiveservices account keys list \
  --name YOUR_OPENAI_ACCOUNT_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --query key1 -o tsv)

az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name openai-api-key \
  --value "$OPENAI_KEY"
```

### 4. Build and Push Slack Holmes Bot Image

```bash
cd slack-holmes-bot

# Login to ACR
az acr login --name acrrobustadev

# Build and push image
docker build --platform linux/amd64 -t acrrobustadev.azurecr.io/slack-holmes-bot:latest .
docker push acrrobustadev.azurecr.io/slack-holmes-bot:latest
```

### 5. Setup Flux CD

```bash
# Create flux-system namespace
kubectl create namespace flux-system

# Create GitHub App for Flux authentication
# Follow: https://fluxcd.io/blog/2025/04/flux-operator-github-app-bootstrap/

# Create GitHub App secret
flux create secret githubapp flux-system \
  --namespace=flux-system \
  --app-id=YOUR_APP_ID \
  --app-installation-id=YOUR_INSTALLATION_ID \
  --app-private-key=/path/to/your-app.private-key.pem

# Install Flux components
flux install

# Apply FluxInstance
kubectl apply -f flux/clusters/dev/flux-instance.yaml

# Patch GitRepository to use GitHub provider
kubectl patch gitrepository flux-system -n flux-system --type=merge -p '{"spec":{"provider":"github"}}'
```

### 6. Verify Deployment

```bash
# Check Flux resources
flux get all

# Check all applications
kubectl get pods -n robusta
kubectl get pods -n holmesgpt
kubectl get pods -n slack-holmes-bot

# Verify secrets were synced
kubectl get secret robusta-slack-token -n robusta
kubectl get secret slack-holmes-bot-tokens -n slack-holmes-bot

# Check HelmRelease status
kubectl get helmrelease -n robusta
```

---

## ⚙️ Post-Deployment Configuration

After Terraform completes and infrastructure is provisioned, follow these steps to configure and deploy the applications.

### 1. Create Kubernetes Namespaces

```bash
kubectl create namespace robusta
kubectl create namespace flux-system
```

### 2. Add Slack Token to Key Vault

```bash
az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name slack-bot-token \
  --value "xoxb-YOUR-SLACK-BOT-TOKEN"

# Verify secret is stored
az keyvault secret list --vault-name YOUR_KEYVAULT_NAME -o table
```

### 3. Enable CSI Secret Store Driver (if not already enabled)

```bash
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --resource-group YOUR_RESOURCE_GROUP \
  --name YOUR_AKS_CLUSTER_NAME
```

**Note**: This may already be enabled by default in newer AKS versions.

### 4. Setup Flux with GitHub App

Install Flux Operator:

```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

Create GitHub App secret (follow [Flux Docs](https://fluxcd.io/blog/2025/04/flux-operator-github-app-bootstrap/)):

```bash
flux create secret githubapp flux-system \
  --namespace=flux-system \
  --app-id=YOUR_APP_ID \
  --app-installation-id=YOUR_INSTALLATION_ID \
  --app-private-key=/path/to/your-app.private-key.pem
```

Install Flux components:

```bash
flux install
```

Apply FluxInstance and configure GitHub provider:

```bash
kubectl apply -f flux/clusters/dev/flux-instance.yaml

kubectl patch gitrepository flux-system -n flux-system \
  --type=merge -p '{"spec":{"provider":"github"}}'
```

### 5. Update Workload Identity Client IDs

Get the Client ID from Terraform output:

```bash
cd terraform
CLIENT_ID=$(terraform output -raw workload_identity_client_id)
echo "Client ID: $CLIENT_ID"
```

Update these files with your Client ID:
- `flux/apps/robusta/serviceaccount.yaml`
- `flux/apps/robusta/secretproviderclass.yaml`
- `flux/apps/holmesgpt/serviceaccount.yaml`
- `flux/apps/holmesgpt/secretproviderclass.yaml`
- `flux/apps/slack-holmes-bot/serviceaccount.yaml`
- `flux/apps/slack-holmes-bot/secretproviderclass.yaml`

Commit and push:

```bash
git add .
git commit -m "Update workload identity client IDs for new deployment"
git push
```

### 6. Verify Flux Sync

```bash
# Check GitRepository sync
kubectl get gitrepository flux-system -n flux-system

# Check Kustomizations
kubectl get kustomizations -A

# Check Flux pods
kubectl get pods -n flux-system
```

### 7. Verify Secret Sync from Key Vault

```bash
# Check secret sync job
kubectl get jobs -n robusta

# Check secret was created
kubectl get secret robusta-slack-token -n robusta

# Check job logs
kubectl logs -n robusta -l job-name=keyvault-secret-sync
```

### 8. Verify Robusta Deployment

```bash
# Check HelmRelease
kubectl get helmreleases -n robusta

# Check pods
kubectl get pods -n robusta

# Check logs for Slack connection
kubectl logs -n robusta deployment/robusta-runner | grep -i slack
```

### 9. Test Robusta Alerts

Trigger a test alert with a crashing pod:

```bash
# Restart Robusta to ensure latest config
kubectl rollout restart deployment robusta-runner -n robusta
kubectl rollout restart deployment robusta-forwarder -n robusta

# Wait for rollout
kubectl rollout status deployment robusta-runner -n robusta

# Create a crashlooping pod (triggers CrashLoopBackOff alerts)
kubectl run crashloop-test --image=busybox --restart=Always -n default \
  -- /bin/sh -c "exit 1"
```

After a few restarts, you should see an alert in your Slack channel. Clean up:

```bash
kubectl delete pod crashloop-test -n default
```

---

## 📚 Detailed Setup Guide

### Step 1: Add Yourself to KeyVault-Robusta-Admins-dev Group

After Terraform creates the Azure AD group `KeyVault-Robusta-Admins-dev`, add yourself as a member to manage Key Vault secrets:

1. Go to Azure Portal → Azure AD → Groups
2. Find `KeyVault-Robusta-Admins-dev`
3. Add yourself as a member
4. Wait ~5 minutes for permissions to propagate

### Step 3: Enable CSI Secret Store Driver on AKS

```bash
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --resource-group YOUR_RESOURCE_GROUP \
  --name YOUR_AKS_CLUSTER_NAME
```

**Note**: This may already be enabled by default in newer AKS versions.

### Step 4: Create GitHub App for Flux

Follow the official Flux documentation: [Flux GitHub App Bootstrap](https://fluxcd.io/blog/2025/04/flux-operator-github-app-bootstrap/)

**Quick Steps:**
1. Go to: https://github.com/settings/apps/new
2. **App Name**: "Flux CD - AKS Robusta"
3. **Homepage URL**: https://fluxcd.io
4. **Webhook**: Uncheck "Active"
5. **Repository Permissions**:
   - Contents: Read and write
   - Metadata: Read-only
6. **Where can this GitHub App be installed?**: "Only on this account"
7. Click "Create GitHub App"
8. Generate private key (download .pem file)
9. Note App ID and Installation ID

### Step 5: Update Workload Identity Client IDs

**⚠️ CRITICAL**: If you destroy and recreate infrastructure, the workload identity client ID changes!

```bash
# Get the new client ID from Terraform
cd terraform
CLIENT_ID=$(terraform output -raw workload_identity_client_id)
echo "Client ID: $CLIENT_ID"

# Update these files with the new client ID:
# 1. flux/apps/robusta/serviceaccount.yaml (line 8)
# 2. flux/apps/robusta/secretproviderclass.yaml (line 20)
# 3. flux/apps/holmesgpt/serviceaccount.yaml (line 7)
# 4. flux/apps/holmesgpt/secretproviderclass.yaml (line 11)
# 5. flux/apps/slack-holmes-bot/serviceaccount.yaml (line 8)
# 6. flux/apps/slack-holmes-bot/secretproviderclass.yaml (line 12)

# Commit and push
git add flux/apps/*/serviceaccount.yaml flux/apps/*/secretproviderclass.yaml
git commit -m "Update workload identity client IDs for new deployment"
git push
```

### Step 6: Verify Flux Reconciliation

```bash
# Check GitRepository sync status
kubectl get gitrepository flux-system -n flux-system

# Should show:
# NAME          URL                                    AGE   READY   STATUS
# flux-system   https://github.com/user/repo           2m    True    stored artifact for revision 'refs/heads/main@sha1:...'

# Check Kustomizations
kubectl get kustomizations -A

# Check pods
kubectl get pods -n flux-system
```

### Step 7: Verify Secret Sync from Key Vault

```bash
# Check secret sync jobs completed
kubectl get jobs -n robusta
kubectl get jobs -n holmesgpt
kubectl get jobs -n slack-holmes-bot

# Verify secrets were created
kubectl get secret robusta-slack-token -n robusta
kubectl describe secret robusta-slack-token -n robusta

# Check job logs if needed
kubectl logs -n robusta -l job-name=keyvault-secret-sync
```

### Step 8: Verify Application Deployments

```bash
# Check HelmRelease status
kubectl get helmreleases -n robusta
# Should show: NAME: robusta, READY: True, STATUS: Helm install succeeded...

# Check Robusta pods
kubectl get pods -n robusta
# Should show: robusta-runner and robusta-forwarder Running

# Check Robusta logs for Slack sink
kubectl logs -n robusta deployment/robusta-runner | grep -i slack
# Should show: Adding SlackSinkConfigWrapper sink named main_slack_sink

# Check Holmes GPT
kubectl get pods -n holmesgpt
kubectl logs -n holmesgpt deployment/holmesgpt-holmes

# Check Slack Holmes Bot
kubectl get pods -n slack-holmes-bot
kubectl logs -n slack-holmes-bot -l app=slack-holmes-bot
# Should show: "Starting Holmes Slack Bot", "Bolt app is running!"
```

---

## 🔧 Configuration

### Repository Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── aks/                    # AKS cluster with workload identity
│   │   ├── key_vault/              # Azure Key Vault configuration
│   │   ├── networking/             # VNet and subnet configuration
│   │   ├── openai/                 # Azure OpenAI with private endpoint
│   │   └── acr/                    # Azure Container Registry
│   ├── environments/
│   │   └── dev.tfvars              # Development environment variables
│   ├── provider.tf                 # Terraform provider configuration
│   ├── main.tf                     # Main infrastructure orchestration
│   ├── outputs.tf                  # Output values (including client ID)
│   └── variables.tf                # Variable definitions
│
├── flux/
│   ├── apps/
│   │   ├── robusta/
│   │   │   ├── namespace.yaml
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── secretproviderclass.yaml
│   │   │   ├── job.yaml            # Key Vault secret sync job
│   │   │   ├── helmrepository.yaml
│   │   │   ├── helmrelease.yaml
│   │   │   └── configmap.yaml
│   │   ├── holmesgpt/
│   │   │   └── (similar structure)
│   │   └── slack-holmes-bot/
│   │       ├── namespace.yaml
│   │       ├── serviceaccount.yaml
│   │       ├── secretproviderclass.yaml
│   │       ├── job.yaml
│   │       └── deployment.yaml
│   └── clusters/
│       └── dev/
│           ├── flux-instance.yaml  # Flux configuration
│           └── kustomization.yaml
│
├── slack-holmes-bot/
│   ├── app.py                      # Slack bot application code
│   ├── Dockerfile
│   ├── requirements.txt
│   └── README.md
│
└── diagrams/
    └── robusta-holmes.png          # Architecture diagram
```

### Key Configuration Files

<details>
<summary><b>🔑 Values That May Need Updating</b></summary>

#### 1. Azure Subscription ID
**File**: `terraform/environments/dev/terraform.tfvars`
```hcl
subscription_id = "YOUR_AZURE_SUBSCRIPTION_ID"  # TODO: Replace this with your Azure subscription ID
```

#### 2. Tenant ID
**Files**: Service accounts and SecretProviderClass in all 3 apps
```yaml
azure.workload.identity/tenant-id: "YOUR_AZURE_TENANT_ID"  # TODO: Replace this with your Azure tenant ID
```

#### 3. Workload Identity Client ID
**Files**: Service accounts and SecretProviderClass in all 3 apps
```yaml
azure.workload.identity/client-id: "YOUR_WORKLOAD_IDENTITY_CLIENT_ID"  # TODO: Replace this with your workload identity client ID (output from Terraform)
```

**⚠️ This value changes when infrastructure is destroyed/recreated!**

#### 4. Azure OpenAI Endpoint
**File**: `flux/apps/holmesgpt/configmap.yaml`
```yaml
- name: AZURE_API_BASE
  value: "https://YOUR_OPENAI_ACCOUNT_NAME-XXXXXX.openai.azure.com/"
```

Get the correct endpoint:
```bash
az cognitiveservices account show \
  --name YOUR_OPENAI_ACCOUNT_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --query properties.endpoint -o tsv
```

#### 5. GitHub Repository
**File**: `flux/clusters/dev/flux-instance.yaml`
```yaml
url: YOUR_GITHUB_REPOSITORY_URL  # TODO: Replace this with your GitHub repository URL
ref:
  name: refs/heads/main  # Branch to watch
```

</details>

---

## 🎮 Usage

### Testing Robusta Alerts

#### Create a test alert:
```bash
# Create a pod that crashes
kubectl run test-crash --image=busybox --restart=Never -- exit 1

# This should trigger a Slack alert with:
# - Pod name and namespace
# - Crash reason
# - Container logs
# - Recent events
```

#### View Robusta logs:
```bash
kubectl logs -n robusta deployment/robusta-runner -f
kubectl logs -n robusta deployment/robusta-forwarder -f
```

### Testing Holmes GPT

#### Option 1: Via API (Port Forward)
```bash
# Forward Holmes service to localhost
kubectl port-forward -n holmesgpt svc/holmesgpt-holmes 5050:80

# Access API docs
open http://localhost:5050/docs

# Test investigation API
curl -X POST http://localhost:5050/api/investigate \
  -H "Content-Type: application/json" \
  -d '{
    "source": "cli",
    "title": "Test Investigation",
    "description": "Testing Holmes GPT analysis",
    "subject": {
      "name": "holmesgpt-holmes",
      "namespace": "holmesgpt",
      "kind": "Deployment"
    }
  }'
```

**Expected Response:**
```json
{
  "analysis": "...",
  "tool_calls": ["kubectl get deployment holmesgpt-holmes -n holmesgpt", ...],
  "key_findings": ["Deployment is healthy with 1/1 replicas", ...],
  "conclusions": "...",
  "next_steps": [...]
}
```

#### Option 2: Via Slack Bot
1. Tag `@Holmes Bot` in any Slack channel
2. Ask a question about your cluster: *"Why is pod X crashing?"*
3. Holmes analyzes using kubectl + AI and responds in thread

### Testing Slack Holmes Bot

```bash
# Check bot is running
kubectl get pods -n slack-holmes-bot

# View bot logs
kubectl logs -n slack-holmes-bot -l app=slack-holmes-bot -f

# Expected output:
# INFO:__main__:Starting Holmes Slack Bot
# INFO:__main__:Holmes API URL: http://holmesgpt-holmes.holmesgpt.svc.cluster.local:80
# INFO:slack_bolt.App:⚡️ Bolt app is running!
```

**In Slack:**
1. Go to any channel where the bot is installed
2. Mention `@Holmes Bot` with a question
3. Bot queries Holmes GPT and responds with analysis

---

## 🔐 Security Considerations

### Workload Identity Flow

```
1. Pod starts with service account annotation
   ↓
2. AKS injects OIDC token (signed by AKS OIDC issuer)
   ↓
3. Pod requests Azure AD token using OIDC token
   ↓
4. Azure validates OIDC token signature against AKS OIDC issuer
   ↓
5. Azure checks federated credential mapping:
   - Issuer matches AKS OIDC URL
   - Subject matches service account (system:serviceaccount:namespace:name)
   - Audience is api://AzureADTokenExchange
   ↓
6. Azure returns access token for managed identity
   ↓
7. Pod uses access token to access Key Vault
```

### Security Best Practices

✅ **Implemented:**
- Workload Identity (no static secrets in cluster)
- Azure Key Vault for all sensitive data
- Private endpoints for Azure OpenAI
- RBAC with Azure AD integration
- Network policies on AKS
- GitOps for auditable deployments

⚠️ **Recommended Additional Steps:**
- Enable pod security policies/standards
- Configure network policies between namespaces
- Set up Azure Policy for compliance
- Enable diagnostic logs for audit trail
- Implement image scanning in ACR
- Use Azure Defender for Kubernetes

---

## 📖 Support and Documentation

### Official Documentation
- **Robusta**: https://docs.robusta.dev/
- **Holmes GPT**: https://github.com/robusta-dev/holmesgpt
- **Flux CD**: https://fluxcd.io/docs/
- **Azure Workload Identity**: https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview
- **Azure AKS**: https://learn.microsoft.com/en-us/azure/aks/

### Slack Communities
- Robusta Community: https://bit.ly/robusta-slack
- Flux CD: https://cloud-native.slack.com (#flux)

### Getting Help

1. **Check the troubleshooting section** above
2. **Review Flux logs**: `kubectl logs -n flux-system deployment/kustomize-controller`
3. **Check application logs**: `kubectl logs -n <namespace> deployment/<app>`
4. **Verify GitOps sync**: `flux get all`
5. **Join community Slack** for real-time support

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Robusta** team for excellent Kubernetes monitoring platform
- **Holmes GPT** contributors for AI-powered troubleshooting
- **Flux CD** project for GitOps automation
- **Azure AKS** team for workload identity implementation

---

<div align="center">

**Made with ❤️ for the Kubernetes community**

⭐ Star this repo if you find it useful!

</div>
