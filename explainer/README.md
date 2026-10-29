# nanoC compiler — explainer video

A ~3.5 minute narrated walkthrough of this repository, built with [Remotion](https://www.remotion.dev/)
(React → MP4). The rendered video is `out/nanoc-explainer.mp4`.

Scenes: title → repo map → nanoC language → A2 lexer → A3 parser → A4 symbol tables & quads →
backpatching → real TAC for `demo.nc` → build & run → outro.

Every token stream, parser reduction, symbol table and quad shown on screen is real output from the
code in this repo run on [`demo.nc`](demo.nc). See [`NOTES.md`](NOTES.md) for how that was produced
and what was tried along the way.

## Layout

| Path | What |
|---|---|
| `narration.json` | Voiceover script, one entry per scene |
| `scripts/tts.py` | Synthesises `public/audio/*.mp3` with Kokoro TTS and writes `src/timings.json` |
| `src/timing.ts` | `cue(scene, phrase)` — frame at which a phrase is spoken, used to sync animations |
| `src/scenes/*.tsx` | One component per scene |
| `src/Video.tsx` | Stitches scenes with fade transitions and their audio |
| `scripts/stills.mjs` | Renders one preview PNG per scene |

## Re-render

```bash
npm install
npm run render -- --browser-executable=/path/to/chrome-headless-shell
```

(Drop `--browser-executable` to let Remotion download its own headless Chrome.)

Preview and tweak interactively:

```bash
npm run studio
```

## Regenerate narration

Only needed if you edit `narration.json`. Requires `espeak-ng` and the Kokoro model files from
<https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0>.

```bash
pip install kokoro-onnx soundfile tqdm
python scripts/tts.py --model kokoro-v1.0.int8.onnx --voices voices-v1.0.bin
```

`cue()` throws if a phrase used by a scene is no longer in the narration, so edits that break sync fail loudly.
