import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import type { GenerateRequest, GenerateResponse, ErrorResponse, KanjiInput } from "../types";
import type { LyricsInput } from "../types/lyrics";
import { generateKanjiPages } from "../presets/kanji";
import { generateLyricsPages } from "../presets/lyrics";
import { renderPages, generateOutputDirName } from "../utils/satori";

// 요청 바디 스키마
const generateSchema = {
  body: {
    type: "object",
    required: ["type", "data"],
    properties: {
      type: { type: "string", enum: ["kanji", "lyrics"] },
      data: { type: "object" },
    },
  },
};

interface GenerateBody {
  type: "kanji" | "lyrics";
  data: KanjiInput | LyricsInput;
}

/**
 * 이미지 생성 라우트 등록
 */
export async function generateRoutes(fastify: FastifyInstance): Promise<void> {
  // POST /generate - 이미지 생성
  fastify.post<{ Body: GenerateBody }>(
    "/generate",
    { schema: generateSchema },
    async (request: FastifyRequest<{ Body: GenerateBody }>, reply: FastifyReply) => {
      const { type, data } = request.body;

      try {
        // 출력 디렉토리 생성
        const outputDir = generateOutputDirName(type);

        // 타입에 따라 적절한 프리셋으로 페이지 생성
        let pages;
        if (type === "kanji") {
          const kanjiData = data as KanjiInput;
          validateKanjiInput(kanjiData);
          pages = generateKanjiPages(kanjiData);
        } else if (type === "lyrics") {
          const lyricsData = data as LyricsInput;
          validateLyricsInput(lyricsData);
          pages = generateLyricsPages(lyricsData);
        } else {
          const errorResponse: ErrorResponse = {
            success: false,
            error: "Invalid type",
            message: `Unsupported preset type: ${type}. Supported types: kanji, lyrics`,
          };
          return reply.status(400).send(errorResponse);
        }

        fastify.log.info(`Generating ${pages.length} images for ${type} preset...`);

        // 이미지 렌더링
        const imagePaths = await renderPages(pages, outputDir);

        // 파일명만 추출
        const imageFilenames = imagePaths.map((p) => p.split("/").pop() || p);

        const response: GenerateResponse = {
          success: true,
          outputDir: `output/${outputDir}`,
          images: imageFilenames,
        };

        return reply.send(response);
      } catch (error) {
        fastify.log.error(error);

        const errorResponse: ErrorResponse = {
          success: false,
          error: "Generation failed",
          message: error instanceof Error ? error.message : "Unknown error occurred",
        };

        return reply.status(500).send(errorResponse);
      }
    }
  );

  // GET /presets - 지원하는 프리셋 목록
  fastify.get("/presets", async (_request, reply) => {
    return reply.send({
      presets: [
        {
          type: "kanji",
          name: "한자 학습",
          description: "한자 구성, 등식, 관련 단어 등을 포함한 학습 자료 생성",
          pages: ["cover", "intro", "main[]", "additional[]", "outro"],
        },
        {
          type: "lyrics",
          name: "가사 해석",
          description: "노래 가사와 문법 해설을 포함한 학습 자료 생성",
          pages: ["cover", "intro", "objective", "main[]", "summary", "quiz", "outro"],
        },
      ],
    });
  });
}

/**
 * 한자 입력 데이터 검증
 */
function validateKanjiInput(data: KanjiInput): void {
  if (!data.cover || !data.cover.word) {
    throw new Error("cover.word is required");
  }
  if (!data.intro || !Array.isArray(data.intro.kanji)) {
    throw new Error("intro.kanji array is required");
  }
  if (!Array.isArray(data.main) || data.main.length === 0) {
    throw new Error("main array is required and must not be empty");
  }
  if (!Array.isArray(data.additional)) {
    throw new Error("additional array is required");
  }
}

/**
 * 가사 입력 데이터 검증
 */
function validateLyricsInput(data: LyricsInput): void {
  if (!data.cover || !data.cover.title) {
    throw new Error("cover.title is required");
  }
  if (!data.intro || !data.intro.lyrics) {
    throw new Error("intro.lyrics is required");
  }
  if (!data.objective || !data.objective.title) {
    throw new Error("objective.title is required");
  }
  if (!Array.isArray(data.main) || data.main.length === 0) {
    throw new Error("main array is required and must not be empty");
  }
  if (!data.summary || !data.summary.content) {
    throw new Error("summary.content is required");
  }
  if (!data.quiz || !data.quiz.sentence) {
    throw new Error("quiz.sentence is required");
  }
}
