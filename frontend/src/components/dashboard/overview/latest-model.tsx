'use client';

import * as React from 'react';
import {
  Box, Button, Card, CardActions, CardHeader, Divider,
  IconButton, Radio, Table, TableBody, TableCell, TableHead, TableRow,
  Tooltip, Typography
} from '@mui/material';
import { ArrowRight as ArrowRightIcon, DownloadSimple, Question as HelpCircleIcon } from '@phosphor-icons/react';
import dayjs from 'dayjs';
import HighlightText from './Animations';

export interface Model {
  id: string;
  acc: number;
  size: number;
  contributor: string;
  use: boolean;
  createdAt: Date;
  download_time: number;
  download: string;
}

export interface LatestModelProps {
  models?: Model[];
  pageSize?: number;
}

const handleDownload = async (e: React.MouseEvent) => {
    e.preventDefault() // 阻止 a 標籤預設行為

    try {
      const res = await fetch('https://gwcs-a.nemo00407.uk/get_model')
      if (!res.ok) throw new Error('網路錯誤')

      const data = await res.json()

      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
      const downloadUrl = URL.createObjectURL(blob)

      const a = document.createElement('a')
      a.href = downloadUrl
      a.download = 'data.json' // 可改成動態檔名
      document.body.appendChild(a)
      a.click()
      a.remove()

      URL.revokeObjectURL(downloadUrl)
    } catch (error) {
      console.error('下載失敗', error)
    }
  }

export function LatestModel({ models = [], pageSize = 5 }: LatestModelProps): React.JSX.Element {
  const [sortBy, setSortBy] = React.useState<'date' | 'download' | 'accuracy'>('date');
  const [page, setPage] = React.useState(0);
  const [selectedModelId, setSelectedModelId] = React.useState(
    models.find((o) => o.use)?.id ?? null
  );
  const [pendingModelId, setPendingModelId] = React.useState<string | null>(null);

  const sortedModels = [...models].sort((a, b) => {
    if (sortBy === 'date') {
      return b.createdAt.getTime() - a.createdAt.getTime();
    }
    else if (sortBy === 'accuracy') {
      return b.acc - a.acc;
    }
    return b.download_time - a.download_time;
  });

  const pagedModels = sortedModels.slice(page * pageSize, (page + 1) * pageSize);

  return (
    <Card>
      <CardHeader
        title="Latest Models"
        action={
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant={sortBy === 'date' ? 'contained' : 'outlined'}
              onClick={() => setSortBy('date')}
            >
              Sort by Date
            </Button>
            <Button
              variant={sortBy === 'download' ? 'contained' : 'outlined'}
              onClick={() => setSortBy('download')}
            >
              Sort by Downloads
            </Button>
            <Button
              variant={sortBy === 'accuracy' ? 'contained' : 'outlined'}
              onClick={() => setSortBy('accuracy')}
            >
              Sort by Accuracy
            </Button>
          </Box>
        }
      />
      <Divider />
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: 800 }}>
          <TableHead>
            <TableRow>
              <TableCell align="center">Model ID</TableCell>
              <TableCell align="center">Accuracy</TableCell>
              <TableCell align="center">Date</TableCell>
              <TableCell align="center">Data Size</TableCell>
              <TableCell align="center">Contributor</TableCell>
              <TableCell align="center">
                Use
                <Tooltip title="This model would be used into timely judgment. Only one model can be used at a time." arrow>
                  <IconButton>
                    <HelpCircleIcon size={18} />
                  </IconButton>
                </Tooltip>
              </TableCell>
              <TableCell align="center">Download #</TableCell>
              <TableCell align="center">Download</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {pagedModels.map((order) => (
              <TableRow hover key={order.id}>
                <TableCell align="center">{order.id}</TableCell>
                <TableCell align="center">{order.acc}</TableCell>
                <TableCell align="center">{dayjs(order.createdAt).format('MMM D, YYYY')}</TableCell>
                <TableCell align="center">{order.size}</TableCell>
                <TableCell align="center">{order.contributor}</TableCell>
                <TableCell align="center">
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Radio
                      checked={selectedModelId === order.id}
                      onChange={() => setPendingModelId(order.id)}
                    />
                  </Box>
                </TableCell>
                <TableCell align="center">{order.download_time}</TableCell>
                <TableCell align="center">
                  <IconButton
                    href={order.download}
                    target="_blank"
                    rel="noopener noreferrer"
                    aria-label="Download"
                    onClick={handleDownload}
                  >
                    <DownloadSimple size={20} />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Box>

      {pendingModelId && pendingModelId !== selectedModelId && (
        <Box sx={{ px: 2, py: 1, display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={() => {
              setSelectedModelId(pendingModelId);
              setPendingModelId(null);
            }}
          >
            Confirm Change to {pendingModelId}
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            onClick={() => setPendingModelId(null)}
          >
            Cancel
          </Button>
        </Box>
      )}

      <Divider />
      <CardActions sx={{ justifyContent: 'space-between' }}>
        <HighlightText variant="h4">
            <Typography variant="body2">&nbsp;&nbsp;&nbsp;Page {page + 1}</Typography>
        </HighlightText>
        <Box>
          <Button
            onClick={() => setPage((p) => Math.max(p - 1, 0))}
            disabled={page === 0}
          >
            Previous
          </Button>
          <Button
            onClick={() =>
              setPage((p) =>
                (p + 1) * pageSize < sortedModels.length ? p + 1 : p
              )
            }
            disabled={(page + 1) * pageSize >= sortedModels.length}
            endIcon={<ArrowRightIcon />}
          >
            Next Page
          </Button>
        </Box>
      </CardActions>
    </Card>
  );
}
