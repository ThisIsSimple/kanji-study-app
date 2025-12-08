import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {QuizQuestion} from '../types/quiz';
import {getQuestionPrompt} from '../types/quiz';
import {COLORS} from '../constants/colors';
import {SAFE_ZONE_TOP, SAFE_ZONE_LEFT, SAFE_ZONE_WIDTH, HEIGHT, SAFE_ZONE_BOTTOM} from '../constants/layout';
import {QUESTION_DURATION} from '../constants/timing';
import {FONT_FAMILY} from '../utils/fonts';

interface QuestionFrameProps {
  question: QuizQuestion;
}

const optionLabels = ['①', '②', '③', '④'];

export const QuestionFrame: React.FC<QuestionFrameProps> = ({question}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const countdown = Math.max(1, QUESTION_DURATION - Math.floor(frame / fps));
  const timerColor = countdown <= 3 ? COLORS.WRONG : COLORS.TEXT;

  // 문제 텍스트 길이에 따른 폰트 크기 조정
  const questionFontSize = question.question.length > 25 ? 40 : question.question.length > 15 ? 52 : 64;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`,
        fontFamily: FONT_FAMILY,
      }}
    >
      {/* JLPT 레벨 (상단 중앙) */}
      {question.jlpt_level && (
        <div
          style={{
            position: 'absolute',
            top: SAFE_ZONE_TOP - 50,
            left: '50%',
            transform: 'translateX(-50%)',
            fontSize: 48,
            fontWeight: 'bold',
            color: COLORS.CORRECT,
          }}
        >
          N{question.jlpt_level}
        </div>
      )}

      {/* 문제 영역 */}
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          paddingTop: SAFE_ZONE_TOP + 50,
          paddingLeft: SAFE_ZONE_LEFT,
          paddingRight: SAFE_ZONE_LEFT,
        }}
      >
        {/* 문제 프롬프트 */}
        <div
          style={{
            fontSize: 40,
            color: COLORS.GRAY_LIGHT,
            textAlign: 'center',
            marginBottom: 50,
          }}
        >
          {getQuestionPrompt(question.quiz_type)}
        </div>

        {/* 문제 텍스트 */}
        <div
          style={{
            fontSize: questionFontSize,
            fontWeight: 'bold',
            color: COLORS.TEXT,
            textAlign: 'center',
            marginBottom: 100,
          }}
        >
          「 {question.question} 」
        </div>

        {/* 선택지 영역 */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 30,
            width: SAFE_ZONE_WIDTH,
          }}
        >
          {question.options.map((option, index) => {
            const optionFontSize = option.length > 20 ? 44 : 52;
            return (
              <div
                key={index}
                style={{
                  height: 140,
                  backgroundColor: COLORS.ACCENT,
                  borderRadius: 20,
                  display: 'flex',
                  alignItems: 'center',
                  paddingLeft: 30,
                  gap: 30,
                }}
              >
                <div
                  style={{
                    fontSize: optionFontSize,
                    fontWeight: 'bold',
                    color: COLORS.PRIMARY,
                  }}
                >
                  {optionLabels[index]}
                </div>
                <div
                  style={{
                    fontSize: optionFontSize,
                    fontWeight: 'bold',
                    color: COLORS.TEXT,
                  }}
                >
                  {option}
                </div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>

      {/* 카운트다운 타이머 (하단 중앙) */}
      <div
        style={{
          position: 'absolute',
          bottom: SAFE_ZONE_BOTTOM + 50,
          left: '50%',
          transform: 'translateX(-50%)',
          fontSize: 72,
          fontWeight: 'bold',
          color: timerColor,
          display: 'flex',
          alignItems: 'center',
          gap: 10,
        }}
      >
        <span>⏱️</span>
        <span>{countdown}</span>
      </div>
    </AbsoluteFill>
  );
};

