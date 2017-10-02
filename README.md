# Ansible scripts to provision and deploy Odoo

These are [Ansible](http://docs.ansible.com/ansible/) playbooks (scripts) for managing an [Odoo](https://github.com/odoo/odoo) server.

## Bash scripts

### Default User
`scripts/default_user.yml`

Read local SSH key and pass it to `create_user.sh` executed in the host with SSH root connection.
You can define a env var `SSH_PATH` if yout SSH key is in a different path that default `~/.ssh/id_rsa.pub`

### Create User
`script/create_user.yml`

Create the default_user `odoo` and copy the SSH key (first argument) in authorized keys of the user.
Change the SSH root login permissions.
`

### lxc-create
`lxc/lxc-create.sh`

Create a LXC container with host name and python 2.7 installed.
Allow root SSH access and remove the default `ubuntu` user.

## Playbooks

### Sysadmins
`sysadmins.yml` - Create default user `odoo` and sysadmins defined in your `inventory/host_vars/YOUR_HOST/conf.yml` in a dict called `sysadmins`.
The structure to declare user is:

```ỲAML
sysadmins:
  myname:
    key: "{{ lookup('env', 'HOME' ) }}/.ssh/id_rsa.pub"
    state: present
  user1:
    key: ../pub_keys/user1.pub
    state: present
```

Use `state: absent` to remove a user.

After execute this playbook the `odoo` the authorized SSH keys was removed and to acces it you can access with your sysadmin user and execute `sudo su odoo`.
All other users need acces to odoo group to manage the system service.

- Create default_user
- Create all sysadmin
- Add ssh keys
- Add sudo permisses

### Provision
`provision.yml` - Install and configure all required software on the server.

- Install common packages
- Install PostgreSQL database and create a user
- Install NodeJS and LESS

### Deploy
`deploy.yml` - Deploy source code from Odoo Nightly and install Python requirements.

- Install and create VirtualEnv
- Ansistrano deploy:
  - Download the source code
  - Before link task: Build
  - Before link task: Install requirements.txt
- Add systemd service

### Deploy Custom Modules
`deploy_custom_modules.yml` - Deploy the custom or thirdy part modules that you need.

You can make a repository with submodules pointing your module repository. [Like in this example](https://github.com/danypr92/odoo-organization-custom-modules)

Put custom modules repository url in your inventory/host_vars/your_host/config.yml file:

```YAML
custom_modules_repo: https://github.com/danypr92/odoo-organization-custom-modules.git
custom:modules_repo_branch: master
```

- Ansistrano git deploy.
- Update odoo.service to add addons.

### All
`all.yml` - Include all other playbooks

## Requirements

You will need Ansible on your machine to run the playbooks.
These playbooks will install the PostgreSQL database and Python virtualenv to manage python packages. 

It has currently been tested on **Ubuntu 16.04 Xenial (64 bit)**.

If you like run the `lxc-create` script, you need install [LXC](https://linuxcontainers.org/).

## Development - Using LXC containers

You can need a local container to test your customizations.
`lxc/lxc-create.sh` script creates a container, gets IP address of the new container and creates a known host whit this IP address.

`./lxc/lxc-create.sh -n NAME -t TEMPLATE -r RELEASE -h HOST`

Arguments:

```
  -n --name: LXC container name. Ex.: my-cont"
  -t --template: LXC container template. Ex.: ubuntu"
  -r --release: LXC container release. Ex.: xenial"
  -h --host: LXC container host name. Ex.: local.lxc.org"
```

**Name and host are required.** Default template is Ubuntu and default release is Xenial (16.04 LTS)

# Installation instructions

For the first playbook (sysadmin.yml) is needed have a `odoo` user with your SSH pub key.

If you not have this user but have acces like root, you can use the `default_user.sh` script.

#### Script to create default user.

Execute the `script/default_user.sh` to create the `odoo` user and add your SSH key.

System state:
- Permit Root SSH login (modify `/etc/ssh/sshd_config`)
- Access without password (copy your SSH key)

### Step 1 - SysAdmins

The **first time** thet execute this playbook use the user `odoo`

`ansible-playbook playbooks/sysadmins.yml -u odoo`

All the next times use your personal sysadmin user:

`ansible-playbook playbooks/sysadmins.yml -u USER`

USER --> Your sysadmin user name.

### Step 2 - Provision

`ansible-playbook playbooks/provision.yml -u USER`

USER --> Your sysadmin user name.

### Step 3 - Deploy

`ansible-playbook playbooks/deploy.yml -u USER`

USER --> Your user name (not need be superuser)

### Step 4 - Deploy custom modules

`ansible-playbook playbooks/deploy_custom_modules.yml -u USER`

USER --> Your user name (not need be superuser)


