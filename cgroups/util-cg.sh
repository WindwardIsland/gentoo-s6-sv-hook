#!/bin/sh

load_config(){

    conf="/etc/s6/cgroups/cgroups.conf"

    [ -f "$conf" ] || return 1

    # shellcheck source=src/conf/cgroups.conf
    [ -r "$conf" ] && . "$conf"

    CG_MOUNT_OPTS=${CG_MOUNT_OPTS:-nodev,noexec,nosuid}

    CG_CHILD=${CG_CHILD:-false}

    CG_CHILD_NAME=${CG_CHILD_NAME:-"gentoo"}

    CG_SV_EXT=${CG_SV_EXT:-".sv"}

    SV_CG_SETTINGS=${SV_CG_SETTINGS:-}

    SV_CG_SEND_SIGHUP=${SV_CG_SEND_SIGHUP:-false}

    SV_CG_TIMEOUT_STOPSEC=${SV_CG_TIMEOUT_STOPSEC:-90}

    SV_CG_SEND_SIGKILL=${SV_CG_SEND_SIGKILL:-true}

    readonly CG_ROOT="/sys/fs/cgroup"

    readonly CG_INIT="${CG_ROOT}/${CG_CHILD_NAME}"

    return 0
}

load_config
