'use client';

import * as React from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Stack from '@mui/material/Stack';
import { useTheme } from '@mui/material/styles';
import type { SxProps } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import type { Icon } from '@phosphor-icons/react/dist/lib/types';
import { Desktop as DesktopIcon } from '@phosphor-icons/react/dist/ssr/Desktop';
import { DeviceTablet as DeviceTabletIcon } from '@phosphor-icons/react/dist/ssr/DeviceTablet';
import { Phone as PhoneIcon } from '@phosphor-icons/react/dist/ssr/Phone';
import type { ApexOptions } from 'apexcharts';

import { Chart } from '@/components/core/chart';

const iconMapping = { Desktop: DesktopIcon, Tablet: DeviceTabletIcon, Phone: PhoneIcon } as Record<string, Icon>;

export interface DataContributionsProps {
  chartSeries: number[];
  labels: string[];
  sx?: SxProps;
}

export function DataContributions({ chartSeries, labels, sx }: DataContributionsProps): React.JSX.Element {
  const chartOptions = useChartOptions(labels);

  return (
    <Card sx={sx}>
      <CardHeader title="Data Contributions" />
      <CardContent>
        <Stack spacing={2}>
          <Chart height={300} options={chartOptions} series={chartSeries} type="donut" width="100%" />
          <Stack direction="row" spacing={2} sx={{ alignItems: 'center', justifyContent: 'center' }}>
            {chartSeries.map((item, index) => {
              const label = labels[index];
              const Icon = iconMapping[label];

              return (
                <Stack key={label} spacing={1} sx={{ alignItems: 'center' }}>
                  {Icon ? <Icon fontSize="var(--icon-fontSize-lg)" /> : null}
                  <Typography variant="h6">{label}</Typography>
                  <Typography color="text.secondary" variant="subtitle2">
                    {item}%
                  </Typography>
                </Stack>
              );
            })}
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}

function generateSoftColors(n: number): string[] {
  const colors: string[] = [];
  for (let i = 0; i < n; i++) {
    const hue = Math.round((360 / n) * i);
    colors.push(`hsl(${hue}, 80%, 60%)`);
  }
  return colors;
}

function useChartOptions(labels: string[]): ApexOptions {
  const theme = useTheme();
  const colors = generateSoftColors(labels.length);

  return {
    chart: { background: 'transparent' },
    colors,
    dataLabels: {
      enabled: true,
  
    },
    labels,
    legend: {
      show: true,
      markers: { fillColors: colors },
      labels: { colors: Array(labels.length).fill(theme.palette.text.primary) }
    },
    plotOptions: {
      pie: { expandOnClick: false }
    },
    states: {
      active: { filter: { type: 'none' } },
      hover: { filter: { type: 'none' } }
    },
    stroke: { width: 0 },
    theme: { mode: theme.palette.mode },
    tooltip: { fillSeriesColor: false }
  };
}