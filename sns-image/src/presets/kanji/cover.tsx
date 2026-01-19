import type { KanjiCoverProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiCover({ data }: KanjiCoverProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)",
        justifyContent: "center",
        alignItems: "center",
        padding: "60px",
      })}
    >
      {/* 데코레이션 원 */}
      <div
        style={mergeStyles(tw("absolute"), {
          width: "600px",
          height: "600px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(233,69,96,0.15) 0%, transparent 70%)",
          top: "-100px",
          right: "-100px",
        })}
      />

      {/* 메인 컨텐츠 박스 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center justify-center"), {
          backgroundColor: "rgba(255,255,255,0.05)",
          borderRadius: "32px",
          padding: "80px 60px",
          border: "2px solid rgba(255,215,0,0.3)",
          backdropFilter: "blur(10px)",
          width: "90%",
        })}
      >
        {/* 요미가나 */}
        <div
          style={mergeStyles(tw("text-center mb-6 flex"), {
            fontSize: "42px",
            color: "#ffd700",
            fontWeight: "500",
            letterSpacing: "0.1em",
          })}
        >
          {data.yomigana}
        </div>

        {/* 메인 단어 */}
        <div
          style={mergeStyles(tw("text-center mb-10 flex"), {
            fontSize: "140px",
            color: "#ffffff",
            fontWeight: "800",
            letterSpacing: "0.05em",
            textShadow: "0 4px 20px rgba(0,0,0,0.3)",
          })}
        >
          {data.word}
        </div>

        {/* 구분선 */}
        <div
          style={{
            width: "200px",
            height: "4px",
            background: "linear-gradient(90deg, transparent, #ffd700, transparent)",
            marginBottom: "40px",
          }}
        />

        {/* 뜻 */}
        <div
          style={mergeStyles(tw("text-center flex"), {
            fontSize: "48px",
            color: "#e0e0e0",
            fontWeight: "600",
          })}
        >
          {data.meaning}
        </div>
      </div>

      {/* 하단 장식 */}
      <div
        style={mergeStyles(tw("absolute flex items-center gap-4"), {
          bottom: "60px",
        })}
      >
        <div
          style={{
            display: "flex",
            width: "60px",
            height: "3px",
            backgroundColor: "rgba(255,215,0,0.5)",
          }}
        />
        <div
          style={{
            display: "flex",
            fontSize: "24px",
            color: "rgba(255,255,255,0.5)",
            fontWeight: "500",
          }}
        >
          한자 학습
        </div>
        <div
          style={{
            display: "flex",
            width: "60px",
            height: "3px",
            backgroundColor: "rgba(255,215,0,0.5)",
          }}
        />
      </div>
    </div>
  );
}
