# 🚀 AWS CI/CD Pipeline Demonstration

A Node.js boilerplate application demonstrating a fully automated CI/CD pipeline on AWS using **CodePipeline**, **CodeBuild**, and **CodeDeploy** — triggered automatically on every GitHub push.

---

## 📐 Architecture

```
GitHub (push)
     │
     ▼ (CodeStar Connection - event based)
┌─────────────────┐
│  CodePipeline   │  ← Orchestrates the entire flow
└─────────────────┘
     │
     ├──▶ Stage 1: Source
     │         └── Pulls code from GitHub
     │               └── Artifact (CODE_ZIP) → S3
     │
     ├──▶ Stage 2: Build (AWS CodeBuild)
     │         └── Reads buildspec.yaml
     │               ├── npm install
     │               └── Packages artifact → S3
     │
     └──▶ Stage 3: Deploy (AWS CodeDeploy)
               └── Reads appspec.yml
                     ├── BeforeInstall   → stop_server.sh
                     ├── AfterInstall    → install_deps.sh
                     ├── ApplicationStart→ start_server.sh
                     └── ValidateService → validate_service.sh
```

---

## 🛠️ AWS Services Used

| Service | Purpose |
|---|---|
| **CodePipeline** | Orchestrates the full CI/CD workflow |
| **CodeBuild** | Builds and packages the application |
| **CodeDeploy** | Deploys the application to EC2 |
| **S3** | Stores build artifacts between stages |
| **EC2** | Hosts the running Node.js application |
| **IAM** | Roles and permissions for each service |
| **CodeStar Connection** | Connects GitHub to CodePipeline via events |

---

## 📁 Project Structure

```
├── index.js                  # App entry point (Express server)
├── config/
│   └── Database.js           # MongoDB connection
├── controllers/
│   └── authController.js     # Auth logic
├── middlewares/
│   └── verifyUser.js         # JWT middleware
├── models/
│   └── User.js               # Mongoose user model
├── routes/
│   └── authRoutes.js         # Auth routes
├── scripts/                  # CodeDeploy lifecycle hook scripts
│   ├── stop_server.sh        # BeforeInstall - stops running app
│   ├── install_deps.sh       # AfterInstall - installs npm packages
│   ├── start_server.sh       # ApplicationStart - starts app via PM2
│   └── validate_service.sh   # ValidateService - health check
├── appspec.yml               # CodeDeploy deployment instructions
├── buildspec.yaml            # CodeBuild build instructions
└── .env-example              # Environment variable template
```

---

## ⚙️ CI/CD Configuration Files

### `buildspec.yaml` — CodeBuild Instructions
Defines how CodeBuild builds the application:
- **install** phase: sets Node.js runtime version
- **pre_build** phase: runs `npm install`
- **build** phase: runs build commands
- **post_build** phase: cleanup
- **artifacts**: packages all files and uploads to S3

### `appspec.yml` — CodeDeploy Instructions
Defines how CodeDeploy deploys to EC2:
- **files**: copies app files to `/home/ubuntu/app`
- **permissions**: sets correct file ownership
- **hooks**: runs lifecycle scripts in order

> ⚠️ CodeDeploy requires exactly `appspec.yml` — not `appspec.yaml`

---

## 🪝 CodeDeploy Lifecycle Hooks

Scripts run in this exact order during every deployment:

```
BeforeInstall     → scripts/stop_server.sh
                    Stops the running PM2 process gracefully

AfterInstall      → scripts/install_deps.sh
                    Runs npm install --production

ApplicationStart  → scripts/start_server.sh
                    Starts app with PM2 process manager

ValidateService   → scripts/validate_service.sh
                    Curls localhost:3000 to confirm app is healthy
```

---

## 🏗️ Infrastructure Setup

### EC2 Instance
- **OS**: Ubuntu 26 (Resolute)
- **Type**: t2.micro
- **Ports**: 22 (SSH), 3000 (Node.js)
- **Tag**: `Environment: dev` (used by CodeDeploy to find instance)
- **IAM Role**: `EC2-CodeDeploy-Role` with S3 read access

