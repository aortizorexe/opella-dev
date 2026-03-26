# Opella DevOps Technical Challenge: Azure Infrastructure as Code

This repository contains the solution for the Opella DevOps Technical Challenge. It demonstrates the provisioning of secure, reusable, and scalable Azure infrastructure using Terraform, orchestrated through a DevSecOps pipeline in GitHub Actions.

## 🎯 Objective & Architecture Overview

The primary goal of this implementation is to showcase Enterprise-grade Infrastructure as Code (IaC) practices. The architecture adheres to the **Separation of Concerns** principle by decoupling the infrastructure definition (this repository) from the reusable modules (external repository).

This environment (`dev`) provisions a foundational Hub-and-Spoke-ready network topology, compute resources, and secure storage, fully automated through a CI/CD pipeline that integrates Static Application Security Testing (SAST).

---

## 🏗️ Repository Structure & Modularity

### The Multi-Repository Strategy
To ensure true reusability and version control, the Terraform code is split across two repositories:
1. **[azure-modules](https://github.com/aortizorexe/azure-modules)**: A dedicated repository acting as an internal module registry.
2. **opella-dev (This Repo)**: The consumer repository (Caller) that defines the `dev` environment.

**Why this approach?**
In an enterprise setting, infrastructure modules should be treated as independent software products. By isolating modules in their own repository, we enable:
* **Independent Versioning:** Each module is versioned (`?ref=v1.0.0`) independently using Git tags. This guarantees that updates to a module do not inadvertently break existing Production deployments.
* **Future Module Artifacts:** This structure paves the way for publishing modules to private Terraform Cloud/Enterprise Registries or Azure Container Registries (Bicep/Terraform OCI artifacts) for strict access control.
* **Separation of Duties:** The Platform Engineering team can maintain the modules, while Application teams consume them via versioned references.

---

## 🌐 Addressing Challenge Requirements

### 1. Reusable Module Creation (The VNet Module)
The core of this challenge was to build a highly reusable Virtual Network module.

* **Design Flexibility:** The `azure-vnet` module was refactored from a monolithic design into a streamlined module. It uses a nested map variable (`vnets`) processed with Terraform's `flatten()` function. This allows consumers to declare multiple VNets and their respective Subnets in a single, declarative block without duplicating code.
* **Security Integrations:** The module supports `service_endpoints` out of the box. In this `dev` setup, the Storage Subnet explicitly enables the `Microsoft.Storage` service endpoint, demonstrating PaaS network isolation capabilities.
* **Outputs:** The module exports `vnet_ids` and `subnet_ids` as Maps. This is critical for cross-module referencing. For example, the NIC and Storage Account modules directly consume these outputs to attach themselves to the correct subnets without hardcoding IDs or using brittle `data` blocks.

### 2. Infrastructure Setup & Environment Strategy
* **Subscriptions vs. Resource Groups:**
  While this challenge uses Resource Groups (`rg-opella-network-001`, `rg-opella-compute-001`) to separate workloads within a single Free-Tier subscription, **the recommended enterprise approach is to use Subscriptions as the primary management boundary** (following the Azure Landing Zone conceptual architecture).
  * *Why Subscriptions?* Subscriptions provide strict IAM boundaries, separate billing/invoicing, and prevent API rate limits from impacting different environments (e.g., a noisy Dev environment taking down Prod due to throttling).
* **Tagging Governance:** A dedicated `azure-tags` module enforces a strict FinOps tagging baseline. The `tags_mandatory` object guarantees that no resource is provisioned without `CostCenter`, `Environment`, and `Owner` labels. This is enforced programmatically; if a caller omits a mandatory tag, the `terraform plan` will fail.

---

## 🔒 Security & Networking Considerations

### 1. Network Security Groups (NSGs) vs. Route Tables
In this `dev` environment, a Route Table is attached to the Application Subnet, forcing all outbound traffic to the Internet via a `0.0.0.0/0` route for practicality during the challenge.
* *Trade-off Acknowledgement:* A Production environment strictly requires **Network Security Groups (NSGs)** to control inbound/outbound traffic at the Subnet and NIC levels (Zero Trust). Furthermore, outbound traffic would ideally be routed through an Azure Firewall or NVA instead of directly to the internet.

### 2. Passwordless Authentication (Azure OIDC)
The GitHub Actions pipeline does **not** use static Client Secrets to authenticate with Azure. Instead, it leverages **OpenID Connect (OIDC)** federated credentials.
* *Why?* Client Secrets expire and are a major vector for credential leaks. OIDC allows GitHub to request short-lived, scoped access tokens directly from Microsoft Entra ID. The trust is explicitly bound to the `main` branch of this repository, enforcing the Principle of Least Privilege.

### 3. Ephemeral Configuration (No `.tfvars` in Git)
You will not find sensitive `.tfvars` files in this repository.
The configuration payload (including the VM Admin Password) is stored securely as a GitHub Secret and injected dynamically into the pipeline runner as an ephemeral `terraform.tfvars` file just before the `terraform plan` executes. This guarantees a completely stateless and secure repository.

---

## 🚀 DevSecOps Pipeline Lifecycle

The deployment is orchestrated via a GitHub Actions workflow (`.github/workflows/deploy.yml`) structured into distinct, security-focused jobs:

1. **Validation & SAST (`plan-and-scan`):**
   * Code formatting (`terraform fmt`) and syntax validation.
   * **Plan-based SAST (Checkov):** Instead of scanning static `.tf` files, the pipeline compiles the `tfplan` into JSON. Checkov audits this computed plan, catching vulnerabilities in runtime variables that static analysis misses.
   * Artifact generation: The immutable binary plan is uploaded for the next stage.
2. **Deployment (`terraform-apply`):**
   * Only triggers on the `main` branch.
   * **Environment Protection:** The job is linked to a GitHub Environment (`production-approval`). While the Free tier limits the use of "Required Reviewers" to the repository owner, in an Enterprise License scenario, this block mandates that a specific Team (e.g., `Cloud-Approvers`) or `CODEOWNERS` manually authorize the deployment via the GitHub UI before infrastructure is altered.

---

## 🧰 Tools & Processes for Clean Code

To maintain code quality and automate documentation, the following tools are integrated (or proposed) for this repository:
* **Terraform fmt / Validate:** Native formatting and syntax checking.
* **TFLint:** A Pluggable Terraform Linter to catch provider-specific errors (e.g., invalid Azure VM sizes).
* **Checkov / tfsec:** Static application security testing (SAST) for IaC.
* **terraform-docs:** *(Proposed)* An automated utility to generate markdown documentation from Terraform variables and outputs, ensuring the `README.md` of the modules is always synchronized with the code via pre-commit hooks.

***

### 👤 Author
**Anthony Ortiz**
*Prepared for the Opella DevOps Technical Challenge.*