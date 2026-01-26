import type { KanjiAdditionalProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiAdditional({ data, index }: KanjiAdditionalProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-6 mb-8"), {
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "80px",
            color: "#000000",
            fontWeight: "900",
          }}
        >
          {data.kanji}
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "40px",
            color: "#000000",
            fontWeight: "700",
          }}
        >
          관련 단어
        </div>
        <div
          style={mergeStyles(tw("ml-auto flex"), {
            fontSize: "32px",
            color: "#000000",
            fontWeight: "700",
          })}
        >
          #{index + 1}
        </div>
      </div>

      {/* 예시 단어 리스트 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-6"), {
          flex: 1,
        })}
      >
        {data.examples.map((example, idx) => (
          <div
            key={idx}
            style={mergeStyles(tw("flex items-center"), {
              gap: "24px",
            })}
          >
            {/* 레벨 */}
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "#000000",
                fontWeight: "700",
                minWidth: "80px",
              }}
            >
              {example.level}
            </div>

            {/* 단어 */}
            <div
              style={{
                display: "flex",
                fontSize: "56px",
                color: "#000000",
                fontWeight: "800",
                minWidth: "200px",
              }}
            >
              {example.word}
            </div>

            {/* 화살표 */}
            <div
              style={{
                display: "flex",
                fontSize: "40px",
                color: "#000000",
              }}
            >
              →
            </div>

            {/* 등식/설명 */}
            <div
              style={{
                display: "flex",
                fontSize: "40px",
                color: "#000000",
                fontWeight: "700",
                flex: 1,
              }}
            >
              {example.equation}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
