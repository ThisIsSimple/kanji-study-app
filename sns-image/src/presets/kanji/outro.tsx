import type { KanjiOutroProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiOutro(_props: KanjiOutroProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)",
        justifyContent: "center",
        alignItems: "center",
        padding: "60px",
      })}
    >
      {/* 데코레이션 */}
      <div
        style={mergeStyles(tw("absolute flex"), {
          width: "500px",
          height: "500px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(255,215,0,0.1) 0%, transparent 70%)",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
        })}
      />

      {/* 메인 컨텐츠 */}
      <div
        style={mergeStyles(tw("flex flex-col items-center gap-12"), {
          zIndex: 10,
        })}
      >
        {/* 체크 아이콘 */}
        <div
          style={mergeStyles(tw("flex items-center justify-center"), {
            width: "140px",
            height: "140px",
            backgroundColor: "rgba(34,197,94,0.2)",
            borderRadius: "50%",
            border: "4px solid rgba(34,197,94,0.5)",
          })}
        >
          <div
            style={{
              display: "flex",
              fontSize: "80px",
            }}
          >
            ✓
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
            학습 완료!
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "28px",
              color: "rgba(255,255,255,0.6)",
              fontWeight: "500",
            }}
          >
            오늘도 한 걸음 성장했어요
          </div>
        </div>

        {/* 구분선 */}
        <div
          style={{
            display: "flex",
            width: "200px",
            height: "2px",
            background: "linear-gradient(90deg, transparent, rgba(255,215,0,0.5), transparent)",
          }}
        />

        {/* CTA */}
        <div style={mergeStyles(tw("flex flex-col items-center gap-6"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "24px",
              color: "rgba(255,255,255,0.5)",
            }}
          >
            더 많은 학습 자료가 궁금하다면
          </div>
          <div
            style={mergeStyles(tw("flex items-center gap-4"), {
              backgroundColor: "#ffd700",
              borderRadius: "16px",
              padding: "24px 48px",
            })}
          >
            <div
              style={{
                display: "flex",
                fontSize: "28px",
                color: "#1a1a2e",
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
              👆
            </div>
          </div>
        </div>

        {/* 해시태그 */}
        <div style={mergeStyles(tw("flex flex-wrap justify-center gap-3 mt-8"), {})}>
          {["#일본어", "#한자", "#JLPT", "#일본어공부", "#한자학습"].map((tag, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                fontSize: "22px",
                color: "rgba(255,215,0,0.7)",
                backgroundColor: "rgba(255,215,0,0.1)",
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
