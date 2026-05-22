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

## Environment Setup

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Fill values as needed (especially `VITE_CLERK_PUBLISHABLE_KEY`).

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

## Safety

- Do not commit secrets.
- `.env` is gitignored.
- Common logs/temp/build/dependency artifacts are gitignored.
