# Teardown

Destructive operations in this repository can delete Proxmox VMs and their disks. Do not run `terragrunt run-all destroy` unless the entire fleet managed by this repository is meant to be removed.

## Safer Destroy Checklist

1. Identify the exact rack and VM resources to remove.
2. Export current outputs for audit.

   ```bash
   cd infra/racks/top-rack
   terragrunt output -json > top-rack.outputs.redacted.json
   ```

3. Run a destroy plan and read every resource action.

   ```bash
   terragrunt plan -destroy
   ```

4. Snapshot or back up VM data in Proxmox if any workload data matters.
5. Apply destroy only from the specific rack directory.

   ```bash
   terragrunt destroy
   ```

## Avoiding Accidental Data Loss

- Never destroy from `infra/racks` unless every rack is intended to be destroyed.
- Do not delete a VM from the rack map until you understand that Terraform will plan a destroy for that VM.
- Linked clones and template-backed disks may have storage behavior that differs by Proxmox storage pool. Confirm in the Proxmox UI before destroying important workloads.
- Terraform Cloud state history is not a backup of VM disks or application data.

## Removing State Without Destroying

If a VM should remain in Proxmox but stop being managed by Terraform, remove it from state first and then edit code:

```bash
terragrunt state list
terragrunt state rm 'module.vms["example"].proxmox_vm_qemu.vm[0]'
```

After state removal, run `terragrunt plan` and confirm Terraform no longer proposes changes to that VM.
