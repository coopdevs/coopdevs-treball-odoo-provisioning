# Ansible inventories
This repository stores hosts informations and related variables for this specific instance of Odoo.

## Requirements

1. Clone this repo and [odoo-provisioning](https://gitlab.com/femprocomuns/odoo-provisioning) in the same directory
2. Go to `odoo-provisioning` directory and install Ansible dependencies:
   ```
   ansible-galaxy -r requirements.yml
   ```
3. Run `ansible-playbook` command pointing to the `inventory/hosts` file of this repository:
   ```
   ansible-playbook playbooks/provision.yml -i ../odoo-coopdevs-treball-provisioning/inventory/hosts --ask-vault-pass --limit=dev
   ```
