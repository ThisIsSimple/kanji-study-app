import type { LyricsCoverProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsCover({ data }: LyricsCoverProps) {
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
        {/* 아티스트 */}
        <div
          style={mergeStyles(tw("flex items-center gap-3 mb-8"), {})}
        >
          <div
            style={{
              display: "flex",
              fontSize: "40px",
              color: "#000000",
              fontWeight: "700",
            }}
          >
            {data.artist}
          </div>
        </div>

        {/* 일본어 제목 */}
        <div
          style={mergeStyles(tw("text-center mb-6 flex"), {
            fontSize: "120px",
            color: "#000000",
            fontWeight: "900",
            letterSpacing: "0.02em",
          })}
        >
          {data.title}
        </div>

        {/* 한국어 제목 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "64px",
            color: "#000000",
            fontWeight: "700",
          })}
        >
          {data.korean_title}
        </div>
      </div>
    </div>
  );
}

