import React from 'react';
import {useCurrentFrame} from 'remotion';
import {Panel, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

const COMMANDS = [
  'cd a4',
  'flex 7_A4.l',
  'bison 7_A4.y --header=7_A4.tab.h -o 7_A4.tab.c',
  'gcc lex.yy.c 7_A4.tab.c 7_A4_translator.c -ll -o translator',
  './translator < demo.nc',
];

const Typed: React.FC<{text: string; start: number}> = ({text, start}) => {
  const frame = useCurrentFrame();
  const chars = Math.max(0, Math.min(text.length, Math.floor((frame - start) * 1.6)));
  if (frame < start) {
    return null;
  }
  return (
    <div style={{whiteSpace: 'pre'}}>
      <span style={{color: colors.ok}}>$ </span>
      {text.slice(0, chars)}
    </div>
  );
};

export const RunScene: React.FC = () => {
  const typeAt = cue('run', 'generate the scanner');
  const makeAt = cue('run', 'The Makefile');
  const caveatAt = cue('run', 'One caveat');
  const per = Math.floor((makeAt - typeAt) / COMMANDS.length);
  return (
    <Scene id="run" stage="translator" kicker="TRY IT" title="Build and run">
      <div style={{display: 'flex', gap: 48}}>
        <Reveal at={typeAt - 10} style={{flex: 1}}>
          <Panel title="terminal" accent={colors.ok}>
            <div style={{fontFamily: fonts.mono, fontSize: 24, lineHeight: 1.7, padding: '18px 26px', minHeight: 300}}>
              {COMMANDS.map((c, i) => (
                <Typed key={c} text={c} start={typeAt + i * per} />
              ))}
            </div>
          </Panel>
          <Reveal at={makeAt} style={{marginTop: 26}}>
            <div style={{fontSize: 26, color: colors.muted}}>
              or <span style={{fontFamily: fonts.mono, color: colors.text}}>make build</span> — the Makefile sets{' '}
              <span style={{fontFamily: fonts.mono, color: colors.parser}}>CC=gcc-13</span>
            </div>
          </Reveal>
        </Reveal>
        <Reveal at={caveatAt} style={{width: 640}}>
          <Panel title="known issue" accent={colors.error}>
            <div style={{padding: '22px 26px', fontSize: 26, lineHeight: 1.5}}>
              Functions with parameters <b style={{color: colors.error}}>segfault</b> in{' '}
              <span style={{fontFamily: fonts.mono}}>insert_entry()</span>.
              <div style={{marginTop: 16, color: colors.muted}}>
                <span style={{fontFamily: fonts.mono, color: colors.text}}>new_symtab()</span> mallocs the table but
                never initialises <span style={{fontFamily: fonts.mono, color: colors.text}}>n_elems</span>.
              </div>
              <div style={{marginTop: 16, color: colors.muted, fontSize: 22}}>
                The bundled bubble-sort sample hits it; demo.nc avoids it.
              </div>
            </div>
          </Panel>
        </Reveal>
      </div>
    </Scene>
  );
};
