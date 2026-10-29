import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {Code, Panel, progress, Reveal, Scene} from '../components';
import {colors, fonts} from '../theme';
import {cue} from '../timing';

// Excerpt of a2/7_A2/7_A2.l
const RULES = [
  'letter      [a-zA-Z]',
  'digit       [0-9]',
  'ID          {idnondigit}({idnondigit}|{digit})*',
  'KEYWORD     {INT}|{CHAR}|{ELSE}|{FOR}|{IF}|...',
  'PUNC        "["|"]"|"("|")"|"{"|"}"|"->"|...',
  '%%',
  '{KEYWORD}  printf("<KEYWORD, %s>", yytext);',
  '{CONST}    printf("<CONSTANT, %s>", yytext);',
  '{ID}       printf("<IDENTIFIER, %s>", yytext);',
  '{PUNC}     printf("<PUNCTUATOR, %s>", yytext);',
  '"//".*     ;          /* comment */',
  '{WS}       ;          /* whitespace */',
  '.          printf("<INVALID INPUT, %s>", ...);',
];

// Real output of the A2 lexer on demo.nc (47 tokens).
const TOKENS: [string, string][] = (
  'K int|I main|P (|P )|P {|K int|I i|P ;|K int|I sum|P ;|I sum|P =|C 0|P ;|K for|P (|I i|P =|C 0|P ;|' +
  'I i|P <|C 10|P ;|I i|P =|I i|P +|C 1|P )|K if|P (|I i|P >|C 4|P )|I sum|P =|I sum|P +|I i|P ;|' +
  'K return|I sum|P ;|P }'
)
  .split('|')
  .map((t) => [t[0], t.slice(2)] as [string, string]);

const KIND: Record<string, {name: string; color: string}> = {
  K: {name: 'KEYWORD', color: colors.lexer},
  I: {name: 'IDENTIFIER', color: '#93c5fd'},
  C: {name: 'CONSTANT', color: '#f9a8d4'},
  P: {name: 'PUNCTUATOR', color: colors.muted},
};

const TokenStream: React.FC<{start: number; end: number}> = ({start, end}) => {
  const frame = useCurrentFrame();
  const shown = Math.floor(
    interpolate(frame, [start, end], [0, TOKENS.length], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
  );
  return (
    <div style={{display: 'flex', flexWrap: 'wrap', gap: 10, padding: 22}}>
      {TOKENS.map(([kind, lexeme], i) => {
        const p = progress(frame, start + (i / TOKENS.length) * (end - start), 8);
        return (
          <div
            key={i}
            style={{
              opacity: i < shown ? 1 : p,
              scale: 0.8 + 0.2 * p,
              fontFamily: fonts.mono,
              fontSize: 22,
              padding: '6px 12px',
              borderRadius: 8,
              border: `2px solid ${KIND[kind].color}`,
              color: KIND[kind].color,
            }}
          >
            {lexeme}
          </div>
        );
      })}
    </div>
  );
};

export const LexerScene: React.FC = () => {
  const frame = useCurrentFrame();
  const streamAt = cue('lexer', 'stream of tokens');
  const dropAt = cue('lexer', 'Comments and whitespace');
  const invalidAt = cue('lexer', 'any character');
  const focus = frame >= invalidAt ? [12] : frame >= dropAt ? [10, 11] : frame >= cue('lexer', 'Flex compiles') ? [] : [0, 1, 2, 3, 4];
  return (
    <Scene id="lexer" stage="lexer" kicker="STAGE 1 · A2" title="Lexer: characters → tokens">
      <div style={{display: 'flex', gap: 40, marginTop: 10}}>
        <Reveal at={cue('lexer', 'regular definitions')} style={{width: 900}}>
          <Panel title="a2/7_A2/7_A2.l (excerpt)" accent={colors.lexer}>
            <Code lines={RULES} accent={colors.lexer} fontSize={22} focus={focus} plain />
          </Panel>
        </Reveal>
        <Reveal at={streamAt - 10} style={{flex: 1}}>
          <Panel title="./lexer < demo.nc" accent={colors.lexer} style={{height: 610}}>
            <div style={{display: 'flex', gap: 18, padding: '14px 22px 0'}}>
              {Object.values(KIND).map((k) => (
                <div key={k.name} style={{fontFamily: fonts.mono, fontSize: 17, color: k.color}}>
                  ■ {k.name}
                </div>
              ))}
            </div>
            <TokenStream start={streamAt} end={dropAt} />
          </Panel>
        </Reveal>
      </div>
    </Scene>
  );
};
