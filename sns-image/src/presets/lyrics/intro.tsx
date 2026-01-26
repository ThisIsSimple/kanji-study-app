import type { LyricsIntroProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsIntro({ data }: LyricsIntroProps) {
  const lyricsLines = data.lyrics.split("\n").filter(Boolean);
  const meaningLines = data.meaning.split("\n").filter(Boolean);

  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-8"), {
          paddingBottom: "20px",
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
          가사 & 해석
        </div>
      </div>

      {/* 가사 + 해석 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-6"), {
          flex: 1,
          overflow: "hidden",
        })}
      >
        {lyricsLines.map((line, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex flex-col"), {})}
          >
            {/* 일본어 가사 */}
            <div
              style={{
                display: "flex",
                fontSize: "44px",
                color: "#000000",
                fontWeight: "700",
                marginBottom: "10px",
                lineHeight: "1.4",
              }}
            >
              {line}
            </div>
            {/* 한국어 해석 */}
            {meaningLines[index] && (
              <div
                style={{
                  display: "flex",
                  fontSize: "36px",
                  color: "#000000",
                  fontWeight: "600",
                  lineHeight: "1.4",
                }}
              >
                {meaningLines[index]}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
