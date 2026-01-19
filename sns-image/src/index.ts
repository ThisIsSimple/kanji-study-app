import Fastify from "fastify";
import { generateRoutes } from "./routes/generate";
import { loadFonts } from "./utils/fonts";

const PORT = parseInt(process.env.PORT || "3000", 10);
const HOST = process.env.HOST || "0.0.0.0";

async function main() {
  // Fastify 인스턴스 생성
  const fastify = Fastify({
    logger: {
      level: "info",
      transport: {
        target: "pino-pretty",
        options: {
          translateTime: "HH:MM:ss Z",
          ignore: "pid,hostname",
        },
      },
    },
  });

  // 서버 시작 전 폰트 로드 (캐싱)
  try {
    fastify.log.info("Loading fonts...");
    const fonts = loadFonts();
    fastify.log.info(`Loaded ${fonts.length} font configurations`);
  } catch (error) {
    fastify.log.error({ err: error }, "Failed to load fonts");
    process.exit(1);
  }

  // 헬스 체크 엔드포인트
  fastify.get("/health", async () => {
    return {
      status: "ok",
      timestamp: new Date().toISOString(),
    };
  });

  // 루트 엔드포인트
  fastify.get("/", async () => {
    return {
      name: "SNS Image Generator",
      version: "1.0.0",
      description: "Satori + Sharp 기반 SNS 이미지 생성 서버",
      endpoints: {
        health: "GET /health",
        presets: "GET /presets",
        generate: "POST /generate",
      },
    };
  });

  // 이미지 생성 라우트 등록
  await fastify.register(generateRoutes);

  // Graceful shutdown
  const signals: NodeJS.Signals[] = ["SIGINT", "SIGTERM"];
  for (const signal of signals) {
    process.on(signal, async () => {
      fastify.log.info(`${signal} received, shutting down gracefully`);
      await fastify.close();
      process.exit(0);
    });
  }

  // 서버 시작
  try {
    await fastify.listen({ port: PORT, host: HOST });
    fastify.log.info(`Server is running on http://${HOST}:${PORT}`);
    fastify.log.info("Available endpoints:");
    fastify.log.info(`  GET  /health  - Health check`);
    fastify.log.info(`  GET  /presets - List available presets`);
    fastify.log.info(`  POST /generate - Generate images`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

main();
