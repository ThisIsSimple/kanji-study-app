import React from 'react';
import {AbsoluteFill, Audio, Sequence, useVideoConfig, staticFile} from 'remotion';
import {QuizQuestion} from './types/quiz';
import {IntroFrame} from './components/IntroFrame';
import {QuestionFrame} from './components/QuestionFrame';
import {AnswerFrame} from './components/AnswerFrame';
import {AccountFrame} from './components/AccountFrame';
import {INTRO_DURATION, QUESTION_DURATION, ANSWER_DURATION, ACCOUNT_DURATION, TOTAL_DURATION, FPS} from './constants/timing';

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

      {/* 카운트다운 효과음 (문제 화면에서만) */}
      {Array.from({length: QUESTION_DURATION}, (_, i) => (
        <Audio
          key={i}
          src={staticFile('sounds/tick.wav')}
          volume={0.5}
          startFrom={(INTRO_DURATION + i) * fps}
          endAt={(INTRO_DURATION + i) * fps + Math.floor(0.2 * fps)}
        />
      ))}
    </AbsoluteFill>
  );
};

