import type { KanjiOutroProps } from "../../types/kanji";
import { containerStyle, tw, mergeStyles } from "../../utils/tailwind";

export function KanjiOutro(_props: KanjiOutroProps) {
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
        style={mergeStyles(tw("flex flex-col items-center gap-12"), {})}
      >
        {/* 완료 메시지 */}
        <div style={mergeStyles(tw("flex flex-col items-center gap-4"), {})}>
          <div
            style={{
              display: "flex",
              fontSize: "72px",
              color: "#000000",
              fontWeight: "900",
            }}
          >
            학습 완료!
          </div>
          <div
            style={{
              display: "flex",
              fontSize: "40px",
              color: "#000000",
              fontWeight: "700",
            }}
          >
            오늘도 한 걸음 성장했어요
          </div>
        </div>
      </div>
    </div>
  );
}
