(() => {
    const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 's82coords';

    const app = document.getElementById('app');
    const toastBox = document.getElementById('toast');

    const state = {
        x: 0, y: 0, z: 0, heading: 0,
        laser: { x: 0, y: 0, z: 0 },
        laserEnabled: false,
        favorites: [],
    };

    // ---------------------------------------------
    // Helpers
    // ---------------------------------------------

    function post(endpoint, data = {}) {
        return fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).catch(() => {});
    }

    function showToast(text) {
        const el = document.createElement('div');
        el.className = 'toast-item';
        el.textContent = text;
        toastBox.appendChild(el);
        setTimeout(() => el.remove(), 2000);
    }

    function copyText(text) {
        const fallback = () => {
            const ta = document.createElement('textarea');
            ta.value = text;
            ta.style.position = 'fixed';
            ta.style.opacity = '0';
            document.body.appendChild(ta);
            ta.select();
            try { document.execCommand('copy'); } catch (e) {}
            document.body.removeChild(ta);
        };

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(fallback);
        } else {
            fallback();
        }
        showToast('Đã sao chép: ' + text);
    }

    // ---------------------------------------------
    // Tabs
    // ---------------------------------------------

    document.querySelectorAll('.tab-btn').forEach((btn) => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach((c) => c.classList.remove('active'));
            btn.classList.add('active');
            document.querySelector(`[data-tab-content="${btn.dataset.tab}"]`).classList.add('active');
        });
    });

    // ---------------------------------------------
    // Đóng UI
    // ---------------------------------------------

    function closeUI() {
        app.classList.add('hidden');
        post('close');
    }

    document.getElementById('btnClose').addEventListener('click', closeUI);

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeUI();
    });

    // ---------------------------------------------
    // Copy buttons
    // ---------------------------------------------

    document.querySelectorAll('.copy-btn[data-copy]').forEach((btn) => {
        btn.addEventListener('click', () => {
            const type = btn.dataset.copy;
            const { x, y, z, heading } = state;
            let text = '';

            switch (type) {
                case 'vector3':
                    text = `vector3(${x}, ${y}, ${z})`;
                    break;
                case 'vector4':
                    text = `vector4(${x}, ${y}, ${z}, ${heading})`;
                    break;
                case 'coords':
                    text = `{${x}, ${y}, ${z}}`;
                    break;
                case 'xyz':
                    text = `${x}, ${y}, ${z}`;
                    break;
            }

            copyText(text);
        });
    });

    // ---------------------------------------------
    // Laser
    // ---------------------------------------------

    const btnLaser = document.getElementById('btnLaser');
    const laserLabel = document.getElementById('laserLabel');
    const laserInfo = document.getElementById('laserInfo');
    const laserCoordsEl = document.getElementById('laserCoords');

    btnLaser.addEventListener('click', async () => {
        state.laserEnabled = !state.laserEnabled;
        btnLaser.classList.toggle('on', state.laserEnabled);
        laserLabel.textContent = state.laserEnabled ? 'Đang bật' : 'Đang tắt';
        laserInfo.classList.toggle('hidden', !state.laserEnabled);
        await post('toggleLaser', { enabled: state.laserEnabled });
    });

    document.getElementById('btnCopyLaser').addEventListener('click', () => {
        const { x, y, z } = state.laser;
        copyText(`vector3(${x}, ${y}, ${z})`);
    });

    // ---------------------------------------------
    // Favorites
    // ---------------------------------------------

    const favInput = document.getElementById('favLabel');
    const favList = document.getElementById('favoritesList');
    const favEmpty = document.getElementById('favoritesEmpty');

    function persistFavorites() {
        post('saveFavorites', { favorites: state.favorites });
    }

    function renderFavorites() {
        favList.innerHTML = '';

        if (!state.favorites.length) {
            favEmpty.classList.remove('hidden');
            return;
        }
        favEmpty.classList.add('hidden');

        state.favorites.forEach((fav, index) => {
            const item = document.createElement('div');
            item.className = 'favorite-item';

            const c = fav.coords;
            item.innerHTML = `
                <div class="favorite-info">
                    <span>${fav.label}</span>
                    <small>${c.x.toFixed(1)}, ${c.y.toFixed(1)}, ${c.z.toFixed(1)}</small>
                </div>
                <div class="favorite-actions">
                    <button class="go-btn" title="Di chuyển tới">➤</button>
                    <button class="del-btn" title="Xoá">✕</button>
                </div>
            `;

            item.querySelector('.go-btn').addEventListener('click', async () => {
                await post('gotoFavorite', { coords: fav.coords });
                showToast('Đã di chuyển tới: ' + fav.label);
            });

            item.querySelector('.del-btn').addEventListener('click', () => {
                state.favorites.splice(index, 1);
                persistFavorites();
                renderFavorites();
            });

            favList.appendChild(item);
        });
    }

    document.getElementById('btnAddFavorite').addEventListener('click', () => {
        const label = favInput.value.trim() || `Vị trí #${state.favorites.length + 1}`;

        state.favorites.push({
            label,
            coords: { x: state.x, y: state.y, z: state.z, w: state.heading },
        });

        favInput.value = '';
        persistFavorites();
        renderFavorites();
        showToast('Đã lưu vị trí yêu thích');
    });

    favInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') document.getElementById('btnAddFavorite').click();
    });

    // ---------------------------------------------
    // Nhận dữ liệu từ client Lua
    // ---------------------------------------------

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'toggle':
                if (data.open) {
                    app.classList.remove('hidden');
                    if (Array.isArray(data.favorites)) {
                        state.favorites = data.favorites;
                        renderFavorites();
                    }
                } else {
                    app.classList.add('hidden');
                }
                break;

            case 'update':
                state.x = data.x;
                state.y = data.y;
                state.z = data.z;
                state.heading = data.heading;

                document.getElementById('valX').textContent = data.x.toFixed(2);
                document.getElementById('valY').textContent = data.y.toFixed(2);
                document.getElementById('valZ').textContent = data.z.toFixed(2);
                document.getElementById('valH').textContent = data.heading.toFixed(2);
                break;

            case 'laserUpdate':
                state.laser = { x: data.x, y: data.y, z: data.z };
                laserCoordsEl.textContent = `${data.x}, ${data.y}, ${data.z}`;
                break;
        }
    });
})();
