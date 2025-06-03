import React, { useEffect, useRef } from "react";
import * as THREE from "three";
import FOG from "vanta/dist/vanta.fog.min";

export default function VantaFogBackground() {
  const vantaRef = useRef(null);
  const vantaEffect = useRef<any>(null);

  useEffect(() => {
    if (!vantaEffect.current && vantaRef.current) {
      vantaEffect.current = FOG({
        el: vantaRef.current,
        THREE,
        mouseControls: true,
        touchControls: true,
        gyroControls: false,
        minHeight: 400,
        minWidth: 400,
        backgroundColor: 0x00000000, // 透明背景
      });
    }
    return () => {
      if (vantaEffect.current) {
        vantaEffect.current.destroy();
        vantaEffect.current = null;
      }
    };
  }, []);

  return (
    <div
      ref={vantaRef}
      style={{
        width: "100vw",
        height: "100vh",
        maxWidth: 1200,
        maxHeight: 800,
        margin: "auto",
        overflow: "hidden",
      }}
    />
  );
}