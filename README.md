## Standalone Matterhorn Deployment

- Requires Ansible 1.3 or newer
- Expects Ubuntu 12.04 or 14.04 hosts, may work on Debian

These playbooks deploy a full Matterhorn cluster, from source.
To use them, first edit the "hosts" inventory file to contain the
hostnames of the machines on which you want Matterhorn deployed, and edit the 
group_vars files to set any Tomcat configuration parameters you need.

Then run the playbook, like this:

	ansible-playbook -K -i $hosts_file.hosts $playbook.yml

When the playbook run completes, you should be able to see Matterhorn on the 
port 80, on the target machines.

This playbook is *not* meant to deploy production machines, although it could
easily form the basis of a playbook which does.

If you are using a private repository and it is available via SSH, you can use the group_vars/ssh directory to push an appropriate deployment key and known\_hosts file so that cloning on the target machines functions as expected.  Just place the files in that directory and run the playbooks.

## Detailed Docs

More detailed docs can be found at https://bitbucket.org/opencast-community/configuration-management/src/master/docs.md

### Ideas for Improvement

Here are some ideas for ways that these playbooks could be extended:

- Support for CentOS/RHEL
- Enable multiple Solr cluster (for services other than search)
- Clean up the packaging (apt) lines
