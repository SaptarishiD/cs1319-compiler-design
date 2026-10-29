import React from 'react';
import {Audio} from '@remotion/media';
import {staticFile} from 'remotion';
import {linearTiming, TransitionSeries} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {SceneId, timings} from './timing';
import {TitleScene} from './scenes/TitleScene';
import {MapScene} from './scenes/MapScene';
import {NanoCScene} from './scenes/NanoCScene';
import {LexerScene} from './scenes/LexerScene';
import {ParserScene} from './scenes/ParserScene';
import {SymtabScene} from './scenes/SymtabScene';
import {BackpatchScene} from './scenes/BackpatchScene';
import {DemoScene} from './scenes/DemoScene';
import {RunScene} from './scenes/RunScene';
import {OutroScene} from './scenes/OutroScene';

export const TRANSITION_FRAMES = 15;

const SCENES: {id: SceneId; Component: React.FC}[] = [
  {id: 'title', Component: TitleScene},
  {id: 'map', Component: MapScene},
  {id: 'nanoc', Component: NanoCScene},
  {id: 'lexer', Component: LexerScene},
  {id: 'parser', Component: ParserScene},
  {id: 'symtab', Component: SymtabScene},
  {id: 'backpatch', Component: BackpatchScene},
  {id: 'demo', Component: DemoScene},
  {id: 'run', Component: RunScene},
  {id: 'outro', Component: OutroScene},
];

export const totalFrames =
  SCENES.reduce((sum, s) => sum + timings[s.id].durationInFrames, 0) - (SCENES.length - 1) * TRANSITION_FRAMES;

export const NanoCExplainer: React.FC = () => (
  <TransitionSeries>
    {SCENES.map(({id, Component}, i) => (
      <React.Fragment key={id}>
        {i > 0 ? (
          <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: TRANSITION_FRAMES})} />
        ) : null}
        <TransitionSeries.Sequence name={id} durationInFrames={timings[id].durationInFrames}>
          <Component />
          <Audio src={staticFile(`audio/${id}.mp3`)} />
        </TransitionSeries.Sequence>
      </React.Fragment>
    ))}
  </TransitionSeries>
);