### Software Installed on EC2
```bash
# CodeDeploy Agent
sudo apt install ruby3.2  # required dependency
sudo ./install auto       # installs codedeploy-agent

# Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# PM2 (process manager)
sudo npm install -g pm2
```

> 💡 **Ubuntu 26 Note**: The AWS CodeDeploy install script does not yet support Ruby 3.3 (which ships with Ubuntu 26). Fix: add `'3.3'` to the supported versions array in the install script, and install `ruby3.2` to satisfy the `.deb` package dependency.

---

## 🔐 IAM Roles Created

| Role | Used By | Policies |
|---|---|---|
| `EC2-CodeDeploy-Role` | EC2 Instance | AmazonEC2RoleforAWSCodeDeploy, AmazonS3ReadOnlyAccess |
| `CodeDeploy-Service-Role` | CodeDeploy | AWSCodeDeployRole |
| `AWSCodePipelineServiceRole-...` | CodePipeline | Auto-created |
| `codebuild-...-service-role` | CodeBuild | Auto-created |

---

## 🔄 How the Pipeline Triggers

Every `git push` to the `main` branch:

1. GitHub notifies AWS via **CodeStar Connection** (event-based, not polling)
2. **CodePipeline** picks up the change and starts execution
3. **CodeBuild** pulls the source, runs `buildspec.yaml`, uploads artifact to S3
4. **CodeDeploy** pulls the artifact, runs `appspec.yml` hooks on EC2
5. App is live at `http://<EC2-PUBLIC-IP>:3000`

---

## 🚀 Getting Started

### Prerequisites
- AWS Account
- GitHub Account
- Node.js 18+

### Environment Variables
Copy `.env-example` to `.env` and fill in your values:
```
PORT=3000
MONGO_URI=your_mongodb_connection_string
API_KEY=your_api_key
```

### Local Development
```bash
npm install
npm run dev
```

---

## 🧹 AWS Resource Cleanup

To avoid charges, delete resources in this order:

```
1. CodePipeline        → delete pipeline
2. CodeBuild           → delete build project
3. CodeDeploy          → delete deployment group → delete application
4. EC2                 → terminate instance
5. Security Group      → delete
6. S3                  → empty buckets first → delete both buckets
7. IAM Roles           → delete all 4 roles
8. CodeStar Connection → delete GitHub connection
9. Key Pair            → delete
```

> ⚠️ Always empty S3 buckets before deleting them

---

## 📚 Key Learnings & Gotchas

| Issue | Root Cause | Fix |
|---|---|---|
| CodeDeploy agent install fails on Ubuntu 26 | Ruby 3.3 not in supported versions list | Add `'3.3'` to install script + install `ruby3.2` |
| `appspec.yml` not found | Named file `appspec.yaml` | CodeDeploy requires exactly `.yml` extension |
| CodeBuild can't reach RDS | Runs outside VPC by default | Configure CodeBuild VPC settings |
| `InvalidSignatureException` | Clock skew between EC2 and AWS | Sync EC2 clock via NTP |

---

## 📖 DVA-C02 Exam Concepts Demonstrated

- ✅ CodeDeploy Agent installation and configuration
- ✅ `appspec.yml` lifecycle hooks (BeforeInstall → AfterInstall → ApplicationStart → ValidateService)
- ✅ `buildspec.yaml` phases (install → pre_build → build → post_build → artifacts)
- ✅ CodePipeline event-based triggering via CodeStar Connection
- ✅ S3 as artifact store between pipeline stages
- ✅ IAM roles for each service (least privilege principle)
- ✅ EC2 instance tagging for CodeDeploy deployment groups
- ✅ PM2 as process manager for Node.js in production

---

## 👨‍💻 Author

Built as part of AWS Developer Associate (DVA-C02) exam preparation.
