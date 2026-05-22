# Production Deployment Checklist

**Last Updated:** 2026-05-22  
**Status:** Ready with critical issues to resolve

---

## ⚠️ CRITICAL ISSUES TO RESOLVE FIRST

Before attempting production deployment, these issues MUST be fixed:

### 1. Fix Dockerfile.api
- [ ] Update `music-catalog-core/Dockerfile.api` to match actual project structure
- [ ] Change build command from `npm run build:shared && npm run build:api` to `npm run build`
- [ ] Change start command from `npm run dev:api` to `npm start`
- [ ] Verify image builds successfully: `docker build -f music-catalog-core/Dockerfile.api -t media-platform-api ./music-catalog-core`

### 2. Add PostgreSQL to docker-compose.yml
- [ ] Add `postgres` service to `docker-compose.yml`
- [ ] Configure connection string: `postgresql://user:password@postgres:5432/music_catalog`
- [ ] Add health check for postgres service
- [ ] Update API `depends_on` to include postgres with health check
- [ ] Verify migrations run automatically or document manual steps

### 3. Create Environment Files
- [ ] Copy `music-catalog-core/.env.example` to `music-catalog-core/.env`
- [ ] Copy `.env.example` to `.env` in root
- [ ] Fill in actual values for production:
  - [ ] Clerk API keys (SECRET_KEY, JWT_ISSUER, JWKS_URL)
  - [ ] Supabase credentials (URL, SERVICE_ROLE_KEY)
  - [ ] Cloudflare R2 credentials (all R2_* variables)
  - [ ] Database URL (PostgreSQL connection)
  - [ ] Redis URL (currently `redis://redis:6379`)
  - [ ] CORS origins (update to production domains)
  - [ ] Vite Clerk publishable key

### 4. Resolve Git Repository Issues
- [ ] Decide: Keep `music-catalog-core/` and `soundloom-core/` as full clones or convert to git submodules?
- [ ] If keeping as clones: Update `.gitignore` to include these directories
- [ ] If using submodules: Convert with `git submodule add` and remove from `.gitignore`
- [ ] Document chosen strategy in `docs/REPOSITORY_STRATEGY.md`

---

## 🔧 PRE-DEPLOYMENT SETUP

