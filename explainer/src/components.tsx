import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {colors, fonts, Stage} from './theme';
import {SceneId, sentences} from './timing';

/** 0 → 1 over `duration` frames starting at `start`, spring-eased, clamped. */
export const progress = (frame: number, start: number, duration = 18): number =>
  interpolate(frame, [start, start + duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.spring({damping: 200}),
  });

/** Fades and slides its children up when `at` is reached. */
export const Reveal: React.FC<{
  at: number;
  children: React.ReactNode;
  distance?: number;
  style?: React.CSSProperties;
}> = ({at, children, distance = 24, style}) => {
  const frame = useCurrentFrame();
  const p = progress(frame, at);
  return (
    <div style={{opacity: p, translate: `0px ${(1 - p) * distance}px`, ...style}}>{children}</div>
  );
};

const stageColor: Record<Stage, string> = {
  a1: colors.a1,
  lexer: colors.lexer,
  parser: colors.parser,
  translator: colors.translator,
};

export const colorOf = (stage: Stage) => stageColor[stage];

const Background: React.FC<{accent: string}> = ({accent}) => (
  <AbsoluteFill
    style={{
      backgroundColor: colors.bg,
      backgroundImage: [
        `radial-gradient(circle at 85% 10%, ${accent}22, transparent 45%)`,
        `linear-gradient(${colors.border}55 1px, transparent 1px)`,
        `linear-gradient(90deg, ${colors.border}55 1px, transparent 1px)`,
      ].join(','),
      backgroundSize: '100% 100%, 64px 64px, 64px 64px',
    }}
  />
);

const Captions: React.FC<{id: SceneId}> = ({id}) => {
  const frame = useCurrentFrame();
  const list = sentences(id);
  const current = [...list].reverse().find((s) => frame >= s.from);
  if (!current) {
    return null;
  }
  return (
    <div
      style={{
        position: 'absolute',
        left: 160,
        right: 160,
        bottom: 44,
        display: 'flex',
        justifyContent: 'center',
      }}
    >
      <div
        style={{
          fontFamily: fonts.sans,
          fontSize: 28,
          lineHeight: 1.35,
          color: colors.text,
          backgroundColor: '#000000aa',
          padding: '10px 22px',
          borderRadius: 10,
          textAlign: 'center',
          maxWidth: 1500,
        }}
      >
        {current.text}
      </div>
    </div>
  );
};

const PIPELINE: {stage: Stage; label: string}[] = [
  {stage: 'lexer', label: 'A2 · Lexer'},
  {stage: 'parser', label: 'A3 · Parser'},
  {stage: 'translator', label: 'A4 · Translator'},
];

const PipelineBar: React.FC<{active: Stage}> = ({active}) => (
  <div style={{position: 'absolute', top: 64, right: 96, display: 'flex', gap: 10}}>
    {PIPELINE.map(({stage, label}) => {
      const on = stage === active;
      return (
        <div
          key={stage}
          style={{
            fontFamily: fonts.mono,
            fontSize: 20,
            padding: '8px 16px',
            borderRadius: 999,
            border: `2px solid ${on ? colorOf(stage) : colors.faint}`,
            color: on ? colors.bg : colors.muted,
            backgroundColor: on ? colorOf(stage) : 'transparent',
            fontWeight: on ? 700 : 500,
          }}
        >
          {label}
        </div>
      );
    })}
  </div>
);

/** Shared scene chrome: background, kicker + title, pipeline position, captions. */
export const Scene: React.FC<{
  id: SceneId;
  stage?: Stage;
  kicker?: string;
  title?: string;
  children: React.ReactNode;
}> = ({id, stage, kicker, title, children}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const accent = stage ? colorOf(stage) : colors.a1;
  const p = progress(frame, 0, Math.round(0.6 * fps));
  return (
    <AbsoluteFill style={{fontFamily: fonts.sans, color: colors.text, fontVariantLigatures: 'none'}}>
      <Background accent={accent} />
      {title ? (
        <div style={{position: 'absolute', top: 56, left: 96, opacity: p, translate: `${(1 - p) * -30}px 0px`}}>
          <div style={{fontFamily: fonts.mono, fontSize: 24, letterSpacing: 4, color: accent, fontWeight: 700}}>
            {kicker}
          </div>
          <div style={{fontSize: 60, fontWeight: 800, marginTop: 6, letterSpacing: -1}}>{title}</div>
        </div>
      ) : null}
      {stage && stage !== 'a1' ? <PipelineBar active={stage} /> : null}
      <div style={{position: 'absolute', top: title ? 210 : 0, bottom: title ? 130 : 0, left: 96, right: 96}}>
        {children}
      </div>
      <Captions id={id} />
    </AbsoluteFill>
  );
};

const C_KEYWORDS = new Set(['int', 'char', 'void', 'if', 'else', 'for', 'return']);

/** Minimal C highlighter: keywords, numbers, strings, comments. */
const highlight = (line: string, accent: string): React.ReactNode[] => {
  if (line.trim().startsWith('//') || line.trim().startsWith('/*')) {
    return [<span key="c" style={{color: colors.muted}}>{line}</span>];
  }
  return line.split(/(\b\w+\b|"[^"]*")/).map((part, i) => {
    if (C_KEYWORDS.has(part)) {
      return <span key={i} style={{color: accent, fontWeight: 700}}>{part}</span>;
    }
    if (/^\d+$/.test(part)) {
      return <span key={i} style={{color: '#f9a8d4'}}>{part}</span>;
    }
    if (part.startsWith('"')) {
      return <span key={i} style={{color: '#86efac'}}>{part}</span>;
    }
    return <span key={i}>{part}</span>;
  });
};

export const Panel: React.FC<{
  title?: string;
  children: React.ReactNode;
  style?: React.CSSProperties;
  accent?: string;
}> = ({title, children, style, accent = colors.faint}) => (
  <div
    style={{
      backgroundColor: colors.bgPanel,
      border: `2px solid ${colors.border}`,
      borderTop: `4px solid ${accent}`,
      borderRadius: 14,
      overflow: 'hidden',
      ...style,
    }}
  >
    {title ? (
      <div
        style={{
          fontFamily: fonts.mono,
          fontSize: 20,
          color: colors.muted,
          padding: '12px 22px',
          borderBottom: `1px solid ${colors.border}`,
        }}
      >
        {title}
      </div>
    ) : null}
    {children}
  </div>
);

export const Code: React.FC<{
  lines: string[];
  accent: string;
  fontSize?: number;
  /** Indices of lines to emphasise; others are dimmed. Empty = no emphasis. */
  focus?: number[];
  plain?: boolean;
}> = ({lines, accent, fontSize = 28, focus = [], plain = false}) => (
  <pre style={{margin: 0, padding: '18px 24px', fontFamily: fonts.mono, fontSize, lineHeight: 1.5}}>
    {lines.map((line, i) => {
      const dim = focus.length > 0 && !focus.includes(i);
      return (
        <div key={i} style={{opacity: dim ? 0.3 : 1, whiteSpace: 'pre'}}>
          {plain ? line : highlight(line, accent)}
          {line === '' ? ' ' : null}
        </div>
      );
    })}
  </pre>
);

export const DEMO_SOURCE = [
  'int main() {',
  '  int i;',
  '  int sum;',
  '  sum = 0;',
  '  for (i = 0; i < 10; i = i + 1)',
  '    if (i > 4) sum = sum + i;',
  '  return sum;',
  '}',
];
