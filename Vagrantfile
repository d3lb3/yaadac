require "yaml"

Vagrant.require_version ">= 2.3.0"
VAGRANTFILE_API_VERSION = "2"

global_vars = YAML.load_file('config.yml')
host_vars = "ansible/host_vars"
group_vars = "ansible/group_vars"
inventory = "ansible/inventory.yml"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    
    config.vagrant.plugins = ["vagrant-hostsupdater", "vagrant-vbguest"]

    # general virtualization config
    config.vm.boot_timeout = 600
    config.vm.graceful_halt_timeout = 600
    config.vm.provider "virtualbox" do |vbox|
        vbox.customize ["modifyvm", :id, "--groups", '/' + global_vars['defaults']['virtualbox']['group']]
        vbox.customize ['modifyvm', :id, '--clipboard-mode', 'bidirectional']
        vbox.customize ['modifyvm', :id, '--draganddrop', 'bidirectional']
        vbox.linked_clone = true
        config.vbguest.auto_update = false
    end

    # dynamic vm creation based on the configuration file
    global_vars['machines'].each do |host_name, machine|

        next if machine.key?("enabled") and machine['enabled'] == false

        config.vm.define host_name do |node|
            
            box = machine['os']
            # generic configuration
            if box.start_with?("windows") then
                box = "gusztavvargadr/" + box
            end

            if box.include?("windows-server") then
                box = box + "-standard"
            end

            node.vm.box = box

            # TODO: automatically detect if box version node.vm.box_version = machine['vagrant']['box_version']
            node.vm.hostname = host_name
            node.vm.network :private_network, ip: machine['address']
            
            # virtualbox config
            node.vm.provider :virtualbox do |vbox|
                vbox.name = host_name
                if machine['virtualbox'] && machine['virtualbox']['gui'] then
                    vbox.gui = machine['virtualbox']['gui']
                else
                    vbox.gui = global_vars['defaults']['virtualbox']['gui']
                end
                if machine['virtualbox'] && machine['virtualbox']['memory'] then
                    vbox.memory = machine['virtualbox']['memory']
                else
                    vbox.memory = global_vars['defaults']['virtualbox']['memory']
                end
                if machine['virtualbox'] && machine['virtualbox']['cpus'] then
                    vbox.cpus = machine['virtualbox']['cpus']
                else
                    vbox.cpus = global_vars['defaults']['virtualbox']['cpus']
                end
            end
            
            # windows specific stuff
            if machine['os'].include?("windows") then
                node.vm.guest = :windows
                node.vm.communicator = "winrm"
                node.vm.synced_folder ".", "/vagrant", disabled: true
            end
            
            # shared folders
            if machine.key?("shared_folders") then
                machine['shared_folders'].each do |shared_folder|
                    # TODO: shared_folder_dest variable
                    
                    node.vm.synced_folder shared_folder, global_vars["defaults"]["windows"]["shared_folders_root"] + '\\' + File.basename(shared_folder), create: true, owner: "vagrant", mount_options: ["dmode=777", "fmode=666"]
                end
            end

        end
    end

    # clears existing ansible inventory

    def clear_directory(dir_path)
        Dir.foreach(dir_path) do |file|
            file_path = File.join(dir_path, file)  
            next if file == '.' || file == '..'
            File.delete(file_path) if File.file?(file_path)
        end
    end

    clear_directory(host_vars)
    clear_directory(group_vars)

    if File.exist?(inventory)
        File.delete(inventory)
    end

    # create ansible inventory and variables
    ansible_inventory = { "all_groups" => 
                            { "children" => 
                                { "windows" => { "hosts" => {} }, 
                                  "linux" => { "hosts" => {} }, 
                                  "servers" => { "hosts" => {} },
                                  "workstations" => {"hosts" => {} },
                                  "domain_controller" => {"hosts" => {} }                                
                                } 
                            } 
                        }
    ansible_vars = {}

    global_vars['machines'].each do |host_name, machine|

        next if machine.key?("enabled") and machine['enabled'] == false

        # inventory.yml
        core_os = ['windows', 'linux']
        core_os.each do |os|
            if machine['os'].include?(os) then
                if ansible_inventory['all_groups']['children'].has_key?(os)
                    ansible_inventory['all_groups']['children'][os]['hosts'][host_name] = nil
                end                    
            end
        end

        # automatic group based on machine type
        if machine['os'].include?("windows")
            if machine['os'].include?("server")
                ansible_inventory['all_groups']['children']['servers']['hosts'][host_name] = nil
            else
                ansible_inventory['all_groups']['children']['workstations']['hosts'][host_name] = nil
            end
        end
        
        # host_vars/*.yml
        machine_vars = machine
        machine_vars['ansible_ssh_host'] = machine['address']
        File.open(File.join(host_vars, host_name + '.yml'), 'w') do |file|
            file.write(machine_vars.to_yaml(line_width: -1).sub(/^---\n/, ''))
        end
    end

    # retrieve domain controller
    ansible_inventory['all_groups']['children']['domain_controller']['hosts'][global_vars['domain']['domain_controller']] = nil

    # inventory.yml
    File.open(inventory, 'w') do |file|
        file.write(ansible_inventory.to_yaml(line_width: -1).sub(/^---\n/, ''))
    end

    # group_vars/all.yml
    all_vars = {
        "ansible_ssh_port" => 22,
        "ansible_user" => 'vagrant',
        "ansible_password" =>'vagrant',
        "ansible_ssh_pass" => 'vagrant',
        "ansible_ssh_user" => 'vagrant',
        "ansible_connection" => 'ssh',
        "ansible_shell_type" => 'cmd',
        "ansible_ssh_retries" => 3,
        "ansible_become_method" => 'runas'
    } 

    all_vars["domain"] = global_vars["domain"]
    all_vars["defaults"] = global_vars["defaults"]
    all_vars["domain"]["dc_ip"] = global_vars['machines'][global_vars["domain"]["domain_controller"]]["address"]

    File.open(File.join(group_vars, "all.yml"), 'w') do |file|
        file.write(all_vars.to_yaml(line_width: -1).sub(/^---\n/, ''))
    end
end


# TODO :
# - better defaults handling / configurations
# - refactor vagrantfile
# - mandatory parameters validation