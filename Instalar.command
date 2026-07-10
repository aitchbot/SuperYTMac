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

# Corre "brew install" y, si falla por los problemas tipicos de un Homebrew viejo
# en /usr/local (carpetas cuyo dueno ya no es el usuario actual, o enlaces sueltos
# de versiones anteriores que bloquean "brew link"), aplica el arreglo que el propio
# brew sugiere en su mensaje de error y reintenta. Cualquier otro error corta aca.
instalar_con_brew() {
    local formula="$1"
    local log intento status
    log="$(mktemp)"
    for intento in 1 2 3; do
        # tee: mostrar el progreso en pantalla y a la vez guardarlo para analizarlo
        brew install "$formula" 2>&1 | tee "$log"
        status=${PIPESTATUS[0]}
        if [ "$status" -eq 0 ]; then
            rm -f "$log"
            return 0
        fi

        # Caso 1: "The following directories are not writable by your user"
        # Brew lista las carpetas afectadas; les devolvemos la propiedad al usuario
        # actual. Pide la contrasena porque hace falta sudo para cambiar el dueno.
        if grep -q "not writable by your user" "$log"; then
            local dirs
            dirs=$(sed -n '/not writable by your user/,/^$/p' "$log" | grep '^/' || true)
            if [ -n "$dirs" ]; then
                echo ""
                echo "Homebrew necesita permisos sobre estas carpetas:"
                echo "$dirs"
                echo "Se va a pedir tu contrasena para corregirlas (sudo chown)."
                # Sin comillas a proposito: son varias rutas, una por linea
                if sudo chown -R "$(whoami)" $dirs && chmod u+w $dirs; then
                    echo "Permisos corregidos. Reintentando la instalacion..."
                    continue
                fi
            fi
        fi

        # Caso 2: "Could not symlink ... You can unlink it: brew unlink X".
        # Quedaron enlaces de una version vieja de la formula; "brew link
        # --overwrite" (el arreglo que sugiere el propio brew) los reemplaza.
        if grep -q "brew link --overwrite" "$log"; then
            local conflictivas f arreglado=""
            conflictivas=$(grep -oE "brew link --overwrite [^ ]+" "$log" | awk '{print $4}' | sort -u || true)
            for f in $conflictivas; do
                echo ""
                echo "Reemplazando enlaces viejos de '$f' (brew link --overwrite $f)..."
                if brew link --overwrite "$f"; then
                    arreglado=1
                fi
            done
            if [ -n "$arreglado" ]; then
                echo "Enlaces corregidos. Reintentando la instalacion..."
                continue
            fi
        fi

        break
    done
    rm -f "$log"
    echo ""
    echo "ERROR: no se pudo instalar '$formula' con Homebrew."
    echo "Revisa los mensajes de arriba para ver el motivo; si el error menciona"
    echo "un comando para corregirlo, correlo en Terminal y volve a ejecutar"
    echo "este instalador."
    read -p "Presiona ENTER para salir"
    exit 1
}

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
    instalar_con_brew python@3.12
    PYTHON="python3.12"
fi
echo "Usando: $("$PYTHON" --version)"

# 2b) Tkinter (la interfaz grafica de la app). El Python de Homebrew NO lo trae
# incluido (a diferencia del de Windows o el de python.org): viene en la formula
# aparte python-tk@3.12. Sin esto la app muere al arrancar con
# "No module named '_tkinter'".
if ! "$PYTHON" -c "import tkinter" >/dev/null 2>&1; then
    echo ""
    echo "Instalando Tkinter (la interfaz grafica)..."
    instalar_con_brew python-tk@3.12
    if ! "$PYTHON" -c "import tkinter" >/dev/null 2>&1; then
        # python-tk@3.12 habilita Tkinter en el python3.12 de Homebrew; si el
        # Python detectado era otro, cambiamos a ese (el launcher tambien lo
        # prefiere), siempre que ahora si tenga Tkinter.
        if command -v python3.12 >/dev/null 2>&1 && python3.12 -c "import tkinter" >/dev/null 2>&1; then
            PYTHON="python3.12"
            echo "Usando: $("$PYTHON" --version) (con Tkinter)"
        else
            echo ""
            echo "ERROR: Python sigue sin poder usar Tkinter (la interfaz grafica)."
            echo "Revisa los mensajes de arriba y volve a correr este instalador."
            read -p "Presiona ENTER para salir"
            exit 1
        fi
    fi
fi

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
    instalar_con_brew deno
fi

echo ""
echo "=== Instalacion completa ==="
echo "Ya podes usar SuperYT.command (doble clic) para abrir el programa."
read -p "Presiona ENTER para cerrar"
