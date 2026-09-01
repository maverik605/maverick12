# MAVERICK — AI Voice Agent & AI Automation Specialist

A complete, clean, premium portfolio website with a private admin dashboard.

Full-stack Node.js app (Express + SQLite) that runs wherever a Node server runs —
**Railway** is the recommended (and simplest) host. It runs the exact same
`node server/index.js` you use locally — no serverless functions, no extra config.

---

## Quick start (local)

```bash
npm install
npm start
```
Open **http://localhost:3001** — admin at **http://localhost:3001/#/admin** (default `admin` / `maverick2026`).

---

## 🚀 Deploying to Railway (recommended)

Railway runs your app as a persistent container. Because it isn't serverless,
the Express server, file uploads, and (with a volume) the SQLite database all just work.

### 1. Run the SQL schema + Storage (optional but recommended)

If you'd rather keep a cloud Postgres database you can still use Supabase for
data — see the "Supabase (optional)" section below. **For the simplest setup,
skip it** and let Railway persist SQLite on a volume instead.

### 2. Push the project to a Git repo

The repo root is `maverick/`. Push it to GitHub/GitLab, then in Railway:

1. **New Project → Deploy from GitHub repo** → select your repo.
2. Railway will build the image from the included **`Dockerfile`**. (It can also
   auto-detect Node, but the Dockerfile gives a predictable runtime.)

### 3. Add a persistent volume

Railway's default container filesystem is wiped on each deploy. To keep your
database and uploads, create a **Volume** and mount it at **`/app/.data`**.

Once mounted, add the following **Service → Variables**:

```
DB_PATH=/app/.data/maverick.db
MEDIA_DIR=/app/.data/uploads
```

> The `Dockerfile` already sets these defaults, so you only need the volume if
> you want data to **persist across deploys and restarts** (yes — do this).

### 4. Expose the port

Railway automatically injects a `PORT` variable and maps it. The app listens on
`process.env.PORT || 3001`, so just make sure a port is assigned (Set a
**Public Networking** domain). Then set the **healthcheck** path to `/health`.

### 5. Create / reset the admin account

The first time the app boots it auto-creates the admin:

```
username: admin
password: maverick2026
```

**Change this immediately.** To set your own, run (locally, or with volume env):

```bash
node scripts/create-admin.js YOUR_USERNAME YOUR_STRONG_PASSWORD
```

### Done

Your site is live at the Railway URL. Admin dashboard: `https://your-app.up.railway.app/#/admin`.

---

## Data & storage

| Item | Default (no volume) | With volume (recommended) |
|------|--------------------|----------------------------|
| Database | `data/maverick.db` (local) | `DB_PATH=/app/.data/maverick.db` |
| Uploads | `public/uploads/` | `MEDIA_DIR=/app/.data/uploads` |

Both are controlled by env vars, so pointing them at a mounted volume makes the
database and all uploaded images/videos persist across deploys and restarts.

---

## Supabase (optional)

The app also ships a Supabase adapter for cloud Postgres + Storage, if you'd
prefer that over a Railway volume. Set these env vars and it switches
automatically (SQLite → Supabase):

```
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_ANON_KEY=...
SUPABASE_STORAGE_BUCKET=maverick-media
```

Set up the tables with **`supabase/schema.sql`** (run in Supabase's SQL Editor)
and create a public **`maverick-media`** Storage bucket. See the
"Deploying to Supabase" section in the commit history / earlier docs.

> You don't need Supabase for Railway + volume. It's purely optional.

---

## Admin dashboard

**http://your-site.com/#/admin** (also linked in the footer).

- **Dashboard** — total/published projects, total/unread messages, recent activity.
- **Projects** — search, filter by category, sort newest/oldest/name, featured/published filters.
- **Add / Edit Project** — name, short description, full description (max **3,000 chars** + live counter), category (choose or type), tools/technologies, image upload, video upload or URL, demo URL, featured toggle, publish/draft toggle, project date.
- **Delete project** — with confirmation.
- **Messages** — view submissions, mark read/unread, delete, search.

---

## Project structure

```
maverick/
├─ server/
│  ├─ index.js          # Express app (API + static + SPA + healthcheck)
│  ├─ config.js         # provider selection + env config
│  ├─ db.js             # SQLite schema + seed admin
│  ├─ auth.js           # session auth helpers
│  └─ store/            # (optional) SQLite / Supabase adapters
├─ public/              # frontend (index.html, css, js)
├─ Dockerfile           # production image (Railway)
├─ scripts/create-admin.js
└─ vercel.json          # optional Vercel config (only if you deploy to Vercel)
```

---

## API overview

| Method | Route | Auth | Purpose |
|--------|-------|------|---------|
| POST | `/api/auth/login` | – | Admin login |
| POST | `/api/auth/logout` | ✓ | Logout |
| GET  | `/api/auth/me` | ✓ | Current admin |
| GET  | `/api/portfolio` | – | Public projects (paginated, filtered) |
| GET  | `/api/portfolio/:id` | – | Public project detail |
| GET  | `/api/portfolio/categories/all` | – | Public category list |
| POST | `/api/contact` | – | Submit contact form |
| GET  | `/api/admin/stats` | ✓ | Dashboard stats |
| GET  | `/api/admin/portfolio` | ✓ | List/manage projects |
| GET/POST/PUT/DELETE | `/api/admin/portfolio/:id` | ✓ | Project CRUD |
| POST | `/api/admin/media` | ✓ | Upload image/video |
| GET/PATCH/DELETE | `/api/admin/contact/:id` | ✓ | Manage messages |
| GET  | `/health` | – | Health check (Railway) |

### Environment variables

- `PORT` — server port (Railway injects this; default `3001`).
- `DB_PATH` — SQLite file path (`/app/.data/maverick.db` on a volume).
- `MEDIA_DIR` — uploads directory (`/app/.data/uploads` on a volume).
- `NODE_ENV=production` — secure cookie.
- Supabase keys (optional — see above).

---

## Security notes

- Passwords hashed with bcrypt (12 rounds); custom session login, HTTP-only cookie, secure flag in production.
- All admin routes require a valid session; public routes expose only published projects.
- Forms validated client & server; descriptions hard-capped at 3,000 chars (DB CHECK + app + client).
- Uploads validated by MIME type + extension.
