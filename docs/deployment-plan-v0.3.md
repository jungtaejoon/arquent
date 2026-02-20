# Deployment Plan v0.3 (Execution-Ready)

## 1) Readiness verdict

Current state is **deployable for public beta** after this repo update:

- Cloud service can run in production mode with `PORT`, `HOST`, `CORS_ORIGIN`
- Flutter Web can target non-local API via `--dart-define=API_BASE_URL=...`
- CI gates exist for Rust core, Cloud, Flutter web build
- Cloud container image build is defined (Dockerfile)

## 2) What was upgraded now

- Cloud runtime config via env vars
- Cloud production start script (`npm run start`)
- Cloud Dockerfile for image deployment
- GitHub Actions CI (`.github/workflows/ci.yml`)
- Flutter API base URL configuration (`API_BASE_URL`)

## 3) Chosen low-cost targets

- Cloud API: **Railway** (small paid tier, easy container deploy)
- Flutter Web: **Cloudflare Pages** (free static hosting)

Why this combo:

- lowest monthly cost while keeping setup simple
- fast global web delivery via Cloudflare edge
- predictable API deployment and logs on Railway

Estimated monthly cost (as of now, may vary by provider plan):

- Cloudflare Pages: $0 on free tier for this MVP scale
- Railway API: typically starts around $5/month usage-based

## 4) Exact execution steps

### A. Cloud API deploy (Railway)

From `app/cloud` (already configured with `railway.toml`):

```bash
npm ci
npm run test
npm run build
docker build -t arquent-cloud:0.3.0 .
```

Set runtime env vars in hosting platform:

- `PORT=4000` (or platform default)
- `HOST=0.0.0.0`
- `CORS_ORIGIN=https://<your-web-domain>`

Health check endpoint for quick verification:

```bash
curl -s https://<your-api-domain>/marketplace/recipes
```

### B. Flutter Web deploy (Cloudflare Pages)

Use helper script from repo root:

```bash
./scripts/build_web_prod.sh https://<your-api-domain>
```

Deploy generated artifacts:

- upload `app/flutter_client/build/web` to static hosting

Cloudflare Pages build settings (if using Git integration):

- Framework preset: `None`
- Build command: `./scripts/build_web_prod.sh https://<your-api-domain>`
- Output directory: `app/flutter_client/build/web`

## 5) Go-live checklist

- CI green on main branch
- Cloud endpoint reachable from browser domain (CORS)
- Marketplace publish/refresh/install/run tested once on production URL
- Sensitive recipe policy still enforced (user-initiated gate)

## 6) Staging + production strategy (recommended)

- Branches:
	- `staging` → staging deployment validation
	- `main` → production deployment
- GitHub Actions behavior (`.github/workflows/ci.yml`):
	- Pull Request: tests only
	- Push to `staging`/`main`: tests + build
	- Push to `staging`: staging smoke test
	- Push to `main`: production smoke test

Required GitHub Repository Variables:

- `STAGING_API_URL`
- `STAGING_WEB_URL`
- `PROD_API_URL`
- `PROD_WEB_URL`

Smoke test checks:

- API `GET /marketplace/recipes` returns success
- Web domain returns successful HTTP headers

## 7) User input needed

Please provide these 2 values so I can complete final production wiring:

1. API domain on Railway: `https://...`
2. Web domain on Cloudflare Pages: `https://...`
