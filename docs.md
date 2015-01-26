## Ansible Deployment Scripts

* Requires Ansible 1.3 or newer
* Expects Ubuntu 12.04 or 14.04 hosts, may work on Debian hosts

### Background

Matterhorn is a complex piece of software that can be difficult to set up for a new adopter.  The scripts outlined in this guide can be used to set up a local instance of Matterhorn, or can be adapted for use in a production environment.

#### Caveats
* These scripts were designed with a Debian based system in mind, so some assumptions have been made in that regard (file paths, use of Apt for various dependencies, etc).
* These scripts set up Matterhorn from source, including the 3rd party tools.
    * This can take a very, very long time, especially for the 3rd party tools.  There is no progress bar.  Set this to run overnight and come back in the morning.

### Quick Start

If you are just looking to get a running Matterhorn system at this point, then you need only do two things:  Modify the group\_vars/common.yml, and your .hosts file.  Setup your hosts file to match your environment, and then set up the mh\_version and mh\_pom\_version variables in common.yml to match the version of Matterhorn you wish to install.  Then run _ansible-playbook -K -i $hosts_file.hosts $playbook.yml_ and wait

### Details

In this example we will examine the most common topology available using the Ansible scripts found at here﻿.  This is the configuration contained in the _consolidated.hosts_ file.  This file defines which playbook will run on each host.  Think of these playbooks as node profiles - worker.example.org would be installed as a worker node, for example.  The _consolidated.hosts_ defines the most basic Matterhorn cluster using four machines - the classic admin, worker, engage core cluster, with a capture agent.

#### Hosts

To begin, we first must first change the .hosts file to match our environment.  Each playbook (e.g: [fileserver]) can have between zero and N hosts associated with it.  A given host can also be associated with multiple playbooks.  In consolidated.hosts we see that the admin.example.org host will play the role of the fileserver, mysql server, and admin node.  We also see that the ingest playbook has no hosts associated - that means that it will not be used.  These scripts do not have a way to define dependencies between playbooks, which means (as an example) that you can deploy a cluster without an admin node.  Keep this in mind when defining your host environment!  At this point, please change the hosts to match your environment.  If, for instance, you wish to skip installing the capture agent (which installs in demo mode!), just remove the host(s) from under that playbook.

#### Playbooks

Now that you have defined which playbooks should run on each node, it's time to examine the playbooks themselves.  We have two major playbooks defined in this project - _all-in-one.yml_, and _distributed.yml_.  In this example we will use the distributed.yml file since we will be deploying a distributed cluster.  This playbook contains a number of different plays, each of which contains several roles.  These plays are executed in the order which they are defined.  As an example, the admin play looks like this, and executes after the fileserver role:

    - hosts: admin
      user: matterhorn
    
      roles:
        - matterhorn-base
        - matterhorn-core
        - admin-build
        - matterhorn-start
      vars_files:
        - group_vars/common.yml
        - group_vars/cluster.yml
        - roles/admin-build/vars/admin.yml

This means that the _matterhorn_ user should be used to run all of roles listed, using the variables in the listed variable files, on each host tagged with the admin playbook.  Each role defines a piece of the puzzle which forms the final, installed, software on the node.  These can be very complex, or very simple.  The _matterhorn-core_ role, for example, sets up all of the relevant configuration items in config.properties.  The _matterhorn-start_ role, on the other hand, just starts Matterhorn and then sets it to start on boot.  Each role contains a number of tasks, or steps, and lives in the roles directory.  These roles should be relatively stable and should not need modification, assuming you are using a Debian based system.  If you are running a different type of system then you will obviously need to modify things!

#### Variables

At this point we delve into variables.  For the most part you should not need to modify the variables aside from the mh\_version and mh\_pom\_version variables, but for completeness we will examine what the various variable files do.  Ansible's variable files have an inheritance structure, which flows from global variables (group\_vars/\*.yml), to role variables (roles/\*/vars/\*), to task variables (items within roles/\*/tasks/\*).  For instance, the global _common.yml_ file defines _is\_ca_ to be false, but in the _capture-agent-build_ role we redefine it to true.

### Extending this codebase (Advanced)

#### Adding new roles

Say you want to add a new role which installs Flash Media Server instead of Red5.  To accomplish this you need to create a new role directory under _roles_, and define its tasks, variables, and templates (if any), and then either replace the _red5-build_ role in the streamer section of an existing playbook, or create a new play in the playbook which builds that role.  By far the simplest role in the current set is the mysql-build role.  Use this as a template to get you going!

#### Making this work for other systems (e.g: RPM based distros)

The two major blockers for this script working on other distros are the package manager, and the paths.  In the case of the package manager, we need only figure out which package(s) provide the same functionality as the Apt packages and either replace the apt tasks, or add some intelligence to the install so that it choses apt or yum depending on the OS family.  See http://docs.ansible.com/playbooks_conditionals.html#the-when-statement for more details.  The paths are less of an issue, but still something that will need to be addressed.  These scripts assume a current Ubuntu filesystem, and init system.  This means we are using rc.d scripts, and all of our files are installed somewhere under /opt/matterhorn.  This may be an issue, or it may not, depending on the flavour.
