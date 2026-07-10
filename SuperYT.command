#!/bin/bash
# Lanzador de SuperYT (doble clic para abrir la aplicacion)
cd "$(dirname "$0")"

if command -v python3.12 >/dev/null 2>&1; then
    exec python3.12 app.py
else
    exec python3 app.py
fi
