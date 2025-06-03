'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import ScatterLogo from "./ScatterLogo"
import { paths } from '@/paths';
import { DynamicLogo } from '@/components/core/logo';
import Typography from '@mui/material/Typography';

export interface LayoutProps {
  children: React.ReactNode;
}

export function Layout({ children }: LayoutProps): React.JSX.Element {
  return (
    <Box
      sx={{
        display: { xs: 'flex', lg: 'grid' },
        flexDirection: 'column',
        gridTemplateColumns: '1fr 1fr',
        minHeight: '100%',
      }}
    >
      <Box sx={{ display: 'flex', flex: '1 1 auto', flexDirection: 'column' }}>
        <Box sx={{ p: 3 }}>
          <Box component={RouterLink} href={paths.home} sx={{ display: 'inline-block', fontSize: 0 }}>
            <DynamicLogo colorDark="light" colorLight="dark" height={32} width={70} />
          </Box>
        </Box>
        <Box sx={{ alignItems: 'center', display: 'flex', flex: '1 1 auto', justifyContent: 'center', p: 3 }}>
          <Box sx={{ maxWidth: '450px', width: '100%' }}>{children}</Box>
        </Box>
      </Box>
        <Box
          sx={{
            display: { xs: 'none', lg: 'flex' },
            justifyContent: 'center',
            maxWidth: '450px',
            height: '100%',
            p: '3',
          }}
        >
          <Box sx={{ width: '100%', height: '100%', zIndex: -1}}>
            <ScatterLogo />
          </Box>
        </Box>
      
    </Box>
  );
}
