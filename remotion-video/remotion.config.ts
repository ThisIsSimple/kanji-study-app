import {Config} from '@remotion/bundler';
import {Config as CliConfig} from '@remotion/cli/config';

// delayRender 타임아웃 설정 (60초)
CliConfig.setDelayRenderTimeoutInMilliseconds(60000);

export default {
  outputLocation: 'out/video.mp4',
  publicDir: 'public',
} satisfies Config;

