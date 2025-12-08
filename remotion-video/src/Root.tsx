import React from 'react';
import {Composition} from 'remotion';
import {Video} from './Video';
import {WIDTH, HEIGHT} from './constants/layout';
import {TOTAL_DURATION, FPS} from './constants/timing';
import {QuizQuestion} from './types/quiz';

// 테스트용 퀴즈 데이터
const testQuestion: QuizQuestion = {
  id: 1,
  question: '勉強',
  options: ['운동', '독서', '공부', '여행'],
  correct_answer: '공부',
  explanation: '勉(힘쓸 면) + 強(강할 강) = 공부하다',
  jlpt_level: 3,
  quiz_type: 'jp_to_kr',
};

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="QuizVideo"
        component={Video}
        durationInFrames={TOTAL_DURATION * FPS}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
        defaultProps={{
          question: testQuestion,
        }}
      />
    </>
  );
};

