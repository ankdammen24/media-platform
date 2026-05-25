# media-platform

Orchestration and deployment repository for the **Media Rosenqvist** platform.

This repository runs two existing projects together:

- `music-catalog-core` = backend/API
- `soundloom-core` = frontend, branded as **Catalogus Musicus**

> This repo intentionally does **not** merge application code from either project.

## Purpose

`media-platform` is the deployment/orchestration layer only. It manages Docker Compose, operational scripts, and infrastructure docs/config examples.

## Repository Strategy

- `music-catalog-core` remains the backend repository.
- `soundloom-core` remains the frontend repository.
- `media-platform` only orchestrates deployment.
- Future option: convert to git submodules or a monorepo later.

## Required Folder Layout

```text
/opt/media-platform/
├── docker-compose.yml
├── .env.example
├── README.md
├── docs/
├── scripts/
├── nginx/
├── music-catalog-core/
└── soundloom-core/
```

## Clone Existing Repos Into This Folder

From `/opt/media-platform`:

```bash
git clone <music-catalog-core-repo-url> music-catalog-core
git clone <soundloom-core-repo-url> soundloom-core
```

You can also replace sibling folders with git submodules later if desired.

## Internal Auth (Clerk-free) rollout

This repository now assumes internal JWT + refresh-cookie auth in `music-catalog-core` and **no Clerk integration** in either app.

Because app code is maintained in separate repositories, do the auth migration there:

- Backend (`music-catalog-core`): add `users` table, `/auth/*` routes, JWT access tokens, refresh cookie, `requireAuth`, `requireRole`, admin seed/setup, and role checks.
- Frontend (`soundloom-core`): add login page, in-memory access token handling, refresh flow, protected routes, user/role display, and logout.

### Required auth env vars (backend repo)

Set these in `music-catalog-core/.env`:

```bash
JWT_SECRET=
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_SECRET=
REFRESH_TOKEN_EXPIRES_IN=7d
ADMIN_EMAIL=
ADMIN_PASSWORD=
ADMIN_DISPLAY_NAME=
```

### CORS/cookie expectations

- Backend must allow frontend origin with `credentials: true`.
- Refresh cookie policy:
  - **dev/same-site**: `SameSite=Lax` (secure false on localhost)
  - **prod/cross-site**: `SameSite=None` + `Secure=true`

### Manual API checks (run against backend)

```bash
# register
curl -i -X POST http://127.0.0.1:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"StrongPass123!","displayName":"Test User"}'

# login (stores refresh cookie)
curl -i -c cookies.txt -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"StrongPass123!"}'

# /auth/me with bearer token
curl -i http://127.0.0.1:3000/auth/me \
  -H "Authorization: Bearer <ACCESS_TOKEN>"

# refresh using cookie
curl -i -b cookies.txt -X POST http://127.0.0.1:3000/auth/refresh

# logout
curl -i -b cookies.txt -X POST http://127.0.0.1:3000/auth/logout
```


## Troubleshooting: `docker compose up --build` fails in API build

If `api` image build fails on TypeScript errors under `music-catalog-core/src/...` (for example `TS2345 string | undefined` and role mismatch errors), the failure is coming from application code in **music-catalog-core**, not from this orchestration repo.

Use this sequence from `/opt/media-platform`:

```bash
# 1) verify sibling app repos exist
ls -la music-catalog-core soundloom-core

# 2) update both repos to latest branch state
./scripts/update-repos.sh

# 3) run backend typecheck/build directly to see the same errors quickly
cd music-catalog-core
npm ci
npm run build
```

Then fix the reported files inside `music-catalog-core` (e.g. `src/auth/requireAuth.ts`, `src/routes/*.routes.ts`) and rebuild the stack:

```bash
cd /opt/media-platform
docker compose up --build -d
```

> Tip: if you need frontend-only iteration while backend code is being fixed, run frontend locally in `soundloom-core` and keep API disabled until backend TypeScript errors are resolved.

## Environment Setup

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Fill values as needed.

3. Ensure `music-catalog-core/.env` exists because the `api` service reads it via `env_file`.

## Start the Stack

```bash
./scripts/start.sh
```

Or rebuild images first:

```bash
./scripts/rebuild.sh
```

## Stop the Stack

```bash
./scripts/stop.sh
```

## Check Status and Health

```bash
./scripts/status.sh
```

This checks:

- `docker compose ps`
- `http://127.0.0.1:3000/health`
- `http://127.0.0.1:8080`

## View Logs

```bash
./scripts/logs.sh
```

## Update App Repositories

```bash
./scripts/update-repos.sh
```

Behavior:

- Pulls latest changes in `music-catalog-core` when folder/repo exists.
- Pulls latest changes in `soundloom-core` when folder/repo exists.
- Prints clear skip messages when folders are missing or not git repositories.

## Domain Routing (Nginx)

Current domains:

- `api.mediarosenqvist.com`
- `catalogusmusicus.mediarosenqvist.com`

Example Nginx configs are provided:

- `nginx/api.mediarosenqvist.com.conf` routes to `http://127.0.0.1:3000`
- `nginx/catalogusmusicus.mediarosenqvist.com.conf` routes to `http://127.0.0.1:8080`

Nginx installation is not automated in this repo.

## Production Deployment

**⚠️ Status:** 4 critical issues identified, fixes documented.

Before deploying to production, review the deployment documentation:

1. **[DEPLOYMENT_README.md](./DEPLOYMENT_README.md)** - Overview and quick start
2. **[docs/PRODUCTION_READINESS.md](./docs/PRODUCTION_READINESS.md)** - Issues and status
3. **[docs/QUICK_FIX_GUIDE.md](./docs/QUICK_FIX_GUIDE.md)** - Step-by-step fixes (90 min)
4. **[docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md](./docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md)** - Full deployment procedures
5. **[docs/DEPLOYMENT_INDEX.md](./docs/DEPLOYMENT_INDEX.md)** - Navigation guide

## Safety

- Do not commit secrets.
- `.env` is gitignored.
- Common logs/temp/build/dependency artifacts are gitignored.
