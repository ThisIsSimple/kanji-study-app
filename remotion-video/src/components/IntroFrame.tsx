import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame, staticFile, Img} from 'remotion';
import {QuizQuestion} from '../types/quiz';
import {getQuizTypeDisplay, getQuestionPrompt} from '../types/quiz';
import {COLORS} from '../constants/colors';
import {SAFE_ZONE_TOP, HEIGHT} from '../constants/layout';
import {FONT_FAMILY} from '../utils/fonts';

interface IntroFrameProps {
  question: QuizQuestion;
}

export const IntroFrame: React.FC<IntroFrameProps> = ({question}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 30], [0, 1], {extrapolateRight: 'clamp'});
  const backgroundImage = staticFile('images/christmas-background.jpg');

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`, // Fallback
        fontFamily: FONT_FAMILY,
        opacity,
      }}
    >
      {/* 배경 이미지 */}
      <Img
        src={backgroundImage}
        delayRenderTimeoutInMilliseconds={60000}
        style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          objectFit: 'cover',
        }}
      />
      {/* 어두운 오버레이 */}
      <AbsoluteFill
        style={{
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
        }}
      />
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* 타이틀 */}
        <div
          style={{
            fontSize: 80,
            fontWeight: 'bold',
            color: COLORS.TEXT,
            marginBottom: 50,
            textAlign: 'center',
          }}
        >
          🇯🇵 일본어 퀴즈
        </div>

        {/* 퀴즈 유형 프롬프트 */}
        <div
          style={{
            fontSize: 150,
            color: '#cccccc',
            fontWeight: 'bold',
            textAlign: 'center',
            marginTop: 32,
            marginBottom: 80,
          }}
        >
          {question.question}
        </div>

        {/* JLPT 레벨 */}
        {question.jlpt_level && (
          <div
            style={{
              fontSize: 72,
              fontWeight: 'bold',
              color: COLORS.CORRECT,
              marginBottom: 32,
              textAlign: 'center',
            }}
          >
            JLPT N{question.jlpt_level}
          </div>
        )}

        {/* 퀴즈 유형 뱃지 */}
        <div
          style={{
            width: 200,
            height: 60,
            backgroundColor: COLORS.PRIMARY,
            borderRadius: 30,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 50,
          }}
        >
          <div
            style={{
              fontSize: 36,
              fontWeight: 'bold',
              color: COLORS.TEXT,
            }}
          >
            {getQuizTypeDisplay(question.quiz_type)}
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

