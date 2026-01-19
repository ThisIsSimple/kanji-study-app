import type { LyricsMainProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsMain({ data, index }: LyricsMainProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #2d1b4e 0%, #1a0a2e 100%)",
        padding: "50px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center justify-between mb-6"), {
          borderBottom: "2px solid rgba(0,212,255,0.3)",
          paddingBottom: "20px",
        })}
      >
        <div style={mergeStyles(tw("flex items-center gap-3"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "28px",
            }}
          >
            📖
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "28px",
              color: "#ffffff",
              fontWeight: "600",
            }}
          >
            문법 해설
          </div>
        </div>
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "50px",
            height: "50px",
            backgroundColor: "#ff6b9d",
            borderRadius: "50%",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "24px",
              color: "#ffffff",
              fontWeight: "700",
            }}
          >
            {data.number}
          </div>
        </div>
      </div>

      {/* 원문 문장 */}
      <div
        style={mergeStyles(tw("mb-6 flex flex-col"), {
          backgroundColor: "rgba(255,107,157,0.1)",
          borderRadius: "20px",
          padding: "30px",
          border: "2px solid rgba(255,107,157,0.3)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "20px",
            color: "#ff6b9d",
            fontWeight: "600",
            marginBottom: "12px",
          }}
        >
          원문
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#ffffff",
            fontWeight: "700",
            lineHeight: "1.4",
          }}
        >
          {data.sentence}
        </div>
      </div>

      {/* 핵심 내용 */}
      <div
        style={mergeStyles(tw("mb-6 flex flex-col"), {
          backgroundColor: "rgba(0,212,255,0.1)",
          borderRadius: "20px",
          padding: "30px",
          border: "2px solid rgba(0,212,255,0.3)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "20px",
            color: "#00d4ff",
            fontWeight: "600",
            marginBottom: "12px",
          }}
        >
          핵심 문법
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#ffffff",
            fontWeight: "600",
            lineHeight: "1.5",
          }}
        >
          {data.content}
        </div>
      </div>

      {/* 설명 */}
      <div
        style={mergeStyles(tw("flex-1 flex flex-col"), {
          backgroundColor: "rgba(255,255,255,0.05)",
          borderRadius: "20px",
          padding: "30px",
          border: "1px solid rgba(255,255,255,0.1)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "20px",
            color: "rgba(255,255,255,0.6)",
            fontWeight: "600",
            marginBottom: "16px",
          }}
        >
          상세 설명
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "28px",
            color: "#e0e0e0",
            fontWeight: "500",
            lineHeight: "1.6",
          }}
        >
          {data.explanation}
        </div>
      </div>

      {/* 페이지 인디케이터 */}
      <div style={mergeStyles(tw("flex justify-center gap-3 mt-6"), {})}>
        {[0, 1, 2, 3, 4].map((i) => (
          <div
            key={i}
            style={{
              display: "flex",
              width: i === index % 5 ? "32px" : "10px",
              height: "10px",
              borderRadius: "5px",
              backgroundColor: i === index % 5 ? "#00d4ff" : "rgba(255,255,255,0.2)",
            }}
          />
        ))}
      </div>
    </div>
  );
}
