import React from 'react';
import {AbsoluteFill, staticFile, Img} from 'remotion';
import {COLORS} from '../constants/colors';
import {WIDTH, HEIGHT} from '../constants/layout';
import {FONT_FAMILY} from '../utils/fonts';

export const AccountFrame: React.FC = () => {
  const imageSrc = staticFile('images/christmas-logo.png');
  const backgroundImage = staticFile('images/christmas-background.jpg');

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(to bottom, ${COLORS.BACKGROUND}, ${COLORS.ACCENT})`, // Fallback
        fontFamily: FONT_FAMILY,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* 배경 이미지 */}
      <Img
        src={backgroundImage}
        delayRenderTimeoutInMilliseconds={60000}
        style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          objectFit: 'cover',
        }}
      />
      {/* 어두운 오버레이 */}
      <AbsoluteFill
        style={{
          backgroundColor: 'rgba(0, 0, 0, 0.1)',
        }}
      />
      {/* 콘텐츠 영역 */}
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* 프로필 이미지 (크리스마스 로고) */}
        <Img
          src={imageSrc}
          style={{
            width: 300,
            height: 300,
            borderRadius: '50%',
            objectFit: 'cover',
            marginBottom: 60,
            border: `4px solid ${COLORS.PRIMARY}`,
          }}
        />

        {/* 메인 메시지 */}
        <div
          style={{
            fontSize: 56,
            fontWeight: 'bold',
            color: COLORS.TEXT,
            textAlign: 'center',
            marginBottom: 40,
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
    </AbsoluteFill>
  );
};

