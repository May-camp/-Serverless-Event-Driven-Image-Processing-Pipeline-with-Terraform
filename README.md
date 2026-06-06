# Serverless Event-Driven Image Processing Pipeline with Terraform

A production-grade, event-driven serverless infrastructure deployed on **AWS** that automatically generates optimized image thumbnails whenever a new image is uploaded to an Amazon S3 bucket. Built using **Terraform (Infrastructure as Code)** and **AWS Lambda (Python/Pillow)**.

## 🎯 Project Purpose & Architecture

In modern web applications (like E-commerce or Social Media sites), users often upload high-resolution images. Serving these large images directly slows down frontend performance and increases data transfer costs. 

This project solves that problem by implementing a decoupled, automated image resizing workflow that operates only when needed, minimizing cloud costs and operational overhead.

### Key Architectural Concepts:
* **Serverless Execution:** Powered by AWS Lambda, which scales automatically from zero to thousands of parallel requests, ensuring zero idle server costs.
* **Infrastructure as Code (IaC):** 100% automated provisioning via Terraform, preventing configuration drift and enabling repeatable deployments.
* **Cross-Compiled Layers:** Dynamically cross-compiles the C-extension dependent Python Pillow library into an AWS Lambda Layer optimized for the target AWS Linux runtime environment.

---

## 🛠️ Tech Stack & AWS Services Used

* **Cloud Provider:** Amazon Web Services (AWS)
* **Infrastructure as Code:** Terraform
* **Compute:** AWS Lambda (Python 3.12 Runtime)
* **Storage:** Amazon S3 (Source & Destination Buckets)
* **Security & Governance:** AWS IAM (Roles and Policies tailored to the Principle of Least Privilege)
* **Image Optimization:** Python Pillow Library

---

<img width="1408" height="768" alt="diagram" src="https://github.com/user-attachments/assets/b2aae7c2-02c7-400f-89e4-3ad340f25156" />


## 📂 Project Structure

```text
image-processor-project/
├── lambda/
│   └── lambda_function.py      # Core image optimization Python logic
└── terraform/
    ├── provider.tf             # AWS provider configuration
    ├── lambda.tf               # Core S3, IAM, Lambda, and Trigger definitions
    └── outputs.tf              # Target outputs for validation 

🚀 Deployment Guide to AWS
1. Prerequisites
Ensure you have the following installed and configured on your machine:

Terraform

AWS CLI installed and authenticated with valid credentials (aws configure)

2. Initialize the Working Directory
Prepare the backend configuration and download the official AWS provider plugins from HashiCorp registry:

Bash
cd terraform
terraform init
3. Review the Infrastructure Blueprint
Generate a speculative execution plan to review the structural changes Terraform will perform on your AWS account:

Bash
terraform plan
4. Deploy Infrastructure to AWS
Build the Pillow Layer dependency, zip the deployment package, and provision live AWS resources:

Bash
terraform apply -auto-approve
🧪 Verification & Testing
Once deployment completes successfully, Terraform will output your dynamically generated live AWS S3 bucket names.

Upload a high-resolution raw image to your newly created Source S3 Bucket via AWS CLI:

Bash
aws s3 cp my_large_photo.jpg s3://<your-source-bucket-name>/
Verify automated execution: S3 will automatically broadcast an ObjectCreated event notification to invoke the Lambda function asynchronously.

Check results: Navigate to your Destination S3 Bucket. An optimized 300x300 thumbnail version of your photo will be generated in the thumbnails/ prefix folder within seconds:

Bash
aws s3 ls s3://<your-destination-bucket-name>/thumbnails/
🔒 Security & Optimization Highlights
Principle of Least Privilege (PoLP): IAM policies strictly scope structural boundaries to grant the Lambda execution role precise access only to target Source/Destination buckets instead of standard blanket administrative tokens ("Resource": "*").

Memory Optimization: Uses Python's io.BytesIO data stream buffer to process images asynchronously inside the memory buffer before streaming payloads out to S3, bypassing localized disk-write bottlenecks and minimizing execution duration timeouts.
