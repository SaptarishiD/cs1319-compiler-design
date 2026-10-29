"""Synthesise narration.json into public/audio/<id>.mp3 and write src/timings.json.

Usage:
    python scripts/tts.py --model kokoro.onnx --voices voices.bin

Model files: https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0
Needs system espeak-ng (apt-get install espeak-ng).
"""
import argparse
import json
import subprocess
from pathlib import Path

import soundfile as sf
from kokoro_onnx import EspeakConfig, Kokoro
from tqdm import tqdm

ROOT = Path(__file__).resolve().parent.parent
FPS = 30
# Silence before / after the voice inside each scene, in seconds.
LEAD_IN = 0.6
TAIL = 1.0

parser = argparse.ArgumentParser()
parser.add_argument("--model", required=True)
parser.add_argument("--voices", required=True)
parser.add_argument("--voice", default="am_michael")
parser.add_argument("--speed", type=float, default=1.0)
parser.add_argument("--espeak-lib", default="/usr/lib/x86_64-linux-gnu/libespeak-ng.so.1")
parser.add_argument("--espeak-data", default="/usr/lib/x86_64-linux-gnu/espeak-ng-data")
args = parser.parse_args()

kokoro = Kokoro(
    args.model,
    args.voices,
    espeak_config=EspeakConfig(lib_path=args.espeak_lib, data_path=args.espeak_data),
)

scenes = json.loads((ROOT / "narration.json").read_text())
out_dir = ROOT / "public" / "audio"
out_dir.mkdir(parents=True, exist_ok=True)

timings = {}
for scene in tqdm(scenes, desc="Synthesising narration"):
    samples, sr = kokoro.create(scene["text"], voice=args.voice, speed=args.speed, lang="en-us")
    wav = out_dir / f"{scene['id']}.wav"
    sf.write(wav, samples, sr)
    mp3 = out_dir / f"{scene['id']}.mp3"
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-b:a", "128k", str(mp3)],
        check=True,
    )
    wav.unlink()
    voice_seconds = len(samples) / sr
    timings[scene["id"]] = {
        "voiceFrames": round(voice_seconds * FPS),
        "leadInFrames": round(LEAD_IN * FPS),
        "durationInFrames": round((LEAD_IN + voice_seconds + TAIL) * FPS),
    }

(ROOT / "src" / "timings.json").write_text(json.dumps(timings, indent=2) + "\n")
total = sum(t["durationInFrames"] for t in timings.values()) / FPS
print(f"Wrote {len(timings)} clips, ~{total:.1f}s of scenes (before transition overlap)")
