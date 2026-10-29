// Render one preview still per scene: node scripts/stills.mjs <outDir> [browserExecutable] [fraction]
// Without a fraction, the still is taken 1s before the scene ends.
import path from 'node:path';
import {readFileSync} from 'node:fs';
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';

const [outDir, browserExecutable = null, fraction] = process.argv.slice(2);
const timings = JSON.parse(readFileSync('src/timings.json', 'utf8'));
const TRANSITION = 15;

const serveUrl = await bundle({entryPoint: path.resolve('src/index.ts')});
const composition = await selectComposition({serveUrl, id: 'NanoCExplainer', browserExecutable});

let start = 0;
const ids = Object.keys(timings);
for (const [i, id] of ids.entries()) {
  const d = timings[id].durationInFrames;
  const frame = start + (fraction ? Math.round(d * Number(fraction)) : d - 30);
  await renderStill({composition, serveUrl, frame, output: path.join(outDir, `${i}-${id}.png`), browserExecutable});
  console.log(`[${i + 1}/${ids.length}] ${id} @ frame ${frame}`);
  start += timings[id].durationInFrames - TRANSITION;
}
