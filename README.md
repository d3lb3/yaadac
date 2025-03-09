# yaadac

Yet Another Active Directory As Code using Vagrant and Ansible.

## Overview

I created the project with the idea of dynamically create virtual machines and populate the ansible variables through a single configuration file.
The provided *config.yml* as well as Ansible playbooks can serve as a basic template.

The project uses the following folder structure:
```bash
.
├── config.yml # configuration file containing the active directory and machines variables
├── Vagrantfile # used by vagrant to parse config.yml, spawn machines and populate Ansible inventory/variables files
├── lab.sh # wrapper used to launch common vagrant/ansible actions
└── ansible
    ├── ansible.cfg # hardcoded ansible configuration (used to configure SSH connection to Windows hosts)
    ├── group_vars # common variables (ex: domain controller name), dynamically populated by Vagrant
    │   └── all.yml
    ├── host_vars # host_vars (ex: a machine local administrator password), dynamically populated by Vagrant
    │   ├── <machine1>.yml
    │   └── <machine2>.yml
    ├── inventory.yml # machines inventory, dynamically populated by vagrant
    ├── playbooks # where to put your playbooks
    │   ├── ad.yml
    │   ├── base
    │   ├── base_install.yml
    │   ├── software.yml
    ├── requirements.yml # ansible requirements (ex: Active Directory module)
    └── resources # resources used by some ansible playbooks
        └── disable_defender.bat

```



## Useful Commands

While a dirty `lab.sh` is provided as a wrapper, here are some useful commands to use the projet:

**Create/Delete virtual machines**

```bash
vagrant up
vagrant destroy
```

**Stop/Resume virtual machines**

```bash
vagrant halt
vagrant resume
```

**Save/restore/delete virtual machines snapshots**

```bash
vagrant snapshot save <name> (--force)
vagrant snapshot restore <name>
vagrant delete restore <name>
```

**Connect to a created virtual machine**

```bash
vagrant ssh <vm_name>
ssh vagrant@<vm_name> # /etc/hosts should be automatically set up, otherwise connect using the IP/manually add name resolution (creds: vagrant/vagrant) 
```

**Launch Ansible playbooks**

Once the configuration files generated, you can launch the playbooks of your choice using:

```bash
ansible-playbook -i ./ansible/inventory.yml <path_to_playbook> --tags <optional playbook tags>
```

While this repository is more about the dynamic generation of Ansible variables, you can use the provided playbooks as a boilerplate to create your own Active Directory environments. 
To do a step-by-step (useful for debugging) AD installation you can for example use:
```bash
# windows base configuration (set local admin password, disable firewall, etc)
ansible-playbook -i ./ansible/inventory.yml ansible/playbooks/base_install.yml --tags check,windows

# windows nic configuration for proper network requirements to create domain
ansible-playbook -i ./ansible/inventory.yml ansible/playbooks/base_install.yml --tags check,nic_issues

# create ADDS and add users (may take some time, TODO: tinker variables to make restart timeout shorter ?)
ansible-playbook -i ./ansible/inventory.yml ansible/playbooks/base_install.yml --tags check,adds

# join machines to the domaine
ansible-playbook -i ./ansible/inventory.yml ansible/playbooks/base_install.yml --tags check,join_machines

# install softwares
ansible-playbook -i ./ansible/inventory.yml ansible/playbooks/software.yml --tags choco
```


## Troubleshooting

Sometimes the ansible.cfg is not properly read which causes errors when trying to connect to hosts using SSH.

You can set up this parameter manually using :
```bash
export ANSIBLE_HOST_KEY_CHECKING=False
```