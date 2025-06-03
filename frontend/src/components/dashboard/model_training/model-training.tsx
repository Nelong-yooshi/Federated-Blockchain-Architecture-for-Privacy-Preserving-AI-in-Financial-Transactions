'use client';

import React, { useState } from 'react';
import Card from '@mui/material/Card';
import CardHeader from '@mui/material/CardHeader';
import CardContent from '@mui/material/CardContent';
import Divider from '@mui/material/Divider';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import UploadFileIcon from '@mui/icons-material/UploadFile';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Fade from '@mui/material/Fade';
import CircularProgress from '@mui/material/CircularProgress';
import { IconButton, Tooltip } from '@mui/material';
import { Question as HelpCircleIcon } from '@phosphor-icons/react';
import HighlightText from './../overview/Animations';
import bounceInTop from './Animation';

export default function ModelTraining() {
  const [file, setFile] = useState<File | null>(null);
  const [isTrainingStarted, setIsTrainingStarted] = useState(false);
  const [trainingInProgress, setTrainingInProgress] = useState(false);

  const handleFileInput = (incomingFile: File | null) => {
    if (!incomingFile) return;
    if (!incomingFile.name.endsWith('.csv')) {
      alert('Please upload a .csv file');
      return;
    }
    setFile(incomingFile);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0] || null;
    handleFileInput(selectedFile);
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const droppedFile = e.dataTransfer.files?.[0] || null;
    handleFileInput(droppedFile);
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  const handleConfirmUpload = () => {
    if (!file) {
      alert('No file selected.');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result;
      if (typeof text !== 'string' || text.trim() === '') {
        alert('File is empty or unreadable.');
        return;
      }

      const lines = text.split('\n').filter(line => line.trim() !== '');
      if (lines.length === 0) {
        alert('CSV file is empty or malformed.');
        return;
      }

      const headers = lines[0].split(',').map(h => h.trim());
      const json = lines.slice(1).map(line => {
        const values = line.split(',');
        const entry = {} as Record<string, string>;
        headers.forEach((header, index) => {
          entry[header] = values[index]?.trim() || '';
        });
        return entry;
      });

      const uploadPayload = { data: json };
      alert(JSON.stringify(uploadPayload)); // For debugging, remove in production
      fetch('http://gwcs-a.nemo00407.uk/upload_data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(uploadPayload),
      })
        .then(res => {
          if (!res.ok) throw new Error('Network response was not ok');
          return res.json();
        })
        .then(data => {
          console.log('Uploaded to server:', data);
          alert('Upload successful!');
        })
        .catch(err => {
          console.error('Upload error:', err);
          alert('Upload failed');
        });
    };
    reader.readAsText(file);
  };

  const startTraining = async () => {
    setTrainingInProgress(true);
    if (!isTrainingStarted) {
      try {
        const res = await fetch('/api/update-env?url=https://gwcs-a.nemo00407.uk/start_upload', { method: 'GET' })
        const data = await res.json()
        console.log('GET Response:', data)
      } catch (err) {
        console.error('GET 發送失敗', err)
      } finally {
        // setTrainingInProgress(false)
      }

      setIsTrainingStarted(true);
      // Simulate loading effect
      setTimeout(() => {
        setTrainingInProgress(false);
      }, 2000);
    }
    else {
      try {
        const res = await fetch('/api/update-env?url=https://gwcs-a.nemo00407.uk/end_upload', { method: 'GET' })
        const data = await res.json()
        console.log('GET Response:', data)
      } catch (err) {
        console.error('GET 發送失敗', err)
      } finally {
        setIsTrainingStarted(false);
      }

    }
  };

  return (
    <Box sx={{ p: 4 }}>
      <HighlightText variant="h4" sx={{ mb: 2 }}>
        Model Training
      </HighlightText>

      <Grid container spacing={4}>
        {/* Upload Card */}
        <Grid item xs={12} md={6}>
          <Card
            variant="outlined"
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            sx={{
              height: '100%',
              p: 2,
              border: '2px dashed #ccc',
              '&:hover': { borderColor: 'primary.main' },
              transition: 'border-color 0.3s ease',
              animation: `${bounceInTop} 0.6s ease-out both`
            }}
          >
            <CardHeader title="Upload" subheader="Drag & drop or select a file" />
            <Divider />
            <CardContent sx={{ textAlign: 'center' }}>
              <UploadFileIcon color="action" sx={{ fontSize: 40, mb: 1 }} />
              <Typography variant="body2" color="textSecondary">
                Drag and drop a file here, or
              </Typography>
              <input type="file" id="fileInput" style={{ display: 'none' }} onChange={handleFileChange} />
              <label htmlFor="fileInput">
                <Button variant="outlined" component="span" sx={{ mt: 1 }}>
                  Browse Files
                </Button>
              </label>
              <Fade in={Boolean(file)}>
                <Box>
                  <Typography variant="body2" sx={{ mt: 2 }} color="success.main">
                    Selected file: {file?.name}
                  </Typography>
                  <Button variant="contained" color="primary" sx={{ mt: 1 }} onClick={handleConfirmUpload}>
                    Confirm Upload
                  </Button>
                </Box>
              </Fade>
            </CardContent>
          </Card>
        </Grid>

        {/* Training Card */}
        <Grid item xs={12} md={6}>
          <Card variant="outlined" 
            sx={{ p: 2, 
                  height: '100%',
                  animation: `${bounceInTop} 0.6s ease-out both`
            }
            }>
            <CardHeader title="Training" subheader="Start a new training session" />
            <Divider />
            <CardContent>
              {trainingInProgress ? (
                <Fade in={true}>
                  <Box textAlign="center">
                    <Typography variant="body2" color="textSecondary" mb={2}>
                      Training has already been started by another user.
                    </Typography>
                    <CircularProgress />
                  </Box>
                </Fade>
              ) : (
                <Fade in={true}>
                  <Box textAlign="center">
                    <Typography variant="body2" color="textSecondary" mb={2}>
                      No active training sessions. You can start one now.
                    </Typography>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={startTraining}
                      disabled={trainingInProgress}
                    >
                      {trainingInProgress ? 'Starting...' : isTrainingStarted ? 'End Training' : 'Start Training'}
                    </Button>
                  </Box>
                </Fade>
              )}
              <Box textAlign="center" mt={2}>
                <img
                  src={isTrainingStarted ? '/assets/shin_end.gif' : '/assets/shin_start.gif'}
                  alt="Training status"
                  style={{ width: '120px'}}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}