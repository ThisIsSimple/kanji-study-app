import type { LyricsOutroProps } from "../../types/lyrics";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function LyricsOutro(_props: LyricsOutroProps) {
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
          width: "600px",
          height: "600px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(255,107,157,0.1) 0%, transparent 60%)",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
        })}
      />

      {/* 메인 컨텐츠 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center gap-10"), {
          zIndex: 10,
        })}
      >
        {/* 완료 아이콘 */}
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "140px",
            height: "140px",
            backgroundColor: "rgba(255,107,157,0.2)",
            borderRadius: "50%",
            border: "4px solid rgba(255,107,157,0.5)",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "70px",
            }}
          >
            🎉
          </div>
        </div>

        {/* 완료 메시지 */}
        <div style={mergeStyles(tw("flex flex-col items-center gap-4"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "52px",
              color: "#ffffff",
              fontWeight: "700",
            }}
          >
            수고하셨어요!
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "28px",
              color: "rgba(255,255,255,0.6)",
              fontWeight: "500",
            }}
          >
            오늘도 일본어 실력이 늘었어요 ✨
          </div>
        </div>

        {/* 구분선 */}
        <div
          style={{
            display: "flex",
            width: "200px",
            height: "3px",
            background: "linear-gradient(90deg, transparent, #ff6b9d, #00d4ff, transparent)",
          }}
        />

        {/* 다음 단계 안내 */}
        <div style={mergeStyles(tw("flex flex-col items-center gap-6"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "24px",
              color: "rgba(255,255,255,0.5)",
            }}
          >
            더 많은 노래로 일본어를 배워보세요
          </div>
          <div
            style={mergeStyles(tw("flex items-center gap-4"), {
              background: "linear-gradient(135deg, #ff6b9d, #00d4ff)",
              borderRadius: "16px",
              padding: "24px 48px",
            })}
          >
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "#ffffff",
                fontWeight: "700",
              }}
            >
              팔로우하기
            </div>
            <div
              style={{
                display: "flex",
                fontSize: "28px",
              }}
            >
              💜
            </div>
          </div>
        </div>

        {/* 해시태그 */}
        <div style={mergeStyles(tw("flex flex-wrap justify-center gap-3 mt-6"), {})}>
          {["#일본어", "#J-POP", "#가사해석", "#일본어공부", "#문법학습"].map((tag, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                fontSize: "20px",
                color: "rgba(0,212,255,0.8)",
                backgroundColor: "rgba(0,212,255,0.1)",
                padding: "10px 20px",
                borderRadius: "20px",
              }}
            >
              {tag}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
