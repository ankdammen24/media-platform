# Media Platform Architecture

## Purpose

`media-platform` orchestrates deployment for the Media Rosenqvist platform. It does **not** contain the application source code for backend or frontend.

## Repository Strategy

- `music-catalog-core` remains the backend/API repository.
- `soundloom-core` remains the frontend repository (branded as **Catalogus Musicus**).
- `media-platform` is responsible for orchestration and deployment only.
- Future option: migrate to Git submodules or a monorepo when needed.

## Target Server Layout

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

## Runtime Topology

- **api** service builds from `./music-catalog-core` and listens on host port `3000`.
- **redis** service uses `redis:7-alpine` and provides caching/session infrastructure.
- **frontend** service builds from `./soundloom-core` and listens on host port `8080`.

## Domain Routing

- `api.mediarosenqvist.com` → `http://127.0.0.1:3000`
- `catalogusmusicus.mediarosenqvist.com` → `http://127.0.0.1:8080`

Nginx configuration examples are provided in the `nginx/` directory. Installation and certificate provisioning are intentionally out of scope for this repository.
