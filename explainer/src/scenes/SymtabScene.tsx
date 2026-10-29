import React from 'react';
import {useCurrentFrame} from 'remotion';
import {Code, Panel, progress, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

// Real symbol tables printed by the A4 translator for demo.nc.
const MAIN_ROWS: {name: string; type: string; cat: string}[] = [
  {name: 'i', type: 'int', cat: 'local'},
  {name: 'sum', type: 'int', cat: 'local'},
  {name: 't0000', type: 'int', cat: 'temp'},
  {name: 't0001', type: 'int', cat: 'temp'},
  {name: 't0002', type: 'int', cat: 'temp'},
  {name: 't0003', type: 'null', cat: 'temp'},
];

const Row: React.FC<{cells: string[]; highlight?: boolean; header?: boolean}> = ({cells, highlight, header}) => (
  <div
    style={{
      display: 'grid',
      gridTemplateColumns: '1.1fr 0.8fr 1fr',
      fontFamily: fonts.mono,
      fontSize: 22,
      padding: '7px 22px',
      color: header ? colors.muted : highlight ? colors.translator : colors.text,
      backgroundColor: highlight ? `${colors.translator}1f` : 'transparent',
      borderBottom: `1px solid ${colors.border}`,
    }}
  >
    {cells.map((c, i) => (
      <div key={i}>{c}</div>
    ))}
  </div>
);

const QUAD_FIELDS: {field: string; value: string}[] = [
  {field: 'op', value: 'op_PLUS'},
  {field: 'arg1', value: 'i'},
  {field: 'arg2', value: 't0004'},
  {field: 'result', value: 't0005'},
];

export const SymtabScene: React.FC = () => {
  const frame = useCurrentFrame();
  const globalAt = cue('symtab', 'global symbol table');
  const nestedAt = cue('symtab', 'nested table');
  const tempAt = cue('symtab', 'The gentemp');
  const quadAt = cue('symtab', 'Every instruction');
  return (
    <Scene id="symtab" stage="translator" kicker="STAGE 3 · A4" title="Symbol tables & quads">
      <div style={{display: 'flex', gap: 48}}>
        <div style={{width: 760, display: 'flex', flexDirection: 'column', gap: 22}}>
          <Reveal at={globalAt}>
            <Panel title="ST: Global" accent={colors.translator}>
              <Row cells={['name', 'type', 'category']} header />
              <Row cells={['main', 'int', 'funct → ST: main']} highlight={frame >= nestedAt && frame < tempAt} />
            </Panel>
          </Reveal>
          <Reveal at={nestedAt}>
            <Panel title="ST: main   (parent: Global)" accent={colors.translator}>
              <Row cells={['name', 'type', 'category']} header />
              {MAIN_ROWS.map((r, i) => {
                const isTemp = r.cat === 'temp';
                const p = isTemp ? progress(frame, tempAt + (i - 2) * 8, 10) : 1;
                return (
                  <div key={r.name} style={{opacity: p}}>
                    <Row cells={[r.name, r.type, r.cat]} highlight={isTemp && frame >= tempAt && frame < quadAt} />
                  </div>
                );
              })}
              <div style={{fontFamily: fonts.mono, fontSize: 20, color: colors.muted, padding: '8px 22px'}}>
                … t0004 – t0008
              </div>
            </Panel>
          </Reveal>
        </div>
        <div style={{flex: 1, display: 'flex', flexDirection: 'column', gap: 26}}>
          <Reveal at={tempAt}>
            <Panel title="7_A4_translator.c (simplified)" accent={colors.translator}>
              <Code
                lines={['symtab_entry* gentemp(symtab* st) {', '  static int counter = 0;', '  sprintf(str, "t%04d", counter++);', '  ...']}
                accent={colors.translator}
                fontSize={22}
              />
            </Panel>
          </Reveal>
          <Reveal at={quadAt}>
            <div style={{fontSize: 26, color: colors.muted, marginBottom: 12}}>
              quad: <span style={{fontFamily: fonts.mono, color: colors.text}}>t0005 = i + t0004</span>
            </div>
            <div style={{display: 'flex', gap: 10}}>
              {QUAD_FIELDS.map((q, i) => {
                const p = progress(frame, quadAt + 12 + i * 8, 12);
                return (
                  <div
                    key={q.field}
                    style={{
                      flex: 1,
                      opacity: p,
                      translate: `0px ${(1 - p) * 20}px`,
                      border: `2px solid ${colors.translator}`,
                      borderRadius: 10,
                      padding: '10px 14px',
                      fontFamily: fonts.mono,
                    }}
                  >
                    <div style={{fontSize: 18, color: colors.muted}}>{q.field}</div>
                    <div style={{fontSize: 26, color: colors.translator, fontWeight: 700}}>{q.value}</div>
                  </div>
                );
              })}
            </div>
            <div style={{display: 'flex', gap: 6, marginTop: 24, alignItems: 'center'}}>
              <div style={{fontFamily: fonts.mono, fontSize: 20, color: colors.muted, marginRight: 8}}>quad_array</div>
              {Array.from({length: 20}).map((_, i) => (
                <div
                  key={i}
                  style={{
                    width: 26,
                    height: 34,
                    borderRadius: 4,
                    backgroundColor: i === 9 ? colors.translator : colors.bgPanel,
                    border: `1px solid ${colors.faint}`,
                    opacity: progress(frame, quadAt + 40 + i * 2, 6),
                  }}
                />
              ))}
            </div>
          </Reveal>
        </div>
      </div>
    </Scene>
  );
};
