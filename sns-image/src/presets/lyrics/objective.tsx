import type { LyricsObjectiveProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsObjective({ data }: LyricsObjectiveProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        justifyContent: "center",
        alignItems: "center",
        padding: "200px",
      })}
    >
      {/* 메인 컨텐츠 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center"), {
          width: "100%",
        })}
      >
        {/* 타이틀 */}
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "20px",
            letterSpacing: "0.2em",
          }}
        >
          학습 목표
        </div>

        {/* 메인 타이틀 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "72px",
            color: "#000000",
            fontWeight: "900",
            marginBottom: "24px",
            lineHeight: "1.3",
          })}
        >
          {data.title}
        </div>

        {/* 서브타이틀 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "44px",
            color: "#000000",
            fontWeight: "700",
            lineHeight: "1.5",
          })}
        >
          {data.subtitle}
        </div>
      </div>
    </div>
  );
}
