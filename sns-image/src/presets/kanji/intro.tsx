import type { KanjiIntroProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiIntro({ data }: KanjiIntroProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        background: "linear-gradient(180deg, #1a1a2e 0%, #16213e 100%)",
        padding: "60px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-10"), {
          borderBottom: "2px solid rgba(255,215,0,0.3)",
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            width: "8px",
            height: "40px",
            backgroundColor: "#ffd700",
            borderRadius: "4px",
          }}
        />
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#ffffff",
            fontWeight: "700",
          }}
        >
          한자 구성
        </div>
      </div>

      {/* 한자 리스트 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-6"), {
          flex: 1,
        })}
      >
        {data.kanji.map((item, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-center gap-6"), {
              backgroundColor: "rgba(255,255,255,0.05)",
              borderRadius: "20px",
              padding: "30px 40px",
              border: "1px solid rgba(255,255,255,0.1)",
            })}
          >
            {/* 한자 */}
            <div
              style={mergeStyles(tw("flex items-center justify-center"), {
                width: "120px",
                height: "120px",
                backgroundColor: "rgba(255,215,0,0.1)",
                borderRadius: "16px",
                border: "2px solid rgba(255,215,0,0.3)",
              })}
            >
              <div
                style={{
                  display: "flex",
                  fontSize: "72px",
                  color: "#ffd700",
                  fontWeight: "700",
                }}
              >
                {item.kanji}
              </div>
            </div>

            {/* 화살표 */}
            <div
              style={{
                display: "flex",
                fontSize: "36px",
                color: "rgba(255,255,255,0.3)",
              }}
            >
              →
            </div>

            {/* 한국어 뜻 */}
            <div
              style={{
                display: "flex",
                fontSize: "42px",
                color: "#ffffff",
                fontWeight: "600",
                flex: 1,
              }}
            >
              {item.korean}
            </div>
          </div>
        ))}
      </div>

      {/* 전체 의미 */}
      <div
        style={mergeStyles(tw("mt-10 flex flex-col"), {
          backgroundColor: "rgba(233,69,96,0.1)",
          borderRadius: "20px",
          padding: "40px",
          border: "2px solid rgba(233,69,96,0.3)",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "24px",
            color: "#e94560",
            fontWeight: "600",
            marginBottom: "16px",
          }}
        >
          종합 의미
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "36px",
            color: "#ffffff",
            fontWeight: "500",
            lineHeight: "1.5",
          }}
        >
          {data.meaning}
        </div>
      </div>
    </div>
  );
}
