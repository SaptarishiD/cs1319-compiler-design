import React from 'react';
import {useCurrentFrame} from 'remotion';
import {Code, DEMO_SOURCE, Panel, progress, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

// Exact quads printed by the A4 translator for demo.nc.
const TAC = [
  't0000 = 0',
  'sum = t0000',
  't0001 = 0',
  'i = t0001',
  't0002 = 10',
  't0003 = i < t0002',
  'if t0003 goto 12',
  'goto 19',
  't0004 = 1',
  't0005 = i + t0004',
  'i = t0005',
  'goto 4',
  't0006 = 4',
  't0007 = i > t0006',
  'if t0007 goto 16',
  'goto 8',
  't0008 = sum + i',
  'sum = t0008',
  'goto 8',
  'return sum',
];

const ROW = 31;
const TOP = 14;

type Step = {phrase: string; tac: number[]; src: number[]; jump?: [number, number]};

const STEPS: Step[] = [
  {phrase: 'The loop test compares', tac: [4, 5], src: [4]},
  {phrase: 'If it holds', tac: [6, 12], src: [4, 5], jump: [6, 12]},
  {phrase: 'otherwise quad seven', tac: [7, 19], src: [4, 6], jump: [7, 19]},
  {phrase: 'The if inside', tac: [12, 13, 14, 15], src: [5], jump: [15, 8]},
  {phrase: 'which then loops', tac: [8, 9, 10, 11], src: [4], jump: [11, 4]},
  {phrase: 'Twenty quads', tac: [], src: []},
];

const JumpArrow: React.FC<{from: number; to: number; start: number}> = ({from, to, start}) => {
  const frame = useCurrentFrame();
  const p = progress(frame, start, 20);
  const y1 = TOP + from * ROW + ROW / 2;
  const y2 = TOP + to * ROW + ROW / 2;
  const bulge = 60 + Math.abs(to - from) * 6;
  const d = `M 0 ${y1} C ${bulge} ${y1}, ${bulge} ${y2}, 6 ${y2}`;
  return (
    <svg width={200} height={TOP * 2 + TAC.length * ROW} style={{position: 'absolute', left: 330, top: 0, overflow: 'visible'}}>
      <path
        d={d}
        fill="none"
        stroke={colors.translator}
        strokeWidth={4}
        pathLength={1}
        strokeDasharray={1}
        strokeDashoffset={1 - p}
      />
      <polygon
        points={`6,${y2} 20,${y2 - 8} 20,${y2 + 8}`}
        fill={colors.translator}
        opacity={p > 0.9 ? 1 : 0}
      />
    </svg>
  );
};

export const DemoScene: React.FC = () => {
  const frame = useCurrentFrame();
  const startAt = cue('demo', 'Here is');
  const starts = STEPS.map((s) => cue('demo', s.phrase));
  const idx = starts.reduce((acc, s, i) => (frame >= s ? i : acc), -1);
  const step = idx >= 0 ? STEPS[idx] : undefined;
  return (
    <Scene id="demo" stage="translator" kicker="REAL OUTPUT" title="demo.nc → three-address code">
      <div style={{display: 'flex', gap: 56}}>
        <Reveal at={startAt} style={{width: 720}}>
          <Panel title="demo.nc" accent={colors.a1}>
            <Code lines={DEMO_SOURCE} accent={colors.a1} fontSize={28} focus={step?.src ?? []} />
          </Panel>
          {idx === STEPS.length - 1 ? (
            <Reveal at={starts[STEPS.length - 1]} style={{marginTop: 30}}>
              <div style={{fontSize: 64, fontWeight: 800, color: colors.translator}}>20 quads</div>
            </Reveal>
          ) : null}
        </Reveal>
        <Reveal at={startAt + 8} style={{flex: 1}}>
          <Panel title="./translator < demo.nc" accent={colors.translator} style={{position: 'relative'}}>
            <div style={{position: 'relative', paddingTop: TOP, paddingBottom: TOP}}>
              {TAC.map((line, i) => {
                const dim = step && step.tac.length > 0 && !step.tac.includes(i);
                const isJump = line.includes('goto');
                return (
                  <div
                    key={i}
                    style={{
                      height: ROW,
                      display: 'flex',
                      alignItems: 'center',
                      fontFamily: fonts.mono,
                      fontSize: 22,
                      paddingLeft: 24,
                      opacity: (dim ? 0.25 : 1) * progress(frame, startAt + 8 + i * 3, 8),
                      color: isJump ? colors.translator : colors.text,
                    }}
                  >
                    <span style={{color: colors.muted, width: 52, textAlign: 'right', marginRight: 22}}>{i}:</span>
                    {line}
                  </div>
                );
              })}
              {step?.jump ? <JumpArrow key={idx} from={step.jump[0]} to={step.jump[1]} start={starts[idx]} /> : null}
            </div>
          </Panel>
        </Reveal>
      </div>
    </Scene>
  );
};
