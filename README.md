# EKS Production Platform

Terraform foundation for isolated dev, staging, and production EKS clusters. It
provides a stable, On-Demand system node group and a separate Karpenter pool for
application capacity.

## What is included

- EKS control-plane logging, KMS encryption for Kubernetes secrets, private API
  endpoints, and EKS access entries.
- EKS-managed VPC CNI, CoreDNS, kube-proxy, EBS CSI, and Pod Identity Agent.
- Metrics Server for CPU/memory HPA metrics.
- Karpenter with interruption handling, an application-only NodePool, Spot and
  On-Demand capacity, and an aggregate vCPU limit.
- Namespace-scoped DevOps, developer, and read-only Kubernetes RBAC; separate
  cluster-admin and platform-automation roles.
- Encrypted S3 remote state configuration examples using native S3 lock files.
  The state bucket is created and secured outside this repository.

## Before deploying

1. Use Terraform 1.10 or later, AWS CLI v2, Helm, and `kubectl`.
2. Provide an AWS identity with the infrastructure permissions needed to create
   the VPC, EKS, IAM, KMS, CloudWatch, SQS, EventBridge, and optional budgeted
   add-on resources.
3. Create and secure the remote-state bucket outside Terraform. Enable S3
   versioning, encryption, and public-access blocking.
4. Copy the environment's `backend.hcl.example` to `backend.hcl` and enter the
   bucket details. `backend.hcl` is ignored by Git.
5. Replace the IAM role and namespace placeholders in that environment's
   `terraform.tfvars`. Plans reject placeholder role ARNs and invalid/system
   namespaces.
6. Make sure Terraform can reach the private EKS API endpoint. Run the add-on
   phase from a VPC-connected runner, VPN, or equivalent network.

New cluster deployments have two Terraform phases because Helm cannot connect
to an EKS API endpoint until the control plane and system node group exist.
Detailed commands, access requirements, upgrade procedures, and recovery steps
are in [OPERATIONS.md](./OPERATIONS.md).

## Architecture and cost

The managed node group is the fixed On-Demand system pool; CoreDNS, Metrics
Server, and the Karpenter controller are scheduled there. Karpenter provisions
only application nodes. Applications must opt into its application label and
taint; HPA scales pods, while Karpenter adds/removes nodes for unschedulable
pods.

## How the components connect

Each environment root composes the same modules with its own variables, AWS
region, and Terraform state. The infrastructure dependency flow is:

```text
environment root
  ├── vpc ──> eks cluster ──> fixed system node group ──> addons
  └── cost-controls (account-level AWS Budgets; independent of the cluster)
```

The VPC module passes its VPC ID and private subnet IDs to EKS and the add-ons.
The EKS module passes its cluster name to the node group. The add-ons module
receives the cluster name/version, VPC and subnet details, and system node
group name; it looks up the cluster endpoint and certificate through the AWS
EKS API for Helm. The system node group name input orders add-on installation
after the nodes exist. The add-ons module installs EKS-managed components,
Pod Identity associations, Helm releases, namespace RBAC, and Karpenter
resources.

At runtime, the main paths are:

- The VPC CNI assigns pod networking and IP addresses; kube-proxy installs
  service-network rules; CoreDNS resolves cluster service names. These are
  EKS-managed add-ons. CoreDNS is pinned to system nodes; the CNI and kube-proxy
  DaemonSets run on eligible nodes, including Karpenter nodes.
- HPA reads CPU/memory metrics from Metrics Server and adjusts pod replicas.
  Karpenter watches for pods that cannot be scheduled, then uses its
  [`EC2NodeClass`](./terraform/modules/addons/charts/karpenter-resources/templates/ec2nodeclass.yaml)
  and [`NodePool`](./terraform/modules/addons/charts/karpenter-resources/templates/nodepool.yaml)
  to launch application nodes in tagged private subnets. The application label
  and taint keep that capacity separate from the system node group.
- EventBridge sends EC2 interruption and health events to Karpenter's SQS
  queue. The controller reads the queue and coordinates node disruption.
- The EBS CSI controller uses AWS permissions to provision and attach EBS
  volumes for Kubernetes persistent volume claims.
