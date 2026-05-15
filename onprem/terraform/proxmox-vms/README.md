# Proxmox VM Terraform

## Purpose

This stack manages the on-prem VM layer for the team infrastructure.

Terraform is responsible for:

- Cloning VMs from the existing Ubuntu cloud-init template `9100`
- Setting CPU, memory, disk size, VLAN tag, static IP, and cloud-init SSH user
- Creating Kubernetes control-plane/worker VMs plus bastion, load balancer, monitoring, ArgoCD, and MariaDB VMs
- Generating the Ansible inventory consumed by `ansible/playbooks`

Terraform is not responsible for:

- pfSense VM creation or firewall/router configuration
- kubeadm init/join
- HAProxy and Keepalived configuration
- MetalLB, ArgoCD, and Monitoring stack deployment

## Prerequisites

- Proxmox API token with VM clone/config permissions
- Template VM `9100` exists on `kosa-team3-01`
- Template disk and cloud-init disk are on Ceph datastore `TEAM3`
- Every target node has a working VLAN-aware `vmbr0`
- SSH public key exists at `~/.ssh/id_rsa.pub`

## Usage

Start with the one-VM test file first.

```bash
cd terraform/proxmox-vms
cp terraform.tfvars.test.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

After the test VM boots and SSH works, switch to the full plan.

```bash
cd terraform/proxmox-vms
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Keep `terraform.tfvars` out of git because it contains the Proxmox API token.

After apply, Terraform writes:

```text
ansible/inventories/onprem/hosts.yml
```

Then run the Ansible bootstrap:

```bash
cd ../../ansible
ansible-playbook playbooks/k8s-prereq.yml
```

## Notes

The provider used here is `bpg/proxmox`. The VM resource uses a `clone` block, cloud-init `initialization`, and `network_device.vlan_id`.
