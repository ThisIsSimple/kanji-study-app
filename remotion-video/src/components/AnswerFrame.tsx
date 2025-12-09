import React from "react";
import { AbsoluteFill, staticFile, Img } from "remotion";
import { QuizQuestion } from "../types/quiz";
import { getQuestionPrompt } from "../types/quiz";
import { COLORS } from "../constants/colors";
import {
  SAFE_ZONE_TOP,
  SAFE_ZONE_LEFT,
  SAFE_ZONE_RIGHT,
} from "../constants/layout";
import { FONT_FAMILY } from "../utils/fonts";

interface AnswerFrameProps {
  question: QuizQuestion;
}

const optionLabels = ["①", "②", "③", "④"];

export const AnswerFrame: React.FC<AnswerFrameProps> = ({ question }) => {
  const correctIndex = question.options.findIndex(
    (opt) => opt === question.correct_answer
  );
  const correctLabel = optionLabels[correctIndex];
  const backgroundImage = staticFile("images/christmas-background.jpg");

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
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          paddingLeft: SAFE_ZONE_LEFT / 2,
          paddingRight: SAFE_ZONE_RIGHT / 2,
        }}
      >
        {/* 문제 표시 */}
        <div style={{ marginBottom: 60, textAlign: "center" }}>
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
          <div
            style={{
              fontSize: 150,
              fontWeight: "bold",
              color: COLORS.TEXT,
              textAlign: "center",
            }}
          >
            「 {question.question} 」
          </div>
        </div>

        {/* 정답 표시 */}
        <div
          style={{
            fontSize: 100,
            fontWeight: "bold",
            color: COLORS.CORRECT,
            textAlign: "center",
            marginBottom: 80, // 정답과 해설 사이 간격 감소
          }}
        >
          정답 : {correctLabel} {question.correct_answer}
        </div>

        {/* 해설 영역 */}
        <div
          style={{
            backgroundColor: "rgba(0, 0, 0, 0.5)",
            borderRadius: 40,
            padding: 50,
            maxWidth: 1000,
            width: "100%",
          }}
        >
          <div
            style={{
              fontSize: 60,
              fontWeight: "bold",
              color: COLORS.PRIMARY,
              textAlign: "center",
              marginBottom: 30,
            }}
          >
            💡 해설
          </div>
          {explanationLines.slice(0, 4).map((line, index) => (
            <div
              key={index}
              style={{
                fontSize: 60,
                color: COLORS.TEXT,
                textAlign: "center",
                marginBottom: index < explanationLines.length - 1 ? 20 : 0,
                whiteSpace: "pre-line",
                wordBreak: "keep-all",
                overflowWrap: "break-word",
                lineHeight: 1.8,
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
