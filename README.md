# Notes and config files for securing docker on linux

The aim of this repository is to document the steps needed to secure a new docker installation, allowing arbitrary dockers to be run without giving them any access to the host filesystem, and allowing untrusted users to run dockers safely.


## Quick setup

After installing docker run. 

```
git clone https://github.com/pigfrown/securing-docker
cd securing-docker
sudo cp daemon.json /etc/docker/daemon.json
docker plugin install openpolicyagent/opa-docker-authz-v2:0.4 opa-args="-policy-file /opa/policies/authz.rego"
sudo mkdir /etc/docker/policies
sudo cp authz.rego /etc/docker/policies
sudo echo dockremap:624288:65536 >> /etc/subuid
sudo echo dockremap:624288:65536 >> /etc/subgid
sudo systemctl restart docker
```
If you have many users you may need to manually edit /etc/subuid and /etc/subgid to ensure there is no overlap in namespaces, e.g. if a user already exists that can map the range starting with 624288, change the value dockremap can map to the start of an unused range.


## Explanations

Docker is secured through 2 mechanisms, enabling user namespaces, and through the Open Policy Agent authorisation plugin and associated policy file.

### Namespaces

By default users within a docker are run in the default UID/GID range, which means that root (UID 0) in a Docker would map to root (UID 0) on the host. If volumes are shared with the Docker it's possible (depending on what the docker user is being run as, and what that UID maps to on the host) that the container can bypass the normal file permissions of the user executing the container. This can be abused by a malicious Dockerfile to, amoungst other things, edit or create new executables with setuid root on the host.

To prevent this the user namespaces can be used to remap the internal docker users UID and GID to values that are not shared by users (e.g. root) on the host filesystem. This will restrict a dockers ability to  read or write mounted volumes, unless the host filesystems permissions are set to allow that. This may break development dockers that rely on unfettered access to host volumes, but can be worked around by giving permission on a case by case basis to needed files/directories (principle of least privilege).

### Authorisation Plugin

Through the use of docker --privileged flag, (or through adding capabilities/secure computing profiles), a malicious user on a multi user system can run a container that escapes it's isolation and reads/writes arbitrary devices on the host filesystem, giving the untrusted user effectively root access (https://ericchiang.github.io/post/privileged-containers/).

To mitigate this docker allows plugins to be used to limit the execution of Dockers depending on what options they are configured or launched with. We will use the Open Policy Agent authorisation plugin for this purpose. This can be used to limit every aspect of a dockers execution, but the provided .rego file does the following:

* Prevents dockers using the root user
* Prevents dockers running with --privileged 
* Prevents dockers being run with the --userns=host option
* Disables dockers being run with any added "capabilities" (with --add-cap)
* Prevents dockers being run with the non-default seccomp profile


Preventing dockers running as root will almost certainly break some images, but is required to stop attacks where root in the container uses the MKNOD capability to let a host user bypass file permissions (https://labs.f-secure.com/blog/abusing-the-access-to-mount-namespaces-through-procpidroot/). If you need your containers applications to run as the root user it is recommended that the --drop-cap=MKNOD options is used with docker.





## TODO

* Rootless dockerd.
* More research into OPA configuration
