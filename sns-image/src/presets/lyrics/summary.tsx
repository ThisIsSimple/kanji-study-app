import type { LyricsSummaryProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsSummary({ data }: LyricsSummaryProps) {
  const contentLines = data.content.split("\n").filter(Boolean);

  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-10"), {
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
          오늘의 요약
        </div>
      </div>

      {/* 요약 내용 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-6"), {
          flex: 1,
        })}
      >
        {contentLines.map((line, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-start gap-4"), {})}
          >
            {/* 번호 */}
            <div
              style={{
                display: "flex",
                fontSize: "32px",
                color: "#000000",
                fontWeight: "800",
                minWidth: "50px",
              }}
            >
              {index + 1}.
            </div>

            {/* 내용 */}
            <div
              style={{
                display: "flex",
                fontSize: "40px",
                color: "#000000",
                fontWeight: "700",
                lineHeight: "1.5",
                flex: 1,
              }}
            >
              {line}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
