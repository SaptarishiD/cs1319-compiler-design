import React from 'react';
import {Code, DEMO_SOURCE, Panel, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

const FEATURES: {label: string; phrase: string}[] = [
  {label: 'int · char · void', phrase: 'int, char'},
  {label: 'pointers', phrase: 'pointers'},
  {label: '1-D arrays', phrase: 'one-dimensional'},
  {label: 'if / else', phrase: 'if-else'},
  {label: 'for loops', phrase: 'for loops'},
  {label: 'functions', phrase: 'and functions'},
];

const KEYWORDS = ['int', 'char', 'void', 'if', 'else', 'for', 'return'];

export const NanoCScene: React.FC = () => (
  <Scene id="nanoc" stage="a1" kicker="THE LANGUAGE" title="nanoC: just enough C">
    <div style={{display: 'flex', gap: 64, marginTop: 20}}>
      <div style={{flex: 1}}>
        <div style={{display: 'flex', flexWrap: 'wrap', gap: 18}}>
          {FEATURES.map((f) => (
            <Reveal key={f.label} at={cue('nanoc', f.phrase)}>
              <div
                style={{
                  fontSize: 34,
                  fontWeight: 600,
                  padding: '16px 28px',
                  borderRadius: 14,
                  backgroundColor: colors.bgPanel,
                  border: `2px solid ${colors.border}`,
                }}
              >
                {f.label}
              </div>
            </Reveal>
          ))}
        </div>
        <Reveal at={cue('nanoc', 'only seven')} style={{marginTop: 56}}>
          <div style={{fontSize: 26, color: colors.muted, marginBottom: 14}}>All 7 keywords</div>
          <div style={{display: 'flex', gap: 12, flexWrap: 'wrap'}}>
            {KEYWORDS.map((k) => (
              <div
                key={k}
                style={{
                  fontFamily: fonts.mono,
                  fontSize: 30,
                  fontWeight: 700,
                  color: colors.a1,
                  padding: '8px 18px',
                  borderRadius: 10,
                  border: `2px solid ${colors.a1}66`,
                }}
              >
                {k}
              </div>
            ))}
          </div>
        </Reveal>
      </div>
      <Reveal at={cue('nanoc', 'follow this')} style={{width: 720}}>
        <Panel title="demo.nc — our running example" accent={colors.a1}>
          <Code lines={DEMO_SOURCE} accent={colors.a1} fontSize={30} />
        </Panel>
      </Reveal>
    </div>
  </Scene>
);
