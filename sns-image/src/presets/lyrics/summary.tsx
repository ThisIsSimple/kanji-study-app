import type { LyricsSummaryProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsSummary({ data }: LyricsSummaryProps) {
  const contentLines = data.content.split("\n").filter(Boolean);

  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #462066 0%, #2d1b4e 100%)",
        padding: "60px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-10"), {
          borderBottom: "2px solid rgba(255,107,157,0.3)",
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "36px",
          }}
        >
          📋
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#ffffff",
            fontWeight: "700",
          }}
        >
          오늘의 요약
        </div>
      </div>

      {/* 요약 내용 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-5"), {
          flex: 1,
        })}
      >
        {contentLines.map((line, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-start gap-4"), {
              backgroundColor: "rgba(255,255,255,0.05)",
              borderRadius: "16px",
              padding: "24px 28px",
              border: "1px solid rgba(255,255,255,0.1)",
            })}
          >
            {/* 번호 */}
            <div
              style={mergeStyles(tw("flex items-center justify-center shrink-0"), {
                width: "40px",
                height: "40px",
                backgroundColor: index % 2 === 0 ? "#ff6b9d" : "#00d4ff",
                borderRadius: "10px",
              })}
            >
              <div
                style={{
                  display: "flex",
                  fontSize: "22px",
                  color: "#ffffff",
                  fontWeight: "700",
                }}
              >
                {index + 1}
              </div>
            </div>

            {/* 내용 */}
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "#ffffff",
                fontWeight: "500",
                lineHeight: "1.5",
                flex: 1,
              }}
            >
              {line}
            </div>
          </div>
        ))}
      </div>

      {/* 하단 장식 */}
      <div
        style={mergeStyles(tw("flex items-center justify-center gap-3 mt-10"), {
          padding: "20px",
          backgroundColor: "rgba(0,212,255,0.1)",
          borderRadius: "16px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "24px",
          }}
        >
          💡
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "22px",
            color: "#00d4ff",
            fontWeight: "500",
          }}
        >
          복습하면서 문법 패턴을 익혀보세요!
        </div>
      </div>
    </div>
  );
}
