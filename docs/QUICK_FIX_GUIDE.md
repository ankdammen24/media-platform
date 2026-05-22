# Quick Fix Guide - Get Production Ready in 90 Minutes

**Goal:** Fix all critical blockers to enable production deployment  
**Time estimate:** 90 minutes  
**Difficulty:** Easy (copy-paste fixes)

---

## Step 1: Fix Dockerfile.api (20 minutes)

**File:** `music-catalog-core/Dockerfile.api`

Replace entire contents with:
```dockerfile
FROM node:22-alpine
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy build artifacts
COPY tsconfig.json ./
COPY src ./src

# Build
RUN npm run build

# Run
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["npm", "start"]
```

**Verify:**
```bash
docker build -f music-catalog-core/Dockerfile.api -t test-api ./music-catalog-core
# Should complete without errors
```

---

## Step 2: Add PostgreSQL to docker-compose.yml (15 minutes)

**File:** `docker-compose.yml`

Add this after the redis service:

```yaml
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres_prod_password_change_me
      POSTGRES_DB: music_catalog
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
```

Update the `api` service's `depends_on`:
```yaml
  api:
    build:
      context: ./music-catalog-core
      dockerfile: Dockerfile.api
    env_file:
      - ./music-catalog-core/.env
    ports:
      - "3000:3000"
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    restart: unless-stopped
```

Add this at the very end of the file:
```yaml
volumes:
  postgres_data:
```

**Verify:**
```bash
docker compose config > /dev/null && echo "✓ Valid YAML"
```

---

## Step 3: Create Environment Files (30 minutes)

### Create music-catalog-core/.env

```bash
cp music-catalog-core/.env.example music-catalog-core/.env
```

Edit `music-catalog-core/.env` with actual values:

```env
DATABASE_URL=postgresql://postgres:postgres_prod_password_change_me@postgres:5432/music_catalog
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
CLERK_SECRET_KEY=sk_live_or_test_key_from_clerk
CLERK_JWT_ISSUER=https://clerk.your-domain.com
CLERK_JWKS_URL=https://clerk.your-domain.com/.well-known/jwks.json
STORAGE_PROVIDER=r2
R2_ACCOUNT_ID=your-r2-account-id
R2_ACCESS_KEY_ID=your-r2-access-key-id
R2_SECRET_ACCESS_KEY=your-r2-secret-access-key
R2_BUCKET=music-catalog
R2_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
R2_PUBLIC_BASE_URL=https://cdn.example.com
REDIS_URL=redis://redis:6379
PORT=3000
NODE_ENV=production
CORS_ORIGINS=https://soundloom-core.lovable.app,https://catalogusmusicus.mediarosenqvist.com,https://catalog.mediarosenqvist.com
```

**Important values to get:**
- `CLERK_SECRET_KEY` - from https://dashboard.clerk.com
- `SUPABASE_SERVICE_ROLE_KEY` - from Supabase project settings
- `R2_*` - from Cloudflare R2 dashboard
- `DATABASE_URL` - use password from postgres service above

### Create root .env

```bash
cp .env.example .env
```

Edit `.env` with values:

```env
VITE_CLERK_PUBLISHABLE_KEY=pk_live_or_test_key_from_clerk
FRONTEND_DOMAIN=catalogusmusicus.mediarosenqvist.com
API_DOMAIN=api.mediarosenqvist.com
VITE_API_BASE_URL=https://api.mediarosenqvist.com
```

**Verify:**
```bash
# Check files exist
[ -f music-catalog-core/.env ] && echo "✓ Backend .env created"
[ -f .env ] && echo "✓ Root .env created"

# Check they have content
wc -l music-catalog-core/.env .env
```

---

## Step 4: Test Everything (25 minutes)

### 4a. Build images
```bash
docker compose build
# Watch for any build errors
```

### 4b. Start services
```bash
docker compose up -d
# Wait 30 seconds for postgres to initialize
sleep 30
```

### 4c. Check health
```bash
# Show all containers
docker compose ps
# All should show "healthy" or "up"

# Test API
curl http://localhost:3000/health
# Should return: {"status":"ok"}

# Test frontend
curl http://localhost:8080
# Should return HTML

# Test Redis
docker compose exec redis redis-cli ping
# Should return: PONG

# Test Postgres
docker compose exec postgres pg_isready
# Should return: accepting connections
```

### 4d. View logs if issues
```bash
docker compose logs api        # API logs
docker compose logs frontend   # Frontend logs
docker compose logs postgres   # Database logs
```

### 4e. Cleanup
```bash
docker compose down
# Stack is now stopped, ready for production deployment
```

---

## Step 5: Optional - Fix Git Structure (10 minutes)

**Choose ONE:**

### Option A: Remove from gitignore (Simpler)
```bash
# Edit .gitignore
# Remove these lines:
# music-catalog-core/
# soundloom-core/
# Then add to commit
git add .gitignore
git commit -m "docs: keep app repos as full clones for simpler deployment"
```

### Option B: Convert to Submodules (Cleaner)
```bash
# Remove current directories from git tracking
git rm -r --cached music-catalog-core soundloom-core

# Add as submodules
git submodule add https://github.com/your-org/music-catalog-core music-catalog-core
git submodule add https://github.com/your-org/soundloom-core soundloom-core

# Commit
git commit -m "refactor: use git submodules for app repositories"
```

---

## Verification Checklist

- [ ] ✓ Dockerfile.api builds without errors
- [ ] ✓ docker-compose.yml is valid YAML
- [ ] ✓ music-catalog-core/.env exists and has values
- [ ] ✓ Root .env exists and has values
- [ ] ✓ All Docker images build successfully
- [ ] ✓ All containers start and become healthy
- [ ] ✓ API /health endpoint responds
- [ ] ✓ Frontend serves HTML
- [ ] ✓ Redis responds to ping
- [ ] ✓ Postgres accepts connections

---

## Common Issues & Fixes

### "Cannot find file" errors during docker build
→ Check file paths in Dockerfile match actual project structure

### "DATABASE_URL not set" error in api logs
→ Ensure music-catalog-core/.env exists with DATABASE_URL value

### "VITE_CLERK_PUBLISHABLE_KEY undefined" on frontend
→ Ensure root .env has VITE_CLERK_PUBLISHABLE_KEY value

### Postgres won't start
→ Check password doesn't have special chars, use quotes if needed

### Port already in use
→ Check what's running: `lsof -i :3000` then kill or change port

---

## Next Steps After Fixes

1. Follow `docs/PRODUCTION_DEPLOYMENT_CHECKLIST.md`
2. Deploy to staging environment first
3. Run smoke tests
4. Deploy to production during maintenance window
5. Monitor logs closely for first 24 hours

**Estimated total time:** 2-4 hours including testing and deployment
