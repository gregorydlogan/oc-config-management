## Quickstart

- Ansible 2.6.18 or newer
- Supported Distributions
  - Debian 8+
  - Ubuntu 16.04+
  - CentOS 7+
  - Red Hat 7+

These playbooks deploy a full Opencast cluster, from packages.  To use them, first edit the `hosts` inventory file
to contain the hostnames of the machines on which you want Opencast deployed, and edit `group_vars/all.yml` to set any
parameters you might want.  Prior to running the playbook you need to install the dependency roles.  This can be done
with:

	ansible-galaxy install -r requirements.yml

Then run the playbook, like this:

	ansible-playbook -K -i hosts opencast.yml

When the playbook run completes, you should be able to see Opencast on port 80, on the target machines.

This playbook is *not* meant to deploy production machines as is, instead use it to form the basis of a playbook which
better matches your local needs and infrastructure.

## Detailed Docs

#### Hosts

To begin, we first must first change the hosts file to match our environment.  Each play (e.g: `[fileserver]`) can have
between zero and N hosts associated with it.  A given host can also be associated with multiple playbooks.  In [the 
default `hosts` file](hosts) we see that the `admin.example.org` host will play the role of the fileserver, database server,
and admin node.  We also see that the `ingest` playbook has no hosts associated - that means that it will not be used.
These scripts do not have a way to define dependencies between playbooks, which means (as an example) that you can
deploy a cluster without an admin node, which is an invalid configuration.  Keep this in mind when defining your host
environment!  At this point, please change the hosts to match your environment.

Host list requirements:

 - `fileserver`: At most 1 host.  With 2 or more hosts only the first will be used. 0 hosts disables the fileserver and
   only makes sense of you are just building an allinone host.
 - `database`: Exactly 1 host.  With 2 or more hosts only the first will be used, with 0 hosts you will encounter errors.
 - `activemq`: Exactly 1 host.  With 2 or more hosts only the first will be used, with 0 hosts you will encounter errors.
 - `allinone`, `admin`, `adminpresentation`: At most 1 host in all of these groups combined.  The admin 
   node used by the cluster is defined by the _first_ entry of the `admin_node` group.  This means that if you define an
   a host under `admin`, and a host under `adminpresentation` then the cluster will use the host under `admin`.
 - `allinone`, `presentation`, `adminpresentation`: At most 1 host in all of these groups combined.  The presentation
   node used by the cluster is defined by the __first__ entry of the `presentation_node` group.  This means that if you
   define a host under `presentation`, and a host under `adminpresentation` then the cluster will use the host under
   `presentation`.
 - `allinone`, `worker`: At least 1 host in at least one of these groups.  There are no outright errors if
   you deploy a cluster without any workers, but Opencast will be unable to process any recordings.  In general this is
   a useless configuration, unless you are strictly testing configuration files.

Host configuration for these scripts:
 - A shared user (by default named `ansible`) who accepts your SSH key, has `sudo` access, and either no password (for
   passwordless sudo) or the same password on all nodes in `hosts`.

Configuration Hints:
 - The most common production configuration is a single admin, single presentation, and N workers.
 - Decide where you want your admin and presentation nodes first.  Once media has been processed, it's very difficult
   to change the admin and presentation hostnames.
 - Opencast uses the hostname as defined in the hosts file.  Use the externally resolvable name (ie, admin.example.org,
   rather than just admin), otherwise you will encounter problems in the future.

#### Variables

Most variables are exposed in the `group_vars/all.yml` and `group_vars/opencast.yml` files.  These files should be
well documented, so please take a look.

### Troubleshooting

 - __My install fails with an error complaining that the SEQUENCE table already exists__

You already have some data in the schema you are installing to.  This might be pre-existing Opencast data, so we fail
the install rather than potentially overwrite your data.  If you are sure you want to overwrite it, use the `reset` tag
after reading the caveat in the Advanced Usage section below.

 - __My install fails complaining that a package could not be installed__

Try again in a day or so.  If you are particularly unlucky you might have caught us updating the repository, or there
might be an issue with your distribution's mirroring systems.  If this does not resolve itself in a day please complain
on list!

#### Known issues for production use

 - These playbooks ship with the default upstream Opencast credentials.  These *must* be changed for production use.
 - ActiveMQ is left in a world-connectable state.  Setup a firewall between your ActiveMQ node and the untrusted network.
 - NFS is restricted to the hosts involved in the playbook, but does not have any other security in place and is running
   in version 3.
 - HTTPS configuration is possible (`oc_protocol` in `group_vars/opencast.yml`), however these playbooks do not cover
   setting up and issuing certificates.

### Ideas for Improvement

Here are some ideas for ways that these playbooks could be extended:

 - Enable Solr clustering for relevant services
 - Enable Elastic Search server clustering for relevant services
 - Add security to various installed services to prevent them from being world accessible (see above)
 - Multiple tenant support
 - Error checking for group settings.  You can define insane configurations such as multiple admin nodes, or clusters
   without ActiveMQ.

### Advanced Usage

#### Using other repositories

It is possible to use other repositories (ie, internal testing repositories) with these playbooks.  You will need to
override a few variables.

For Debian based systems:

 - `deb_repo_suite` needs to be the repository suite (ie, `unstable`)
 - `oc_deb_repo_url` needs to be the full URL to the repository base (ie, `http://ci.opencast.org/debian`)
 - `oc_deb_key_url` needs to be the full URL to the repository signing key (ie, `https://pkg.opencast.org/gpgkeys/automated.key`)
 - `oc_deb_key_id` needs to be the signing key's id (ie, `048D039F1DAE53EA0357ED824917F260EA15B53F`)

For RedHat based systems:

 - `rpm_repo_suite` needs to be the repository suite (ie, `unstable`)
 - `oc_rpm_repo_url` needs to be the full URL to the repository base (ie, `http://ci.opencast.org/rpms`)
 - `oc_rpm_key_url` needs to be the full URL to the repository signing key (ie, `https://pkg.opencast.org/gpgkeys/automated.key`)
 - `oc_rpm_key_id` needs to be the signing key's id (ie, `048D039F1DAE53EA0357ED824917F260EA15B53F`)

#### Tags

The playbook contains tags, which cause Ansible to only execute part of the full playbook.  These tags are currently:

 - `config`, which updates all of the configuration files created by this playbook, then restarts Opencast.  Don't do
   this on your production system, figure out the correct settings on your test instance then reinstall for production.
 - `opencast`, which does all of the steps for installing Opencast, and Opencast alone.  Use this if you're testing
   packaging and you are confident that the rest of the system (NFS mounts, activemq, etc) is properly configured.
 - `uninstall`, which removes all Opencast packages, even if they do not match the currently checked out branch.
 - **DANGER** `reset`, which removes _all_ Opencast user data, but leaves the packages installed.  This is only useful
   for testing situations, and *will happily wipe out your production data without further prompting.*

Hints:
 - Running `--tags config,reset` resets the database, filesystem, and ensures all of your config files are in the
   expected state, then restarts Opencast.
 - If you are switching between Opencast versions when testing, first run `--tags uninstall` to remove the packages,
   then checkout the correct branch of these playbooks.  Then run `--tags opencast,reset` to install and reset.
   Without the reset tag you will see an error when the database is imported because the schema will already exist.
 - If you are testing a CI system you can combine the above as `--tags uninstall,opencast,reset` to uninstall the current
   version, reinstall the same branch (but likely new build), and clear the database and storage system before restarting
   Opencast.
