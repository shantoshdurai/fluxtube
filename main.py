import os
import sys
import io

# Force UTF-8 stdout/stderr on Windows to prevent charmap encode errors
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import yt_dlp
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import asyncio
import uuid
import shutil

app = FastAPI()

# Configuration
DOWNLOAD_DIR = os.path.join(os.getcwd(), "downloads")
if not os.path.exists(DOWNLOAD_DIR):
    os.makedirs(DOWNLOAD_DIR)

app.mount("/static", StaticFiles(directory="static"), name="static")

# Global state to track progress
download_jobs = {}

class VideoURL(BaseModel):
    url: str

class DownloadRequest(BaseModel):
    url: str
    format_id: str
    ext: str

@app.get("/")
async def read_index():
    return FileResponse('static/index.html')

@app.post("/info")
async def get_video_info(data: VideoURL):
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(data.url, download=False)
            
            formats = []
            for f in info.get('formats', []):
                if f.get('vcodec') != 'none' or f.get('acodec') != 'none':
                    formats.append({
                        'format_id': f.get('format_id'),
                        'ext': f.get('ext'),
                        'resolution': f.get('resolution') or f.get('format_note'),
                        'filesize': f.get('filesize'),
                        'vcodec': f.get('vcodec'),
                        'acodec': f.get('acodec'),
                    })
            
            return {
                'title': info.get('title'),
                'thumbnail': info.get('thumbnail'),
                'duration': info.get('duration'),
                'uploader': info.get('uploader'),
                'formats': formats[::-1]
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

import re

def strip_ansi(text):
    if not text: return ""
    # More comprehensive ANSI cleaning
    ansi_escape = re.compile(r'(?:\x1B[@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)

def progress_hook(d, job_id):
    if d['status'] == 'downloading':
        p = strip_ansi(d.get('_percent_str', '0%')).replace('%', '').strip()
        speed = strip_ansi(d.get('_speed_str', 'N/A'))
        eta = strip_ansi(d.get('_eta_str', 'N/A'))
        download_jobs[job_id]['progress'] = p
        download_jobs[job_id]['status'] = f'Downloading: {p}% | Speed: {speed} | ETA: {eta}'
    elif d['status'] == 'finished':
        download_jobs[job_id]['progress'] = '100'
        download_jobs[job_id]['status'] = 'Processing...'

def run_download(job_id, url, format_id, ext):
    # Ensure job_id is clean
    output_tmpl = os.path.join(DOWNLOAD_DIR, f"{job_id}_%(title).100s.%(ext)s")
    
    import shutil
    has_ffmpeg = shutil.which("ffmpeg") is not None
    print(f"[{job_id}] Start. URL: {url}, FFmpeg: {has_ffmpeg}, RequestFormat: {format_id}")
    
    # Selection logic
    if has_ffmpeg:
        # Best video of requested resolution + best audio
        if format_id.isdigit():
            # If it's a specific format id, we try to merge it with best audio
            f_str = f"{format_id}+bestaudio/best"
        else:
            # Fallback to general best
            f_str = "bestvideo+bestaudio/best"
    else:
        # No ffmpeg: must find a single file with both v+a
        # Format 18 (360p) and 22 (720p) are common muxed ones.
        # "best" usually finds the best muxed file (up to 720p).
        f_str = "best"
        if "mp3" in format_id.lower() or ext == "mp3":
            f_str = "bestaudio/best"

    ydl_opts = {
        'format': f_str,
        'outtmpl': output_tmpl,
        'noplaylist': True,
        'progress_hooks': [lambda d: progress_hook(d, job_id)],
        'quiet': False,
        'no_warnings': False,
    }

    # Add postprocessor for audio extraction (WAV for Premiere Pro compatibility)
    if ("mp3" in format_id.lower() or ext == "mp3") and has_ffmpeg:
        ydl_opts['postprocessors'] = [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',  # WAV format for Premiere Pro compatibility
            'preferredquality': '0',   # 0 means best quality (lossless for WAV)
        }]

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            print(f"[{job_id}] Calling extract_info with format: {f_str}")
            info = ydl.extract_info(url, download=True)
            
            # Find the actual file
            # yt-dlp might have changed the extension during merge/post-process
            for f in os.listdir(DOWNLOAD_DIR):
                if f.startswith(job_id):
                    download_jobs[job_id]['file_id'] = f
                    download_jobs[job_id]['status'] = 'complete'
                    print(f"[{job_id}] Success: {f}")
                    return
            
            raise Exception("File was downloaded but could not be located on disk.")
            
    except Exception as e:
        err_msg = strip_ansi(str(e))
        print(f"[{job_id}] ERROR: {err_msg}")
        download_jobs[job_id]['status'] = f'error: {err_msg}'

@app.post("/download")
async def download_video(data: DownloadRequest):
    job_id = str(uuid.uuid4())
    download_jobs[job_id] = {'status': 'Preparing...', 'progress': '0', 'file_id': None}
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, run_download, job_id, data.url, data.format_id, data.ext)
    return {"job_id": job_id}

@app.get("/progress/{job_id}")
async def get_progress(job_id: str):
    if job_id not in download_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return download_jobs[job_id]

@app.get("/get-file/{file_id}")
async def get_file(file_id: str):
    file_path = os.path.join(DOWNLOAD_DIR, file_id)
    if os.path.exists(file_path):
        return FileResponse(file_path, filename=file_id.split('_', 1)[-1])
    raise HTTPException(status_code=404, detail="File not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
