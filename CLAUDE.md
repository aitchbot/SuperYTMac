# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

SuperYT (Mac) is the macOS port of a single-file desktop app (Tkinter GUI) that wraps `yt-dlp`
to download videos or full playlists in the best available quality, individually or in batch.
It has no site-specific logic: any URL `yt-dlp` can extract works, which today in practice means
YouTube (videos/playlists) and Odysee (videos/channels, since yt-dlp's `lbry` extractor treats an
Odysee channel as a playlist). Don't add per-site branching to `app.py` — new site support should
come for free from yt-dlp unless something breaks that assumption. It's built for a non-technical
end user (an installer script does all setup), so all UI text, identifiers, and comments are in
Spanish — keep new code consistent with that.

**This repo was ported from the Windows version without access to a real Mac to test on.**
The porting changes (right-click binding, mouse-wheel scroll direction, Deno path detection,
dropping `windowsfilenames`) are based on documented Tk/macOS behavior, not verified by running
the app. If something in the "macOS-specific" sections below turns out to be wrong once someone
actually runs this on a Mac, trust the real behavior over this file and fix both.

## Commands

Run the app:
```
python3 app.py
```
(Use `python3.12` explicitly if that's what `Instalar.command` installed via Homebrew and
plain `python3` on the machine still resolves to an older system Python.)

Install/update dependencies:
```
python3 -m pip install -r requirements.txt --break-system-packages
```
The `--break-system-packages` flag is needed because Homebrew's Python 3.12+ marks itself
"externally managed" (PEP 668) and refuses a global `pip install` otherwise. It's a no-op
(and harmless) on a python.org-installed Python that isn't externally managed.

There is no build step, lint config, or test suite in this repo.

## Architecture

Everything lives in [app.py](app.py), a single `tk.Tk` subclass (`SuperYT`). There is no
separate backend/frontend split — the GUI class also owns the download logic. This mirrors
the Windows version closely; when porting a fix from there, check whether it's Windows-specific
(skip it) or general (apply it here too).

**Threading model.** Tkinter is not thread-safe, so downloads never touch widgets directly:
- `_iniciar` spawns a daemon thread running `_descargar`, which does all `yt_dlp.YoutubeDL` work.
- That thread only communicates by putting tuples onto `self.cola_msgs` (a `queue.Queue`):
  `("progreso", pct, texto)`, `("log", texto)`, `("estado", texto)`, `("seleccion", info, resultado, evento)`,
  `("fin", texto)`.
- `_procesar_cola`, scheduled via `self.after(100, ...)`, drains the queue on the main thread and
  updates widgets. Any new message type must be handled there.

**Cross-thread playlist picker.** When the "elegir qué videos bajar" checkbox is on, the worker
thread calls `_info_lista` (flat playlist extraction) then `_pedir_seleccion`, which posts a
`"seleccion"` message carrying a shared `dict` and a `threading.Event`, then blocks on
`evento.wait()`. The main thread's queue loop calls `_dialogo_seleccion` to build the `Toplevel`
checklist; closing it (confirm or "Omitir lista") writes the chosen indices into the shared dict
and sets the event, unblocking the worker. Selected indices get compacted into a yt-dlp
`playlist_items` range string via `_compactar` (e.g. `[1,2,3,5,7,8]` → `"1-3,5,7-8"`).

**Output template.** `outtmpl` uses yt-dlp field replacement so a lone video lands directly in
the destination folder, while a playlist gets its own subfolder named after the playlist title,
with entries prefixed by playlist index. Don't simplify this to a plain f-string — the
conditional `%(playlist_title|)s` syntax is what avoids creating an empty subfolder for
non-playlist URLs.

