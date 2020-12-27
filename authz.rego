package docker.authz

default allow = false

# Use null here to catch not just "unconfied" but also explicit profiles
allow {
    not privd
    not host_ns
    not any_seccomp
    not any_caps
    not root
}

# Don't let docker use the root user. This will probably break a lot of images
root {
    input.Body.User == "root"
}

# Disable privileged execution
privd {
    input.Body.HostConfig.Privileged == true
}

# Disable --userns=host. If you want to enable privileged dockers with namespaces
# you also need to allow this.
host_ns {
    input.Body.HostConfig.UsernsMode == "host"
}

# Any added capability 
any_caps {
    input.Body.HostConfig.CapAdd != null
}

# block seccomp:unconfined or any custom profile
any_seccomp {
    input.Body.HostConfig.SecurityOpt[_] != null
}
