'use client';
import { styled, keyframes } from '@mui/material/styles';
import Typography from '@mui/material/Typography';

const flow = keyframes`
  0% {
    background-position: 0% 0%;
  }
  100% {
    background-position: 100% 0%;
  }
`;

const HighlightText = styled(Typography)(({ theme }) => ({
  background: theme.palette.text.highlight,
  backgroundSize: '200% 200%',
  backgroundClip: 'text',
  WebkitBackgroundClip: 'text',
  WebkitTextFillColor: 'transparent',
  animation: `${flow} 3s linear infinite alternate`,
}));

export default HighlightText;

export const slideInEllipticTopFwd = keyframes`
  0% {
    transform: translateY(-600px) rotateX(-30deg) scale(0);
    transform-origin: 50% 100%;
    opacity: 0;
  }
  100% {
    transform: translateY(0) rotateX(0) scale(1);
    transform-origin: 50% 1400px;
    opacity: 1;
  }
`;