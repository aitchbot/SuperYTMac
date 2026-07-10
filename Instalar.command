#!/bin/bash
# Instalador de SuperYT para Mac: deja la computadora lista para correr la app
# (Python, yt-dlp, ffmpeg y Deno). Doble clic aqui la PRIMERA vez.
set -e
cd "$(dirname "$0")"

echo "=== Instalador de SuperYT ==="
echo ""

# 1) Homebrew (administrador de paquetes de macOS)
if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: no se encontro Homebrew."
    echo "Instalalo desde https://brew.sh (copia y pega el comando de esa pagina"
    echo "en la app Terminal) y despues volve a correr este instalador."
    read -p "Presiona ENTER para salir"
    exit 1
fi
echo "Homebrew encontrado: $(command -v brew)"

# 2) Python 3.12
PYTHON=""
if command -v python3.12 >/dev/null 2>&1; then
    PYTHON="python3.12"
elif python3 --version 2>/dev/null | grep -qE "Python 3\.1[2-9]"; then
    PYTHON="python3"
fi
if [ -z "$PYTHON" ]; then
    echo ""
    echo "Instalando Python 3.12 (via Homebrew, puede tardar unos minutos)..."
    brew install python@3.12
    PYTHON="python3.12"
fi
echo "Usando: $("$PYTHON" --version)"

# 3) Dependencias de Python (yt-dlp + ffmpeg incluido)
echo ""
echo "Instalando yt-dlp y demas dependencias..."
# --break-system-packages evita el bloqueo "externally-managed-environment" que trae
# el Python de Homebrew; no tiene efecto (ni hace falta) si se usa otro Python.
"$PYTHON" -m pip install --upgrade pip --quiet --break-system-packages
"$PYTHON" -m pip install --upgrade -r requirements.txt --quiet --break-system-packages
echo "Listo."

# 4) Deno (necesario para que YouTube funcione correctamente)
echo ""
if command -v deno >/dev/null 2>&1; then
    echo "Deno ya esta instalado."
else
    echo "Instalando Deno (motor de JavaScript que necesita YouTube)..."
    brew install deno
fi

echo ""
echo "=== Instalacion completa ==="
echo "Ya podes usar SuperYT.command (doble clic) para abrir el programa."
read -p "Presiona ENTER para cerrar"