**ffmpeg** is not a system dependency — it ships via the `imageio_ffmpeg` package (which bundles
the right binary for the host's architecture, Apple Silicon or Intel) and its path is passed to
yt-dlp as `ffmpeg_location`.

**Subtitle handling via a custom yt-dlp postprocessor.** yt-dlp can download subtitles but can't
translate or burn them in, and there's no way to conditionally pick "Spanish if present, else
translated English" using yt-dlp's declarative `postprocessors` option list alone (subtitle files
land on disk before any `post_process`-stage postprocessor runs, but you can't inspect/rewrite
them from there without a custom class). `_TraductorSubtitulosPP` (subclasses yt-dlp's
`PostProcessor`) is registered via `ydl.add_post_processor(..., when="post_process")` *after*
the instance is created, so it runs after the declarative `FFmpegVideoRemuxer` entry (which was
registered earlier, during `YoutubeDL.__init__` from the `postprocessors` option) — this ordering
is what guarantees translation/burning happens on the already-remuxed final container. Its
`run()` picks one subtitle language to keep (prefers anything in `IDIOMAS_ES`; otherwise
translates the first `IDIOMAS_EN` match via `_traducir_srt` and synthesizes an `"es"` entry),
deletes every other downloaded subtitle file, then either leaves the `.srt` on disk as-is
(`modo == "srt"`) or burns it into the video pixels via its own `subprocess` call to ffmpeg's
`subtitles` filter (`modo == "hardsub"`, re-encodes with `libx264` since burning requires
pixel-level compositing — can't be a stream copy like the rest of the pipeline). There is
deliberately no "soft-embed as a selectable track" option: the user was offered that choice and
picked exactly two outcomes (plain `.srt` file, or permanently burned-in). `_traducir_srt` batches
cues into one translation call per ~3500 characters (falls back to per-cue translation if a batch
comes back misaligned) to avoid one network round-trip per subtitle line. If a subtitle's own
download failed (YouTube 429s this endpoint fairly often), `_reintentar_descarga_subtitulo` retries
a few times with increasing backoff using the subtitle's own URL before giving up.

The `_quemar_subtitulos` ffmpeg subprocess sends `stderr` to a `tempfile.TemporaryFile`, not a
`subprocess.PIPE` — reading only `stdout` in a blocking loop while `stderr` is also a pipe deadlocks
once ffmpeg fills that pipe's OS buffer (it doesn't take much output for a re-encode of any real
length). This bit the Windows version once already; don't "simplify" it back to
`stdout=PIPE, stderr=PIPE`.

**Subtitle language codes are an intentional allowlist, not a regex.** `IDIOMAS_ES`/`IDIOMAS_EN`
list exact codes (`es`, `es-419`, `es-ES`, ...) instead of a `"es.*"` pattern. YouTube's automatic
captions expose a chain-translation matrix where e.g. `es-ar` means "Spanish translated from
Arabic" — a broad regex would match and embed several redundant/lower-quality auto-translated
tracks alongside the real one.

## macOS-specific porting notes

**Right-click context menu.** `_agregar_menu_contextual` binds `<Button-2>`, `<Button-3>`, *and*
`<Control-Button-1>`. On Windows/Linux, right-click is unambiguously `<Button-3>`. On macOS with
Tk, which button number a real right-click fires depends on the mouse/trackpad and Tk version —
historically `<Button-2>` (one-button-mouse legacy), sometimes `<Button-3>` with a genuine
two-button mouse. `<Control-Button-1>` is the classic trackpad/one-button-mouse "right-click"
gesture on macOS and should always work regardless of how the physical click gets reported. Don't
drop any of the three without testing on real hardware first.

**Mouse-wheel scroll direction** (playlist picker dialog). The Windows version divides
`event.delta // 120` because Windows reports wheel movement in multiples of 120. macOS reports
much smaller `delta` values (not a fixed multiple), so that division would floor to 0 almost
always and the wheel would do nothing. This version just looks at the sign of `event.delta`
instead (`-1 if e.delta > 0 else 1`) — the standard cross-platform-safe idiom for Tk on macOS.

**Deno detection** (`_detectar_deno`). Same PATH-first lookup as Windows, but the fallback checks
Homebrew's install locations (`/opt/homebrew/bin/deno` for Apple Silicon, `/usr/local/bin/deno`
for Intel) instead of a WinGet packages folder — for the same underlying reason: a shell that just
ran `brew install deno` may not see it on `PATH` until a new terminal/session starts.

**No `"windowsfilenames": True`** in the yt-dlp options (present in the Windows version). That
option forces filenames into a Windows-safe character subset; unnecessary and needlessly
restrictive on macOS's filesystem, so it's omitted here rather than carried over as dead weight.

## Installer scripts

`Instalar.command` is the macOS equivalent of the Windows `Instalar.ps1`/`.bat` pair — a single
double-clickable Bash script (Finder requires the executable bit for `.command` files to run on
double-click; if this file ever gets re-saved/re-generated, make sure that bit survives). It
checks for Homebrew first and **stops with instructions instead of auto-installing it** — unlike
`winget` (present by default on Windows 11) or the rest of this script's `brew install` calls,
bootstrapping Homebrew itself runs a remote script with `sudo`, which is a bigger trust step than
this installer should take silently on someone else's machine. Once Homebrew is confirmed present,
it's treated as trusted for everything downstream (`brew install python@3.12`, `brew install deno`),
same posture as the Windows script trusting `winget`. `SuperYT.command` is the everyday
launcher; it prefers `python3.12` (matching what the installer set up) and falls back to `python3`.

When editing installer logic, keep it non-destructive and safe to re-run.
