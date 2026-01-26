import type { LyricsMainProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsMain({ data, index }: LyricsMainProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center justify-between mb-6"), {
          paddingBottom: "20px",
        })}
      >
        <div style={mergeStyles(tw("flex items-center gap-3"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "40px",
              color: "#000000",
              fontWeight: "800",
            }}
          >
            문법 해설
          </div>
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "40px",
            color: "#000000",
            fontWeight: "800",
          }}
        >
          {data.number}
        </div>
      </div>

      {/* 원문 문장 */}
      <div
        style={mergeStyles(tw("mb-6 flex flex-col"), {})}
      >
        <div
          style={{
            display: "flex",
            fontSize: "28px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "12px",
          }}
        >
          원문
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "52px",
            color: "#000000",
            fontWeight: "800",
            lineHeight: "1.4",
          }}
        >
          {data.sentence}
        </div>
      </div>

      {/* 핵심 내용 */}
      <div
        style={mergeStyles(tw("mb-6 flex flex-col"), {})}
      >
        <div
          style={{
            display: "flex",
            fontSize: "28px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "12px",
          }}
        >
          핵심 문법
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "44px",
            color: "#000000",
            fontWeight: "800",
            lineHeight: "1.5",
          }}
        >
          {data.content}
        </div>
      </div>

      {/* 설명 */}
      <div
        style={mergeStyles(tw("flex-1 flex flex-col"), {})}
      >
        <div
          style={{
            display: "flex",
            fontSize: "28px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "16px",
          }}
        >
          상세 설명
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "40px",
            color: "#000000",
            fontWeight: "700",
            lineHeight: "1.6",
          }}
        >
          {data.explanation}
        </div>
      </div>
    </div>
  );
}
