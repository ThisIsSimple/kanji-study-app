import type { LyricsIntroProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsIntro({ data }: LyricsIntroProps) {
  const lyricsLines = data.lyrics.split("\n").filter(Boolean);
  const meaningLines = data.meaning.split("\n").filter(Boolean);

  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #2d1b4e 0%, #462066 100%)",
        padding: "50px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-8"), {
          borderBottom: "2px solid rgba(255,107,157,0.3)",
          paddingBottom: "20px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "32px",
          }}
        >
          📝
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#ffffff",
            fontWeight: "700",
          }}
        >
          가사 & 해석
        </div>
      </div>

      {/* 가사 + 해석 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-4"), {
          flex: 1,
          overflow: "hidden",
        })}
      >
        {lyricsLines.map((line, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex flex-col"), {
              backgroundColor: "rgba(255,255,255,0.05)",
              borderRadius: "16px",
              padding: "20px 28px",
              borderLeft: "4px solid rgba(255,107,157,0.5)",
            })}
          >
            {/* 일본어 가사 */}
            <div
              style={{
                display: "flex",
                fontSize: "30px",
                color: "#ffffff",
                fontWeight: "600",
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
                  fontSize: "24px",
                  color: "#00d4ff",
                  fontWeight: "500",
                  lineHeight: "1.4",
                }}
              >
                {meaningLines[index]}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* 하단 안내 */}
      <div
        style={mergeStyles(tw("flex items-center justify-center gap-2 mt-6"), {
          color: "rgba(255,255,255,0.4)",
          fontSize: "20px",
        })}
      >
        <div style={{ display: "flex" }}>다음 페이지에서 문법을 자세히 알아봐요</div>
        <div style={{ display: "flex" }}>→</div>
      </div>
    </div>
  );
}
