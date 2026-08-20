#!/bin/sh

# {{{ sv-cg helpers

sv_cg_pids() {

    CG_PIDS=

    while read -r p; do

        [ "$p" -eq $$ ] && continue

        CG_PIDS="${CG_PIDS} ${p}"

    done < "${CG_PROCS}"

    return 0
}

sv_cg_remove() {

    if [ ! -d "${SV_CG_PATH}" ]; then
        return 0
    fi

    if grep -qx "$$" "${CG_PROCS}"; then
        printf "%d" 0 > "${CG_PROCS}"
    fi

    while read -r key value; do

        if [ "${key}" = "populated" ]; then
            populated=${value}
        fi

    done < "${CG_EVENTS}"

    if [ "${populated}" -eq 1 ]; then
        return 0
    fi

    rmdir "${SV_CG_PATH}"

    return 0
}

sv_cg_kill() {

    if [ -f "${CG_KILL}" ]; then
        printf "%d" 1 > "${CG_KILL}"
    fi

    return 0
}

sv_cg_cleanup() {
    loops=0

    sv_cg_pids

    if [ -n "${CG_PIDS}" ]; then

        kill -s CONT "${CG_PIDS}" 2> /dev/null
        kill -s "${stopsig:-TERM}" "${CG_PIDS}" 2> /dev/null

        if "${SV_CG_SEND_SIGHUP}"; then
            kill -s HUP "${CG_PIDS}" 2> /dev/null
        fi

        kill -s "${stopsig:-TERM}" "${CG_PIDS}" 2> /dev/null

        sv_cg_pids

        while [ -n "${CG_PIDS}" ] && [ "${loops}" -lt "${SV_CG_TIMEOUT_STOPSEC}" ]; do

            loops=$((loops+1))
            sleep 1

            sv_cg_pids

        done

        if [ -n "${CG_PIDS}" ] && "${SV_CG_SEND_SIGKILL}"; then
            kill -s KILL "${CG_PIDS}" 2> /dev/null
        fi
    fi
}

# }}}

# {{{ sv-cg

sv_cg_up() {

    if [ ! -d "${SV_CG_PATH}" ]; then
        mkdir "${SV_CG_PATH}"
    fi

    if [ -f "${CG_PROCS}" ]; then
        printf "%d" 0 > "${CG_PROCS}"
    fi

    if [ -z "${SV_CG_SETTINGS}" ]; then
        return 0
    fi

    while read -r key value; do

        [ -z "${key}" ] && continue
        [ -z "${value}" ] && continue

        [ ! -f "${SV_CG_PATH}/${key}" ] && continue

        printf "%s" "${value}" > "${SV_CG_PATH}/${key}"

    done < "${SV_CG_SETTINGS}"

    return 0
}

sv_cg_down() {
    if [ ! -d "${CG_ROOT}" ]; then
        return 0
    fi

    if ! sv_cg_kill; then
        sv_cg_cleanup
    fi

    sv_cg_remove
    sv_cg_pids

    if [ -n "${CG_PIDS}" ]; then
        printf "%s\n" "Unable to stop all processes"
        return 1
    fi

    return 0
}

# }}}

readonly SV_CG="${SV_NAME}${CG_SV_EXT}"

SV_CG_PATH="${CG_ROOT}/${SV_CG}"

if ${CG_CHILD}; then
    SV_CG_PATH="${CG_INIT}/${SV_CG}"
fi

readonly CG_PROCS="${SV_CG_PATH}"/cgroup.procs

readonly CG_KILL="${SV_CG_PATH}"/cgroup.kill

readonly CG_EVENTS="${SV_CG_PATH}"/cgroup.events
