#!/bin/bash

set -euxo pipefail

trap '/etc/init.d/unbound stop; exit 0' TERM

/bin/bash /home/unbound-conf.sh

# unboundをデーモンとして起動する
/etc/init.d/unbound start

while true; do sleep 86400 & wait $!; done