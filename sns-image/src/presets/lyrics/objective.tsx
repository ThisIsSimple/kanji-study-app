import type { LyricsObjectiveProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsObjective({ data }: LyricsObjectiveProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(135deg, #462066 0%, #2d1b4e 100%)",
        justifyContent: "center",
        alignItems: "center",
        padding: "60px",
      })}
    >
      {/* 배경 그래픽 */}
      <div
        style={mergeStyles(tw("absolute flex"), {
          width: "100%",
          height: "100%",
          background:
            "repeating-linear-gradient(45deg, transparent, transparent 50px, rgba(255,255,255,0.02) 50px, rgba(255,255,255,0.02) 100px)",
        })}
      />

      {/* 메인 컨텐츠 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center"), {
          zIndex: 10,
          backgroundColor: "rgba(0,0,0,0.3)",
          borderRadius: "32px",
          padding: "80px 60px",
          border: "2px solid rgba(0,212,255,0.3)",
          width: "90%",
        })}
      >
        {/* 아이콘 */}
        <div
          style={mergeStyles(tw("flex items-center justify-center mb-10"), {
            width: "120px",
            height: "120px",
            backgroundColor: "rgba(0,212,255,0.15)",
            borderRadius: "50%",
            border: "3px solid rgba(0,212,255,0.4)",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "60px",
            }}
          >
            🎯
          </div>
        </div>

        {/* 타이틀 */}
        <div
          style={{
            display: "flex",
            fontSize: "24px",
            color: "#00d4ff",
            fontWeight: "600",
            marginBottom: "20px",
            letterSpacing: "0.2em",
          }}
        >
          학습 목표
        </div>

        {/* 메인 타이틀 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "56px",
            color: "#ffffff",
            fontWeight: "800",
            marginBottom: "24px",
            lineHeight: "1.3",
          })}
        >
          {data.title}
        </div>

        {/* 구분선 */}
        <div
          style={{
            display: "flex",
            width: "150px",
            height: "4px",
            background: "linear-gradient(90deg, #ff6b9d, #00d4ff)",
            borderRadius: "2px",
            marginBottom: "30px",
          }}
        />

        {/* 서브타이틀 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "32px",
            color: "rgba(255,255,255,0.7)",
            fontWeight: "500",
            lineHeight: "1.5",
          })}
        >
          {data.subtitle}
        </div>
      </div>

      {/* 하단 장식 */}
      <div
        style={mergeStyles(tw("absolute flex gap-6"), {
          bottom: "60px",
        })}
      >
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            style={{
              display: "flex",
              width: "12px",
              height: "12px",
              borderRadius: "50%",
              backgroundColor: i === 2 ? "#00d4ff" : "rgba(255,255,255,0.2)",
            }}
          />
        ))}
      </div>
    </div>
  );
}
