import React from 'react';
import {AbsoluteFill} from 'remotion';
import {colorOf, Reveal, Scene} from '../components';
import {colors, fonts, Stage} from '../theme';
import {cue} from '../timing';

const STAGES: {stage: Stage; label: string; phrase: string}[] = [
  {stage: 'lexer', label: 'Lexer', phrase: 'Lexer'},
  {stage: 'parser', label: 'Parser', phrase: 'parser'},
  {stage: 'translator', label: 'Translator', phrase: 'translator'},
];

export const OutroScene: React.FC = () => (
  <Scene id="outro">
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column'}}>
      <div style={{display: 'flex', gap: 28, alignItems: 'center'}}>
        {STAGES.map(({stage, label, phrase}, i) => (
          <React.Fragment key={stage}>
            {i > 0 ? <div style={{fontSize: 48, color: colors.faint}}>→</div> : null}
            <Reveal at={cue('outro', phrase)}>
              <div style={{fontSize: 72, fontWeight: 800, color: colorOf(stage)}}>{label}</div>
            </Reveal>
          </React.Fragment>
        ))}
      </div>
      <Reveal at={cue('outro', 'in about')} style={{marginTop: 48, textAlign: 'center'}}>
        <div style={{fontSize: 40, fontWeight: 600}}>~3,500 lines of Flex, Bison and C</div>
        <div style={{fontFamily: fonts.mono, fontSize: 28, color: colors.muted, marginTop: 20}}>
          github.com/SaptarishiD/cs1319-compiler-design
        </div>
      </Reveal>
    </AbsoluteFill>
  </Scene>
);
