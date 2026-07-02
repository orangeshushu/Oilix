(function () {
  const APP_TITLE = "Oil Spill Detection Management System";
  const AUTH_KEY = "wateroil_console_auth";
  const API_BASE_KEY = "wateroil_api_base";
  const app = document.getElementById("app");

  const state = {
    photos: [],
    users: [],
    meta: {},
    user: loadAuth(),
    loading: false,
    photosLoaded: false,
    usersLoaded: false,
    profileLoaded: false,
    pendingDeleteId: null,
    lastQuery: {},
    uploadFiles: []
  };

  function loadAuth() {
    try {
      const auth = JSON.parse(localStorage.getItem(AUTH_KEY) || "null");
      if (!auth || auth.expires < Date.now()) return null;
      return auth;
    } catch {
      return null;
    }
  }

  function saveAuth(auth) {
    state.user = auth;
    localStorage.setItem(AUTH_KEY, JSON.stringify(auth));
  }

  function clearAuth() {
    state.user = null;
    state.photos = [];
    state.users = [];
    state.photosLoaded = false;
    state.usersLoaded = false;
    state.profileLoaded = false;
    localStorage.removeItem(AUTH_KEY);
  }

  function apiBase() {
    const params = new URLSearchParams(location.search);
    const fromQuery = params.get("api");
    if (fromQuery) {
      localStorage.setItem(API_BASE_KEY, fromQuery.replace(/\/$/, ""));
      return fromQuery.replace(/\/$/, "");
    }
    return (localStorage.getItem(API_BASE_KEY) || "").replace(/\/$/, "");
  }

  function apiPath(path) {
    return `${apiBase()}${path}`;
  }

  async function request(path, options = {}) {
    const response = await fetch(apiPath(path), {
      credentials: "include",
      ...options,
      headers: {
        ...(options.headers || {})
      }
    });
    const text = await response.text();
    let data;
    try {
      data = text ? JSON.parse(text) : {};
    } catch {
      throw new Error(text || `HTTP ${response.status}`);
    }
    if (!response.ok) {
      throw new Error(data.msg || `HTTP ${response.status}`);
    }
    return data;
  }

  function formRequest(path, values) {
    return request(path, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8" },
      body: new URLSearchParams(values)
    });
  }

  function routeTo(target) {
    location.hash = target;
    render();
  }

  function currentPath() {
    const hash = location.hash.replace(/^#/, "");
    return (hash || "/login").split("?")[0] || "/login";
  }

  function routeParams() {
    const hash = location.hash.replace(/^#/, "");
    const queryIndex = hash.indexOf("?");
    return new URLSearchParams(queryIndex >= 0 ? hash.slice(queryIndex + 1) : "");
  }

  function withQuery(path, params) {
    const query = new URLSearchParams(params);
    for (const [key, value] of [...query.entries()]) {
      if (value === "" || value == null) query.delete(key);
    }
    const text = query.toString();
    return `${path}${text ? `?${text}` : ""}`;
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function imageUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    const clean = String(path).replace(/^\/+/, "");
    return `${apiBase()}/${clean}`;
  }

  function normalizePhotos(msg) {
    if (!msg || typeof msg !== "object") return [];
    return Object.keys(msg)
      .sort((a, b) => Number(a) - Number(b))
      .map((key) => msg[key])
      .filter(Boolean)
      .map((photo) => ({
        id: String(photo.id ?? ""),
        path: photo.path || "",
        gps: photo.gps || "",
        detailed_gps: photo.detailed_gps || "",
        date: photo.date || "",
        result: photo.result || "",
        notes: photo.notes || "",
        tags: photo.tags || "",
        username: photo.username || state.user?.username || ""
      }));
  }

  function normalizeUsers(msg) {
    if (!msg || typeof msg !== "object") return [];
    return Object.keys(msg)
      .sort((a, b) => Number(a) - Number(b))
      .map((key) => msg[key])
      .filter(Boolean)
      .map((user) => ({
        id: String(user.id ?? ""),
        username: user.username || "",
        name: user.name || "",
        email: user.email || "",
        role: user.role || "user",
        photo_count: user.photo_count ?? ""
      }));
  }

  async function loadUsers() {
    if (!state.user || state.user.role !== "Admin") return;
    state.loading = true;
    render();
    try {
      const data = await formRequest("/userlist", {});
      if (data.status === 8) {
        clearAuth();
        toast("Login expired. Please sign in again.");
        routeTo("/login");
        return;
      }
      if (data.status !== 0) throw new Error(data.msg || "Request failed.");
      state.users = normalizeUsers(data.msg);
      state.usersLoaded = true;
    } catch (error) {
      state.usersLoaded = true;
      toast(error.message);
    } finally {
      state.loading = false;
      render();
    }
  }

  async function loadPhotos(query = {}) {
    if (!state.user || state.user.role !== "Admin") return;
    state.loading = true;
    state.lastQuery = query;
    render();
    try {
      let data;
      if (query.tag) {
        data = await formRequest("/searchfiltertag", { taglist: query.tag });
      } else if (query.q) {
        data = await formRequest("/searchfilterglobal", { querystring: query.q, page: query.page || "1" });
      } else if (query.gps && query.radius) {
        data = await formRequest("/searchfiltergeography", {
          gps: query.gps,
          radius: query.radius,
          radiusunit: query.radiusunit || "km",
          last_token: query.last_token || "-",
          next_token: query.next_token || "-",
          request_id: query.request_id || "-"
        });
      } else {
        data = await formRequest("/adminphotolist", {
          mindate: query.start || "-",
          maxdate: query.end || "-",
          page: query.page || "1"
        });
      }
      if (data.status === 8) {
        clearAuth();
        toast("Login expired. Please sign in again.");
        routeTo("/login");
        return;
      }
      if (data.status !== 0) throw new Error(data.msg || "Request failed.");
      state.photos = normalizePhotos(data.msg);
      state.meta = data.meta || {};
      state.photosLoaded = true;
    } catch (error) {
      state.photosLoaded = true;
      toast(error.message);
    } finally {
      state.loading = false;
      render();
    }
  }

  async function loadProfile() {
    try {
      const data = await request("/user");
      if (data.status === 0 && state.user) {
        saveAuth({
          ...state.user,
          username: data.msg.username,
          name: data.msg.name,
          email: data.msg.email
        });
        state.profileLoaded = true;
        render();
      }
    } catch {
      state.profileLoaded = true;
      // Profile is a convenience call; the page still works with cached login data.
    }
  }

  function nav() {
    return `
      <nav class="top-nav">
        <ul>
          <li class="dropdown">
            <img class="avatar" src="public/assets/icon/unknown_user.jpg" alt="user">
            <div class="dropdown-content">
              <a href="#/profile" data-link="/profile">Profile</a>
              <a href="#" data-logout>Log out</a>
            </div>
          </li>
          <li><span class="material-icons nav-icon" data-go="/upload" title="Upload">cloud_upload</span></li>
          <li><span class="material-icons nav-icon" data-go="/mapview/global" title="Map">map</span></li>
          <li><span class="material-icons nav-icon" data-go="/" title="Grid">grid_view</span></li>
          <li><span class="material-icons nav-icon" data-go="/table" title="Table">table_rows</span></li>
          <li><span class="material-icons nav-icon" data-go="/analysis" title="Analysis">analytics</span></li>
          ${state.user?.role === "Admin" ? '<li><span class="material-icons nav-icon" data-go="/users" title="Users">manage_accounts</span></li>' : ""}
        </ul>
      </nav>
    `;
  }

  function shell(content) {
    return `<div class="shell">${nav()}${content}${deleteModal()}</div>`;
  }

  function deleteModal() {
    if (!state.pendingDeleteId) return "";
    return `
      <div class="modal-backdrop" role="presentation">
        <section class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="delete-title">
          <h3 id="delete-title">Delete photo?</h3>
          <p>This will remove photo ID ${escapeHtml(state.pendingDeleteId)} and its stored image from the server.</p>
          <div class="dialog-actions">
            <button class="action-button neutral" type="button" data-cancel-delete>Cancel</button>
            <button class="action-button danger-fill" type="button" data-confirm-delete="${escapeHtml(state.pendingDeleteId)}">Delete Photo</button>
          </div>
        </section>
      </div>
    `;
  }

  function loginPage(mode) {
    const isNormal = mode === "normal";
    document.title = `${isNormal ? "Normal Login" : "Admin Login"} - ${APP_TITLE}`;
    return `
      <main class="login-page">
        <section class="login-card">
          <form data-login="${isNormal ? "normal" : "admin"}">
            <h1>${APP_TITLE}</h1>
            ${isNormal ? '<h1 class="sub-title">Normal User Quick Upload</h1>' : ""}
            <div class="error" data-error hidden></div>
            <div class="form-field">
              <label>Username</label>
              <input name="username" placeholder="Username" required autocomplete="username">
            </div>
            <div class="form-field">
              <label>Password</label>
              <input name="password" type="password" placeholder="Password" required autocomplete="current-password">
            </div>
            <div class="button-row">
              <a class="stacked-link" href="#${isNormal ? "/adminlogin" : "/resetpassword"}" data-link="${isNormal ? "/adminlogin" : "/resetpassword"}">${isNormal ? "Admin Login" : "Change<br>Password"}</a>
              <button class="raised" type="submit">Login</button>
              ${isNormal
                ? '<a class="stacked-link" href="#/resetpassword" data-link="/resetpassword">Change Password</a>'
                : '<a class="stacked-link" href="#/login" data-link="/login">Normal user<br>quick upload</a>'}
            </div>
          </form>
        </section>
      </main>
    `;
  }

  function resetPage() {
    document.title = `Reset Password - ${APP_TITLE}`;
    return `
      <main class="login-page">
        <section class="login-card">
          <form data-reset>
            <h1>${APP_TITLE}</h1>
            <div class="error" data-error hidden></div>
            <div class="form-field"><label>Username</label><input name="username" placeholder="Username" required></div>
            <div class="form-field"><label>New password</label><input name="password" type="password" placeholder="New password" required></div>
            <div class="form-field"><label>Email</label><input name="email" type="email" placeholder="Email" required></div>
            <div class="button-row">
              <a href="#/login" data-link="/login">Login</a>
              <button class="raised" type="submit">Change Password</button>
            </div>
          </form>
        </section>
      </main>
    `;
  }

  function toolbar(title) {
    const params = routeParams();
    return `
      <section class="toolbar-card">
        <div class="toolbar-title">
          <h2>${title}</h2>
          ${state.loading ? '<span class="loading-chip">Loading</span>' : ""}
        </div>
        <form class="filters" data-filter>
          <div class="form-field"><label>Start date</label><input type="date" name="start" value="${escapeHtml(params.get("start") || "")}"></div>
          <div class="form-field"><label>End date</label><input type="date" name="end" value="${escapeHtml(params.get("end") || "")}"></div>
          <div class="form-field"><label>Search notes</label><input name="q" placeholder="Notes" value="${escapeHtml(params.get("q") || "")}"></div>
          <div class="form-field"><label>Tags</label><input name="tag" placeholder="#oil" value="${escapeHtml(params.get("tag") || "")}"></div>
          <button class="raised" type="submit">Search</button>
        </form>
        <form class="geo-filters" data-geo-filter>
          <div class="form-field"><label>GPS center</label><input name="gps" placeholder="38.95,-92.33" value="${escapeHtml(params.get("gps") || "")}"></div>
          <div class="form-field"><label>Radius</label><input name="radius" type="number" min="0" step="0.1" placeholder="10" value="${escapeHtml(params.get("radius") || "")}"></div>
          <div class="form-field"><label>Unit</label><select name="radiusunit">
            ${["km", "m", "mile"].map((unit) => `<option value="${unit}" ${params.get("radiusunit") === unit ? "selected" : ""}>${unit}</option>`).join("")}
          </select></div>
          <button class="raised secondary" type="submit">Geo Search</button>
        </form>
        <div class="summary-strip">
          <span>${state.photos.length} photos</span>
          <span>Page ${escapeHtml(state.meta.current_page || "1")} / ${escapeHtml(state.meta.total_page || "1")}</span>
          <span>${apiBase() || location.origin}</span>
        </div>
      </section>
    `;
  }

  function photoThumb(photo, extra = "") {
    const src = imageUrl(photo.path);
    if (!src) return `<div class="photo-thumb ${extra}"><span class="photo-badge">ID: ${escapeHtml(photo.id)}</span></div>`;
    return `
      <div class="photo-thumb has-image ${extra}">
        <img src="${escapeHtml(src)}" alt="Photo ${escapeHtml(photo.id)}" loading="lazy">
        <span class="photo-badge">ID: ${escapeHtml(photo.id)}</span>
      </div>
    `;
  }

  function gridPage() {
    document.title = `Photo List - ${APP_TITLE}`;
    const cards = state.photos.map((p) => `
      <article class="photo-card">
        ${photoThumb(p)}
        <div class="body">
          <h3>${escapeHtml(p.detailed_gps || "Unknown location")}</h3>
          <div class="meta-list">
            <span><strong>GPS:</strong> ${escapeHtml(p.gps)}</span>
            <span><strong>Date:</strong> ${escapeHtml(p.date)}</span>
            <span><strong>Result:</strong> ${escapeHtml(p.result)}</span>
            <span><strong>Uploaded by:</strong> ${escapeHtml(p.username)}</span>
            <span><strong>Note:</strong> ${escapeHtml(p.notes)}</span>
            <span><strong>Tags:</strong> ${escapeHtml(p.tags)}</span>
          </div>
          <div class="card-actions">
            <button class="action-button neutral" data-go="/mapview/specific-${escapeHtml(p.id)}">Map View</button>
            <button class="action-button primary" data-edit="${escapeHtml(p.id)}">Edit</button>
            <button class="action-button danger-fill" data-delete="${escapeHtml(p.id)}">Delete</button>
          </div>
        </div>
      </article>
    `).join("");
    return shell(`<main class="content">${toolbar("Photo List")}${cards ? `<section class="grid">${cards}</section>` : empty("No photos matched this filter.")}</main>`);
  }

  function tablePage() {
    document.title = `Table view - ${APP_TITLE}`;
    const rows = state.photos.map((p) => `
      <tr>
        <td>${miniThumb(p)}</td>
        <td>${escapeHtml(p.id)}</td>
        <td>${escapeHtml(p.date)}</td>
        <td>${escapeHtml(p.gps)}</td>
        <td>${escapeHtml(p.detailed_gps)}</td>
        <td>${escapeHtml(p.result)}</td>
        <td>${escapeHtml(p.notes)}</td>
        <td>${escapeHtml(p.tags)}</td>
        <td>${escapeHtml(p.username)}</td>
        <td>
          <div class="table-actions">
            <button class="action-button primary compact" data-edit="${escapeHtml(p.id)}">Edit</button>
            <button class="action-button danger-fill compact" data-delete="${escapeHtml(p.id)}">Delete</button>
          </div>
        </td>
      </tr>
    `).join("");
    return shell(`
      <main class="content">
        ${toolbar("Table view")}
        <div class="toolbar-card action-row">
          <button class="raised" data-export="csv">Export CSV</button>
          <button class="raised" data-export="json">Export JSON</button>
          <button class="raised secondary" data-refresh>Refresh</button>
        </div>
        <section class="table-wrap">
          <table>
            <thead><tr><th>Photo</th><th>ID</th><th>Date</th><th>GPS</th><th>Location</th><th>Result</th><th>Note</th><th>Tags</th><th>Uploaded By</th><th>Actions</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </section>
      </main>
    `);
  }

  function miniThumb(photo) {
    const src = imageUrl(photo.path);
    return src ? `<img class="mini-thumb" src="${escapeHtml(src)}" alt="">` : '<div class="mini-thumb"></div>';
  }

  function mapPage(id) {
    document.title = `Map - ${APP_TITLE}`;
    const selected = id && id.startsWith("specific-")
      ? state.photos.find((p) => p.id === id.replace("specific-", ""))
      : state.photos[0];
    const details = selected ? `
      <h3>Image Details</h3>
      ${photoThumb(selected, "large-thumb")}
      <div class="meta-list">
        <span><strong>ID:</strong> ${escapeHtml(selected.id)}</span>
        <span><strong>GPS:</strong> ${escapeHtml(selected.gps)}</span>
        <span><strong>Location:</strong> ${escapeHtml(selected.detailed_gps)}</span>
        <span><strong>Date:</strong> ${escapeHtml(selected.date)}</span>
        <span><strong>Result:</strong> ${escapeHtml(selected.result)}</span>
        <span><strong>Uploaded by:</strong> ${escapeHtml(selected.username)}</span>
        <span><strong>Note:</strong> ${escapeHtml(selected.notes)}</span>
        <span><strong>Tags:</strong> ${escapeHtml(selected.tags)}</span>
      </div>
      <div class="card-actions">
        <button class="action-button primary" data-edit="${escapeHtml(selected.id)}">Edit</button>
        <button class="action-button danger-fill" data-delete="${escapeHtml(selected.id)}">Delete</button>
      </div>
    ` : "<h3>No photo selected</h3>";
    return shell(`
      <main class="content">
        ${toolbar("Map view")}
        <section class="map-layout">
          <div id="real-map" class="map-canvas real-map" aria-label="Photo map"></div>
          <aside class="side-panel">${details}</aside>
        </section>
      </main>
    `);
  }

  function photoLatLng(photo) {
    const parts = String(photo.gps || "").split(",").map(Number);
    if (parts.length !== 2 || !Number.isFinite(parts[0]) || !Number.isFinite(parts[1])) return null;
    if (Math.abs(parts[0]) > 90 || Math.abs(parts[1]) > 180) return null;
    return [parts[0], parts[1]];
  }

  function initRealMap() {
    const el = document.getElementById("real-map");
    if (!el) return;
    if (!window.L) {
      el.innerHTML = '<div class="map-error">Map library could not be loaded.</div>';
      return;
    }

    const selectedId = currentPath().split("/").pop()?.replace("specific-", "");
    const points = state.photos
      .map((photo) => ({ photo, latlng: photoLatLng(photo) }))
      .filter((item) => item.latlng);
    const selected = points.find((item) => item.photo.id === selectedId) || points[0];
    const usaCenter = [39.5, -98.35];
    const center = selected ? selected.latlng : usaCenter;
    const map = L.map(el, { scrollWheelZoom: true }).setView(center, selected ? 7 : 4);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    const markerLayer = window.L.markerClusterGroup
      ? L.markerClusterGroup({
          showCoverageOnHover: false,
          spiderfyOnMaxZoom: true,
          spiderfyDistanceMultiplier: 1.6,
          maxClusterRadius: 58,
          disableClusteringAtZoom: 12,
          iconCreateFunction(cluster) {
            const count = cluster.getChildCount();
            const size = count < 10 ? "small" : count < 50 ? "medium" : "large";
            return L.divIcon({
              html: `<div><span>${count}</span></div>`,
              className: `photo-cluster photo-cluster-${size}`,
              iconSize: L.point(46, 46)
            });
          }
        })
      : L.layerGroup();
    const bounds = [];
    points.forEach(({ photo, latlng }) => {
      bounds.push(latlng);
      const src = imageUrl(photo.path);
      const html = src
        ? `<img src="${escapeHtml(src)}" alt=""><span>${escapeHtml(photo.id)}</span>`
        : `<div class="marker-fallback"></div><span>${escapeHtml(photo.id)}</span>`;
      const marker = L.marker(latlng, {
        icon: L.divIcon({
          className: "photo-map-marker",
          html,
          iconSize: [58, 70],
          iconAnchor: [29, 58],
          popupAnchor: [0, -58]
        })
      });
      marker.bindPopup(`
        <strong>ID: ${escapeHtml(photo.id)}</strong><br>
        ${escapeHtml(photo.detailed_gps || "Unknown location")}<br>
        Result: ${escapeHtml(photo.result)}
      `);
      marker.on("click", () => {
        if (photo.id !== selectedId) routeTo(`/mapview/specific-${photo.id}`);
      });
      markerLayer.addLayer(marker);
    });
    map.addLayer(markerLayer);

    if (bounds.length > 1) {
      map.fitBounds(bounds, { padding: [44, 44], maxZoom: 8 });
    } else if (bounds.length === 1) {
      map.setView(bounds[0], 8);
    } else {
      map.setView(usaCenter, 4);
    }

    setTimeout(() => map.invalidateSize(), 120);
  }

  function uploadPage() {
    document.title = `Upload - ${APP_TITLE}`;
    return shell(`
      <main class="upload-page">
        <section class="upload-header">
          <h2>Photo Upload</h2>
          <div class="upload-actions">
            <input class="hidden-file" type="file" id="file" accept="image/*" multiple>
            <button class="raised" data-pick-file><span class="material-icons" style="vertical-align:middle">add</span> Add Photos</button>
            <button class="raised" data-submit-upload ${state.uploadFiles.length ? "" : "disabled"}>Upload</button>
          </div>
        </section>
        <section id="upload-list" class="upload-list">${uploadListHtml()}</section>
        <section id="upload-empty" ${state.uploadFiles.length ? "hidden" : ""}>${empty("No photo selected.")}</section>
      </main>
    `);
  }

  function uploadListHtml() {
    return state.uploadFiles.map((item, index) => `
      <article class="upload-item">
        <img class="upload-preview" src="${escapeHtml(item.src)}" alt="${escapeHtml(item.file.name)}">
        <div class="form-field"><label>GPS</label><input data-upload-gps="${index}" value="${escapeHtml(item.gps)}" placeholder="No space, separate by comma"></div>
        <div class="form-field"><label>Note</label><textarea data-upload-note="${index}">${escapeHtml(item.note)}</textarea></div>
        <p class="upload-status ${item.statusClass || ""}">${escapeHtml(item.status)}</p>
        <progress value="${item.progress}" max="100"></progress>
        <button class="action-button danger-outline compact" data-remove-upload="${index}">Remove</button>
      </article>
    `).join("");
  }

  function profilePage() {
    const user = state.user || {};
    document.title = `Profile - ${APP_TITLE}`;
    return shell(`
      <main>
        <section class="profile-card">
          <img src="public/assets/icon/unknown_user.jpg" alt="user">
          <h4>Username: ${escapeHtml(user.username)}</h4>
          <h4>Role: ${escapeHtml(user.role)}</h4>
          <form class="profile-form" data-profile-update>
            <div class="error" data-error hidden></div>
            <div class="form-field"><label>Name</label><input name="name" value="${escapeHtml(user.name)}" required></div>
            <div class="form-field"><label>Email</label><input name="email" type="email" value="${escapeHtml(user.email)}" required></div>
            <div class="button-row profile-actions">
              <button class="raised" type="submit">Save Profile</button>
              <button class="raised secondary" type="button" data-go="/resetpassword">Reset Password</button>
            </div>
          </form>
        </section>
      </main>
    `);
  }

  function usersPage() {
    document.title = `Users - ${APP_TITLE}`;
    if (state.user?.role !== "Admin") {
      return shell(`<main class="content">${empty("Only admin users can view registered users.")}</main>`);
    }
    const rows = state.users.map((user) => `
      <tr>
        <td>${escapeHtml(user.id)}</td>
        <td>${escapeHtml(user.username)}</td>
        <td>${escapeHtml(user.name)}</td>
        <td>${escapeHtml(user.email)}</td>
        <td><span class="role-chip ${user.role === "admin" ? "admin" : ""}">${escapeHtml(user.role)}</span></td>
        <td>${escapeHtml(user.photo_count)}</td>
      </tr>
    `).join("");
    return shell(`
      <main class="content">
        <section class="toolbar-card">
          <div class="toolbar-title">
            <h2>Registered Users</h2>
            ${state.loading ? '<span class="loading-chip">Loading</span>' : ""}
          </div>
          <div class="summary-strip">
            <span>${state.users.length} users</span>
            <span>Admin only</span>
          </div>
        </section>
        <section class="table-wrap">
          <table>
            <thead><tr><th>ID</th><th>Username</th><th>Name</th><th>Email</th><th>Role</th><th>Photos</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </section>
      </main>
    `);
  }

  function analysisPage() {
    const values = state.photos
      .map((p) => Number(p.result))
      .filter((value) => Number.isFinite(value));
    const avg = values.length ? (values.reduce((sum, value) => sum + value, 0) / values.length).toFixed(2) : "-";
    const max = values.length ? Math.max(...values).toFixed(2) : "-";
    const tagged = state.photos.filter((p) => p.tags).length;
    return shell(`
      <main class="content">
        ${toolbar("Analysis")}
        <section class="stats-grid">
          <article class="stat-card"><span>Total photos</span><strong>${state.photos.length}</strong></article>
          <article class="stat-card"><span>Average result</span><strong>${avg}</strong></article>
          <article class="stat-card"><span>Highest result</span><strong>${max}</strong></article>
          <article class="stat-card"><span>Tagged photos</span><strong>${tagged}</strong></article>
        </section>
      </main>
    `);
  }

  function empty(text) {
    return `<div class="empty-state">${clockIcon()}<h3>${escapeHtml(text)}</h3></div>`;
  }

  function clockIcon() {
    return `
      <svg viewBox="0 0 502 511.82" aria-hidden="true">
        <path fill-rule="nonzero" d="M279.75 471.21c14.34-1.9 25.67 12.12 20.81 25.75-2.54 6.91-8.44 11.76-15.76 12.73a260.727 260.727 0 0 1-50.81 1.54c-62.52-4.21-118.77-31.3-160.44-72.97C28.11 392.82 0 330.04 0 260.71 0 191.37 28.11 128.6 73.55 83.16S181.76 9.61 251.1 9.61c24.04 0 47.47 3.46 69.8 9.91a249.124 249.124 0 0 1 52.61 21.97l-4.95-12.96c-4.13-10.86 1.32-23.01 12.17-27.15 10.86-4.13 23.01 1.32 27.15 12.18L428.8 68.3a21.39 21.39 0 0 1 1.36 6.5c1.64 10.2-4.47 20.31-14.63 23.39l-56.03 17.14c-11.09 3.36-22.8-2.9-26.16-13.98-3.36-11.08 2.9-22.8 13.98-26.16l4.61-1.41a210.71 210.71 0 0 0-41.8-17.12c-18.57-5.36-38.37-8.24-59.03-8.24-58.62 0-111.7 23.76-150.11 62.18-38.42 38.41-62.18 91.48-62.18 150.11 0 58.62 23.76 111.69 62.18 150.11 34.81 34.81 81.66 57.59 133.77 61.55 14.9 1.13 30.23.76 44.99-1.16zm-67.09-312.63c0-10.71 8.69-19.4 19.41-19.4 10.71 0 19.4 8.69 19.4 19.4V276.7l80.85 35.54c9.8 4.31 14.24 15.75 9.93 25.55-4.31 9.79-15.75 14.24-25.55 9.93l-91.46-40.2c-7.35-2.77-12.58-9.86-12.58-18.17V158.58z"></path>
      </svg>
    `;
  }

  function attachEvents() {
    document.querySelectorAll("[data-link]").forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        routeTo(link.dataset.link);
      });
    });

    document.querySelectorAll("[data-go]").forEach((node) => {
      node.addEventListener("click", () => routeTo(node.dataset.go));
    });

    const logoutLink = document.querySelector("[data-logout]");
    if (logoutLink) {
      logoutLink.addEventListener("click", async (event) => {
        event.preventDefault();
        try {
          await request("/logout", { method: "GET" });
        } catch {
          // Logging out locally is still useful if the network request fails.
        }
        clearAuth();
        routeTo("/login");
      });
    }

    const loginForm = document.querySelector("[data-login]");
    if (loginForm) {
      loginForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const data = Object.fromEntries(new FormData(loginForm).entries());
        const error = loginForm.querySelector("[data-error]");
        error.hidden = true;
        try {
          const normal = loginForm.dataset.login === "normal";
          const result = await formRequest(normal ? "/login" : "/adminlogin", data);
          if (result.status !== 0) throw new Error(result.msg || "Login failed.");
          saveAuth({
            username: result.meta?.attempted_username || data.username,
            name: result.meta?.name || data.username,
            email: result.meta?.email || "",
            role: normal ? "User" : "Admin",
            expires: Date.now() + 24 * 60 * 60 * 1000
          });
          state.photosLoaded = false;
          state.usersLoaded = false;
          state.profileLoaded = false;
          routeTo(normal ? "/upload" : "/");
          if (!normal) await loadPhotos({});
        } catch (err) {
          error.textContent = err.message;
          error.hidden = false;
        }
      });
    }

    const resetForm = document.querySelector("[data-reset]");
    if (resetForm) {
      resetForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const error = resetForm.querySelector("[data-error]");
        error.hidden = true;
        try {
          const result = await formRequest("/resetpassword", Object.fromEntries(new FormData(resetForm).entries()));
          if (result.status !== 0) throw new Error(result.msg || "Password reset failed.");
          toast(result.msg || "Password changed.");
          routeTo("/login");
        } catch (err) {
          error.textContent = err.message;
          error.hidden = false;
        }
      });
    }

    const profileForm = document.querySelector("[data-profile-update]");
    if (profileForm) {
      profileForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const error = profileForm.querySelector("[data-error]");
        error.hidden = true;
        try {
          const result = await formRequest("/user", Object.fromEntries(new FormData(profileForm).entries()));
          if (result.status !== 0) throw new Error(result.msg || "Profile update failed.");
          saveAuth({
            ...state.user,
            name: result.meta?.name || profileForm.elements.name.value,
            email: result.meta?.email || profileForm.elements.email.value
          });
          state.profileLoaded = true;
          toast(result.msg || "Profile updated.");
          render();
        } catch (err) {
          error.textContent = err.message;
          error.hidden = false;
        }
      });
    }

    const filter = document.querySelector("[data-filter]");
    if (filter) {
      filter.addEventListener("submit", async (event) => {
        event.preventDefault();
        const query = Object.fromEntries(new FormData(filter).entries());
        routeTo(withQuery(currentPath(), query));
        await loadPhotos(query);
      });
    }

    const geoFilter = document.querySelector("[data-geo-filter]");
    if (geoFilter) {
      geoFilter.addEventListener("submit", async (event) => {
        event.preventDefault();
        const query = Object.fromEntries(new FormData(geoFilter).entries());
        routeTo(withQuery(currentPath(), query));
        await loadPhotos(query);
      });
    }

    document.querySelectorAll("[data-refresh]").forEach((button) => {
      button.addEventListener("click", () => loadPhotos(Object.fromEntries(routeParams().entries())));
    });

    document.querySelectorAll("[data-delete]").forEach((button) => {
      button.addEventListener("click", () => {
        state.pendingDeleteId = button.dataset.delete;
        render();
      });
    });

    const cancelDelete = document.querySelector("[data-cancel-delete]");
    if (cancelDelete) {
      cancelDelete.addEventListener("click", () => {
        state.pendingDeleteId = null;
        render();
      });
    }

    const confirmDelete = document.querySelector("[data-confirm-delete]");
    if (confirmDelete) {
      confirmDelete.addEventListener("click", () => deletePhoto(confirmDelete.dataset.confirmDelete));
    }

    document.querySelectorAll("[data-edit]").forEach((button) => {
      button.addEventListener("click", () => editPhoto(button.dataset.edit));
    });

    document.querySelectorAll("[data-export]").forEach((button) => {
      button.addEventListener("click", () => exportData(button.dataset.export));
    });

    attachUploadEvents();
  }

  async function editPhoto(id) {
    const photo = state.photos.find((item) => item.id === id);
    if (!photo) return;
    const notes = prompt("Notes", photo.notes || "");
    if (notes == null) return;
    const tags = prompt("Tags", photo.tags || "");
    if (tags == null) return;
    try {
      const result = await formRequest("/adminupdatephotoinfo", { photo_id: id, notes, tags });
      if (result.status !== 0) throw new Error(result.msg || "Update failed.");
      toast(result.msg || "Updated.");
      await loadPhotos(state.lastQuery);
    } catch (error) {
      toast(error.message);
    }
  }

  async function deletePhoto(id) {
    try {
      const result = await formRequest("/deletephoto", { photo_id: id });
      if (result.status !== 0) throw new Error(result.msg || "Delete failed.");
      toast(result.msg || "Deleted.");
      state.pendingDeleteId = null;
      state.photosLoaded = false;
      await loadPhotos(Object.fromEntries(routeParams().entries()));
    } catch (error) {
      state.pendingDeleteId = null;
      toast(error.message);
      render();
    }
  }

  function attachUploadEvents() {
    const picker = document.getElementById("file");
    const pickButton = document.querySelector("[data-pick-file]");
    const uploadButton = document.querySelector("[data-submit-upload]");
    if (!picker || !pickButton || !uploadButton) return;

    pickButton.addEventListener("click", () => picker.click());
    picker.addEventListener("change", () => {
      state.uploadFiles = Array.from(picker.files || []).map((file, index) => ({
        file,
        src: URL.createObjectURL(file),
        gps: sampleGps(index),
        note: "",
        progress: 0,
        status: "Ready",
        statusClass: ""
      }));
      render();
    });

    document.querySelectorAll("[data-upload-gps]").forEach((input) => {
      input.addEventListener("input", () => {
        state.uploadFiles[Number(input.dataset.uploadGps)].gps = input.value;
      });
    });

    document.querySelectorAll("[data-upload-note]").forEach((input) => {
      input.addEventListener("input", () => {
        state.uploadFiles[Number(input.dataset.uploadNote)].note = input.value;
      });
    });

    document.querySelectorAll("[data-remove-upload]").forEach((button) => {
      button.addEventListener("click", () => {
        state.uploadFiles.splice(Number(button.dataset.removeUpload), 1);
        render();
      });
    });

    uploadButton.addEventListener("click", runUpload);
  }

  function sampleGps(index) {
    const samples = ["38.952,-92.329", "37.421997,-122.084", "40.7128,-74.0060", "29.7604,-95.3698"];
    return samples[index % samples.length];
  }

  function validGps(value) {
    const parts = String(value).replaceAll(" ", "").split(",").map(Number);
    return parts.length === 2 && Number.isFinite(parts[0]) && Number.isFinite(parts[1]) && Math.abs(parts[0]) <= 90 && Math.abs(parts[1]) <= 180;
  }

  async function runUpload() {
    if (!state.uploadFiles.length) return;
    if (!state.uploadFiles.every((item) => validGps(item.gps))) {
      toast("Format error: Please input correct gps locations.");
      return;
    }
    for (let index = 0; index < state.uploadFiles.length; index += 1) {
      const item = state.uploadFiles[index];
      item.status = "Uploading";
      item.statusClass = "";
      item.progress = 35;
      render();
      const body = new FormData();
      body.append("photo", item.file, item.file.name);
      body.append("gps", item.gps.replaceAll(" ", ""));
      body.append("notes", item.note || "");
      try {
        const result = await request("/photoupload", { method: "POST", body });
        if (result.status !== 0) throw new Error(result.msg || "Upload failed.");
        item.progress = 100;
        item.status = `Successful. Result: ${result.meta?.result ?? ""}`;
        item.statusClass = "success";
      } catch (error) {
        item.progress = 100;
        item.status = error.message;
        item.statusClass = "failed";
      }
      render();
    }
    if (state.user?.role === "Admin") await loadPhotos({});
  }

  function exportData(kind) {
    const list = state.photos;
    const text = kind === "json"
      ? JSON.stringify(list, null, 2)
      : [
          "Photo ID,GPS,Location,Date,Result,Note,Tags,Uploaded By",
          ...list.map((p) => [p.id, p.gps, p.detailed_gps, p.date, p.result, p.notes, p.tags, p.username].map(csvCell).join(","))
        ].join("\n");
    const blob = new Blob([text], { type: kind === "json" ? "application/json" : "text/csv" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `Photo-${new Date().toISOString().slice(0, 10)}.${kind}`;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  function csvCell(value) {
    return `"${String(value || "").replaceAll('"', '""')}"`;
  }

  function toast(message) {
    const old = document.querySelector(".toast");
    if (old) old.remove();
    const node = document.createElement("div");
    node.className = "toast";
    node.textContent = message;
    document.body.appendChild(node);
    setTimeout(() => node.remove(), 3200);
  }

  function syncRouteData() {
    if (state.user?.role === "Admin" && ["/", "/table", "/mapview/global", "/analysis"].includes(currentPath()) && !state.loading && !state.photosLoaded) {
      loadPhotos(Object.fromEntries(routeParams().entries()));
    }
    if (state.user?.role === "Admin" && currentPath() === "/users" && !state.loading && !state.usersLoaded) {
      loadUsers();
    }
    if (state.user && currentPath() === "/profile" && !state.profileLoaded) {
      loadProfile();
    }
  }

  function render() {
    const publicPaths = ["/login", "/normallogin", "/adminlogin", "/resetpassword"];
    const path = currentPath();
    if (!state.user && !publicPaths.includes(path)) {
      location.hash = "/login";
    }
    if (state.user && ["/login", "/normallogin", "/adminlogin"].includes(path)) {
      location.hash = state.user.role === "Admin" ? "/" : "/upload";
    }

    const activePath = currentPath();
    if (activePath === "/login" || activePath === "/normallogin") app.innerHTML = loginPage("normal");
    else if (activePath === "/adminlogin") app.innerHTML = loginPage("admin");
    else if (activePath === "/resetpassword") app.innerHTML = resetPage();
    else if (activePath === "/") app.innerHTML = gridPage();
    else if (activePath === "/table") app.innerHTML = tablePage();
    else if (activePath.startsWith("/mapview")) app.innerHTML = mapPage(activePath.split("/").pop());
    else if (activePath === "/upload" || activePath === "/mobileupload") app.innerHTML = uploadPage();
    else if (activePath === "/profile") app.innerHTML = profilePage();
    else if (activePath === "/users") app.innerHTML = usersPage();
    else if (activePath === "/analysis") app.innerHTML = analysisPage();
    else routeTo("/");
    attachEvents();
    syncRouteData();
    if (currentPath().startsWith("/mapview")) {
      setTimeout(initRealMap, 0);
    }
  }

  window.addEventListener("hashchange", render);
  render();
})();
