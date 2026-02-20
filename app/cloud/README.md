# cloud scaffold

Minimal cloud API implementation for v0.3.

## Endpoints

- `POST /auth/login`
- `GET /marketplace/recipes`
- `POST /marketplace/publish` (includes signature verification)
- `POST /marketplace/publish-demo` (local demo helper; server signs/validates internally)
- `GET /marketplace/package/:id`
- `POST /webhook/:id` (rate-limited)
- `POST /sync/push`
- `GET /sync/pull`

## Security behavior

- Server validates package signatures before accepting publish requests.
- Webhook ingress is rate-limited using `@fastify/rate-limit`.
- Cloud stores metadata/package blobs only and does not execute recipes.

## Commands

```bash
cd app/cloud
npm install
npm run test
npm run dev
```

## Production deploy (Railway)

- Service root: `app/cloud`
- Config file: `railway.toml`
- Start command: `npm run start`
- Required env:
	- `HOST=0.0.0.0`
	- `PORT=4000` (or platform default)
	- `CORS_ORIGIN=https://<your-web-domain>`

Health check:

```bash
curl -s https://<your-api-domain>/marketplace/recipes
```
# cloud scaffold

Minimal cloud responsibilities:

- auth + sync metadata transport
- marketplace metadata/package registry
- signature validation defense-in-depth
- webhook ingest + push relay with rate limiting

Cloud never executes recipes and does not store local execution state.
