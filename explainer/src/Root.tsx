import React from 'react';
import {Composition} from 'remotion';
import {NanoCExplainer, totalFrames} from './Video';

export const RemotionRoot: React.FC = () => (
  <Composition
    id="NanoCExplainer"
    component={NanoCExplainer}
    durationInFrames={totalFrames}
    fps={30}
    width={1920}
    height={1080}
  />
);
