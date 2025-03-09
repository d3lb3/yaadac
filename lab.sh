#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 {setup|start|stop|clear|base}"
  exit 1
}

# Check if at least one argument is provided
if [ $# -ne 1 ]; then
  usage
fi

setup_vagrant() {
  echo "Setup Vagrant machines..."
  vagrant up --provision
  if [ $? -ne 0 ]; then
    echo "Failed to setup Vagrant machines."
    exit 1
  fi
}

start_vagrant() {
  echo "Start Vagrant machines..."
  vagrant resume
  if [ $? -ne 0 ]; then
    vagrant up
    if [ $? -ne 0 ]; then
      echo "Failed to start Vagrant machines."
      exit 1
    fi
    exit 1
  fi
}

stop_vagrant() {
  echo "Halting Vagrant machines..."
  vagrant suspend
  if [ $? -ne 0 ]; then
    echo "Failed to halt Vagrant machines."
    exit 1
  fi
}

start_ansible() {
  echo "Running Ansible playbook..."
  export ANSIBLE_HOST_KEY_CHECKING=False
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/base_install.yml
  if [ $? -ne 0 ]; then
    echo "Failed to run Ansible playbook."
    exit 1
  fi
}

quick_snapshot() {
  echo "Creating quick vagrant snapshot..."
  vagrant snapshot delete quick 
  vagrant snapshot create quick 
  if [ $? -ne 0 ]; then
    echo "Failed to create quick vagrant snapshot."
    exit 1
  fi
}

quick_restore() {
  echo "Restoring quick vagrant snapshot..."
  vagrant restore quick
  if [ $? -ne 0 ]; then
    echo "Failed to restore quick vagrant snapshot."
    exit 1
  fi
}

clear_all() {
  echo "Stopping and removing all machines and configurations..."
  vagrant destroy -f
  if [ $? -ne 0 ]; then
    echo "Failed to destroy Vagrant machines."
    exit 1
  fi

  echo "Removing configurations..."
  rm -rf .vagrant
  rm -rf ansible/inventory.yml
  rm -rf ansible/group_vars/*
  rm -rf ansible/host_vars/*
  if [ $? -ne 0 ]; then
    echo "Failed to remove configurations."
    exit 1
  fi

  echo "All Vagrant machines and configurations have been cleared."
}

# Main script logic
case "$1" in
  setup)
    setup_vagrant
    ;;
  start)
    start_vagrant
    ;;
  stop)
    stop_vagrant
    ;;
  base)
    start_ansible
    ;;
  snapshot)
    quick_snapshot
    ;;
  restore)
    quick_restore
    ;;
  clear)
    clear_all
    ;;
  *)
    usage
    ;;
esac