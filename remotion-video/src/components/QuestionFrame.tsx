import React from "react";
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
  staticFile,
  Img,
} from "remotion";
import { QuizQuestion } from "../types/quiz";
import { getQuestionPrompt } from "../types/quiz";
import { COLORS } from "../constants/colors";
import {
  SAFE_ZONE_TOP,
  SAFE_ZONE_LEFT,
  SAFE_ZONE_WIDTH,
  HEIGHT,
  SAFE_ZONE_BOTTOM,
} from "../constants/layout";
import { QUESTION_DURATION } from "../constants/timing";
import { FONT_FAMILY } from "../utils/fonts";

interface QuestionFrameProps {
  question: QuizQuestion;
}

const optionLabels = ["①", "②", "③", "④"];

export const QuestionFrame: React.FC<QuestionFrameProps> = ({ question }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const countdown = Math.max(1, QUESTION_DURATION - Math.floor(frame / fps));
  const timerColor = countdown <= 3 ? COLORS.WRONG : COLORS.TEXT;
  const backgroundImage = staticFile("images/christmas-background.jpg");

  // 문제 텍스트 길이에 따른 폰트 크기 조정 (크기 증가)
  const questionFontSize =
    question.question.length > 25
      ? 72
      : question.question.length > 15
      ? 100
      : 150;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`, // Fallback
        fontFamily: FONT_FAMILY,
      }}
    >
      {/* 배경 이미지 */}
      <Img
        src={backgroundImage}
        delayRenderTimeoutInMilliseconds={60000}
        style={{
          position: "absolute",
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />
      {/* 어두운 오버레이 */}
      <AbsoluteFill
        style={{
          backgroundColor: "rgba(0, 0, 0, 0.1)",
        }}
      />
      {/* JLPT 레벨 (상단 중앙) */}
      {/* {question.jlpt_level && (
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
      )} */}

      {/* 문제 영역 */}
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          paddingTop: SAFE_ZONE_TOP + 50,
          paddingLeft: SAFE_ZONE_LEFT,
          paddingRight: SAFE_ZONE_LEFT,
        }}
      >
        {/* 문제 프롬프트 */}
        <div
          style={{
            fontSize: 50,
            color: COLORS.GRAY_LIGHT,
            textAlign: "center",
            marginBottom: 50,
          }}
        >
          {getQuestionPrompt(question.quiz_type)}
        </div>

        {/* 문제 텍스트 */}
        <div
          style={{
            fontSize: questionFontSize,
            fontWeight: "bold",
            color: COLORS.TEXT,
            textAlign: "center",
            marginBottom: 80,
          }}
        >
          「 {question.question} 」
        </div>

        {/* 선택지 영역 */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 30,
            width: SAFE_ZONE_WIDTH,
          }}
        >
          {question.options.map((option, index) => {
            const optionFontSize = 64;
            return (
              <div
                key={index}
                style={{
                  height: 150,
                  maxWidth: 800,
                  margin: "0 auto",
                  width: "100%",
                  backgroundColor: "rgba(0, 0, 0, 0.5)",
                  borderRadius: 40,
                  display: "flex",
                  justifyContent: "start",
                  alignItems: "center",
                  padding: "0 50px",
                  gap: 30,
                }}
              >
                <div
                  style={{
                    fontSize: optionFontSize,
                    fontWeight: "bold",
                    color: COLORS.PRIMARY,
                  }}
                >
                  {optionLabels[index]}
                </div>
                <div
                  style={{
                    fontSize: optionFontSize,
                    fontWeight: "bold",
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
          position: "absolute",
          bottom: SAFE_ZONE_BOTTOM,
          left: "50%",
          transform: "translateX(-50%)",
          fontSize: 144,
          fontWeight: "bold",
          color: timerColor,
          display: "flex",
          alignItems: "center",
          gap: 10,
        }}
      >
        <span>⏱️</span>
        <span>{countdown}</span>
      </div>
    </AbsoluteFill>
  );
};
