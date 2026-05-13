## Terraform 구성

```
terraform/
├── modules/                # 재사용 가능한 부품들
│   ├── network/            # VPC, Subnet, NAT, IGW, Endpoint
│   ├── security/           # SG, NACL
│   ├── route53/            # Hosted zone, failover, health check
│   ├── s3/                 # 기존 버킷 import
│   ├── rds/                # RDS instance
│   ├── dms/                # DMS
│   ├── ecr/                # 기존 ECR import
│   ├── eks/                # EKS, Node Group, Add-on, IRSA
│   ├── alb-ingress/        # AWS Load Balancer Controller, ACM
│   ├── iam/                # Roles, OIDC
│   └── observability/      # CloudWatch
├── bootstrap/              # tfstate 버킷, lock 테이블 import용
└── envs/
    └── dr/                 # 실제 환경 (DR)
        ├── backend.tf
        ├── providers.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

### Network
```
terraform/modules/network/
├── README.md
├── versions.tf          # provider 버전 제약
├── variables.tf         # 입력 변수
├── outputs.tf           # vpc_id, subnet_ids, route_table_ids 등
├── vpc.tf               # VPC + IGW
├── subnet.tf            # 6개 서브넷
├── nat.tf               # EIP × 2, NAT × 2
├── route_table.tf       # 5개 RT + association
├── vpn.tf               # VGW, CGW, VPN Connection
├── vpc_endpoints.tf     # Gateway × 2, Interface × 5
└── locals.tf            # AZ, CIDR 매핑
```
### EKS
```
terraform/modules/eks/
├── README.md
├── versions.tf
├── variables.tf
├── outputs.tf
├── cluster.tf           # aws_eks_cluster, log group, KMS 연결
├── oidc.tf              # OIDC Provider (IRSA의 기반)
├── nodegroup.tf         # Managed Node Group
├── launch_template.tf   # 노드 OS-level 설정 (IMDSv2, EBS 등)
├── iam_cluster.tf       # Cluster Role
├── iam_node.tf          # Node Role
├── irsa.tf              # IRSA Role들 (flaskapp-sa, ALB Controller, ESO, Karpenter)
├── addons.tf            # vpc-cni, coredns, kube-proxy, ebs-csi
├── access_entry.tf      # IAM ↔ K8s RBAC
└── locals.tf

terraform/modules/k8s-bootstrap/   # Helm 설치 모듈
├── albc.tf
├── external_secrets.tf
├── karpenter.tf
├── metrics_server.tf
└── fluent_bit.tf
```

### Data
```
terraform/modules/
├── rds/
│   ├── README.md
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── main.tf              # aws_db_instance
│   ├── subnet_group.tf
│   ├── parameter_group.tf
│   ├── iam_monitoring.tf    # Enhanced Monitoring Role
│   └── snapshot_lambda.tf   # 월 스냅샷 자동화 (선택)
│
├── dms/
│   ├── README.md
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── instance.tf          # replication instance + subnet group
│   ├── endpoints.tf         # source + target
│   ├── task.tf              # replication task
│   ├── table_mappings.json
│   └── task_settings.json
│
└── s3/
    ├── README.md
    ├── versions.tf
    ├── variables.tf
    ├── outputs.tf
    ├── proddata.tf          # 기존 import + 정책 보강
    ├── tfstate.tf           # 기존 import + 정책 보강
    ├── lifecycle.tf
    └── policy.tf
```

### Security
```
terraform/modules/
├── iam/
│   ├── README.md
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── boundary.tf              # Permission Boundary
│   ├── identity_center.tf       # SSO Permission Sets
│   ├── github_oidc.tf           # GitHub OIDC Provider
│   ├── terraform_role.tf        # TerraformDeployRole
│   ├── ecr_push_role.tf         # GitHubActionsECRPushRole
│   ├── breakglass.tf            # 비상 대응 Role
│   ├── service_roles.tf         # EKS Cluster/Node, DMS, RDS Monitoring 등
│   └── policies/
│       ├── boundary.json
│       ├── eso_permissions.json
│       └── albc_permissions.json
│
├── kms/
│   ├── keys.tf                  # 5종 키 생성
│   ├── aliases.tf
│   ├── policies/
│   │   ├── rds.json
│   │   ├── s3.json
│   │   ├── secrets.json
│   │   ├── ebs.json
│   │   └── logs.json
│   └── alarms.tf                # 키 삭제 시도 알람
│
├── secrets/
│   ├── flaskapp_db.tf           # RDS 자동 관리 secret 참조
│   ├── api_keys.tf              # 외부 API 비밀
│   ├── rotation_lambda.tf       # 커스텀 회전 Lambda
│   └── policies.tf              # Resource Policy
│
└── security/
    ├── guardduty.tf
    ├── security_hub.tf
    ├── config.tf
    ├── access_analyzer.tf
    ├── cloudtrail.tf
    ├── waf.tf
    └── sns_alerts.tf
```

### 관측성
```
terraform/modules/observability/
├── README.md
├── versions.tf
├── variables.tf
├── outputs.tf
│
├── amp.tf                    # Prometheus Workspace
├── amg.tf                    # Grafana Workspace
├── container_insights.tf     # EKS Add-on
├── adot.tf                   # ADOT IRSA + Helm release
├── fluent_bit.tf             # Fluent Bit IRSA + Helm release
├── xray.tf                   # X-Ray Sampling Rule
│
├── alarms_infra.tf           # RDS, DMS, ALB, EKS Node Alarm
├── alarms_app.tf             # 로그 기반 + 비즈니스 메트릭 Alarm
├── alarms_security.tf        # Root use, BreakGlass, KMS deletion
├── alarms_cost.tf            # AWS Budgets
│
├── sns.tf                    # P1/P2/P3 Topic + 구독
├── slack_lambda.tf           # SNS → Slack Webhook Lambda
│
├── dashboards/
│   ├── dr-readiness.json
│   ├── failover-status.json
│   ├── app-performance.json
│   ├── infrastructure.json
│   └── security.json
│
└── grafana_dashboards.tf     # 위 JSON 파일을 Grafana에 import
```

### CI/CD
```
modules/<name>/
├── README.md                 # 자동 생성 (terraform-docs)
├── versions.tf               # required_providers
├── variables.tf              # 입력 변수
├── outputs.tf                # 출력
├── main.tf                   # 핵심 리소스
├── <feature>.tf              # 기능별 파일 분할 (선택)
├── iam.tf                    # 모듈 자체 IAM (있다면)
└── locals.tf                 # 내부 계산 값
```