import type { KanjiAdditionalProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiAdditional({ data, index }: KanjiAdditionalProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #0f3460 0%, #16213e 100%)",
        padding: "60px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-6 mb-8"), {
          borderBottom: "2px solid rgba(255,215,0,0.3)",
          paddingBottom: "24px",
        })}
      >
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "100px",
            height: "100px",
            backgroundColor: "rgba(255,215,0,0.15)",
            borderRadius: "20px",
            border: "2px solid rgba(255,215,0,0.4)",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "60px",
              color: "#ffd700",
              fontWeight: "700",
            }}
          >
            {data.kanji}
          </div>
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#ffffff",
            fontWeight: "600",
          }}
        >
          관련 단어
        </div>
        <div
          style={mergeStyles(tw("ml-auto flex"), {
            fontSize: "24px",
            color: "rgba(255,255,255,0.4)",
          })}
        >
          #{index + 1}
        </div>
      </div>

      {/* 예시 단어 리스트 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-5"), {
          flex: 1,
        })}
      >
        {data.examples.map((example, idx) => (
          <div
            key={idx}
            style={mergeStyles(tw("flex items-center"), {
              backgroundColor: "rgba(255,255,255,0.05)",
              borderRadius: "16px",
              padding: "28px 32px",
              border: "1px solid rgba(255,255,255,0.1)",
              gap: "24px",
            })}
          >
            {/* 레벨 뱃지 */}
            <div
              style={mergeStyles(tw("flex items-center justify-center"), {
                minWidth: "70px",
                height: "36px",
                backgroundColor:
                  example.level === "N1"
                    ? "#e94560"
                    : example.level === "N2"
                      ? "#f97316"
                      : example.level === "N3"
                        ? "#eab308"
                        : example.level === "N4"
                          ? "#22c55e"
                          : "#3b82f6",
                borderRadius: "8px",
              })}
            >
              <div
                style={{
                  display: "flex",
                  fontSize: "18px",
                  color: "#ffffff",
                  fontWeight: "700",
                }}
              >
                {example.level}
              </div>
            </div>

            {/* 단어 */}
            <div
              style={{
                display: "flex",
                fontSize: "40px",
                color: "#ffffff",
                fontWeight: "700",
                minWidth: "200px",
              }}
            >
              {example.word}
            </div>

            {/* 화살표 */}
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "rgba(255,255,255,0.3)",
              }}
            >
              →
            </div>

            {/* 등식/설명 */}
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "#e0e0e0",
                fontWeight: "500",
                flex: 1,
              }}
            >
              {example.equation}
            </div>
          </div>
        ))}
      </div>

      {/* 하단 팁 */}
      <div
        style={mergeStyles(tw("flex items-center justify-center gap-3 mt-8"), {
          padding: "20px",
          backgroundColor: "rgba(255,215,0,0.1)",
          borderRadius: "12px",
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
            color: "#ffd700",
            fontWeight: "500",
          }}
        >
          같은 한자가 포함된 단어들을 함께 외우면 효과적이에요!
        </div>
      </div>
    </div>
  );
}
