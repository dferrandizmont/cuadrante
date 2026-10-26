#!/bin/sh
# POSIX entry point. Python only uses its standard library; no network calls.
set -eu
if [ "$#" -ne 2 ]; then
    echo 'Uso: sh tool/publish/export_public.sh <commit> <carpeta-destino>' >&2
    exit 2
fi
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -n "${PUBLIC_PYTHON:-}" ]; then
    python_command=$PUBLIC_PYTHON
elif command -v python >/dev/null 2>&1; then
    python_command=python
else
    python_command=python3
fi
exec "$python_command" -B "$script_dir/export_public.py" "$1" "$2"
