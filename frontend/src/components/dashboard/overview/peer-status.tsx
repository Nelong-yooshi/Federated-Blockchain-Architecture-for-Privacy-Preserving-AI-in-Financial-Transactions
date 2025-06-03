'use client';

import * as React from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Stack from '@mui/material/Stack';
import type { SxProps } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import { slideInEllipticTopFwd } from './Animations';

export interface PeerStatusProps {
  values: number[];
  statusText: string;
  sx?: SxProps;
}

export function PeerStatus({ values, statusText, sx }: PeerStatusProps): React.JSX.Element {
  const getColor = (ratio: number) => {
    if (ratio >= 0.7) return '#e74c3c'; // 紅色
    if (ratio >= 0.4) return '#f1c40f'; // 黃色
    return '#2ecc71'; // 綠色
  };

  return (
    <Card
      sx={{
        animation: `${slideInEllipticTopFwd} 0.7s ease forwards`,
        ...sx,
      }}
    >
      <CardContent>
        <Stack spacing={3}>
          <Stack direction="row" sx={{ alignItems: 'flex-start', justifyContent: 'space-between' }} spacing={3}>
            <Stack spacing={1}>
              <Typography color="text.secondary" variant="overline">
                Docker Usage Status
              </Typography>
              <Stack direction="row" spacing={2}>
                {values.map((ratio, i) => (
                  <Stack
                    key={i}
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: '50%',
                      backgroundColor: getColor(ratio),
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#fff',
                      fontWeight: 'bold',
                      userSelect: 'none',
                    }}
                  >
                    {Math.round(ratio * 100)}%
                  </Stack>
                ))}
              </Stack>
            </Stack>
          </Stack>

          <Stack sx={{ alignItems: 'center' }} direction="row" spacing={0}>
            <Typography color="text.secondary" variant="caption">
              {statusText}
            </Typography>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}
