# CookShare — agent notes

> *From their kitchen, to yours.*

A social-first app for home cooks. Laravel 12 + PostGIS API, Flutter 3.38 mobile app. Monorepo: `backend/` + `app/`.

## Run locally

```bash
# Backend (PostgreSQL with PostGIS extension required)
cd backend && php artisan serve --port=8001

# Mobile (Android emulator uses 10.0.2.2 instead of localhost — already
# configured in app/lib/core/api/api_config.dart)
cd app && flutter run
```

`php artisan migrate --seed` creates 6 demo cooks (all share password `password`), 15 posts, 6 active stories, demo follow graph wired so the feed and map are populated immediately.

## Architecture rules

- **Bucket-private + presigned URLs** is intentional. Don't switch S3 to public-read without explicit user approval.
- **Photos route through `/api/v1/img-proxy`** for whitelisted hosts (picsum, placehold) because the Android emulator has broken DNS. The allow-list is in `MapController::imageProxy`. Don't widen it.
- **OSM and AWS Location tiles are both proxied through the backend** (`/map/osm/{z}/{x}/{y}` and `/map/tiles/{z}/{x}/{y}`). Same emulator-DNS reason. Public, unauthenticated, but locked to `geo:GetMapTile`.
- **`whatsapp_at_post`** on the `stories` table is a snapshot — don't pull it from the user record at read time, or editing the profile would rewrite history.
- **Stories have a generated PostGIS column** (`location geography(Point, 4326) GENERATED ALWAYS AS (...)`) and a GIST index. Writes use raw `lat`/`lng`; reads can use `ST_DWithin`.
- **Phase 1 stays social.** Marketplace work (real payments, in-app chat, reservations) belongs in Phase 2. Stories' "Available to buy" is a deliberately thin layer — it deeplinks to WhatsApp and is cash-on-pickup. Don't pull Stripe/bKash forward into Phase 1.

## Phase 2 — must-have before more cook recruitment

**NSFW + non-food image moderation on every photo upload.** This is the user's #1 trust requirement and the next thing to build. Plan:
- AWS Rekognition `DetectModerationLabels` rejects Explicit Nudity / Suggestive / Violence / Drugs.
- AWS Rekognition `DetectLabels` requires at least one food label (Food, Meal, Dish, Cuisine, Dessert, etc.) above a confidence threshold.
- Reject = delete the row + S3 object + return 422 with a clear message. Clean = no-op.
- Default to async: S3 ObjectCreated event → Lambda → Rekognition → patch the row. Sync inline in `posts/store` + `stories/store` is fine for MVP if Lambda setup is a yak.

## Source of truth

- **Plan file**: `/Users/mdomerarafat/.claude/plans/cookshare-souds-good-binary-mitten.md` — full feature roadmap and original scaffold plan.
- **Memory**: `/Users/mdomerarafat/.claude/projects/-Users-mdomerarafat/memory/project_cookshare.md` — running notes about AWS infra, decisions, demo data shape, this Phase 2 moderation requirement.
- **GitHub**: https://github.com/arafatomer66/cookshare (private).

## Don'ts

- Don't commit `.env`. The `.gitignore` blocks it but never bypass.
- Don't add real AWS credentials anywhere in source. They live in `~/.aws/credentials` or `backend/.env` only.
- Don't run `flutter clean` casually on emulator — last time it freed 675MB but also wiped the simulator's installed app and re-running took ~5min for a fresh build.
- Don't fetch fonts over the network in the app — Google Fonts CDN is unreachable from the user's emulator. We use system fonts (`.SF Pro Text` + `Roboto` fallback). Don't add `google_fonts` back.
