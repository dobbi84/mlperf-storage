#!/bin/bash
set -e

if [[ "$1" == 'benchmark' ]]; then
    shift
    exec /mlperf/benchmark.sh "$@"
fi

exec "$@"
