import React from 'react';
import {colorOf, Reveal, Scene} from '../components';
import {colors, fonts, Stage} from '../theme';
import {cue} from '../timing';

const FOLDERS: {dir: string; stage: Stage; role: string; files: string[]; lines: string; phrase: string}[] = [
  {
    dir: 'a1/',
    stage: 'a1',
    role: 'Warm-up: languages + GCC',
    files: ['a1.c', 'Assignment_1.pdf'],
    lines: 'written answers',
    phrase: 'A1 is',
  },
  {
    dir: 'a2/',
    stage: 'lexer',
    role: 'Lexer · Flex',
    files: ['7_A2.l', '7_A2.c', '7_test_output/'],
    lines: '70 lines',
    phrase: 'A2 builds',
  },
  {
    dir: 'a3/',
    stage: 'parser',
    role: 'Parser · Bison',
    files: ['7_A3.l', '7_A3.y', 'samples/'],
    lines: '432 lines',
    phrase: 'A3 builds',
  },
  {
    dir: 'a4/',
    stage: 'translator',
    role: 'Translator → TAC',
    files: ['7_A4.l', '7_A4.y', '7_A4_translator.c/.h'],
    lines: '2,954 lines',
    phrase: 'And A4',
  },
];

const FLOW: {label: string; sub: string; color: string}[] = [
  {label: 'program.nc', sub: 'source', color: colors.muted},
  {label: 'tokens', sub: 'A2', color: colors.lexer},
  {label: 'parse', sub: 'A3', color: colors.parser},
  {label: 'quads', sub: 'A4', color: colors.translator},
];

export const MapScene: React.FC = () => {
  const flowAt = cue('map', 'joins them');
  return (
    <Scene id="map" stage="a1" kicker="THE REPOSITORY" title="One folder per assignment">
      <div style={{display: 'flex', gap: 28, marginTop: 20}}>
        {FOLDERS.map((f) => (
          <Reveal key={f.dir} at={cue('map', f.phrase)} style={{flex: 1}}>
            <div
              style={{
                backgroundColor: colors.bgPanel,
                border: `2px solid ${colors.border}`,
                borderTop: `6px solid ${colorOf(f.stage)}`,
                borderRadius: 16,
                padding: '26px 28px',
                height: 330,
              }}
            >
              <div style={{fontFamily: fonts.mono, fontSize: 48, fontWeight: 800, color: colorOf(f.stage)}}>
                {f.dir}
              </div>
              <div style={{fontSize: 30, fontWeight: 700, marginTop: 8}}>{f.role}</div>
              <div style={{marginTop: 18}}>
                {f.files.map((file) => (
                  <div key={file} style={{fontFamily: fonts.mono, fontSize: 22, color: colors.muted, marginTop: 6}}>
                    {file}
                  </div>
                ))}
              </div>
              <div style={{fontSize: 20, color: colors.faint, marginTop: 18, fontFamily: fonts.mono}}>{f.lines}</div>
            </div>
          </Reveal>
        ))}
      </div>
      <div style={{display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 18, marginTop: 56}}>
        {FLOW.map((step, i) => (
          <React.Fragment key={step.label}>
            {i > 0 ? (
              <Reveal at={flowAt + i * 8}>
                <div style={{fontSize: 44, color: colors.faint}}>→</div>
              </Reveal>
            ) : null}
            <Reveal at={flowAt + i * 8}>
              <div
                style={{
                  fontFamily: fonts.mono,
                  fontSize: 30,
                  padding: '14px 28px',
                  borderRadius: 12,
                  border: `2px solid ${step.color}`,
                  color: step.color,
                  textAlign: 'center',
                }}
              >
                {step.label}
                <div style={{fontSize: 18, color: colors.muted}}>{step.sub}</div>
              </div>
            </Reveal>
          </React.Fragment>
        ))}
      </div>
    </Scene>
  );
};
