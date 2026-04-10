# 🌊 FluxTube

<div align="center">

```ascii
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ███████╗██╗     ██╗   ██╗██╗  ██╗████████╗██╗   ██╗██████╗ ███████╗  ║
║   ██╔════╝██║     ██║   ██║╚██╗██╔╝╚══██╔══╝██║   ██║██╔══██╗██╔════╝  ║
║   █████╗  ██║     ██║   ██║ ╚███╔╝    ██║   ██║   ██║██████╔╝█████╗    ║
║   ██╔══╝  ██║     ██║   ██║ ██╔██╗    ██║   ██║   ██║██╔══██╗██╔══╝    ║
║   ██║     ███████╗╚██████╔╝██╔╝ ██╗   ██║   ╚██████╔╝██████╔╝███████╗  ║
║   ╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

**Where content liberation meets digital artistry** ✨

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![yt-dlp](https://img.shields.io/badge/yt--dlp-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://github.com/yt-dlp/yt-dlp)
[![License](https://img.shields.io/badge/License-MIT-blueviolet?style=for-the-badge)](LICENSE)

> [!NOTE]
> 📝 **Documentation Notice**: This README was crafted with AI assistance to help explain the project clearly and creatively. The code, however, is human-written and thoroughly tested. Transparency matters! 🤖✨

[🚀 Quick Start](#-quick-start) •
[✨ Features](#-features) •
[🎨 Screenshots](#-what-it-looks-like) •
[🛠️ Installation](#️-installation) •
[💫 Usage](#-usage)

</div>

---

## 🌊 The Philosophy

> *In a world drowning in paywalls and platform lock-ins, **FluxTube** emerges as a breath of digital freedom.*

This isn't just another YouTube downloader. It's an **experience** — a seamless blend of raw power and elegant design. Think of it as the rebellious artist who refuses to color inside the lines, yet somehow creates a masterpiece every time.

**This is not a tool. This is digital liberation with a premium aesthetic.**

---

## ✨ Features

### 🎭 **The Core Experience**

```
🎬  Video Downloads     →  Up to 4K/8K quality, because pixels matter
🎵  Audio Extraction    →  Pristine WAV format (Adobe Premiere Pro ready)
⚡  Real-time Progress  →  Watch the magic unfold, byte by byte
🎨  Premium UI          →  Glassmorphic design that makes you *feel* rich
🚀  Lightning Fast      →  Async architecture because life's too short
📱  Format Selection    →  You choose, it delivers — no compromises
```

### 🔮 **The Magic Behind the Curtain**

- **Smart Format Detection**: Automatically detects available qualities and codecs
- **FFmpeg Integration**: Seamlessly merges video + audio streams for premium quality
- **Progress Streaming**: Live download stats with speed, ETA, and completion percentage
- **Background Processing**: Download multiple files while sipping coffee ☕
- **Automatic Cleanup**: ANSI escape sequences vanished like they were never there
- **Error Resilience**: Graceful failure handling that actually makes sense

---

## 🎨 What It Looks Like

![FluxTube Screenshot](image.png)

Imagine **dark mode** had a baby with **neon dreams** and **minimalist sophistication**:

```css
/* The visual poetry */
🌌 Deep dark backgrounds with subtle gradients
✨ Glassmorphic cards that float on your screen
🎯 Vibrant accent colors that pop without being obnoxious
🔮 Smooth animations that respect your time
💎 Premium typography (Outfit font) because Comic Sans is a crime
```

**TL;DR**: It looks like money, but it's free. 💰

---

## 🛠️ Installation

### Prerequisites

Before you embark on this journey, make sure you have:

- **Python 3.8+** (because it's 2026, not 2015)
- **FFmpeg** (the Swiss Army knife of media processing)
  ```bash
  # Windows (PowerShell as Admin):
  choco install ffmpeg
  
  # macOS:
  brew install ffmpeg
  
  # Linux:
  sudo apt install ffmpeg
  ```

### 🚀 Quick Start

#### Option 1: The Lazy Genius Way (Windows)

```powershell
# Just double-click this bad boy:
launch_yt_downloader.bat
```

**What it does:**
- Creates a virtual environment
- Installs dependencies
- Launches the server
- Opens your browser automatically
- Makes your day better

#### Option 2: The Manual Artist Way

```bash
# Clone this beauty
git clone https://github.com/shantoshdurai/fluxtube.git
cd fluxtube

# Create a virtual sanctuary
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

