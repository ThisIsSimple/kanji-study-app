import React from 'react';
import {AbsoluteFill} from 'remotion';
import {COLORS} from '../constants/colors';
import {WIDTH, HEIGHT} from '../constants/layout';
import {FONT_FAMILY} from '../utils/fonts';

export const AccountFrame: React.FC = () => {
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`,
        fontFamily: FONT_FAMILY,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* 메인 메시지 */}
      <div
        style={{
          fontSize: 56,
          fontWeight: 'bold',
          color: COLORS.TEXT,
          textAlign: 'center',
          marginBottom: 80,
        }}
      >
        팔로우하고 더 많은 퀴즈를 풀어보세요!
      </div>

      {/* 인스타그램 계정 */}
      <div
        style={{
          fontSize: 64,
          fontWeight: 'bold',
          color: COLORS.PRIMARY,
          textAlign: 'center',
        }}
      >
        @jlpt.everyday
      </div>
    </AbsoluteFill>
  );
};

