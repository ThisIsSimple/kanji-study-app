import type { KanjiCoverProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiCover({ data }: KanjiCoverProps) {
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
        style={mergeStyles(tw("flex flex-col items-center justify-center"), {
          width: "100%",
        })}
      >
        {/* 요미가나 */}
        <div
          style={mergeStyles(tw("text-center mb-6 flex"), {
            fontSize: "56px",
            color: "#000000",
            fontWeight: "700",
            letterSpacing: "0.1em",
          })}
        >
          {data.yomigana}
        </div>

        {/* 메인 단어 */}
        <div
          style={mergeStyles(tw("text-center mb-10 flex"), {
            fontSize: "180px",
            color: "#000000",
            fontWeight: "900",
            letterSpacing: "0.05em",
          })}
        >
          {data.word}
        </div>

        {/* 뜻 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "64px",
            color: "#000000",
            fontWeight: "700",
          })}
        >
          {data.meaning}
        </div>
      </div>
    </div>
  );
}
