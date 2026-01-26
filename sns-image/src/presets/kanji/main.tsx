import type { KanjiMainProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiMain({ data, index }: KanjiMainProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 페이지 번호 */}
      <div
        style={mergeStyles(tw("flex items-center justify-between mb-8"), {
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#000000",
            fontWeight: "700",
          }}
        >
          구성 분석
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#000000",
            fontWeight: "700",
          }}
        >
          {index + 1}
        </div>
      </div>

      {/* 등식 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center justify-center"), {
          flex: 1,
          gap: "60px",
        })}
      >
        {/* 등식 */}
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "100%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "80px",
              color: "#000000",
              fontWeight: "900",
              textAlign: "center",
              letterSpacing: "0.05em",
            }}
          >
            {data.equation}
          </div>
        </div>

        {/* 설명 */}
        <div
          style={mergeStyles(tw("flex flex-col items-center"), {
            width: "100%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "52px",
              color: "#000000",
              fontWeight: "800",
              lineHeight: "1.6",
              textAlign: "center",
            }}
          >
            {data.explanation}
          </div>
        </div>
      </div>
    </div>
  );
}
