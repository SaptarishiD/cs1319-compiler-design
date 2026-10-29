import narration from '../narration.json';
import timings from './timings.json';

export type SceneId = keyof typeof timings;

const textOf = (id: SceneId): string => {
  const scene = narration.find((s) => s.id === id);
  if (!scene) {
    throw new Error(`No narration for scene "${id}"`);
  }
  return scene.text;
};

/**
 * Frame (relative to the scene start) at which `phrase` is spoken.
 * Kokoro gives no word timestamps, so this assumes a uniform speaking rate
 * and maps the phrase's character offset onto the voice clip's length.
 */
export const cue = (id: SceneId, phrase: string): number => {
  const text = textOf(id);
  const index = text.indexOf(phrase);
  if (index === -1) {
    throw new Error(`Phrase "${phrase}" not found in narration for "${id}"`);
  }
  const t = timings[id];
  return Math.round(t.leadInFrames + (index / text.length) * t.voiceFrames);
};

// Narration is spelled for the TTS voice; captions show the written form.
const CAPTION_FIXES: [string, string][] = [
  ['c s 13 19 compiler design', 'cs1319-compiler-design'],
  ['G C C', 'GCC'],
  ['gcc 13', 'gcc-13'],
  ['t zero zero zero zero', 't0000'],
  ['t zero zero zero one', 't0001'],
  ['new symtab', 'new_symtab'],
  ['Nano C', 'nanoC'],
  ['nano C', 'nanoC'],
  ['sum equals sum plus i', 'sum = sum + i'],
];

/** Sentences of a scene's narration with the frame each one starts at. */
export const sentences = (id: SceneId): {text: string; from: number}[] => {
  const text = textOf(id);
  const parts = text.match(/[^.!?]+[.!?]+/g) ?? [text];
  return parts.map((p) => {
    const trimmed = p.trim();
    const shown = CAPTION_FIXES.reduce((s, [from, to]) => s.split(from).join(to), trimmed);
    return {text: shown, from: cue(id, trimmed)};
  });
};

export {timings};
