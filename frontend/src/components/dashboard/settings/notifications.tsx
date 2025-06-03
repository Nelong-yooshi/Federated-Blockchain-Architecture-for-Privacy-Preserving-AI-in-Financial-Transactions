'use client';

import * as React from 'react';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Checkbox from '@mui/material/Checkbox';
import Divider from '@mui/material/Divider';
import FormControlLabel from '@mui/material/FormControlLabel';
import tilt_in_top from './Animation';

export function Notifications(): React.JSX.Element {
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
      }}
    >
      <Card square sx={{ animation: `${tilt_in_top} 0.6s cubic-bezier(0.250, 0.460, 0.450, 0.940) both` }}>
        <CardHeader subheader="Manage the notifications" title="Notifications" />
        <Divider />
        <CardContent>
          <FormControlLabel control={<Checkbox defaultChecked />} label="Subscribe Email to get more timely informations." />
        </CardContent>
        <Divider />
        <CardActions sx={{ justifyContent: 'flex-end' }}>
          <Button variant="contained">Save changes</Button>
        </CardActions>
      </Card>
    </form>
  );
}