### Server & Infrastructure
- [ ] Provision Linux server (Ubuntu 22.04 LTS recommended)
- [ ] Install Docker: `curl -fsSL https://get.docker.com | sh`
- [ ] Install Docker Compose: `curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose`
- [ ] Install Nginx: `apt-get install nginx`
- [ ] Setup SSL/TLS certificates (Let's Encrypt recommended)
  - [ ] `api.mediarosenqvist.com`
  - [ ] `catalogusmusicus.mediarosenqvist.com`

### DNS Configuration
- [ ] Verify DNS records point to server IP:
  - [ ] `api.mediarosenqvist.com` → server IP
  - [ ] `catalogusmusicus.mediarosenqvist.com` → server IP
- [ ] Test DNS propagation

### Directory Structure
- [ ] Create deployment directory: `/opt/media-platform/`
- [ ] Clone repository: `git clone <repo-url> /opt/media-platform`
- [ ] Set ownership: `chown -R deploy:deploy /opt/media-platform`
- [ ] Set permissions: `chmod 750 /opt/media-platform`

### Database Setup
- [ ] Create PostgreSQL database backup strategy
- [ ] Document connection pooling settings (if needed)
- [ ] Setup automatic backups (if not in Docker)
- [ ] Test database migrations on staging first

---

## 🚀 DEPLOYMENT STEPS

### 1. Validate Configuration
```bash
cd /opt/media-platform
# Check all required files exist
[ -f .env ] && echo "✓ .env exists" || echo "✗ .env missing"
[ -f music-catalog-core/.env ] && echo "✓ music-catalog-core/.env exists" || echo "✗ missing"
[ -f docker-compose.yml ] && echo "✓ docker-compose.yml exists" || echo "✗ missing"

# Validate Dockerfiles
docker build -f music-catalog-core/Dockerfile.api -t test-api . && echo "✓ API Dockerfile valid"
```

### 2. Build Docker Images
- [ ] Build API image: `docker compose build api`
- [ ] Build frontend image: `docker compose build frontend`
- [ ] Build succeeds without errors: `docker compose build`
- [ ] Test image runs locally: `docker compose up -d`

### 3. Run Database Migrations
- [ ] Connect to running postgres container: `docker compose exec postgres psql -U postgres -d music_catalog`
- [ ] Execute migrations (method TBD - verify with music-catalog-core repo)
- [ ] Verify tables created: `\dt` in psql
- [ ] Test API health: `curl http://localhost:3000/health`

### 4. Configure Nginx
- [ ] Copy config files to Nginx:
  ```bash
  sudo cp nginx/api.mediarosenqvist.com.conf /etc/nginx/sites-available/
  sudo cp nginx/catalogusmusicus.mediarosenqvist.com.conf /etc/nginx/sites-available/
  ```
- [ ] Enable sites: `sudo ln -s /etc/nginx/sites-available/api.* /etc/nginx/sites-enabled/`
- [ ] Update SSL certificates in configs (or use Certbot)
- [ ] Test Nginx config: `sudo nginx -t`
- [ ] Reload Nginx: `sudo systemctl reload nginx`
- [ ] Test domain routing works

### 5. Start Services
```bash
cd /opt/media-platform
./scripts/start.sh
# or
docker compose up -d
```

### 6. Verify Services Are Running
- [ ] Check container status: `docker compose ps`
- [ ] All containers show `healthy` or `up`
- [ ] API responds: `curl http://api.mediarosenqvist.com/health`
- [ ] Frontend loads: `curl http://catalogusmusicus.mediarosenqvist.com`
- [ ] Redis is healthy: `docker compose exec redis redis-cli ping` → `PONG`
- [ ] Database is accessible: `docker compose exec postgres pg_isready`

---

## ✅ POST-DEPLOYMENT VERIFICATION

### Application Functionality
- [ ] Login flow works (test with Clerk)
- [ ] Music catalog loads in frontend
- [ ] Can upload/create music entries
- [ ] File storage works (R2 integration)
- [ ] Search functionality works
- [ ] API returns correct CORS headers

### Monitoring & Logging
- [ ] Check logs for errors: `./scripts/logs.sh`
- [ ] API logs show healthy startup
- [ ] Frontend served successfully
- [ ] No 5xx errors in logs
- [ ] Redis connected messages appear

### Performance & Load Testing
- [ ] Test API with `ab` or `wrk`: `ab -n 100 -c 10 http://api.mediarosenqvist.com/health`
- [ ] Monitor Docker resource usage: `docker stats`
- [ ] Verify no memory leaks
- [ ] Response times acceptable

### Security Verification
- [ ] SSL/TLS working: `curl -I https://api.mediarosenqvist.com` shows 200 OK
- [ ] Redirect HTTP → HTTPS (configure in Nginx)
- [ ] `.env` file not exposed: `curl https://api.mediarosenqvist.com/.env` returns 404
- [ ] No secrets in logs: `./scripts/logs.sh | grep -i "key\|secret\|password"` returns nothing
- [ ] CORS properly restricted

### Backup & Recovery
- [ ] Database backup created: `docker compose exec postgres pg_dump -U postgres music_catalog > backup.sql`
- [ ] Backup stored securely (separate from server)
- [ ] Test restore procedure on non-prod environment

---

## 📊 ONGOING MAINTENANCE

### Daily Checks
- [ ] Review logs for errors: `./scripts/logs.sh | grep ERROR`
- [ ] Verify all services healthy: `./scripts/status.sh`
- [ ] Check disk space: `df -h`
- [ ] Monitor CPU/Memory: `docker stats`

### Weekly Checks
- [ ] Backup database
- [ ] Review Nginx error logs
- [ ] Check for updates to Docker images
- [ ] Verify SSL certificate expiry (if manual renewal)

### Monthly Checks
- [ ] Review application performance metrics
- [ ] Plan capacity scaling if needed
- [ ] Update documentation with any changes
- [ ] Security audit of `.env` values

### Monthly Updates
- [ ] Pull latest changes: `./scripts/update-repos.sh`
- [ ] Rebuild images: `./scripts/rebuild.sh`
- [ ] Test on staging environment first
- [ ] Schedule maintenance window
- [ ] Deploy to production: `./scripts/start.sh`

---

## 🆘 TROUBLESHOOTING

### API Won't Start
```bash
# Check logs
docker compose logs api

# Verify .env file has all required variables
grep -E "^[A-Z_]+=" music-catalog-core/.env | wc -l

# Test build
docker compose build api --no-cache
```

### Database Connection Fails
```bash
# Check postgres is running
docker compose ps postgres

# Test connection
docker compose exec postgres psql -U postgres -d music_catalog -c "SELECT 1"

# Verify DATABASE_URL format
echo $DATABASE_URL
```

### Frontend Not Loading
```bash
# Check frontend logs
docker compose logs frontend

# Verify build output
docker compose exec frontend ls -la /usr/share/nginx/html/

# Check Nginx config
docker compose exec frontend cat /etc/nginx/conf.d/default.conf
```

### Redis Connection Issues
```bash
# Check Redis health
docker compose exec redis redis-cli ping

# Check REDIS_URL in .env
grep REDIS_URL music-catalog-core/.env
```

### SSL/Certificate Issues
```bash
# Check certificate expiry
openssl s_client -connect api.mediarosenqvist.com:443 -servername api.mediarosenqvist.com | grep -A2 "Not After"

# Renew with Certbot (if using Let's Encrypt)
sudo certbot renew
```

---

## 📝 DOCUMENTATION REFERENCES

- **Repository Strategy**: See `docs/ARCHITECTURE.md`
- **API Documentation**: `music-catalog-core/docs/api.md`
- **Storage Architecture**: `music-catalog-core/STORAGE_ARCHITECTURE.md`
- **Frontend Integration**: `music-catalog-core/docs/FRONTEND_INTEGRATION.md`
- **Environment Variables**: `music-catalog-core/docs/ENV.md`
- **Troubleshooting**: `music-catalog-core/docs/TROUBLESHOOTING.md`

---

## 🔐 SECURITY CHECKLIST

- [ ] `.env` file is in `.gitignore`
- [ ] No secrets hardcoded in source code
- [ ] Database password is strong (>20 chars, random)
- [ ] Clerk keys are for production environment
- [ ] R2 credentials have limited permissions (read/write only for bucket)
- [ ] Supabase service role key stored securely
- [ ] SSL/TLS certificates are valid and auto-renewing
- [ ] Firewall configured to only allow necessary ports (80, 443)
- [ ] SSH access restricted (public key only, no password)
- [ ] Docker daemon doesn't expose socket to untrusted users
- [ ] Regular security updates applied to server OS

---

## ✨ COMPLETION

**Deployment Complete When:**
- [ ] All critical issues resolved
- [ ] All pre-deployment checklist items checked
- [ ] All deployment steps completed successfully
- [ ] All post-deployment verification tests passed
- [ ] Security checklist completed
- [ ] Monitoring and logging verified working
- [ ] Team trained on maintenance procedures
- [ ] Incident response plan documented

**Sign-off:**
- [ ] Deployment verified by: _________________ Date: _________
- [ ] Security review completed by: ____________ Date: _________
- [ ] Operations team ready: __________________ Date: _________
