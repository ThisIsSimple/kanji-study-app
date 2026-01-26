import type { KanjiIntroProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiIntro({ data }: KanjiIntroProps) {
  return (
    <div
      style={mergeStyles(containerStyle, {
        padding: "200px",
      })}
    >
      {/* 헤더 */}
      <div
        style={mergeStyles(tw("flex items-center gap-4 mb-10"), {
          paddingBottom: "24px",
        })}
      >
        <div
          style={{
            display: "flex",
            fontSize: "48px",
            color: "#000000",
            fontWeight: "800",
          }}
        >
          한자 구성
        </div>
      </div>

      {/* 한자 리스트 */}
      <div
        style={mergeStyles(tw("flex flex-col gap-8"), {
          flex: 1,
        })}
      >
        {data.kanji.map((item, index) => (
          <div
            key={index}
            style={mergeStyles(tw("flex items-center gap-8"), {})}
          >
            {/* 한자 */}
            <div
              style={mergeStyles(tw("flex items-center justify-center"), {})}
            >
              <div
                style={{
                  display: "flex",
                  fontSize: "96px",
                  color: "#000000",
                  fontWeight: "900",
                }}
              >
                {item.kanji}
              </div>
            </div>

            {/* 화살표 */}
            <div
              style={{
                display: "flex",
                fontSize: "48px",
                color: "#000000",
              }}
            >
              →
            </div>

            {/* 한국어 뜻 */}
            <div
              style={{
                display: "flex",
                fontSize: "56px",
                color: "#000000",
                fontWeight: "700",
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
        style={mergeStyles(tw("mt-10 flex flex-col"), {})}
      >
        <div
          style={{
            display: "flex",
            fontSize: "32px",
            color: "#000000",
            fontWeight: "700",
            marginBottom: "16px",
          }}
        >
          종합 의미
        </div>
        <div
          style={{
            display: "flex",
            fontSize: "48px",
            color: "#000000",
            fontWeight: "700",
            lineHeight: "1.5",
          }}
        >
          {data.meaning}
        </div>
      </div>
    </div>
  );
}
