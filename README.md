# FluxTube

<div align="center">

```
███████╗██╗     ██╗   ██╗██╗  ██╗████████╗██╗   ██╗██████╗ ███████╗
██╔════╝██║     ██║   ██║╚██╗██╔╝╚══██╔══╝██║   ██║██╔══██╗██╔════╝
█████╗  ██║     ██║   ██║ ╚███╔╝    ██║   ██║   ██║██████╔╝█████╗  
██╔══╝  ██║     ██║   ██║ ██╔██╗    ██║   ██║   ██║██╔══██╗██╔══╝  
██║     ███████╗╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝██████╔╝███████╗
╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝
```

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![yt-dlp](https://img.shields.io/badge/yt--dlp-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://github.com/yt-dlp/yt-dlp)
[![License](https://img.shields.io/badge/License-MIT-blueviolet?style=for-the-badge)](LICENSE)

</div>

A clean, fast YouTube downloader with a glassmorphic UI. Paste a link, pick a format, get your file.

![FluxTube](image.png)

---

## Stack

- **FastAPI** — async backend
- **yt-dlp** — YouTube extraction
- **FFmpeg** — video/audio merging (optional)
- **Vanilla JS** — no framework bloat

---

## Run Locally

```bash
git clone https://github.com/shantoshdurai/fluxtube.git
cd fluxtube
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Open `http://localhost:8080`

---

## Notes

- Without FFmpeg, downloads are limited to 720p muxed formats
- With FFmpeg, full quality merging up to 4K if available
- Audio downloads are saved as WAV for Premiere Pro compatibility

---

## License

MIT
