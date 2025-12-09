import React from 'react';
import {AbsoluteFill, Audio, Sequence, useVideoConfig, staticFile} from 'remotion';
import {preloadImage} from '@remotion/preload';
import {QuizQuestion} from './types/quiz';
import {IntroFrame} from './components/IntroFrame';
import {QuestionFrame} from './components/QuestionFrame';
import {AnswerFrame} from './components/AnswerFrame';
import {AccountFrame} from './components/AccountFrame';
import {INTRO_DURATION, QUESTION_DURATION, ANSWER_DURATION, ACCOUNT_DURATION, TOTAL_DURATION, FPS} from './constants/timing';

// 이미지 미리 로드 (모듈 로드 시 즉시)
const christmasLogoImage = staticFile('images/christmas-logo.png');
const christmasBackgroundImage = staticFile('images/christmas-background.jpg');
preloadImage(christmasLogoImage);
preloadImage(christmasBackgroundImage);

interface VideoProps {
  question: QuizQuestion;
}

export const Video: React.FC<VideoProps> = ({question}) => {
  const {fps} = useVideoConfig();

  return (
    <AbsoluteFill>
      {/* 인트로 (0-3초) */}
      <Sequence from={0} durationInFrames={INTRO_DURATION * fps}>
        <IntroFrame question={question} />
      </Sequence>

      {/* 문제 (3-13초) */}
      <Sequence from={INTRO_DURATION * fps} durationInFrames={QUESTION_DURATION * fps}>
        <QuestionFrame question={question} />
      </Sequence>

      {/* 정답 (13-18초) */}
      <Sequence from={(INTRO_DURATION + QUESTION_DURATION) * fps} durationInFrames={ANSWER_DURATION * fps}>
        <AnswerFrame question={question} />
      </Sequence>

      {/* 정답 화면 시작 시 correct 사운드 재생 */}
      <Sequence
        from={(INTRO_DURATION + QUESTION_DURATION) * fps}
        durationInFrames={Math.floor(2 * fps)}
      >
        <Audio
          src={staticFile('sounds/correct.mp3')}
          volume={1.0}
        />
      </Sequence>

      {/* 계정 정보 (18-23초) */}
      <Sequence
        from={(INTRO_DURATION + QUESTION_DURATION + ANSWER_DURATION) * fps}
        durationInFrames={ACCOUNT_DURATION * fps}
      >
        <AccountFrame />
      </Sequence>

      {/* 배경음악 */}
      <Audio
        src={staticFile('sounds/ukulele.mp3')}
        volume={0.3}
        startFrom={0}
        endAt={TOTAL_DURATION * fps}
      />

      {/* 카운트다운 beep 사운드 (문제 화면에서만) - 각 초마다 재생 */}
      {Array.from({length: QUESTION_DURATION}, (_, i) => {
        const startFrame = (INTRO_DURATION + i) * fps;
        return (
          <Sequence key={`tick-seq-${i}`} from={startFrame} durationInFrames={Math.floor(0.3 * fps)}>
            <Audio
              src={staticFile('sounds/tick.wav')}
              volume={1.0}
            />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

