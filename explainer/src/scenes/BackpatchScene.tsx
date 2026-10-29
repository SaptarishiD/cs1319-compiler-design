import React from 'react';
import {useCurrentFrame} from 'remotion';
import {Code, Panel, progress, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

// Quads 4–7 of demo.nc: the for-loop test, before and after backpatching.
const QUADS: {n: number; text: string; target?: string; list?: 'true' | 'false'}[] = [
  {n: 4, text: 't0002 = 10'},
  {n: 5, text: 't0003 = i < t0002'},
  {n: 6, text: 'if t0003 goto', target: '12', list: 'true'},
  {n: 7, text: 'goto', target: '19', list: 'false'},
];

const ListChip: React.FC<{label: string; items: string; color: string}> = ({label, items, color}) => (
  <div
    style={{
      fontFamily: fonts.mono,
      fontSize: 26,
      padding: '12px 20px',
      borderRadius: 12,
      border: `2px solid ${color}`,
      color,
    }}
  >
    {label} = {'{'} {items} {'}'}
  </div>
);

export const BackpatchScene: React.FC = () => {
  const frame = useCurrentFrame();
  const listsAt = cue('backpatch', 'Boolean expressions');
  const fillAt = cue('backpatch', 'Once the target');
  return (
    <Scene id="backpatch" stage="translator" kicker="STAGE 3 · A4" title="Backpatching jumps">
      <div style={{display: 'flex', gap: 56}}>
        <div style={{width: 760, display: 'flex', flexDirection: 'column', gap: 26}}>
          <Reveal at={cue('backpatch', 'An empty marker')}>
            <Panel title="a4/7_A4.y — marker rule" accent={colors.translator}>
              <Code
                lines={['M: %empty', '{', '    $$ = quad_counter;', '}']}
                accent={colors.translator}
                fontSize={26}
                plain
              />
            </Panel>
          </Reveal>
          <Reveal at={fillAt - 10}>
            <Panel title="7_A4_translator.c (simplified)" accent={colors.translator}>
              <Code
                lines={[
                  'void backpatch(list* l, int label) {',
                  '  for (node* c = l->head; c; c = c->next)',
                  '    quad_array[c->val]->result = label;',
                  '}',
                ]}
                accent={colors.translator}
                fontSize={22}
                plain
              />
            </Panel>
          </Reveal>
        </div>
        <div style={{flex: 1}}>
          <Reveal at={cue('backpatch', 'Control flow')}>
            <Panel title="quads for  i < 10" accent={colors.translator}>
              <div style={{padding: '14px 0'}}>
                {QUADS.map((q) => {
                  const fill = q.target ? progress(frame, fillAt + (q.list === 'false' ? 20 : 0), 14) : 0;
                  const listColor = q.list === 'true' ? colors.ok : colors.error;
                  return (
                    <div
                      key={q.n}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 14,
                        fontFamily: fonts.mono,
                        fontSize: 32,
                        padding: '8px 26px',
                      }}
                    >
                      <span style={{color: colors.muted, width: 40}}>{q.n}:</span>
                      <span>{q.text}</span>
                      {q.target ? (
                        <span
                          style={{
                            display: 'inline-block',
                            width: 80,
                            height: 44,
                            textAlign: 'center',
                            borderBottom: `3px solid ${frame >= listsAt ? listColor : colors.faint}`,
                            color: colors.translator,
                            fontWeight: 800,
                            opacity: fill,
                            scale: 0.6 + 0.4 * fill,
                          }}
                        >
                          {q.target}
                        </span>
                      ) : null}
                    </div>
                  );
                })}
              </div>
            </Panel>
          </Reveal>
          <div style={{display: 'flex', gap: 18, marginTop: 30}}>
            <Reveal at={listsAt}>
              <ListChip label="truelist" items="6" color={colors.ok} />
            </Reveal>
            <Reveal at={listsAt + 15}>
              <ListChip label="falselist" items="7" color={colors.error} />
            </Reveal>
          </div>
          <Reveal at={fillAt + 30} style={{marginTop: 26}}>
            <div style={{fontSize: 26, color: colors.muted, lineHeight: 1.5}}>
              truelist → <span style={{color: colors.ok, fontFamily: fonts.mono}}>12</span> (loop body, from M)
              <br />
              falselist → <span style={{color: colors.error, fontFamily: fonts.mono}}>19</span> (statement after loop)
            </div>
          </Reveal>
        </div>
      </div>
    </Scene>
  );
};
