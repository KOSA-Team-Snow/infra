output "vm_plan" {
  description = "VMs managed by this Terraform stack."
  value = {
    for name, vm in var.vms : name => {
      vm_id     = vm.vm_id
      node_name = vm.node_name
      ip        = vm.ip
      vlan_id   = vm.vlan_id
      groups    = vm.ansible_groups
    }
  }
}

output "ansible_inventory" {
  description = "Generated Ansible inventory path."
  value       = local_file.ansible_inventory.filename
}

output "managed_scope" {
  description = "Responsibility split for this stack."
  value = {
    terraform = [
      "Clone VMs from Proxmox cloud-init template",
      "Set VM CPU, memory, disk, VLAN tag, and static IP",
      "Create control-plane, worker, bastion, load-balancer, monitoring, argocd, and database VMs",
      "Generate Ansible inventory"
    ]
    outside_terraform = [
      "pfSense VM and firewall/router configuration",
      "Kubernetes kubeadm init/join",
      "HAProxy and Keepalived service configuration",
      "MetalLB, ArgoCD, and Monitoring stack deployment"
    ]
  }
}

