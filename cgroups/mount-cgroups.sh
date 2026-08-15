#!/bin/sh

[ -r /etc/s6/cgroups/util-cg.sh ] && . /etc/s6/cgroups/util-cg.sh


# {{{ mount-cgroups

mount_cg() {
    mkdir -p "${CG_ROOT}"

    if ! mount -t cgroup2 none -o "${CG_MOUNT_OPTS},nsdelegate" "${CG_ROOT}" 2> /dev/null; then
        mount -t cgroup2 none -o "${CG_MOUNT_OPTS}" "${CG_ROOT}"
    fi

    if ${CG_CHILD}; then
        mkdir -p "${CG_INIT}"
    fi

    return 0
}

config_cg() {

    cg_controllers="${CG_ROOT}/cgroup.controllers"
    cg_subtree_control="${CG_ROOT}/cgroup.subtree_control"

    if ${CG_CHILD}; then
        cg_controllers="${CG_INIT}/cgroup.controllers"
        cg_subtree_control="${CG_INIT}/cgroup.subtree_control"
    fi

    read -r controllers < "${cg_controllers}"
    active=
    for c in ${controllers}; do
        active="${active} +${c}"
    done
    printf "%s" "${active}" > "${cg_subtree_control}"

    return 0
}

mount_cgroups() {
    if [ -d "${CG_ROOT}" ];then
        mount_cg
        config_cg
        return 0
    fi
    return 1
}

# }}}

mount_cgroups
