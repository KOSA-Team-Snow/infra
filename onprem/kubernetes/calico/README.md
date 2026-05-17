# Calico Manifest

## 목적

이 디렉터리는 Kubernetes `v1.30.1` 클러스터에 Calico `v3.28.5`를 manifest 방식으로 설치하기 위한 파일을 관리한다.

Helm 기반 설치는 CRD chart/version mismatch와 CRD annotation 크기 문제로 표준 흐름에서 제외했다.

## 적용 위치

명령어는 Kubernetes API VIP에 접근 가능한 bastion에서 실행한다.

```bash
cd ~/kubernetes/calico
kubectl get --raw='/readyz?verbose'
```

로컬 저장소의 파일을 bastion으로 옮긴 뒤 적용한다.

## 파일 설명

- `custom-resources.yaml`: Calico 설치 설정. VXLAN, BGP Disabled, Pod CIDR `10.244.0.0/16`을 정의한다.
- `kubernetes-services-endpoint.yaml`: Tigera Operator가 Kubernetes Service IP 대신 API VIP `172.16.43.99:6443`을 바라보도록 한다.
- `kustomization.yaml`: 공식 Tigera Operator manifest와 팀 manifest를 함께 적용하기 위한 kustomize entrypoint.

## 적용 순서

기존 Helm 기반 Calico 잔재가 있다면 먼저 정리한다.

```bash
helm uninstall calico -n tigera-operator
kubectl delete namespace tigera-operator --ignore-not-found=true
kubectl delete namespace calico-system --ignore-not-found=true
kubectl get crd -o name | egrep 'tigera|calico|projectcalico' | xargs -r kubectl delete
```

이후 manifest를 적용한다.

```bash
kubectl apply -k .
```

`kubectl apply -k .`가 네트워크 문제로 공식 manifest 다운로드에 실패하면 아래 방식으로 bastion에 원본 manifest를 먼저 내려받아 적용한다.

```bash
curl -L -o tigera-operator.yaml \
  https://raw.githubusercontent.com/projectcalico/calico/v3.28.5/manifests/tigera-operator.yaml

kubectl apply --server-side --force-conflicts -f tigera-operator.yaml
kubectl apply -f kubernetes-services-endpoint.yaml
kubectl apply -f custom-resources.yaml
```

## 검증

```bash
kubectl get pods -n tigera-operator -o wide
kubectl get pods -n calico-system -o wide
kubectl get nodes -o wide
kubectl describe installation.operator.tigera.io default
```

정상 상태에서는 모든 Kubernetes 노드가 `Ready`로 전환된다.
