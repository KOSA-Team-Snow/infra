# On-prem Ansible

## 목적

Terraform은 Proxmox VM을 생성하고 `inventories/onprem/hosts.yml` 인벤토리를 만든다.
Ansible은 생성된 VM 내부의 Kubernetes 사전 설정, control plane 초기화, kube-vip 구성, join 작업을 담당한다.

## 현재 표준 Playbook

- `playbooks/01_pre.yml`: apt/dpkg lock 정리 및 패키지 인덱스 사전 점검
- `playbooks/02_setup.yml`: Kubernetes 노드 공통 OS 설정, containerd, kubelet, kubeadm, kubectl 설치
- `playbooks/03_init.yml`: 임시 API VIP를 사용한 첫 번째 control plane 초기화
- `playbooks/03_kube_vip_handoff.yml`: kube-vip static pod 설치 및 임시 VIP 인계
- `playbooks/04_join.yml`: 추가 control plane join, 노드별 kube-vip manifest 설치, worker join, 최종 노드 확인
- `playbooks/05_verify_control_plane_failover.yml`: kube-vip manifest, kube-vip 컨테이너, kubeconfig, API VIP 응답 검증
- `playbooks/k8s-reset-first-control-plane.yml`: 첫 번째 control plane init 실패 후 정리용 helper
- `playbooks/k8s-reset-join-nodes.yml`: cp2/cp3/worker join 실패 후 정리용 helper
- `playbooks/lb-prereq.yml`: HAProxy/Keepalived 노드 패키지 준비
- `playbooks/lb-config.yml`: DMZ 로드밸런서 노드의 HAProxy/Keepalived 설정
Calico CNI는 Helm 방식 대신 manifest 방식으로 관리한다. 

## 변수 파일

- `inventories/onprem/group_vars/all/k8s.yml`: `onprem` 인벤토리 기준으로 로드되는 Kubernetes 공통 변수
- `group_vars/all/k8s.yml`: 이전 실행 방식과 호환하기 위해 남겨둔 변수 파일

## 실행 순서

Terraform으로 VM 생성을 마친 뒤 Ansible 실행 서버에서 진행한다.

```bash
cd ansible
ansible -m ping all
ansible-playbook playbooks/01_pre.yml
ansible-playbook playbooks/02_setup.yml
ansible-playbook playbooks/k8s-reset-first-control-plane.yml
ansible-playbook playbooks/03_init.yml
ansible-playbook playbooks/03_kube_vip_handoff.yml
ansible-playbook playbooks/04_join.yml
ansible-playbook playbooks/05_verify_control_plane_failover.yml
ansible-playbook playbooks/lb-prereq.yml
```

이미 control plane join을 완료한 상태라면 `04_join.yml`을 다시 실행하기보다 먼저 검증 playbook을 실행한다.

```bash
ansible-playbook playbooks/05_verify_control_plane_failover.yml
```

## 디버깅

join 실패 시 기본적으로 token과 certificate key가 숨겨진다.
원인 확인이 필요할 때만 임시로 로그를 노출한다.

```bash
ansible-playbook playbooks/04_join.yml -e hide_sensitive_logs=false
```

cp2/cp3 또는 worker join 실패 흔적이 남아 있으면 아래 helper로 정리한 뒤 재시도한다.

```bash
ansible-playbook playbooks/k8s-reset-join-nodes.yml
```

## 역할 구분

Ansible이 관리하는 범위:

- OS 패키지 준비
- swap 비활성화
- 커널 모듈 및 sysctl 설정
- containerd 설정
- kubelet, kubeadm, kubectl 설치
- 첫 번째 control plane의 임시 Kubernetes API VIP bootstrap
- kube-vip static pod manifest 설치
- 첫 번째 control plane 초기화
- 추가 control plane 및 worker join
- CNI 설치 전 kubeadm 클러스터 bootstrap
- bastion 기준 Calico CNI Helm 설치
- HAProxy/Keepalived 패키지 설치

Ansible이 현재 관리하지 않는 범위:

- Proxmox VM 생성
- pfSense 설정
- MetalLB 설치
- ArgoCD 애플리케이션 배포
- Monitoring stack 배포

## 참고용 Legacy Playbook

아래 파일들은 이전 실험 흐름 또는 대안 구현으로 남겨둔 파일이다. 현재 표준 실행 흐름에서는 사용하지 않는다.

- `playbooks/k8s-prereq.yml`: 이전 all-in-one Kubernetes 사전 설정
- `playbooks/kube-vip.yml`: standalone kube-vip manifest 설치
- `playbooks/k8s-init.yml`: 이전 kubeadm config 파일 기반 init