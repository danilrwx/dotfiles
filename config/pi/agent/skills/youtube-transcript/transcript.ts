#!/usr/bin/env bun

import { YoutubeTranscript } from 'youtube-transcript-plus';

const videoInput = process.argv[2];

if (!videoInput) {
  console.error('Usage: transcript.ts <video-id-or-url>');
  console.error('Example: transcript.ts EBw7gsDPAYQ');
  console.error('Example: transcript.ts https://www.youtube.com/watch?v=EBw7gsDPAYQ');
  process.exit(1);
}

let extractedId = videoInput;
if (videoInput.includes('youtube.com') || videoInput.includes('youtu.be')) {
  const match = videoInput.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  if (match) {
    extractedId = match[1];
  }
}

try {
  const transcript = await YoutubeTranscript.fetchTranscript(extractedId);

  for (const entry of transcript) {
    const timestamp = formatTimestamp(entry.offset / 1000);
    console.log(`[${timestamp}] ${entry.text}`);
  }
} catch (error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  console.error('Error fetching transcript:', message);
  process.exit(1);
}

function formatTimestamp(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);

  if (h > 0) {
    return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  return `${m}:${s.toString().padStart(2, '0')}`;
}
