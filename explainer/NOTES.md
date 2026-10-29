# Explainer video — process notes

Running log of what was tried while making the repo explainer video.

## Approach (from web research)

Searching for "how people use Claude to make codebase explainer videos" turned up one dominant pattern:
**Claude Code + [Remotion](https://www.remotion.dev/)** — Claude writes React components for each scene,
Remotion renders them to MP4. Remotion publishes an official agent skill (`remotion-dev/skills`);
its rules were followed here:

- one component per scene, stitched with `<TransitionSeries>` (fade transitions)
- every animation driven by `useCurrentFrame()` + `interpolate()` with `Easing.spring` / `Easing.bezier`
  (no CSS transitions/animations — they don't render frame-accurately)
- `fps` from `useVideoConfig()` for all seconds→frames maths
- assets in `public/`, referenced via `staticFile()`

Alternatives seen (Manim, HTML + Playwright + ffmpeg, HyperFrames) were not used: Remotion is the best
fit for code/diagram-heavy explainers and was the most common recommendation.

Voiceover: the Remotion skill suggests ElevenLabs, which needs an API key. Used **Kokoro TTS**
(open-weights, runs locally on CPU) instead.

## Content grounding — everything shown is real output

Built and ran each stage in a scratch dir before writing any scene:

| Stage | Command | Result |
|---|---|---|
| A2 lexer | `gcc a2/7_A2/lex.yy.c a2/7_A2/7_A2.c` | works; token stream used in the Lexer scene |
| A2 lexer (top-level `a2/7_A2.l`) | `flex a2/7_A2.l` | **fails** on modern flex: `7_A2.l:44: unrecognized rule` (the `intconst` definition is wrapped in `{…}`; the copy in `a2/7_A2/7_A2.l` is fixed) |
| A3 parser | `flex 7_A3.l && bison -d 7_A3.y && gcc …` | works (1 shift/reduce conflict warning); reductions for `sum = sum + i;` used in the Parser scene |
| A4 translator | `flex 7_A4.l && bison 7_A4.y … && gcc … -ll` | builds (1 reduce/reduce conflict warning) |
| A4 on bundled `a4/7_A4.nc` (bubble sort) | `./translator < 7_A4.nc` | **segfault** in `insert_entry` (`7_A4_translator.c:107`) |
| A4 on any function with parameters | e.g. `int max(int a, int b)` | **segfault**, same place |
| A4 on `explainer/demo.nc` (loop + if, no params) | `./translator < demo.nc` | works; the 20 quads shown in the demo scene are this exact output |

Root cause of the segfault (found with `-fsanitize=address`): `new_symtab()` mallocs the table but never
initialises `n_elems`, so `insert_entry()` writes to a garbage index. The video mentions this as a caveat.
The repo's compiler code was **not** modified.

Also noted: the Makefile hard-codes `CC=gcc-13`, which isn't installed here; plain `gcc` works.

## Environment hurdles

- `flex` wasn't installed → `apt-get install flex`.
- Piper TTS voices are on Hugging Face → blocked by the network policy (403).
- Switched to Kokoro (`kokoro-onnx`), whose model files are on GitHub releases (allowed).
- `kokoro-onnx`'s bundled espeak-ng has a hard-coded data path that doesn't exist
  (`/home/runner/work/espeakng-loader/...`), even with `ESPEAK_DATA_PATH` set →
  installed system `espeak-ng` and passed `EspeakConfig(lib_path=..., data_path=...)` explicitly.
- Google Fonts CDN (`fonts.gstatic.com`) not reachable → used the locally installed Inter and
  JetBrains Mono instead.

## Syncing visuals to narration

Kokoro returns audio only, no word timestamps. `src/timing.ts` estimates when a phrase is spoken from
its character offset in the scene's text (assumes a uniform speaking rate). Checked against the real
audio with `ffmpeg silencedetect` (pauses between sentences) on the parser, symtab and demo clips:
predicted sentence starts were 0–1.2 s off, usually slightly *early*, so visuals lead the voice a
little rather than lag it. Good enough; if tighter sync is ever needed, synthesise per sentence and
record exact offsets.
Captions use the same timing; a small replacement table turns TTS spellings back into written form
("G C C" → "GCC", "t zero zero zero zero" → "t0000", …).

## Visual QA iterations

1. First stills pass: content overflowed the right edge in most scenes. Cause: the content
   container was `<AbsoluteFill>`, which forces `width: 100%` on top of `left/right: 96px`.
   Replaced it with a plain absolutely-positioned div.
2. JetBrains Mono ligatures rendered `->` as an arrow in C code; disabled with
   `fontVariantLigatures: 'none'`.
3. Parser terminal panel clipped its last line; showed 8 lines instead of 9 and made the panel taller.

Rendering uses the pre-installed `chrome-headless-shell` (`--browser-executable`), so Remotion
doesn't have to download a browser.

## How to rebuild

See `README.md` in this folder.
