'use client';

import * as React from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Stack from '@mui/material/Stack';
import type { SxProps } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import HighlightText, { slideInEllipticTopFwd } from './Animations';

export interface AccProps {
  diff?: number;
  sx?: SxProps;
  value: string;
}

export function Acc({ diff, sx, value }: AccProps): React.JSX.Element {
  return (
    <Card sx={{
        animation: `${slideInEllipticTopFwd} 0.7s ease forwards`,
        ...sx,
      }}>
      <CardContent>
        <Stack spacing={3}>
          <Stack direction="row" sx={{ alignItems: 'flex-start', justifyContent: 'space-between' }} spacing={3}>
            <Stack spacing={1}>
              <Typography color="text.secondary" variant="overline">
                Latest Model Accuracy
              </Typography>
              <HighlightText variant="h4">
                {value}%
              </HighlightText>
            </Stack>
          </Stack>
          {diff ? (
            <Stack sx={{ alignItems: 'center' }} direction="row" spacing={0}>
              <Typography color="text.secondary" variant="caption">
                Training date:&nbsp;
              </Typography>
              <Typography color="text.secondary" variant="caption">
                {process.env.NEXT_PUBLIC_LATEST_MODEL_DATE || 'Unknown'}
              </Typography>
            </Stack>
          ) : null}
        </Stack>
      </CardContent>
    </Card>
  );
}
