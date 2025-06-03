import * as React from 'react';
import type { Metadata } from 'next';
import Grid from '@mui/material/Unstable_Grid2';
import dayjs from 'dayjs';

import { config } from '@/config';
import { Acc } from '@/components/dashboard/overview/latest-model-acc';
import { LatestModel } from '@/components/dashboard/overview/latest-model';
import { TrainingContribution } from '@/components/dashboard/overview/training-contribution';
import { TrainingStatus } from '@/components/dashboard/overview/training-status';
import { CurrentModelEff } from '@/components/dashboard/overview/current-model-effi';
import { PeerStatus } from '@/components/dashboard/overview/peer-status';
import { DataContributions } from '@/components/dashboard/overview/data-contribution';

export const metadata = { title: `Overview @ ${config.site.name}` } satisfies Metadata;


export default function Page(): React.JSX.Element {
  const accStr = process.env.NEXT_PUBLIC_LATEST_MODEL_ACC;
  const accNum = accStr ? Number(accStr) : NaN;
  const accvalue = !isNaN(accNum) ? (accNum * 100).toString() : 'Unknown';

  const ratioStr = process.env.NEXT_PUBLIC_CURRENT_RATIO ?? '';
  const ratioNum = Number(ratioStr);
  const ratiovalue = process.env.NEXT_PUBLIC_CURRENT_NUMBER ?? 'Unknown'
  const ratiotrend = !isNaN(ratioNum) ? (ratioNum >= 1 ? 'up' : 'down') : 'down';
  const ratiodiff = !isNaN(ratioNum) ? Math.abs(1 - ratioNum) : 0;
  const usagesStr = process.env.NEXT_PUBLIC_PEER_DOCKER_USAGE ?? '';
  const usages = usagesStr
    .split(',')
    .map((v) => parseFloat(v))
    .filter((v) => !isNaN(v));
  const avg = usages.reduce((a, b) => a + b, 0) / usages.length;

  let statusText = 'Analyzing overall usage, the situation is not urgent.';
  if (avg >= 0.7) {
    statusText = 'Analyzing overall usage, the situation is critical!';
  } else if (avg >= 0.4) {
    statusText = 'Analyzing overall usage, the situation is somewhat concerning.';
  }
  const isTraining = process.env.NEXT_PUBLIC_IS_TRAINING == 'true';
  const circlrLabels = process.env.NEXT_PUBLIC_CATEGORIES?.split(',') ?? [];
  const circleRatios = process.env.NEXT_PUBLIC_DATA_CONTRIBUTION
    ? process.env.NEXT_PUBLIC_DATA_CONTRIBUTION.split(',').map(s => Number(s.trim())).filter(n => !isNaN(n))
    : [];
  return (
    <Grid container spacing={3}>
      <Grid lg={3} sm={6} xs={12}>
        <Acc diff={12} sx={{ height: '100%' }} value={accvalue} />
      </Grid>
      <Grid lg={3} sm={6} xs={12}>
        <CurrentModelEff diff={ratiodiff} trend={ratiotrend} sx={{ height: '100%' }} value={ratiovalue} />
      </Grid>
      <Grid lg={3} sm={6} xs={12}>
        <PeerStatus sx={{ height: '100%' }} values={usages} statusText={statusText}/>
      </Grid>
      <Grid lg={3} sm={6} xs={12}>
        <TrainingStatus sx={{ height: '100%' }} value={isTraining ? 1 : 0} />
      </Grid>
      <Grid lg={8} xs={12}>
        <TrainingContribution
          chartSeries={[
            { name: 'Contributions in the training', data: (process.env.NEXT_PUBLIC_TIMES ?? '')
              .split(',')
              .map(s => s.trim())
              .filter(Boolean)
              .map(Number) },
          ]}
          sx={{ height: '100%' }}
        />
      </Grid>
      <Grid lg={4} md={12} xs={12}>
        <DataContributions chartSeries={circleRatios} labels={circlrLabels} sx={{ height: '100%' }} />
      </Grid>
      <Grid lg={12} md={12} xs={12}>
        <LatestModel
          models={[
            {
              id: 'model-001',
              acc: 0.95,
              size: 120,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-05-01'),
              download_time: 150,
              download: 'https://example.com/download/model-001'
            },
            {
              id: 'model-002',
              acc: 0.89,
              size: 85,
              contributor: 'Org3',
              use: false,
              createdAt: new Date('2025-04-28'),
              download_time: 102,
              download: 'https://example.com/download/model-002'
            },
            {
              id: 'model-003',
              acc: 0.92,
              size: 98,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-04-30'),
              download_time: 75,
              download: 'https://example.com/download/model-003'
            },
            {
              id: 'model-004',
              acc: 0.88,
              size: 60,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-05-03'),
              download_time: 49,
              download: 'https://example.com/download/model-004'
            },
            {
              id: 'model-005',
              acc: 0.91,
              size: 140,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-05-02'),
              download_time: 164,
              download: 'https://example.com/download/model-005'
            },
            {
              id: 'model-006',
              acc: 0.85,
              size: 130,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-04-27'),
              download_time: 38,
              download: 'https://example.com/download/model-006'
            },
            {
              id: 'model-007',
              acc: 0.93,
              size: 150,
              contributor: 'Org3',
              use: false,
              createdAt: new Date('2025-04-29'),
              download_time: 111,
              download: 'https://example.com/download/model-007'
            },
            {
              id: 'model-008',
              acc: 0.90,
              size: 125,
              contributor: 'Org1',
              use: false,
              createdAt: new Date('2025-05-04'),
              download_time: 89,
              download: 'https://example.com/download/model-008'
            },
            {
              id: 'model-009',
              acc: 0.94,
              size: 100,
              contributor: 'Org3',
              use: false,
              createdAt: new Date('2025-05-05'),
              download_time: 134,
              download: 'https://example.com/download/model-009'
            },
            {
              id: 'model-010',
              acc: 0.87,
              size: 115,
              contributor: 'Org1',
              use: false,
              createdAt: new Date('2025-04-26'),
              download_time: 58,
              download: 'https://example.com/download/model-010'
            },
            {
              id: 'model-011',
              acc: 0.96,
              size: 135,
              contributor: 'Org3',
              use: false,
              createdAt: new Date('2025-05-06'),
              download_time: 177,
              download: 'https://example.com/download/model-011'
            },
            {
              id: 'model-012',
              acc: 0.84,
              size: 90,
              contributor: 'Org2',
              use: false,
              createdAt: new Date('2025-04-25'),
              download_time: 20,
              download: 'https://example.com/download/model-012'
            },
            {
              id: 'model-013',
              acc: 0.97,
              size: 160,
              contributor: 'Org1',
              use: false,
              createdAt: new Date('2025-05-07'),
              download_time: 202,
              download: 'https://example.com/download/model-013'
            },
            {
              id: 'model-014',
              acc: 0.86,
              size: 105,
              contributor: 'Org3',
              use: false,
              createdAt: new Date('2025-05-08'),
              download_time: 66,
              download: 'https://example.com/download/model-014'
            },
            {
              id: 'model-015',
              acc: 0.98,
              size: 170,
              contributor: 'Org3',
              use: true,
              createdAt: new Date('2025-05-12'),
              download_time: 220,
              download: 'https://gwcs-a.nemo00407.uk/get_model'
            }
          ]}
        />
      </Grid>
    </Grid>
  );
}
