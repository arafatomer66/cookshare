# 🍳 CookShare

> **Instagram for home cooks.** Share what you're cooking with neighbors, see who's cooking what nearby on a live map, and (if they're selling) message them on WhatsApp to grab a portion.

CookShare is a **social-first** app — we build the network of cooks and eaters first, and only after the social loop is alive do we layer on a marketplace. Phase 1 ships the social MVP plus an early WhatsApp-based portion-selling layer that costs nothing to operate and validates demand for real commerce in Phase 2.

---

## ✨ Features

### 📸 Posts (the feed)
- Create a post: photo + caption + dish name + cuisine + cooking time
- Auto-tagged location (PostGIS `geography(Point, 4326)`)
- **Following** and **Nearby** feed tabs with pull-to-refresh
- Like, comment, view post detail
- Edge-to-edge 4:5 photo cards with relative timestamps and a sale badge

### 🗺️ Live map
- Snapchat-style map showing every dish posted in the last 24 hours
- Clusters when zoomed out, individual pins when close
- Tap a pin → mini bottom-sheet → full post
- Toggle between *only people I follow* and *everyone nearby*
- Your own location dot, follow-mode toggle, refresh button
- OpenStreetMap tiles proxied through the backend (works on the Android emulator's broken DNS)
- AWS Location Service raster tiles available as an alternate basemap

### 👥 Cooks & connections
- Profiles with bio, dish count, follower count, recent dishes grid
- **Discover** tab with two pills: *Nearby* (PostGIS radius search) and *All cooks* (top by post count) — gracefully falls back when location is denied
- One-tap **Follow / Following** toggle right on each row — no profile dive needed
- **Search cooks by name** with debounced live results
- WhatsApp button on profiles for cooks who've added a number

### 🎬 Stories (24-hour ephemeral cooking moments)
- Instagram-style horizontal **rings strip** at the top of the feed
- Gradient ring when unviewed, gray when seen
- **Fullscreen viewer** with progress bars, tap-left/right to navigate, long-press to pause
- Optional **"Available to buy"** toggle — flips a cook's story into a mini-listing with portion count, price, and pickup area
- Buyers see a green **"Message cook on WhatsApp"** button that deeplinks `wa.me/<number>` with a prefilled message about the dish — **cash on pickup, no payments in-app**
- Cook-only **viewer analytics** (who viewed your story) — early signal for engagement
- Auto-expires after 24 hours via `expires_at` column on the `stories` table

### 🔐 Auth
- Email + password (no SMS — keeps friction and cost low)
- Sanctum bearer tokens, persisted on device with `GetStorage`
- Edit profile: name, bio, avatar URL, **WhatsApp number**, default location
- Auto-redirect to login on 401 from any API call

### 📤 Direct-to-S3 photo uploads
- Backend issues 15-minute presigned PUT URLs
- Mobile uploads photos straight to a **private** S3 bucket (no proxying through API)
- Backend issues 60-minute presigned GETs at read time — bucket stays private
- Allow-listed image proxy at `/api/v1/img-proxy?u=...` for public demo image hosts (so dev seed data renders on Android emulators with broken DNS)

### 🎨 Premium UI
- Refined warm palette (espresso ink + cream background + amber accent)
- System fonts (SF Pro on iOS, Roboto on Android) — no network fetch, crisp at small sizes
- 12 typographic variants, hairline borders, gradient FABs, glass chips on the map
- Light theme only (the user's preference across all their apps)

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────┐
│  Flutter app (GetX + Dio + flutter_map)    │
│  ─ Modules: auth, feed, map, post,         │
│    profile, discover, stories               │
└──────────────┬─────────────────────────────┘
               │ HTTPS  Authorization: Bearer <sanctum-token>
┌──────────────▼─────────────────────────────┐
│  Laravel 12 API  (PHP 8.4)                  │
│  ─ Sanctum bearer-token auth                │
│  ─ PostGIS geo queries (ST_DWithin)        │
│  ─ S3 presigned PUT/GET                    │
│  ─ AWS Location tile proxy + img proxy     │
└──────┬──────────────┬──────────────────────┘
       │              │
┌──────▼──────┐  ┌────▼─────────────────────┐
│ PostgreSQL  │  │ AWS                       │
│ + PostGIS   │  │ ─ S3 (cookshare-media-*)  │
└─────────────┘  │ ─ Location Service tiles  │
                 └───────────────────────────┘
```

### Stack at a glance

| Layer | Tech | Why |
|---|---|---|
| Backend | **Laravel 12** + PHP 8.4 | Latest, conventional, fast to iterate |
| Auth | **Sanctum** bearer tokens | Mobile-friendly, no session cookies |
| DB | **PostgreSQL 16** + **PostGIS** | Best-in-class geospatial — we're map-heavy |
| Geo package | `clickbar/laravel-magellan` | Eloquent-friendly PostGIS column casting |
| Storage | **AWS S3** (private bucket) | Presigned PUT/GET, no proxy needed |
| Maps | **AWS Location Service** + **OpenStreetMap** | Both work; OSM as zero-cost fallback |
| Mobile | **Flutter 3.38** | User's standard; matches their other apps |
| State mgmt | **GetX** | Routes, DI, reactive state in one package |
| Network | **Dio** + interceptors | Token injection, 401 redirect-to-login |
| Persist | **GetStorage** | Token survives kill + relaunch |
| Maps SDK | **flutter_map** + `latlong2` | OSS map widget, swappable tile layers |
| WhatsApp | `url_launcher` + `wa.me/<number>` | No SDK needed, opens native WhatsApp |

### Repository layout

```
cookshare/
├── README.md
├── .gitignore                       Hardened — blocks all .env, sqlite, logs, keystores, AWS creds
│
├── backend/                         Laravel 12 API
│   ├── app/
│   │   ├── Models/                  User, Post, Story, Comment + pivots
│   │   ├── Http/
│   │   │   ├── Controllers/Api/     Auth, Post, Story, User, Map, Upload
│   │   │   └── Resources/           PostResource, StoryResource, UserResource, CommentResource
│   │   └── Services/
│   │       ├── S3UrlService.php             Presigned PUT/GET URLs
│   │       └── LocationServiceClient.php    AWS Location tile fetch
│   ├── database/
│   │   └── migrations/              users, posts, stories, story_views, follows, likes, comments
│   ├── routes/api.php               Versioned `/api/v1/*`
│   ├── config/cookshare.php         Tunables (radius, TTLs, AWS map name)
│   └── .env.example                 Every env key the API reads, with safe defaults
│
└── app/                             Flutter 3.38
    ├── lib/
    │   ├── main.dart
    │   ├── app/
    │   │   ├── routes/              GetX route table
    │   │   └── theme/               Premium light theme
    │   ├── core/
    │   │   ├── api/                 Dio client + interceptors + base URL config
    │   │   ├── storage/             GetStorage-backed auth token
    │   │   └── location/            Geolocator wrapper
    │   ├── data/
    │   │   ├── models/              User, Post, Story, StoryRing, Comment
    │   │   └── repositories/        Auth, Post, Story, User, Map
    │   └── modules/
    │       ├── auth/                Login + register
    │       ├── feed/                Home shell + Following/Nearby tabs + post card
    │       ├── map/                 flutter_map + OSM/AWS tile layer + clustering
    │       ├── post/                Create + detail
    │       ├── profile/             View + edit (with WhatsApp number)
    │       ├── discover/            Discover (Nearby + All) + Search
    │       └── stories/             Rings strip + viewer + create
    └── pubspec.yaml                 dio, get, get_storage, flutter_map, latlong2,
                                     geolocator, image_picker, cached_network_image,
                                     permission_handler, intl, url_launcher
```

---

## 🚀 Quick start

### Prerequisites
- **PHP** 8.4+, Composer 2+
- **PostgreSQL** 14+ with the **PostGIS** extension
- **Flutter** 3.38+ (with Android Studio or Xcode for device targets)
- **AWS account** for S3 + Location Service (or skip — see "Running without AWS" below)

### 1. Backend

```bash
cd backend
cp .env.example .env

# Edit .env:
#   DB_*            local Postgres
#   AWS_*           IAM user with s3:* and geo:GetMapTile (optional, see below)
#   FILESYSTEM_DISK=s3 if using AWS, otherwise local

composer install
php artisan key:generate
createdb cookshare                      # if not yet created
psql cookshare -c "CREATE EXTENSION IF NOT EXISTS postgis;"
php artisan migrate --seed              # creates 6 demo cooks + posts + stories
php artisan serve --port=8001           # runs on :8001 (8000 is often taken)
```

The API now listens at **`http://localhost:8001/api/v1`**.

### 2. Mobile app

```bash
cd app
flutter pub get
# Edit lib/core/api/api_config.dart if your backend URL differs:
#   - iOS simulator        → http://localhost:8001/api/v1
#   - Android emulator     → http://10.0.2.2:8001/api/v1   (the magic emulator → host alias)
#   - Physical device      → http://<your-mac-lan-ip>:8001/api/v1
flutter run
```

### Demo logins (after seeding)

| Email | Password | Role |
|---|---|---|
| `demo@cookshare.app` | `password` | Main demo cook in Banani; follows everyone |
| `rumana@cookshare.app` | `password` | Kachchi biriyani specialist (sells via WhatsApp) |
| `nadia@cookshare.app` | `password` | Gulshan-2 home baker |
| `arif@cookshare.app` | `password` | Pitha + breakfast |
| `imran@cookshare.app` | `password` | Niketon quick lunches |
| `sumi@cookshare.app` | `password` | Chittagong specialties |

The seeder creates 15 posts and 6 active stories (3 for-sale, 3 just-sharing) clustered around Gulshan / Banani / Niketon so the map and feed feel populated immediately.

### Running without AWS

If you don't want to wire up AWS for a local demo:
- Set `FILESYSTEM_DISK=local` in `backend/.env`
- The app will still work, but photo upload via presigned PUT will need to be swapped for a local upload endpoint
- The **OSM map basemap** works with no AWS at all (it's the default)
- The seeder uses `picsum.photos` images via the backend's allow-listed `/img-proxy` so photos render even without S3

---

## 📡 API surface

All endpoints are under `/api/v1`. Auth: `Authorization: Bearer <sanctum-token>` on every protected route.

### Public
```
POST   /auth/register                 { name, email, password } → { token, user }
POST   /auth/login                    { email, password }       → { token, user }
GET    /map/tiles/{z}/{x}/{y}         AWS Location tile proxy (no auth, geo:GetMapTile only)
GET    /map/osm/{z}/{x}/{y}           OpenStreetMap tile proxy (works on Android emulator)
GET    /img-proxy?u=<url>             Allow-listed image proxy (picsum, placehold)
```

### Auth & profile
```
POST   /auth/logout
GET    /auth/me
PATCH  /users/me                      { name?, bio?, avatar_url?, whatsapp_number?, default_lat?, default_lng? }
GET    /users/{user}                  { ..., is_following: bool }
GET    /users/{user}/posts            cursor-paginated posts
POST   /users/{user}/follow
DELETE /users/{user}/follow
GET    /users/search?q=...
GET    /users/nearby?lat&lng&radius_km
GET    /users/cooks                   all cooks (location-free fallback)
```

### Posts
```
GET    /feed?lat&lng&radius_km        Following + Nearby fallback, cursor-paginated
POST   /posts                         { photo_key, lat, lng, caption?, dish_name?, cuisine?, cooking_minutes? }
GET    /posts/{post}
DELETE /posts/{post}
POST   /posts/{post}/like
DELETE /posts/{post}/like
GET    /posts/{post}/comments
POST   /posts/{post}/comments         { body }
```

### Stories (24h ephemeral)
```
GET    /stories/rings?lat&lng&radius_km   Instagram-style ring data: own → followed → nearby
GET    /stories/users/{userId}            All active stories from one cook (oldest-first)
POST   /stories                           { photo_key, lat, lng, dish_name?, caption?,
                                            is_available?, portions_total?, price?,
                                            pickup_area? }
POST   /stories/{story}/view              Idempotent; first view stamps timestamp
GET    /stories/{story}/viewers           Owner-only — analytics list
DELETE /stories/{story}                   Owner-only
```

### Map
```
GET    /map/nearby?lat&lng&radius_km   GeoJSON FeatureCollection of recent posts
```

### Uploads
```
POST   /uploads/presign                { content_type, extension } → { upload_url, photo_key }
```

---

## 🗄️ Data model

```
users
├── id, name, email, password
├── bio, avatar_url, whatsapp_number
├── default_lat, default_lng (raw doubles)
└── timestamps

posts
├── id, user_id → users
├── photo_key (S3) / photo_url (legacy)
├── dish_name, caption, cuisine, cooking_minutes
├── lat, lng (doubles)
├── location geography(Point, 4326) GENERATED ALWAYS AS (...)  ← GIST-indexed
├── is_for_sale, price, portions_available  (Phase 2 stubs)
└── timestamps

stories
├── id, user_id → users
├── photo_key / photo_url
├── dish_name, caption
├── lat, lng + location geography(Point, 4326) GENERATED  ← GIST-indexed
├── is_available, portions_total, price, pickup_area      ← sale info
├── whatsapp_at_post (snapshot — survives profile edits)
├── expires_at  ← TTL, indexed
└── timestamps

story_views      composite PK (story_id, user_id) — idempotent view records
follows          composite PK (follower_id, followed_id)
likes            composite PK (user_id, post_id)
comments         id, post_id → posts, user_id → users, body
```

PostGIS is loaded via `clickbar/laravel-magellan`. The `location` columns are **generated** from raw `lat`/`lng` doubles, so writes are simple but reads can use `ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)` for fast nearby queries.

---

## 🔐 Security & secrets

This repo is built so that **nothing private gets committed**:
- `.env` files are ignored everywhere (`backend/.env`, any nested env file)
- `.env.example` is the only env file in the repo and contains zero secrets
- AWS credentials live in `~/.aws/credentials` (or in `backend/.env`, ignored)
- `database.sqlite`, log files, keystores, `.jks`, `.keystore`, `.pem`, `.p12`, mobile provisioning profiles — all ignored
- The backend's S3 bucket is **private**; clients only ever get short-lived presigned URLs
- The AWS Location tile proxy is the only AWS surface exposed without auth, and it's locked to `geo:GetMapTile`

If you fork this repo, the workflow is:
1. `cp backend/.env.example backend/.env`
2. Fill in your own keys
3. Never `git add backend/.env` (it's blocked by `.gitignore` anyway)

---

## 🛣️ Roadmap

### ✅ Phase 1 — Social MVP (shipped)
- Email + password auth
- Posts (photo + caption + auto-tagged location)
- Following / Nearby feed tabs
- Snapchat-style 24h-pin map with clustering
- Likes, comments, follow / unfollow
- Profiles + edit profile (incl. WhatsApp number)
- Discover (Nearby + All cooks) + search
- 24h ephemeral **stories** with sale info + WhatsApp-based commerce
- Story viewer analytics (who viewed)

### 🚧 Phase 2 — Trust, safety & marketplace
- **🛡️ Image safety: NSFW / non-food image rejection on upload** — every story and post photo is scanned before being accepted; only food images are allowed. Likely path: AWS Rekognition `DetectModerationLabels` (catches `Explicit Nudity`, `Suggestive`, `Violence`, etc.) plus a separate `DetectLabels` check that requires at least one food-category label (`Food`, `Meal`, `Dish`, `Cuisine`, `Dessert`, etc.) above a confidence threshold. Rejected uploads return a 422 with a clear message; clean uploads proceed normally. This becomes a presign-time or post-PUT hook.
- **In-app reservations** — buyer taps "Reserve a portion" → cook gets notified → status flow (reserved → ready → picked up)
- **Real payments** — Stripe / bKash / SSLCommerz; cook earnings dashboard
- In-app chat between cook and eater (replaces WhatsApp deeplink for paying users)
- Pickup vs. delivery toggle
- Ratings & reviews after pickup
- Verified-cook badge

### 🔮 Phase 3 — Engagement
- Push notifications (FCM)
- Hashtags + cuisine browsing
- Saved posts
- Report / block / moderation tooling
- Weekly top-cooks leaderboard

### 🌱 Phase 4 — Growth
- Referrals
- Recipe mode (ingredients + steps)
- Group cooking events
- Cook subscription tier
- Web app for SEO

---

## 🧪 Verification checklist

- [x] `php artisan test` passes
- [x] `flutter analyze` — no errors, no warnings
- [x] `php artisan serve` boots backend on `:8001`, `GET /api/v1/auth/me` returns 401 unauthenticated
- [x] `flutter run` boots app, register flow creates user in DB, returns token, app stores it
- [x] Creating a post uploads photo to S3, persists row with PostGIS POINT, photo URL renders in feed
- [x] Map view loads tiles and shows pins from `/api/v1/map/nearby`
- [x] Killing + relaunching app keeps the user logged in (token persisted via `GetStorage`)
- [x] Story creation works end-to-end (photo → presign → PUT → POST `/stories` → ring shows up)
- [x] Story viewer marks views, blocks delete on others, renders WhatsApp CTA when `is_available`
- [x] Discover tab shows cooks + inline Follow toggle, falls back to All when no location

---

## 🤝 Contributing

This is a personal/early-stage project — no formal contribution flow yet. If you fork and improve, please:
- Keep `.env` files out of commits
- Don't add real AWS credentials, even temporarily
- Run `flutter analyze` before pushing app changes
- Run `php artisan test` before pushing backend changes

---

## 📄 License

TBD — currently private/unlicensed. All rights reserved.
