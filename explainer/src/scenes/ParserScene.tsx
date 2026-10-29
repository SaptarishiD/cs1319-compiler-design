import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {Code, Panel, progress, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

// Precedence ladder from a3/7_A3/7_A3.y, lowest rung = tightest binding.
const LADDER = [
  'primary-expression',
  'postfix-expression',
  'unary-expression',
  'multiplicative-expression',
  'additive-expression',
  'relational-expression',
  'equality-expression',
  'logical-AND-expression',
  'logical-OR-expression',
  'conditional-expression',
  'assignment-expression',
];

// Real reductions printed by the A3 parser for `sum = sum + i;` (right-hand side).
const REDUCTIONS = [
  'primary-expression-> IDENTIFIER',
  'postfix-expression',
  'unary-expression',
  'multiplicative-expression',
  'additive-expression',
  'primary-expression-> IDENTIFIER',
  'postfix-expression',
  'unary-expression',
  'multiplicative-expression',
  'additive-expression',
  'relational-expression',
  'equality-expression',
  'logical-AND-expression',
  'logical-OR-expression',
  'conditional-expression',
  'assignment-expression',
  'assignment-expression',
  'expression',
  'expression-statement',
];

const rungOf = (line: string) => LADDER.findIndex((l) => line.startsWith(l));

export const ParserScene: React.FC = () => {
  const frame = useCurrentFrame();
  const ladderAt = cue('parser', 'Expressions are layered');
  const climbAt = cue('parser', 'Each reduction');
  const errorAt = cue('parser', 'When input breaks');
  const shown = Math.floor(
    interpolate(frame, [climbAt, errorAt - 10], [0, REDUCTIONS.length], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    }),
  );
  const activeRung = shown > 0 ? rungOf(REDUCTIONS[shown - 1]) : -1;
  const visible = REDUCTIONS.slice(Math.max(0, shown - 8), shown);
  return (
    <Scene id="parser" stage="parser" kicker="STAGE 2 · A3" title="Parser: tokens → grammar">
      <div style={{display: 'flex', gap: 48}}>
        <div style={{width: 640}}>
          <Reveal at={cue('parser', 'token codes')}>
            <div style={{fontFamily: fonts.mono, fontSize: 21, color: colors.muted, marginBottom: 16}}>
              7_A3.l <span style={{color: colors.parser}}>{'{ID} → return IDENTIFIER;'}</span>
              <br />
              7_A3.y <span style={{color: colors.parser}}>%token IDENTIFIER</span>
            </div>
          </Reveal>
          <div style={{display: 'flex', flexDirection: 'column-reverse', gap: 6}}>
            {LADDER.map((rung, i) => {
              const p = progress(frame, ladderAt + i * 6, 12);
              const lit = i === activeRung;
              return (
                <div
                  key={rung}
                  style={{
                    opacity: p,
                    translate: `${(1 - p) * -30}px 0px`,
                    fontFamily: fonts.mono,
                    fontSize: 22,
                    padding: '6px 16px',
                    borderRadius: 8,
                    marginLeft: i * 10,
                    border: `2px solid ${lit ? colors.parser : colors.border}`,
                    backgroundColor: lit ? `${colors.parser}33` : colors.bgPanel,
                    color: lit ? colors.parser : colors.text,
                  }}
                >
                  {rung}
                </div>
              );
            })}
          </div>
        </div>
        <div style={{flex: 1, display: 'flex', flexDirection: 'column', gap: 24}}>
          <Reveal at={climbAt - 10}>
            <Panel title="./parser   ←   sum = sum + i;" accent={colors.parser} style={{height: 360}}>
              <Code lines={visible} accent={colors.parser} fontSize={21} plain />
            </Panel>
          </Reveal>
          <Reveal at={errorAt}>
            <Panel title="samples/error_test.nc" accent={colors.error}>
              <Code lines={['int a = return 0; // <- Error']} accent={colors.parser} fontSize={22} />
              <div
                style={{
                  fontFamily: fonts.mono,
                  fontSize: 24,
                  color: colors.error,
                  padding: '0 24px 18px',
                  fontWeight: 700,
                }}
              >
                Error: syntax error on &apos;return&apos;
              </div>
            </Panel>
          </Reveal>
        </div>
      </div>
    </Scene>
  );
};
