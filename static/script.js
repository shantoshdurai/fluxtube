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

    let videoData = null;
    let currentTab = 'video';

    extractBtn.addEventListener('click', async () => {
        const url = videoUrlInput.value.trim();
        if (!url) return alert('Please enter a YouTube URL');

        // Reset UI
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

        renderFormats();
        previewSection.classList.remove('hidden');
    }

    function formatDuration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return [h, m, s].map(v => v.toString().padStart(2, '0')).filter((v, i) => v !== '00' || i > 0).join(':');
    }

    function renderFormats() {
        formatsGrid.innerHTML = '';
        const filtered = videoData.formats.filter(f => {
            if (currentTab === 'video') return f.vcodec !== 'none';
            return f.vcodec === 'none' && f.acodec !== 'none';
        });

        // Deduplicate common resolutions
        const seen = new Set();
        filtered.forEach(f => {
            const res = f.resolution || (currentTab === 'audio' ? 'MP3/M4A' : 'Unknown');
            if (seen.has(res) && currentTab === 'video') return;
            seen.add(res);

            const div = document.createElement('div');
            div.className = 'format-item';
            div.innerHTML = `
                <span class="format-res">${res}</span>
                <span class="format-ext">${f.ext.toUpperCase()} ${f.filesize ? '(' + (f.filesize / (1024 * 1024)).toFixed(1) + 'MB)' : ''}</span>
            `;
            div.onclick = () => download(f);
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

    async function download(format) {
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
                    format_id: format.format_id,
                    ext: format.ext
                })
            });

            if (!response.ok) {
                const err = await response.json().catch(() => ({}));
                throw new Error(err.detail || 'Download failed to start');
            }

            const { job_id } = await response.json();

            // Start polling progress
            const pollInterval = setInterval(async () => {
                try {
                    const progRes = await fetch(`/progress/${job_id}`);
                    const data = await progRes.json();

                    if (data.status === 'complete') {
                        clearInterval(pollInterval);
                        progressBar.style.width = '100%';
                        statusText.textContent = 'Download Complete! Saving file...';
                        setTimeout(() => {
                            window.location.href = `/get-file/${data.file_id}`;
                        }, 1000);
                    } else if (data.status.startsWith('error')) {
                        clearInterval(pollInterval);
                        alert('Error: ' + data.status);
                        statusSection.classList.add('hidden');
                    } else {
                        // Update UI
                        const progress = parseFloat(data.progress) || 0;
                        progressBar.style.width = `${progress}%`;
                        statusText.textContent = `${data.status} (${progress}%)`;
                    }
                } catch (e) {
                    console.error("Polling error:", e);
                }
            }, 1000);

        } catch (error) {
            alert('Download failed: ' + error.message);
            statusSection.classList.add('hidden');
        }
    }
});