- If enabled, AWS Load Balancer Controller watches Kubernetes Ingress and
  Service resources and manages AWS load balancers. NGINX ingress is a
  separate in-cluster ingress controller; its `LoadBalancer` Service and
  ingress classes/annotations must be configured for the intended AWS
  load-balancer path.

## IAM, Kubernetes access, and workload identity

These are separate identity paths: EKS Access Entries authenticate people and
automation to the Kubernetes API; Pod Identity gives selected Kubernetes
service accounts AWS API permissions; EC2 instance roles give nodes the
permissions needed to join and operate. They are not interchangeable.

```text
person or CI -> external IAM role -> EKS Access Entry
             -> EKS access policy (admins) or Kubernetes group -> RoleBinding/Role
AWS-enabled pod -> Kubernetes service account -> Pod Identity association -> IAM role -> AWS API
EC2 node -> instance profile role -> AWS API
```

| Component or principal | IAM identity and how it is assumed | Access granted by this repository |
| --- | --- | --- |
| [EKS control plane](./terraform/modules/eks/main.tf) | `${project}-${environment}-eks-cluster-role`, trusted by `eks.amazonaws.com` | AWS-managed `AmazonEKSClusterPolicy` for EKS control-plane operations. This is not a pod or team role. |
| [System managed-node-group instances](./terraform/modules/node-group/main.tf) | `${project}-${environment}-general-role`, trusted by EC2 | `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly`; used by the instances for node operations, CNI, and image pulls. |
| [VPC CNI (`aws-node`)](./terraform/modules/addons/main.tf) | No separate CNI role association is configured; it uses the node instance role | `AmazonEKS_CNI_Policy` is attached to both the system node role and Karpenter node role so CNI can operate on both pools. Migrating CNI to its own Pod Identity role is future hardening, not current behavior. |
| [Karpenter controller (`kube-system/karpenter`)](./terraform/modules/addons/karpenter.tf) | `${cluster}-karpenter-controller`; EKS Pod Identity association for this exact namespace/service account | A custom controller policy for scoped EC2 discovery and provisioning, passing only the Karpenter node role, reading the interruption SQS queue, describing this EKS cluster, and required SSM/pricing lookups. |
| [Karpenter-provisioned EC2 nodes](./terraform/modules/addons/karpenter.tf) | `${cluster}-karpenter-node`; EC2 assumes this role from the `EC2NodeClass`. It is also registered as an EKS `EC2_LINUX` access entry. | `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryPullOnly`, and `AmazonSSMManagedInstanceCore`. This is a node role, not an application workload role. |
| [EBS CSI controller (`kube-system/ebs-csi-controller-sa`)](./terraform/modules/addons/pod-identity.tf) | `${project}-${environment}-ebs-csi-role`; EKS Pod Identity association | AWS-managed `AmazonEBSCSIDriverPolicy` for EBS volume lifecycle operations, attached in [iam-roles.tf](./terraform/modules/addons/iam-roles.tf). |
| [AWS Load Balancer Controller (`kube-system/aws-load-balancer-controller`)](./terraform/modules/addons/aws-lbc.tf), optional | `${project}-${environment}-aws-lbc-role`; EKS Pod Identity association, created only when enabled | The module's custom policy for EC2 security-group and Elastic Load Balancing operations. |
| [CoreDNS and kube-proxy](./terraform/modules/addons/main.tf) | No dedicated AWS IAM role or Pod Identity association | EKS-managed add-ons; they use Kubernetes permissions and do not receive AWS workload permissions here. |
| [Pod Identity Agent](./terraform/modules/addons/main.tf) | No component-specific role association; it runs on nodes and uses the node role's worker permissions to reach EKS Auth | Delivers credentials only for the explicit Pod Identity associations listed above. |
| [Metrics Server](./terraform/modules/addons/metrics-server.tf), [team RBAC](./terraform/modules/addons/team-rbac.tf), [cert-manager](./terraform/modules/addons/cert-manager.tf), and [NGINX ingress](./terraform/modules/addons/nginx-ingress.tf) | No dedicated AWS IAM role is configured for these components | They use Kubernetes service accounts and Kubernetes permissions; they do not receive AWS permissions from this configuration. If cert-manager will use Route 53 DNS challenges, add a narrowly scoped AWS identity and configure the issuer first. |
| Platform automation and break-glass admin | Two externally created IAM roles set in `cluster_access_roles` | [EKS Access Entries](./terraform/modules/eks/main.tf) plus the EKS-managed `AmazonEKSClusterAdminPolicy` at cluster scope. The role trust policies and AWS permissions to assume these roles are managed outside this repository. |
| DevOps, developers, and read-only users | Three distinct externally created IAM roles set in `cluster_access_roles` | EKS Access Entries map them to `eks:devops`, `eks:developers`, and `eks:read-only`; the [team RBAC chart](./terraform/modules/addons/charts/team-rbac) binds those groups to namespace-scoped Roles. DevOps can operate workloads (including `pods/exec`); developers cannot use `pods/exec` or read Secrets; read-only users cannot modify resources. |

