import os
import sys
import io

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    # Force UTF-8 for all file I/O and subprocesses on Windows
    os.environ.setdefault('PYTHONUTF8', '1')
    if hasattr(sys.stdout, 'reconfigure'):
        try:
            sys.stdout.reconfigure(encoding='utf-8', errors='replace')
            sys.stderr.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

import re
import shutil
import uuid
import asyncio

import yt_dlp
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

app = FastAPI()

DOWNLOAD_DIR = os.path.join(os.getcwd(), "downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

app.mount("/static", StaticFiles(directory="static"), name="static")

download_jobs = {}


class VideoURL(BaseModel):
    url: str


class DownloadRequest(BaseModel):
    url: str
    height: int   # e.g. 2160, 1080, 720 — 0 means audio-only
    is_audio: bool = False


def has_ffmpeg():
    return shutil.which("ffmpeg") is not None


@app.get("/")
async def read_index():
    return FileResponse('static/index.html')


@app.post("/info")
async def get_video_info(data: VideoURL):
    ydl_opts = {'quiet': True, 'no_warnings': True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(data.url, download=False)

        # Build a clean deduplicated list of available resolutions
        # For video: collect best format per height
        # For audio: single entry
        height_map = {}   # height -> best format entry
        has_audio_stream = False

        for f in info.get('formats', []):
            vcodec = f.get('vcodec', 'none')
            acodec = f.get('acodec', 'none')
            h = f.get('height') or 0
            filesize = f.get('filesize') or f.get('filesize_approx') or 0

            if vcodec != 'none' and h > 0:
                existing = height_map.get(h)
                if existing is None or filesize > (existing.get('filesize') or 0):
                    height_map[h] = {
                        'height': h,
                        'width': f.get('width') or 0,
                        'ext': 'mp4',
                        'filesize': filesize,
                        'vcodec': vcodec,
                        'acodec': acodec,
                    }
            if acodec != 'none' and vcodec == 'none':
                has_audio_stream = True

        # Sort heights descending
        video_formats = sorted(height_map.values(), key=lambda x: x['height'], reverse=True)

        result_formats = []
        for vf in video_formats:
            result_formats.append({
                'height': vf['height'],
                'resolution': f"{vf['width']}x{vf['height']}",
                'ext': vf['ext'],
                'filesize': vf['filesize'],
                'is_audio': False,
            })

        if has_audio_stream or video_formats:
            result_formats.append({
                'height': 0,
                'resolution': 'Audio Only',
                'ext': 'wav',
                'filesize': None,
                'is_audio': True,
            })

        return {
            'title': info.get('title'),
            'thumbnail': info.get('thumbnail'),
            'duration': info.get('duration'),
            'uploader': info.get('uploader'),
            'formats': result_formats,
            'ffmpeg': has_ffmpeg(),
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


def strip_ansi(text):
    if not text:
        return ""
    return re.compile(r'(?:\x1B[@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]').sub('', text)


def progress_hook(d, job_id):
    if d['status'] == 'downloading':
        p = strip_ansi(d.get('_percent_str', '0%')).replace('%', '').strip()
        speed = strip_ansi(d.get('_speed_str', 'N/A'))
        eta = strip_ansi(d.get('_eta_str', 'N/A'))
        try:
            download_jobs[job_id]['progress'] = float(p)
        except ValueError:
            pass
        download_jobs[job_id]['status'] = f'Downloading {p}% — {speed} — ETA {eta}'
    elif d['status'] == 'finished':
        download_jobs[job_id]['progress'] = 99
        download_jobs[job_id]['status'] = 'Merging streams...'


def run_download(job_id, url, height, is_audio):
    output_tmpl = os.path.join(DOWNLOAD_DIR, f"{job_id}_%(title).100s.%(ext)s")
    ffmpeg = has_ffmpeg()

    if is_audio:
        if ffmpeg:
            # Best audio → WAV via FFmpeg
            f_str = "bestaudio/best"
        else:
            f_str = "bestaudio/best"
    else:
        if ffmpeg:
            # Video-only stream at exact height + best audio merged by FFmpeg
            f_str = f"bestvideo[height={height}]+bestaudio/bestvideo[height<={height}]+bestaudio/best[height<={height}]/best"
        else:
            # No FFmpeg: best muxed stream at or below requested height
            f_str = f"best[height<={height}]/best"

    ydl_opts = {
        'format': f_str,
        'outtmpl': output_tmpl,
        'noplaylist': True,
        'progress_hooks': [lambda d: progress_hook(d, job_id)],
        'quiet': True,           # suppress yt-dlp stdout (avoids Windows charmap errors)
        'no_warnings': True,
        'merge_output_format': 'mp4',
        'encoding': 'utf-8',     # force utf-8 for yt-dlp internal output
    }

    if is_audio and ffmpeg:
        ydl_opts['postprocessors'] = [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
            'preferredquality': '0',
        }]

    print(f"[{job_id}] format='{f_str}' ffmpeg={ffmpeg} height={height} audio={is_audio}")

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.extract_info(url, download=True)

        for f in os.listdir(DOWNLOAD_DIR):
            if f.startswith(job_id):
                download_jobs[job_id]['file_id'] = f
                download_jobs[job_id]['status'] = 'complete'
                download_jobs[job_id]['progress'] = 100
                print(f"[{job_id}] Done: {f}")
                return

        raise Exception("File not found after download.")

    except Exception as e:
        import traceback
        err = strip_ansi(str(e))
        print(f"\n{'='*60}")
        print(f"[DOWNLOAD ERROR] job={job_id}")
        print(f"URL: {url}  height={height}  audio={is_audio}")
        print(f"format string: {f_str}")
        print(f"Error: {err}")
        traceback.print_exc()
        print('='*60 + '\n')
        download_jobs[job_id]['status'] = f'error: {err}'


@app.post("/download")
async def download_video(data: DownloadRequest):
    job_id = str(uuid.uuid4())
    download_jobs[job_id] = {'status': 'Preparing...', 'progress': 0, 'file_id': None}
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, run_download, job_id, data.url, data.height, data.is_audio)
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
    print("Access the app at: http://localhost:8080")
    uvicorn.run(app, host="0.0.0.0", port=8080)
