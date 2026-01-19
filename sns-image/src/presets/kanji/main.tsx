import type { KanjiMainProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiMain({ data, index }: KanjiMainProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #16213e 0%, #1a1a2e 100%)",
        padding: "60px",
      })}
    >
      {/* 페이지 번호 */}
      <div
        style={mergeStyles(tw("flex items-center justify-between mb-8"), {
          borderBottom: "2px solid rgba(255,215,0,0.3)",
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "28px",
            color: "rgba(255,255,255,0.5)",
            fontWeight: "500",
          }}
        >
          구성 분석
        </div>
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "60px",
            height: "60px",
            backgroundColor: "#ffd700",
            borderRadius: "50%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "28px",
              color: "#1a1a2e",
              fontWeight: "700",
            }}
          >
            {index + 1}
          </div>
        </div>
      </div>

      {/* 등식 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center justify-center"), {
          flex: 1,
          gap: "60px",
        })}
      >
        {/* 등식 박스 */}
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            backgroundColor: "rgba(255,255,255,0.08)",
            borderRadius: "24px",
            padding: "50px 60px",
            border: "2px solid rgba(255,215,0,0.4)",
            width: "100%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "64px",
              color: "#ffffff",
              fontWeight: "700",
              textAlign: "center",
              letterSpacing: "0.05em",
            }}
          >
            {data.equation}
          </div>
        </div>

        {/* 구분선 */}
        <div
          style={{
            display: "flex",
            width: "100px",
            height: "4px",
            background: "linear-gradient(90deg, transparent, #e94560, transparent)",
          }}
        />

        {/* 설명 */}
        <div
          style={mergeStyles(tw("flex flex-col items-center"), {
            backgroundColor: "rgba(233,69,96,0.08)",
            borderRadius: "24px",
            padding: "50px",
            border: "1px solid rgba(233,69,96,0.3)",
            width: "100%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "20px",
              color: "#e94560",
              fontWeight: "600",
              marginBottom: "20px",
              letterSpacing: "0.1em",
            }}
          >
            EXPLANATION
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "38px",
              color: "#ffffff",
              fontWeight: "500",
              lineHeight: "1.6",
              textAlign: "center",
            }}
          >
            {data.explanation}
          </div>
        </div>
      </div>

      {/* 하단 장식 */}
      <div
        style={mergeStyles(tw("flex justify-center mt-8"), {
          gap: "12px",
        })}
      >
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              display: "flex",
              width: i === index % 3 ? "40px" : "12px",
              height: "12px",
              borderRadius: "6px",
              backgroundColor: i === index % 3 ? "#ffd700" : "rgba(255,255,255,0.2)",
            }}
          />
        ))}
      </div>
    </div>
  );
}
