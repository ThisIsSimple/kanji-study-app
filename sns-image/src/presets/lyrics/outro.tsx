import type { LyricsOutroProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsOutro(_props: LyricsOutroProps) {
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
        style={mergeStyles(tw("flex flex-col items-center gap-10"), {})}
      >
        {/* 완료 메시지 */}
        <div style={mergeStyles(tw("flex flex-col items-center gap-4"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "72px",
              color: "#000000",
              fontWeight: "900",
            }}
          >
            수고하셨어요!
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "40px",
              color: "#000000",
              fontWeight: "700",
            }}
          >
            오늘도 일본어 실력이 늘었어요 ✨
          </div>
        </div>
      </div>
    </div>
  );
}
