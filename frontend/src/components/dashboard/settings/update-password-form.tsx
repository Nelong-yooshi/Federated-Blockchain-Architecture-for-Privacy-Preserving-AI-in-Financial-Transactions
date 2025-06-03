'use client';

import * as React from 'react';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Divider from '@mui/material/Divider';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import OutlinedInput from '@mui/material/OutlinedInput';
import Stack from '@mui/material/Stack';
import tilt_in_top from './Animation';

export function UpdatePasswordForm(): React.JSX.Element {
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
      }}
    >
      <Card sx={{ animation: `${tilt_in_top} 0.6s cubic-bezier(0.250, 0.460, 0.450, 0.940) both` }}>
        <CardHeader subheader="Update password" title="Password" />
        <Divider />
        <CardContent>
          <Stack spacing={3} sx={{ maxWidth: 'sm' }}>
            <FormControl fullWidth>
              <InputLabel>Password</InputLabel>
              <OutlinedInput label="Password" name="password" type="password" />
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Confirm password</InputLabel>
              <OutlinedInput label="Confirm password" name="confirmPassword" type="password" />
            </FormControl>
          </Stack>
        </CardContent>
        <Divider />
        <CardActions sx={{ justifyContent: 'flex-end' }}>
          <Button variant="contained">Update</Button>
        </CardActions>
      </Card>
    </form>
  );
}
