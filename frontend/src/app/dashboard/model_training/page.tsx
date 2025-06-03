import * as React from 'react';
import type { Metadata } from 'next';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { config } from '@/config';
import ModelTraining from '@/components/dashboard/model_training/model-training';

export const metadata = { title: `Model Training @ ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (
    <Stack spacing={3}>

      <ModelTraining/>
    </Stack>
  );
}
