# Platform Implementation Summary

This repository contains the Terraform foundation for three isolated EKS
environments. It is intentionally not an AWS state-bucket bootstrapper: each
environment has a `backend.hcl.example`, and the operator supplies details for
an already-created, versioned S3 bucket.

## Included

- Reusable VPC, EKS, managed-node-group, and add-on modules.
- EKS control-plane logging, KMS secret encryption, private API defaults, and
  EKS access entries for automation, break-glass admin, DevOps, developers, and
  read-only access.
- EKS-managed VPC CNI, kube-proxy, CoreDNS, EBS CSI, and Pod Identity Agent.
- Namespace Role/RoleBinding RBAC, Pod Security Admission labels, and Metrics
  Server.
- Karpenter controller and CRDs, Pod Identity, interruption queue/events,
  AL2023 EC2NodeClass, and an application-only NodePool.
- Optional AWS Load Balancer Controller, cert-manager, and NGINX ingress. These
  are disabled by default; enable only the services required by the workload.
- Optional monthly AWS Budgets filtered by the activated `Environment` cost
  allocation tag; alerts are notifications, not a spending limit.
- Safe environment wrappers for init, validate, plan, and apply.

The component dependency flow, each IAM role and trust mechanism, the
Pod Identity versus EKS Access Entry distinction, and the environment/module
wiring are documented in the [README architecture and identity sections](./README.md#how-the-components-connect).

## Scaling and cost model

The managed node group is fixed On-Demand system capacity and is labeled
`platform.myapp.io/pool=system`, with a `CriticalAddonsOnly` taint. Karpenter
provisions a separate application pool, tainted so application manifests must
explicitly opt in. HPA scales pods; Karpenter adds nodes for unschedulable pods.
The Karpenter vCPU ceiling is an infrastructure guardrail, not a financial
budget. Configure account-level AWS Budgets using an approved amount and alert
destination.

Dev/staging use a shared NAT gateway; production has a NAT gateway per AZ.
Optional ingress and observability resources have recurring costs and should
be enabled deliberately.

## External operator inputs

Before any plan/apply, supply:

- A pre-created, secured, versioned S3 backend bucket per environment (or
  approved isolated keys) and each environment's local `backend.hcl`.
- Five distinct, real IAM role ARNs and valid application namespaces in
  `terraform.tfvars`.
- AWS permissions for infrastructure deployment and private-network access
  for the Helm provider.
- Approved production add-on/Karpenter/AMI versions, CPU limit, budget amount,
  and cost-alert destination.

Placeholder role ARNs and namespace names are rejected during planning.

## First apply and upgrades

The first cluster deployment uses a foundation phase for VPC, EKS, and the
system node group, followed by a full plan/apply for Kubernetes add-ons. This
is separate from remote-state setup. Subsequent changes use the regular plan
and apply wrappers. Upgrade EKS one minor version at a time; update compatible
add-ons and Karpenter only after reviewing their release/compatibility notes.
The detailed procedures are in [OPERATIONS.md](./OPERATIONS.md).

## Limitations to resolve before production

- No approved monthly budget or notification contact was supplied, so the
  optional `monthly_budget_usd` values default to zero and do not create
  budgets. Set an approved threshold and alert email before production. AWS
  Budget alerts are notifications, not a hard spend cap.
- S3 versioning is an external bucket prerequisite. Terraform does not create
  the bucket or a DynamoDB lock table.
- CNI IAM permissions remain attached to node roles for reliable node
  bootstrap. Consider a tested Pod Identity migration and then removal of
  legacy node-role CNI permissions as a separate hardening change.
- Application-specific monitoring/alerting, external metrics, backup/restore,
  and AWS Config/Security Hub controls are not supplied by this cluster
  foundation and must be designed for the workloads/account.