The three Pod Identity associations above are restricted in their IAM trust
policies by AWS account, cluster, namespace, and service-account name. The
Pod Identity Agent EKS add-on is installed to deliver those credentials. This
repository does **not** create an IAM OIDC provider or use IRSA. EKS Pod
Identity is the configured workload-to-AWS mechanism; EKS Access Entries are
the configured human/automation-to-Kubernetes mechanism. The Helm provider
uses the active Terraform AWS identity to obtain a cluster token, so run
Terraform under the platform automation role (or another principal with a
valid access entry) from a network that can reach the private EKS endpoint.

The five team/platform IAM roles are input ARNs, not roles created here. Set
distinct real ARNs in each environment's `terraform.tfvars`; their trust
relationships and how users assume them must be provisioned in the identity
system/account. Application pods also receive **no AWS role automatically**.
For an application that needs AWS APIs, create a dedicated service account and
least-privilege Pod Identity association (or deliberately implement IRSA with
an OIDC provider); do not grant application pods the broader node role.

## Repository and environment wiring

- `terraform/environments/{dev,staging,production}` are independent Terraform
  roots and states. Each root passes its own inputs to the same VPC, EKS,
  node-group, add-ons, and cost-controls modules; the environments do not
  depend on or share state with one another.
- `terraform/modules/vpc` creates public/private subnets and NAT routing. Its
  private subnet tags are consumed by EKS and used by Karpenter discovery.
- `terraform/modules/eks` creates the cluster, control-plane role, logging,
  encryption, and team access entries/policy associations.
- `terraform/modules/node-group` creates the fixed system capacity and its
  instance role. It consumes the EKS cluster name and VPC private subnets.
- `terraform/modules/addons` consumes the cluster, VPC, private subnets,
  availability zones, and system node group. Its local charts live in
  `terraform/modules/addons/charts`.
- `terraform/modules/cost-controls` creates optional account-level budgets; it
  does not depend on Kubernetes resources.
- `scripts` invoke an environment root for initialization, validation,
  planning, and applying. A first deployment uses the foundation scripts for
  VPC/EKS/system nodes before the full add-on scripts, because Helm needs a
  reachable cluster API.
- `OPERATIONS.md` contains deployment, access, upgrade, cost, and recovery
  procedures. `IMPLEMENTATION_SUMMARY.md` is a concise inventory and lists
  external prerequisites and known limitations.

Dev and staging use one NAT gateway; production uses one per AZ. Karpenter's
CPU ceiling limits aggregate application capacity, **not spend**. Configure
`monthly_budget_usd` and `budget_alert_email` in each `terraform.tfvars` with
approved values before production. A zero amount disables the optional AWS
Budget; budget alerts do not stop charges.

The environment defaults currently target Kubernetes 1.37, which is within
EKS standard support according to the [EKS version lifecycle](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html).
For an already-running cluster, upgrade one Kubernetes minor version at a
time; do not apply the 1.37 target directly to an older cluster.

## Repository layout

- `terraform/environments/{dev,staging,production}`: independent roots, tfvars,
  and backend examples.
- `terraform/modules/{vpc,eks,node-group,addons,cost-controls}`: reusable
  platform modules.
- `scripts`: validation, plan/apply, and operational wrappers. There is no
  state-bucket bootstrap or state-copy backup script.
