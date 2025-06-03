'use client';

import * as React from 'react';
import CardContent from '@mui/material/CardContent';
import Stack from '@mui/material/Stack';
import type { SxProps } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import HighlightText, { slideInEllipticTopFwd } from './Animations';
import { Card } from '@mui/material';

export interface TrainingStatusProps {
  sx?: SxProps;
  value: number;
}

export function TrainingStatus({ value, sx }: TrainingStatusProps): React.JSX.Element {
  const hasValue = value;

  return (
    <Card sx={{
      animation: `${slideInEllipticTopFwd} 0.7s ease forwards`,
      ...sx,
    }}>
      <CardContent>
        <Stack spacing={2}>
          <Stack direction="row" sx={{ alignItems: 'flex-start', justifyContent: 'space-between' }} spacing={3}>
            <Stack spacing={3}>
              <Stack spacing={0}>
                <Typography color="text.secondary" gutterBottom variant="overline">
                  Training Status
                </Typography>
                <HighlightText
                  variant="h4"
                  sx={{ color: hasValue ? 'inherit' : 'gray' }}
                >
                  {hasValue ? 'Yes' : 'No'}
                </HighlightText>
              </Stack>
              <Stack sx={{ alignItems: 'center' }} direction="row" spacing={0}>
                <Typography
                  component="a"
                  variant="caption"
                  href="/dashboard/model_training"
                  sx={{
                    color: 'text.secondary',
                    textDecoration: 'none',
                    '&:hover': {
                      textDecoration: 'underline',
                      color: 'orange',
                      textDecorationColor: 'orange',
                    }
                  }}
                >
                  {hasValue ? '✔️ Click to upload' : '✖️ Click to start'}
                </Typography>
              </Stack>
            </Stack>
            <Box
              component="img"
              src={hasValue ? '/assets/shin-yes.gif' : '/assets/shin-no.gif'}
              alt={hasValue ? 'Shin Yes' : 'Shin No'}
              sx={{
                width: 80,
                height: 80,
                opacity: hasValue ? 1 : 0.5,
                transition: 'opacity 0.3s ease',
              }}
            />
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}