# Install the magic ingredients
pip install -r requirements.txt

# Summon the application
python main.py
```

🎉 **Boom!** Visit `http://localhost:8080` and witness greatness.

---

## 💫 Usage

### The Three-Step Dance

1. **Paste** → Drop that YouTube URL like it's hot 🔥
2. **Extract** → Watch as the app analyzes that video into oblivion 🔍
3. **Download** → Choose your format and claim your prize 🏆

### Example Use Cases

```
📹 Content Creators  →  Archive your work offline
🎓 Students          →  Educational content on-the-go
🎵 Music Lovers      →  Build your offline library
🎬 Film Enthusiasts  →  Collect references in pristine quality
```

---

## 📂 Project Structure

```
fluxtube/
│
├── 🎯 main.py                      # FastAPI backend sorcery
├── 📦 requirements.txt             # Dependencies of destiny
├── 🚀 launch_yt_downloader.bat    # One-click magic (Windows)
├── ⚡ quick_launch.bat             # Speed demon version
│
├── static/                         # Frontend artistry
│   ├── 🎨 index.html              # Semantic HTML poetry
│   ├── 💅 style.css               # Visual orchestration
│   └── ⚙️  script.js              # Client-side wizardry
│
└── downloads/                      # Your treasure chest
    └── (videos and audio appear here)
```

---

## 🔧 Tech Stack

Built with ingredients that would make Gordon Ramsay proud:

| Layer          | Technology        | Why                                    |
|----------------|-------------------|----------------------------------------|
| 🎯 Backend     | **FastAPI**       | Async native, faster than your ex      |
| 📦 Downloader  | **yt-dlp**        | Fork of youtube-dl that actually works |
| 🎬 Processing  | **FFmpeg**        | If it can't do it, it can't be done    |
| 🎨 Frontend    | **Vanilla JS**    | No bloat, just elegance                |
| 💅 Styling     | **CSS3**          | Glassmorphism & gradients galore       |
| 🔤 Fonts       | **Outfit**        | Google Fonts' finest export            |

---

## 🎯 API Endpoints

For the developers who like to tinker:

### `POST /info`
Extract video metadata
```json
{
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ"
}
```

### `POST /download`
Initiate download with format selection
```json
{
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "format_id": "137",
  "ext": "mp4"
}
```

### `GET /progress/{job_id}`
Track download progress in real-time

### `GET /get-file/{file_id}`
Retrieve your downloaded masterpiece

---

## 🎭 Philosophy & Design Decisions

### Why WAV for Audio?
Because when you're importing into **Adobe Premiere Pro**, you don't want compression artifacts. Quality over file size, always.

### Why FastAPI?
Async/await is not just syntax — it's a lifestyle. Non-blocking I/O like coffee: essential for productivity.

### Why Glassmorphism?
Flat design is so 2018. This embraces the future with depth, blur, and transparency. It's like looking through frosted glass at digital dreams.

---

## 🐛 Known Quirks

- **Without FFmpeg**: You're limited to pre-merged formats (usually maxes out at 720p)
  - *Solution*: Install FFmpeg. It's 2026, you should have it anyway.
  
- **Large Files**: Downloads might take time for 4K/8K content
  - *Reality Check*: Physics exists. Good things take time.

---

## 🤝 Contributing

Found a bug? Have an idea? Want to make this even more beautiful?

1. Fork this repo 🍴
2. Create your feature branch (`git checkout -b feature/AmazingIdea`)
3. Commit your changes (`git commit -m 'Add some AmazingIdea'`)
4. Push to the branch (`git push origin feature/AmazingIdea`)
5. Open a Pull Request 🎉

**Code Style**: Write code like you're crafting poetry. Readable, elegant, purposeful.

---

## 📜 License

This project is licensed under the **MIT License** — because information wants to be free.

See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **yt-dlp** team for maintaining the best YouTube downloader on the planet
- **FastAPI** for making async Python feel like butter
- **FFmpeg** for being the unsung hero of media processing
- **You** for reading this far. You're awesome. 💜

---

## 💌 Final Thoughts

> *"In the end, you only regret the videos you didn't download."*  
> — Ancient Internet Proverb

Built with 💜, ☕, and an unhealthy amount of perfectionism.

---

<div align="center">

**[⬆ Back to Top](#-fluxtube)**

Made with 🔥 by someone who believes software should be both powerful and beautiful

*Star this repo if it made your day a little brighter* ⭐

</div>
