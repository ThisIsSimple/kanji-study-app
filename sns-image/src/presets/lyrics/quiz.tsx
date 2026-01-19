import type { LyricsQuizProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsQuiz({ data }: LyricsQuizProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #1a0a2e 0%, #2d1b4e 100%)",
        padding: "60px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-8"), {
          borderBottom: "2px solid rgba(255,107,157,0.4)",
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "36px",
          }}
        >
          ❓
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#ffffff",
            fontWeight: "700",
          }}
        >
          퀴즈 타임!
        </div>
      </div>

      {/* 문제 문장 */}
      <div
        style={mergeStyles(tw("mb-8 flex flex-col"), {
          backgroundColor: "rgba(255,107,157,0.15)",
          borderRadius: "24px",
          padding: "40px",
          border: "2px solid rgba(255,107,157,0.4)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "22px",
            color: "#ff6b9d",
            fontWeight: "600",
            marginBottom: "16px",
          }}
        >
          다음 문장을 해석해보세요
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "40px",
            color: "#ffffff",
            fontWeight: "700",
            lineHeight: "1.4",
            textAlign: "center",
            justifyContent: "center",
          }}
        >
          {data.sentence}
        </div>
      </div>

      {/* 질문들 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-5"), {
          flex: 1,
        })}
      >
        {data.questions.map((question, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-center gap-4"), {
              backgroundColor: "rgba(255,255,255,0.05)",
              borderRadius: "20px",
              padding: "28px 32px",
              border: "2px solid rgba(0,212,255,0.3)",
            })}
          >
            {/* 번호 */}
            <div
              style={mergeStyles(tw("flex items-center justify-center shrink-0"), {
                width: "50px",
                height: "50px",
                backgroundColor: "#00d4ff",
                borderRadius: "50%",
              })}
            >
              <div
                style={{
                  display: "flex",
                  fontSize: "24px",
                  color: "#1a0a2e",
                  fontWeight: "700",
                }}
              >
                {index + 1}
              </div>
            </div>

            {/* 질문 내용 */}
            <div
              style={{
                display: "flex",
                fontSize: "30px",
                color: "#ffffff",
                fontWeight: "500",
                flex: 1,
                lineHeight: "1.4",
              }}
            >
              {question.content}
            </div>
          </div>
        ))}
      </div>

      {/* 힌트 */}
      <div
        style={mergeStyles(tw("flex items-center justify-center gap-4 mt-8"), {
          padding: "24px",
          backgroundColor: "rgba(255,215,0,0.1)",
          borderRadius: "16px",
          border: "1px solid rgba(255,215,0,0.3)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "28px",
          }}
        >
          🤔
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "24px",
            color: "#ffd700",
            fontWeight: "500",
          }}
        >
          앞에서 배운 문법을 떠올려보세요!
        </div>
      </div>
    </div>
  );
}
