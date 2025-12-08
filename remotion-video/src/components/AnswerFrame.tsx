import React from 'react';
import {AbsoluteFill} from 'remotion';
import {QuizQuestion} from '../types/quiz';
import {getQuestionPrompt} from '../types/quiz';
import {COLORS} from '../constants/colors';
import {SAFE_ZONE_TOP, SAFE_ZONE_LEFT, SAFE_ZONE_RIGHT} from '../constants/layout';
import {FONT_FAMILY} from '../utils/fonts';

interface AnswerFrameProps {
  question: QuizQuestion;
}

const optionLabels = ['①', '②', '③', '④'];

export const AnswerFrame: React.FC<AnswerFrameProps> = ({question}) => {
  const correctIndex = question.options.findIndex((opt) => opt === question.correct_answer);
  const correctLabel = optionLabels[correctIndex];

  // 해설 텍스트 줄바꿈 처리
  const maxCharsPerLine = 25;
  const explanationLines: string[] = [];
  let remaining = question.explanation;
  while (remaining.length > maxCharsPerLine) {
    explanationLines.push(remaining.substring(0, maxCharsPerLine));
    remaining = remaining.substring(maxCharsPerLine);
  }
  if (remaining) {
    explanationLines.push(remaining);
  }

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`,
        fontFamily: FONT_FAMILY,
      }}
    >
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          paddingTop: SAFE_ZONE_TOP + 50,
          paddingLeft: SAFE_ZONE_LEFT,
          paddingRight: SAFE_ZONE_RIGHT,
        }}
      >
        {/* 문제 표시 */}
        <div style={{marginBottom: 100}}>
          <div
            style={{
              fontSize: 32,
              color: COLORS.GRAY_LIGHT,
              textAlign: 'center',
              marginBottom: 50,
            }}
          >
            {getQuestionPrompt(question.quiz_type)}
          </div>
          <div
            style={{
              fontSize: 48,
              fontWeight: 'bold',
              color: COLORS.TEXT,
              textAlign: 'center',
            }}
          >
            「 {question.question} 」
          </div>
        </div>

        {/* 정답 표시 */}
        <div
          style={{
            fontSize: 72,
            fontWeight: 'bold',
            color: COLORS.CORRECT,
            textAlign: 'center',
            marginBottom: 200, // 정답과 해설 사이 간격 증가
          }}
        >
          정답 {correctLabel} {question.correct_answer}
        </div>

        {/* 해설 영역 */}
        <div
          style={{
            backgroundColor: COLORS.SECONDARY,
            borderRadius: 20,
            padding: 40,
            marginTop: 'auto',
            marginBottom: 100,
          }}
        >
          <div
            style={{
              fontSize: 36,
              fontWeight: 'bold',
              color: COLORS.PRIMARY,
              textAlign: 'center',
              marginBottom: 30,
            }}
          >
            💡 해설
          </div>
          {explanationLines.slice(0, 4).map((line, index) => (
            <div
              key={index}
              style={{
                fontSize: 42,
                color: '#cccccc',
                textAlign: 'center',
                marginBottom: index < explanationLines.length - 1 ? 20 : 0,
              }}
            >
              {line}
            </div>
          ))}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

