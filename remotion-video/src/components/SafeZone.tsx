import React from 'react';
import {AbsoluteFill} from 'remotion';
import {SAFE_ZONE_TOP, SAFE_ZONE_BOTTOM, SAFE_ZONE_LEFT, SAFE_ZONE_RIGHT} from '../constants/layout';

interface SafeZoneProps {
  children: React.ReactNode;
}

export const SafeZone: React.FC<SafeZoneProps> = ({children}) => {
  return (
    <AbsoluteFill
      style={{
        paddingTop: SAFE_ZONE_TOP,
        paddingBottom: SAFE_ZONE_BOTTOM,
        paddingLeft: SAFE_ZONE_LEFT,
        paddingRight: SAFE_ZONE_RIGHT,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

