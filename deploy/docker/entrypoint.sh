#!/bin/sh

#source vars if file exists
DEFAULT=/etc/default/fluentd
ADDITIONAL_PLUGINS="${ADDITIONAL_PLUGINS:-}"
FLUENTD_CONF="${FLUENTD_CONF:-}"

if [ -r "${DEFAULT}" ]; then
    set -o allexport
    # shellcheck disable=SC1090
    . "${DEFAULT}"
    set +o allexport
fi

# If the user has supplied only arguments append them to `fluentd` command
if [ "${1#-}" != "$1" ]; then
    set -- fluentd "$@"
fi

# If user does not supply config file or plugins, use the default
if [ "$1" = "fluentd" ]; then
    if ! echo "$@" | grep ' \-c' ; then
       set -- "$@" -c "/fluentd/etc/${FLUENTD_CONF}"
    fi

    if ! echo "$@" | grep ' \-p' ; then
       set -- "$@" -p /fluentd/plugins
    fi
fi

# Install custom plugins if specified by user
if [ -n "${ADDITIONAL_PLUGINS}" ]; then
    for plugin in ${ADDITIONAL_PLUGINS}; do
        gem install "${plugin}"
    done
fi

exec "$@"
