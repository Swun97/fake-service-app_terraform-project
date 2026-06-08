# fake-service-app

A Terraform project that provisions a **multi-VPC AWS network topology** simulating an isolated microservice architecture for a retail banking application. Three independent VPCs — each representing a dedicated service boundary — are connected via VPC Peering with strict, least-privilege Security Group rules.

---

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────┐
│  Customer-Profile-VPC           │  10.0.0.0/16
│  ┌──────────────┐               │
│  │ Public Subnet│ 10.0.1.0/24   │──── IGW (Internet Gateway)
│  │  public-rtb  │               │
│  └──────────────┘               │
│  ┌──────────────┐               │
│  │Private Subnet│ 10.0.2.0/24   │
│  │  private-rtb │               │
│  └──────────────┘               │
└────────────┬────────────────────┘
             │ VPC Peering (customer ↔ account)
             ▼
┌─────────────────────────────────┐
│  Account-VPC                    │  192.168.0.0/16
│  ┌──────────────┐               │
│  │ Public Subnet│192.168.1.0/24 │──── IGW + NAT Gateway
│  │  public-rtb  │               │
│  └──────────────┘               │
│  ┌──────────────┐               │
│  │Private Subnet│192.168.2.0/24 │
│  │  private-rtb │               │
│  └──────────────┘               │
└────────────┬────────────────────┘
             │ VPC Peering (account ↔ statement)
             ▼
┌─────────────────────────────────┐
│  Statement-VPC                  │  172.16.0.0/16
│  ┌──────────────┐               │
│  │ Public Subnet│ 172.16.1.0/24 │──── IGW + NAT Gateway
│  │  public-rtb  │               │
│  └──────────────┘               │
│  ┌──────────────┐               │
│  │Private Subnet│ 172.16.2.0/24 │
│  │  private-rtb │               │
│  └──────────────┘               │
└─────────────────────────────────┘
```

Traffic flows **linearly**: `Customer → Account → Statement`. There is no direct peering between Customer and Statement VPCs.

---

## VPC Summary

| VPC | CIDR | Public Subnet | Private Subnet | NAT Gateway |
|-----|------|---------------|----------------|-------------|
| customer-profile-vpc | `10.0.0.0/16` | `10.0.1.0/24` | `10.0.2.0/24` | ✗ |
| account-vpc | `192.168.0.0/16` | `192.168.1.0/24` | `192.168.2.0/24` | ✓ |
| statement-vpc | `172.16.0.0/16` | `172.16.1.0/24` | `172.16.2.0/24` | ✓ |

---

## Security Group Rules

Each service only accepts traffic from its direct upstream — no cross-cutting access.

### customer-sg (Customer-Profile-VPC)

| Direction | Port | Protocol | Source |
|-----------|------|----------|--------|
| Ingress | 22 | TCP | Admin IP only |
| Ingress | 9091 | TCP | `0.0.0.0/0` (service endpoint) |
| Ingress | 9092 | TCP | `192.168.0.0/16` (account-vpc response) |
| Egress | All | All | `0.0.0.0/0` |

### account-sg (Account-VPC)

| Direction | Port | Protocol | Source |
|-----------|------|----------|--------|
| Ingress | 9092 | TCP | `10.0.0.0/16` (customer-vpc) |
| Ingress | 22 | TCP | `10.0.0.0/16` (customer-vpc) |
| Ingress | 9093 | TCP | `172.16.0.0/16` (statement-vpc response) |
| Egress | All | All | `0.0.0.0/0` |

### statement-sg (Statement-VPC)

| Direction | Port | Protocol | Source |
|-----------|------|----------|--------|
| Ingress | 9093 | TCP | `192.168.0.0/16` (account-vpc) |
| Ingress | 22 | TCP | `192.168.0.0/16` (account-vpc) |
| Egress | All | All | `0.0.0.0/0` |

---

## VPC Peering Connections

| Connection | Requester VPC | Accepter VPC | Purpose |
|------------|---------------|--------------|---------|
| `customer-account-peer` | customer-profile-vpc | account-vpc | Customer → Account service calls |
| `account-statement-peer` | account-vpc | statement-vpc | Account → Statement service calls |

> **Note:** There is no direct peering between `customer-profile-vpc` and `statement-vpc`. All communication is routed through `account-vpc`.

---

## Route Table Design

### Customer-Profile-VPC — Public Route Table
| Destination | Target |
|-------------|--------|
| `0.0.0.0/0` | Internet Gateway |
| `192.168.0.0/16` | customer-account-peer |

### Account-VPC — Public Route Table
| Destination | Target |
|-------------|--------|
| `0.0.0.0/0` | Internet Gateway |
| `10.0.0.0/16` | customer-account-peer |

### Account-VPC — Private Route Table
| Destination | Target |
|-------------|--------|
| `0.0.0.0/0` | NAT Gateway |
| `10.0.0.0/16` | customer-account-peer |
| `172.16.0.0/16` | account-statement-peer |

### Statement-VPC — Private Route Table
| Destination | Target |
|-------------|--------|
| `0.0.0.0/0` | NAT Gateway |
| `192.168.0.0/16` | account-statement-peer |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3
- AWS CLI configured with appropriate credentials
- IAM permissions for VPC, EC2, and networking resources

---

## Usage

```bash
# 1. Clone the repository
git clone https://github.com/Swun97/fake-service-app.git
cd fake-service-app

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply the infrastructure
terraform apply
```

---

## Input Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `customer_vpc_cidr` | CIDR block for Customer-Profile VPC | `10.0.0.0/16` |
| `account_vpc_cidr` | CIDR block for Account VPC | `192.168.0.0/16` |
| `statement_vpc_cidr` | CIDR block for Statement VPC | `172.16.0.0/16` |

---

## Project Structure

```
fake-service-app/
├── vpc.tf          # VPCs, Subnets, IGWs, NAT Gateways, Security Groups,
│                   # VPC Peering, and Route Tables
├── variables.tf    # Input variable declarations
├── outputs.tf      # Output values
└── README.md
```

---

## Design Decisions

**Three isolated VPCs instead of one** — Each service (customer-profile, account, statement) lives in its own VPC to enforce hard network boundaries. A compromised service cannot reach others beyond what the peering and security group rules explicitly permit.

**Linear peering topology** — Customer peers with Account; Account peers with Statement. Statement has no direct route to Customer. This mirrors a real microservice call chain and prevents unintended lateral access.

**NAT Gateways on Account and Statement** — Private subnets in these VPCs need outbound internet access (e.g. for pulling dependencies or reaching AWS APIs) without being directly reachable from the internet. The Customer VPC omits a NAT Gateway as its workload sits in the public subnet.

**Port-scoped Security Groups** — Each service binds to a dedicated port (9091, 9092, 9093), and ingress rules only allow traffic from the specific upstream VPC CIDR — not from `0.0.0.0/0`.

---

## Author

**Swun** — [github.com/Swun97](https://github.com/Swun97)
