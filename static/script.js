document.addEventListener('DOMContentLoaded', () => {
    const videoUrlInput = document.getElementById('video-url');
    const extractBtn = document.getElementById('extract-btn');
    const loader = document.getElementById('loader');
    const previewSection = document.getElementById('video-preview');
    const thumbImg = document.getElementById('thumb-img');
    const videoTitle = document.getElementById('video-title');
    const videoUploader = document.getElementById('video-uploader');
    const durationTag = document.getElementById('duration-tag');
    const formatsGrid = document.getElementById('formats-grid');
    const tabButtons = document.querySelectorAll('.format-tabs button');
    const ffmpegWarning = document.getElementById('ffmpeg-warning');

    let videoData = null;
    let currentTab = 'video';

    extractBtn.addEventListener('click', async () => {
        const url = videoUrlInput.value.trim();
        if (!url) return alert('Please enter a YouTube URL');

        previewSection.classList.add('hidden');
        loader.classList.remove('hidden');

        try {
            const response = await fetch('/info', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url })
            });

            if (!response.ok) {
                const err = await response.json().catch(() => ({}));
                throw new Error(err.detail || 'Failed to fetch video info');
            }

            videoData = await response.json();
            displayVideoInfo(videoData);
        } catch (error) {
            alert('Error: ' + error.message);
        } finally {
            loader.classList.add('hidden');
        }
    });

    function displayVideoInfo(data) {
        thumbImg.src = data.thumbnail;
        videoTitle.textContent = data.title;
        videoUploader.textContent = data.uploader;
        durationTag.textContent = formatDuration(data.duration);

        if (ffmpegWarning) {
            ffmpegWarning.classList.toggle('hidden', data.ffmpeg !== false);
        }

        renderFormats();
        previewSection.classList.remove('hidden');
    }

    function formatDuration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return [h, m, s]
            .map(v => v.toString().padStart(2, '0'))
            .filter((v, i) => v !== '00' || i > 0)
            .join(':');
    }

    function renderFormats() {
        formatsGrid.innerHTML = '';
        if (!videoData) return;

        const formats = videoData.formats.filter(f =>
            currentTab === 'video' ? !f.is_audio : f.is_audio
        );

        formats.forEach(f => {
            const div = document.createElement('div');
            div.className = 'format-item';

            const sizeLabel = f.filesize
                ? `(${(f.filesize / (1024 * 1024)).toFixed(1)}MB)`
                : '';

            div.innerHTML = `
                <span class="format-res">${f.resolution}</span>
                <span class="format-ext">${f.ext.toUpperCase()} ${sizeLabel}</span>
            `;
            div.onclick = () => startDownload(f);
            formatsGrid.appendChild(div);
        });
    }

    tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            tabButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentTab = btn.dataset.type;
            renderFormats();
        });
    });

    async function startDownload(format) {
        const statusSection = document.getElementById('download-status');
        const progressBar = document.querySelector('.progress-fill');
        const statusText = document.getElementById('status-text');

        statusSection.classList.remove('hidden');
        progressBar.style.width = '2%';
        statusText.textContent = 'Queueing download...';

        try {
            const response = await fetch('/download', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    url: videoUrlInput.value.trim(),
                    height: format.height,
                    is_audio: format.is_audio,
                })
            });

            if (!response.ok) {
                const err = await response.json().catch(() => ({}));
                throw new Error(err.detail || 'Download failed to start');
            }

            const { job_id } = await response.json();

            const pollInterval = setInterval(async () => {
                try {
                    const progRes = await fetch(`/progress/${job_id}`);
                    const data = await progRes.json();

                    const statusStr = typeof data.status === 'string' ? data.status : JSON.stringify(data.status);
                    if (statusStr === 'complete') {
                        clearInterval(pollInterval);
                        progressBar.style.width = '100%';
                        statusText.textContent = 'Complete! Saving file...';
                        setTimeout(() => {
                            window.location.href = `/get-file/${data.file_id}`;
                        }, 800);
                    } else if (statusStr.startsWith('error')) {
                        clearInterval(pollInterval);
                        const msg = statusStr.replace(/^error:\s*/, '');
                        statusText.textContent = 'Error: ' + msg;
                        statusText.style.color = '#ff4444';
                        progressBar.style.background = '#ff4444';
                        console.error('Download error:', statusStr);
                    } else {
                        const progress = parseFloat(data.progress) || 0;
                        progressBar.style.width = `${Math.max(progress, 2)}%`;
                        statusText.textContent = statusStr;
                    }
                } catch (e) {
                    console.error("Polling error:", e);
                }
            }, 1000);

        } catch (error) {
            const msg = error?.message || JSON.stringify(error);
            statusText.textContent = 'Error: ' + msg;
            statusText.style.color = '#ff4444';
            console.error('Download failed:', error);
        }
    }
});
