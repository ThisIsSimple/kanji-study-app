import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
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

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`,
        fontFamily: FONT_FAMILY,
        opacity,
      }}
    >
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          paddingTop: SAFE_ZONE_TOP,
          paddingBottom: HEIGHT - SAFE_ZONE_TOP - 420,
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
            fontSize: 48,
            color: '#cccccc',
            marginBottom: 50,
            textAlign: 'center',
          }}
        >
          「{getQuestionPrompt(question.quiz_type)}」
        </div>

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

        {/* JLPT 레벨 */}
        {question.jlpt_level && (
          <div
            style={{
              fontSize: 56,
              fontWeight: 'bold',
              color: COLORS.CORRECT,
              marginBottom: 50,
              textAlign: 'center',
            }}
          >
            JLPT N{question.jlpt_level}
          </div>
        )}

        {/* 하단 안내 */}
        <div
          style={{
            fontSize: 36,
            color: COLORS.GRAY_MEDIUM,
            marginTop: 100,
            textAlign: 'center',
          }}
        >
          10초 안에 정답을 맞춰보세요!
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

