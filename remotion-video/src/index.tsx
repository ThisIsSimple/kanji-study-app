import {registerRoot} from 'remotion';
import {RemotionRoot} from './Root';
import {loadFonts} from './utils/loadFonts';

// 폰트를 미리 로드
loadFonts();

registerRoot(RemotionRoot);

