import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {colorOf, progress, Reveal, Scene} from '../components';
import {colors, fonts, Stage} from '../theme';
import {cue} from '../timing';

const STAGES: {stage: Stage; label: string}[] = [
  {stage: 'lexer', label: 'Lexer'},
  {stage: 'parser', label: 'Parser'},
  {stage: 'translator', label: 'Translator'},
];

export const TitleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const p = progress(frame, 6, 30);
  return (
    <Scene id="title">
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column'}}>
        <div style={{fontFamily: fonts.mono, fontSize: 30, color: colors.muted, opacity: p}}>
          cs1319-compiler-design
        </div>
        <div
          style={{
            fontSize: 112,
            fontWeight: 800,
            letterSpacing: -3,
            marginTop: 12,
            opacity: p,
            scale: 0.92 + 0.08 * p,
          }}
        >
          Building a compiler for <span style={{color: colors.lexer}}>nano</span>
          <span style={{color: colors.translator}}>C</span>
        </div>
        <div style={{display: 'flex', gap: 24, marginTop: 48, alignItems: 'center'}}>
          {STAGES.map(({stage, label}, i) => (
            <React.Fragment key={stage}>
              {i > 0 ? (
                <Reveal at={30 + i * 10}>
                  <div style={{fontSize: 40, color: colors.faint}}>→</div>
                </Reveal>
              ) : null}
              <Reveal at={24 + i * 10}>
                <div
                  style={{
                    fontFamily: fonts.mono,
                    fontSize: 34,
                    fontWeight: 700,
                    padding: '14px 30px',
                    borderRadius: 14,
                    border: `3px solid ${colorOf(stage)}`,
                    color: colorOf(stage),
                  }}
                >
                  {label}
                </div>
              </Reveal>
            </React.Fragment>
          ))}
        </div>
        <Reveal at={cue('title', 'Saptarishi')} style={{marginTop: 64, textAlign: 'center'}}>
          <div style={{fontSize: 36, fontWeight: 600}}>Saptarishi Dhanuka · Shivam Kedia</div>
          <div style={{fontSize: 26, color: colors.muted, marginTop: 10}}>
            CS-1319 · Programming Language Design and Implementation
          </div>
        </Reveal>
      </AbsoluteFill>
    </Scene>
  );
};
