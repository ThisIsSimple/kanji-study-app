import type { LyricsCoverProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsCover({ data }: LyricsCoverProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(135deg, #2d1b4e 0%, #462066 50%, #1a0a2e 100%)",
        justifyContent: "center",
        alignItems: "center",
        padding: "60px",
      })}
    >
      {/* 배경 장식 */}
      <div
        style={mergeStyles(tw("absolute flex"), {
          width: "800px",
          height: "800px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(255,107,157,0.15) 0%, transparent 60%)",
          top: "-200px",
          left: "-200px",
        })}
      />
      <div
        style={mergeStyles(tw("absolute flex"), {
          width: "600px",
          height: "600px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(0,212,255,0.1) 0%, transparent 60%)",
          bottom: "-100px",
          right: "-100px",
        })}
      />

      {/* 음표 장식 */}
      <div
        style={mergeStyles(tw("absolute flex"), {
          top: "80px",
          right: "80px",
          fontSize: "60px",
          opacity: 0.2,
        })}
      >
        ♪
      </div>
      <div
        style={mergeStyles(tw("absolute flex"), {
          bottom: "120px",
          left: "80px",
          fontSize: "80px",
          opacity: 0.15,
        })}
      >
        ♫
      </div>

      {/* 메인 컨텐츠 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center"), {
          zIndex: 10,
          width: "100%",
        })}
      >
        {/* 아티스트 */}
        <div
          style={mergeStyles(tw("flex items-center gap-3 mb-8"), {
            backgroundColor: "rgba(255,107,157,0.2)",
            borderRadius: "30px",
            padding: "12px 32px",
            border: "1px solid rgba(255,107,157,0.3)",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "24px",
            }}
          >
            🎤
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "28px",
              color: "#ff6b9d",
              fontWeight: "600",
            }}
          >
            {data.artist}
          </div>
        </div>

        {/* 일본어 제목 */}
        <div
          style={mergeStyles(tw("text-center mb-6 flex"), {
            fontSize: "100px",
            color: "#ffffff",
            fontWeight: "800",
            letterSpacing: "0.02em",
            textShadow: "0 4px 30px rgba(255,107,157,0.3)",
          })}
        >
          {data.title}
        </div>

        {/* 구분선 */}
        <div
          style={{
            display: "flex",
            width: "300px",
            height: "3px",
            background: "linear-gradient(90deg, transparent, #00d4ff, transparent)",
            marginBottom: "30px",
          }}
        />

        {/* 한국어 제목 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "48px",
            color: "#00d4ff",
            fontWeight: "600",
          })}
        >
          {data.korean_title}
        </div>

        {/* 하단 태그 */}
        <div style={mergeStyles(tw("flex items-center gap-4 mt-16"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "22px",
              color: "rgba(255,255,255,0.5)",
              backgroundColor: "rgba(255,255,255,0.1)",
              padding: "10px 24px",
              borderRadius: "20px",
            }}
          >
            가사 해석
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "22px",
              color: "rgba(255,255,255,0.5)",
              backgroundColor: "rgba(255,255,255,0.1)",
              padding: "10px 24px",
              borderRadius: "20px",
            }}
          >
            문법 학습
          </div>
        </div>
      </div>
    </div>
  );
}
