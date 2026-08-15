#!/bin/sh

[ -r /etc/s6/cgroups/util-cg.sh ] && . /etc/s6/cgroups/util-cg.sh

SV_STATE="$1"

SV_NAME="$2"

SV_CG_SETTINGS="$3"

SV_CG_TIMEOUT_STOPSEC="${4:-90}"

SV_CG_SEND_SIGKILL="${5:-true}"

SV_CG_SEND_SIGHUP="${6:-false}"

[ -r /etc/s6/cgroups/util-sv-cg.sh ] && . /etc/s6/cgroups/util-sv-cg.sh

if [ -n "${SV_STATE}" ]; then
    sv_cg_"${SV_STATE}"
fi
