import type { LyricsQuizProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsQuiz({ data }: LyricsQuizProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-8"), {
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "48px",
            color: "#000000",
            fontWeight: "800",
          }}
        >
          퀴즈 타임!
        </div>
      </div>

      {/* 문제 문장 */}
      <div
        style={mergeStyles(tw("mb-8 flex flex-col"), {})}
      >
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "16px",
          }}
        >
          다음 문장을 해석해보세요
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "56px",
            color: "#000000",
            fontWeight: "900",
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
        style={mergeStyles(tw("flex flex-col gap-6"), {
          flex: 1,
        })}
      >
        {data.questions.map((question, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-center gap-4"), {})}
          >
            {/* 번호 */}
            <div
              style={{
                display: "flex",
                fontSize: "36px",
                color: "#000000",
                fontWeight: "800",
                minWidth: "60px",
              }}
            >
              {index + 1}.
            </div>

            {/* 질문 내용 */}
            <div
              style={{
                display: "flex",
                fontSize: "44px",
                color: "#000000",
                fontWeight: "700",
                flex: 1,
                lineHeight: "1.4",
              }}
            >
              {question.content}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
