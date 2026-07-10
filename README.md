# SuperYT (Mac) — Descargador local de YouTube y Odysee

Aplicación de escritorio para descargar videos de YouTube u Odysee en la mejor calidad disponible.
Soporta videos individuales y listas de reproducción completas (en lotes).

Esta es la versión para macOS. Si buscás la versión para Windows, es un repositorio aparte.

## Primeros pasos (solo una vez)

1. Descomprimí el zip en una carpeta cualquiera (o cloná el repo).
2. **Doble clic en `Instalar.command`.**
   - Se abre la app Terminal y corre el instalador. macOS puede mostrar una advertencia
     de Gatekeeper ("no se puede abrir porque proviene de un desarrollador no
     identificado"). Para permitirlo: clic derecho (o Control+clic) sobre `Instalar.command`,
     elegí **"Abrir"**, y confirmá en el cuadro de diálogo que aparece. Solo hace falta
     la primera vez.
   - El instalador revisa que tengas **Homebrew** (el administrador de paquetes de macOS).
     Si no lo tenés, te va a pedir que lo instales desde https://brew.sh y que vuelvas
     a correr `Instalar.command` después.
   - Con Homebrew ya presente, instala automáticamente Python 3.12 (con Tkinter, la
     interfaz gráfica), las dependencias de Python y Deno. Puede tardar varios minutos
     según la conexión.
   - Si tu Homebrew tiene problemas típicos de instalaciones viejas (carpetas sin permiso
     de escritura, enlaces de versiones anteriores), el instalador los corrige solo y
     reintenta. Para corregir permisos puede **pedirte la contraseña de tu usuario** —
     es normal, la pide el propio macOS para autorizar el arreglo.
   - Al final va a decir **"Instalación completa"**. Presioná ENTER para cerrar esa ventana.
3. Necesitás conexión a internet durante este paso (no después, para usar la app).

Este paso se hace **una sola vez** por computadora.

## Cómo ejecutarla (después de instalar)

**Doble clic en `SuperYT.command`.** (La primera vez también puede pedir el mismo permiso
de Gatekeeper que `Instalar.command` — clic derecho → Abrir.)

Si preferís la terminal:

```
python3 app.py
```

## Cómo usarla

1. Pegá una o varias URLs de YouTube u Odysee en el cuadro de texto, **una por línea**.
   - Video de YouTube: `https://www.youtube.com/watch?v=...`
   - Lista de YouTube: `https://www.youtube.com/playlist?list=...`
   - Video de Odysee: `https://odysee.com/@canal/nombre-del-video`
   - Canal de Odysee (se trata como lista): `https://odysee.com/@canal`
2. Elegí la carpeta de destino (por defecto: `~/Downloads/SuperYT`).
3. Elegí el modo:
   - **Mejor calidad (video + audio)**: descarga la máxima resolución disponible (4K si existe).
   - **Solo audio (MP3)**: extrae únicamente el audio en la mejor calidad.
4. En modo video, elegí el formato del archivo: **MKV** (recomendado, tildado por defecto)
   o **MP4**. Sea cual sea el formato original del video, se convierte (remux, sin perder
   calidad) al que elijas.
5. (Opcional) Marcá **"Elegir qué videos bajar de cada lista de reproducción"**:
   antes de descargar una lista, se abre una ventana con todos sus videos para que
   marques cuáles querés (con botones *Todos* / *Ninguno*, o podés omitir la lista entera).
   Si la casilla está desmarcada, se baja la lista completa.
6. (Opcional, solo en modo video) Elegí qué hacer con los **subtítulos en español**:
   - **No bajar**: no hace nada (por defecto).
   - **Como archivo .srt aparte**: se guarda el `.srt` en la misma carpeta, sin tocar el video.
   - **Quemados en el video**: el texto queda dibujado directamente sobre la imagen,
     de forma permanente (se ve en cualquier reproductor o dispositivo, pero no se puede
     apagar ni cambiar de idioma). Como hay que recodificar el video entero, tarda bastante
     más que las otras opciones.

   En cualquiera de las dos opciones: si el video tiene subtítulos en español (manuales o
   automáticos) se usan esos; si **no** tiene español pero sí inglés, SuperYT los traduce
   automáticamente (usando Google Translate por detrás); si no tiene ninguno de los dos
   idiomas, se descarga el video normalmente y no se agrega nada.
7. (Opcional) **"Si YouTube da el error 'no soy un robot', usar la sesión iniciada en:"** —
   dejalo en **Ninguno** salvo que YouTube bloquee las descargas pidiendo verificación
   (ver [Notas](#notas) más abajo).
8. Presioná **Descargar**.

Las listas de reproducción se guardan en una subcarpeta con el nombre de la lista,
con los videos numerados según su posición en la lista. Si un video de la lista
falla, la descarga continúa con el resto.

## Notas

- La traducción de subtítulos necesita internet (usa un servicio de traducción en línea,
  gratuito, sin necesidad de cuenta ni clave). Si falla o no hay conexión, la descarga
  del video sigue igual, simplemente sin subtítulos.
- Si YouTube responde **"Sign in to confirm you're not a bot"** (suele venir acompañado
  de un "HTTP Error 429: Too Many Requests"), está bloqueando temporalmente las descargas
  sin sesión desde tu conexión. Primero probá esperar unas horas. Si sigue, elegí en el
  selector de la app el navegador donde tengas la **sesión de YouTube/Google iniciada**
  (Safari, Chrome, Firefox, etc.) y reintentá — la app descarga usando esa sesión, que es
  la solución que recomienda el propio yt-dlp. Detalles según el navegador:
  - **Safari**: macOS protege sus cookies; si falla la lectura, activá "Terminal" en
    Ajustes del Sistema → Privacidad y seguridad → **Acceso total al disco**, y volvé
    a abrir la app.
  - **Chrome / Edge / Brave / Opera**: la primera vez macOS puede pedir acceso al
    **llavero** — poné tu contraseña y elegí "Permitir siempre".
  - **Firefox**: no pide nada especial.

  Tené en cuenta que con esta opción las descargas quedan asociadas a esa cuenta de
  Google; para uso normal no hay problema, por eso igualmente lo recomendable es dejar
  "Ninguno" mientras no aparezca el error.
- YouTube a veces limita momentáneamente cuántos subtítulos se pueden pedir seguidos
  ("HTTP Error 429"). Si pasa, SuperYT reintenta solo la descarga del subtítulo unas
  pocas veces antes de rendirse; el video en sí no se ve afectado.
- Si YouTube cambia algo y las descargas empiezan a fallar, actualizá yt-dlp:
  ```
  python3 -m pip install --upgrade yt-dlp --break-system-packages
  ```

## ¿Qué instala `Instalar.command`?

- **Python 3.12** (si no lo tenías, vía Homebrew).
- **Tkinter** (`python-tk@3.12`): la interfaz gráfica. El Python de Homebrew no la trae
  incluida, así que se instala aparte.
- **yt-dlp**, **ffmpeg** y **yt-dlp-ejs** (el motor de descarga, el que une video+audio,
  y el resolutor del desafío de JavaScript que exige YouTube en algunos videos).
- **Deno** (otro requisito para resolver ese mismo desafío de JavaScript).

Todo se instala en tu usuario de macOS a través de Homebrew, sin tocar nada del sistema
más allá de lo que Homebrew ya gestiona.

## Instalación manual (por si `Instalar.command` falla)

1. Instalar Homebrew desde https://brew.sh.
2. `brew install python@3.12 python-tk@3.12 deno`
3. En la carpeta del proyecto: `python3.12 -m pip install -r requirements.txt --break-system-packages`
4. Ejecutar con `SuperYT.command` o `python3.12 app.py`.
