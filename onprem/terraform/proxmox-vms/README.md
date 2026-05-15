# Proxmox VM Terraform

## 목적

이 Terraform 코드는 우리 팀 온프레미스 VM 레이어를 Proxmox cloud-init template 기반으로 생성한다.

Terraform으로 관리하는 범위:

- Ubuntu template VM `9000` clone
- Control Plane, Worker, Load Balancer, Bastion, Monitoring, ArgoCD, MariaDB VM 생성
- VMID, 배치 Proxmox 노드, CPU, Memory, Disk, VLAN tag, static IP, gateway, SSH key, cloud-init user 설정
- VM disk를 Ceph datastore `TEAM3`에 저장
- Ansible inventory를 `../../ansible/inventories/onprem/hosts.yml`로 자동 생성

Terraform에서 제외하는 범위:

- pfSense
- kubeadm init/join
- HAProxy/Keepalived 세부 설정
- MetalLB
- ArgoCD Application
- Monitoring stack 배포

## 파일 설명

| 파일 | 설명 |
| --- | --- |
| `versions.tf` | Terraform 및 provider 버전 요구사항 |
| `providers.tf` | Proxmox provider 접속 설정 |
| `variables.tf` | VM 목록, 기본 스펙, IP, VLAN, Proxmox 노드 배치 정의 |
| `main.tf` | Proxmox VM clone, cloud-init, disk, network, inventory 생성 리소스 |
| `outputs.tf` | VM 계획, inventory 경로, 역할 분리 결과 출력 |
| `terraform.tfvars.example` | 전체 VM 생성용 입력값 예시 |
| `terraform.tfvars.test.example` | 테스트 VM 1대 생성용 입력값 예시 |
| `templates/ansible-inventory.yml.tftpl` | Ansible inventory 생성 템플릿 |
| `.gitignore` | state, provider cache, 실제 `terraform.tfvars` 제외 |

## 실행 전 조건

- 관리 VM에 Terraform이 설치되어 있어야 한다.
- Proxmox API endpoint `https://172.16.30.11:8006/`에 접근 가능해야 한다.
- Proxmox API token에 VM clone/config 권한이 있어야 한다.
- Template VM `9000`이 `kosa-team3-01`에 있어야 한다.
- Template disk와 cloud-init disk가 Ceph datastore `TEAM3`에 있어야 한다.
- VM을 배치할 Proxmox 노드의 `vmbr0`가 VLAN-aware bridge로 정상 구성되어 있어야 한다.
- SSH public key가 `~/.ssh/id_rsa.pub`에 있어야 한다.

## 테스트 먼저 실행

전체 VM을 만들기 전에 테스트 VM 1대를 먼저 생성한다.

```bash
cd terraform/proxmox-vms
vi terraform.tfvars
terraform init
terraform plan
terraform apply
```

테스트 파일은 아래 VM 1대만 생성한다.

```text
250 tf-test-vlan30 kosa-team3-01 172.16.43.150 VLAN30
```

테스트가 끝나면 Terraform으로 테스트 VM을 삭제한다.

```bash
terraform destroy
```

## 전체 VM 생성

테스트 VM 생성과 SSH 접속이 성공한 뒤 전체 VM 생성을 진행한다.

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
terraform plan -parallelism=1
terraform apply -parallelism=1
```

`-parallelism=1`을 권장한다. 여러 VM full clone을 동시에 실행하면 Ceph/Proxmox에서 `TEAM3` storage lock timeout이 발생할 수 있다.

## 생성 VM 목록

| VMID | 이름 | Proxmox 노드 | IP | VLAN |
| --- | --- | --- | --- | --- |
| `201` | `k8s-cp-1` | `kosa-team3-01` | `172.16.43.100` | `30` |
| `202` | `k8s-cp-2` | `kosa-team3-02` | `172.16.43.101` | `30` |
| `203` | `k8s-cp-3` | `kosa-team3-03` | `172.16.43.102` | `30` |
| `211` | `k8s-worker-1` | `kosa-team3-01` | `172.16.43.110` | `30` |
| `212` | `k8s-worker-2` | `kosa-team3-02` | `172.16.43.111` | `30` |
| `213` | `k8s-worker-3` | `kosa-team3-03` | `172.16.43.112` | `30` |
| `221` | `lb-1` | `kosa-team3-04` | `172.16.42.100` | `20` |
| `222` | `lb-2` | `kosa-team3-05` | `172.16.42.101` | `20` |
| `231` | `bastion` | `kosa-team3-01` | `172.16.44.100` | `40` |
| `232` | `monitoring` | `kosa-team3-04` | `172.16.44.101` | `40` |
| `233` | `argocd` | `kosa-team3-03` | `172.16.44.102` | `40` |
| `241` | `mariadb-1` | `kosa-team3-05` | `172.16.43.160` | `30` |

## Apply 이후

Terraform output과 생성된 Ansible inventory를 확인한다.

```bash
terraform output
cat ../../ansible/inventories/onprem/hosts.yml
```

그 다음 Ansible로 VM 내부 사전 설정을 진행한다.

```bash
cd ../../ansible
ansible -m ping all
ansible-playbook playbooks/k8s-prereq.yml
ansible-playbook playbooks/lb-prereq.yml
```

## 문제 대응

`cfs-lock 'storage-TEAM3'` 또는 HTTP `596` timeout이 발생하면 잠시 기다린 뒤 아래 명령으로 다시 실행한다.

```bash
terraform apply -parallelism=1
```

Proxmox에는 VM이 있는데 Terraform state에는 없다면, Terraform이 생성 도중 끊긴 상태일 수 있다. 이 경우 import하거나, 부분 생성된 VM/disk를 정리한 뒤 다시 실행한다. 프로젝트 진행 속도를 우선하면 부분 생성된 VM을 정리하고 재실행하는 방식이 더 단순하다.
