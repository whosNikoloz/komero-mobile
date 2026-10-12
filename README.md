# Komero Mobile

Flutter admin app for Komero store operators — the phone counterpart to
`commerce/app/[lang]/admin`. Talks to the same REST API directly; the Next.js
layer is not involved.

```bash
flutter pub get
flutter gen-l10n          # after editing any lib/l10n/*.arb
flutter run
flutter run --dart-define=KOMERO_API_URL=https://staging.api.komero.ge/
```

## How auth works

Two independent things travel on every request:

| | What | Where it comes from |
|---|---|---|
| **Who you are** | `Authorization: Bearer <jwt>` | `POST /User/login` |
| **Which store** | `X-Client-Domain: wonder.ge` | the operator types their store address at sign-in |

The JWT is **tenant-agnostic**. The domain header is what selects the store —
same token + different domain = different store. Both are attached once, in
`lib/src/core/net/api_client.dart`.

`GET /User/me` then returns the operator plus **one** `tenant` (resolved from
that domain) with `role` and `permissions`; `Me.can('orders.manage')` gates the
UI exactly like the web admin's `useMe + can()`.

Operator JWTs are long-lived (~1 year) and have **no refresh token**, so a 401
drops the session and returns to sign-in. The token lives in
`flutter_secure_storage`; the store domain and preferences live in
`SharedPreferences`.

There is no "list my stores" endpoint for a normal operator, which is why the
login screen asks for the store address instead of showing a picker.

## Layout

```
lib/
  l10n/              en · ka · ru (ARB → generated L class)
  src/
    core/
      theme/tokens.dart    every colour, light + dark  (context.c.primary)
      theme/app_theme.dart ThemeData built from those tokens
      net/api_client.dart  Dio + auth/domain interceptor + ApiException
      session.dart         token + store domain
      prefs.dart           theme mode + language
      notifications.dart   FCM + local presentation
    models/          wire shapes (me, order, inventory, product, stats)
    data/
      repositories.dart    the endpoint map
      order_stream.dart    SSE /orders/stream
    features/        auth · shell · dashboard · orders · inventory · products · settings
    widgets/common.dart    Panel, StatTile, StatusBadge, EntityThumb, AsyncView
```

### Colours — Komero's, never the tenant's

`KomeroColors` is a `ThemeExtension` holding every reusable colour as a named
semantic token. The values are the **Komero brand scale from the marketing
site** (`ecommerce-landing/app/globals.css`): brand-600 `#2d4ec4` primary,
brand-500 `#5566ff` accent, navy-950 `#020617` type, mint-600 `#059669`
success. Dark mode is the designed counterpart on the navy ramp, with the
primary lifted to brand-400 for contrast.

The tenant config also ships a full theme. **The app ignores it on purpose** —
this is Komero's operator tool and wears Komero's palette on every store. Only
the tenant's *logo and name* are read (`data/branding.dart`).

Read tokens with `context.c.<token>`. Never write a literal colour; add a
semantic token instead. The two documented exceptions are the camera
viewfinder chrome (fixed black/white over a live feed) and the white plate
behind a tenant logo (transparent PNGs drawn for light headers).

### Modals are mobile-first

There are **no centre dialogs**. Everything modal goes through
`widgets/sheet.dart`:

- `showKomeroSheet` — drag handle, scrollable body, actions pinned at the
  bottom, keyboard inset applied to the whole sheet so the actions ride above
  the keyboard, bottom safe area respected, capped at 90% height so the
  barrier stays visible and tappable.
- `confirmSheet` / `promptSheet` — the yes/no and single-field replacements for
  `AlertDialog`.

Actions stack full-width rather than sitting side by side: they stay in thumb
reach and never truncate a Georgian or Russian label.

### Product images

`imagePath` comes back as an **`http://`** URL on `img.komero.ge`. Android
blocks cleartext traffic (API 28+), so those loads fail silently and every
product shows a placeholder. `absoluteImageUrl` upgrades the scheme to https —
the host serves the same bytes over TLS and 301s http → https anyway — rather
than opening a cleartext hole in the manifest. A test guards it.

### Catalog filtering

`browse()` picks the endpoint that can answer the question: no filter and no
text → `get-all-products`; text only → `get-product-by-searching`; any filter →
`POST get-products-by-filtering`. That last endpoint takes **no search term**,
so a text query combined with a filter is narrowed client-side on the returned
page; if a catalog outgrows that, the endpoint needs a `searchTerm`.

### Delivery map

`widgets/delivery_map.dart` draws the order's pin with **flutter_map over
OpenStreetMap tiles** — no API key, no billing, no per-platform key rotation
for a map that is only looked at. Navigation hands off to Google Maps via its
universal URL, which both platforms route to the installed app. Orders placed
without a dropped pin show the address and still open a Maps search for it.

### Language picker

`widgets/language_picker.dart` — one implementation, two placements:

- **Sign-in screen**, top-right beside the Komero mark. It has to be reachable
  before login: an operator who cannot read the form cannot get to settings to
  change it.
- **Settings**, as a radio list with the same flags.

Languages are shown in their own script (English / ქართული / Русский) with
regional-indicator flag emoji, which Android and iOS both render natively, so
there is no flag asset to ship, scale or theme. "System" shows a device icon
rather than a flag. The name/flag table lives in `core/prefs.dart`, and a test
asserts every supported locale has both.

### Endpoints used

| Feature | Endpoint |
|---|---|
| Login / session | `POST User/login`, `GET User/me`, `POST User/forgot-password` |
| Analytics | `GET api/statistics/summary`, `GET api/statistics/dashboard` |
| Traffic & funnel | `GET api/admin/behavior/overview`, `/sources` |
| Orders | `GET Order/get-all-orders`, `GET Order/get-order-by-{id}`, `PUT Order/update-order-status`, `POST Order/cancel-order-{id}` |
| Live orders | `GET orders/stream` (SSE, credentials in the query string) |
| Stock | `GET Stock/get-all-stocks`, `/low-stock/{n}`, `/out-of-stock`, `PUT /update-stock/{id}`, `POST /add-stock/{id}`, `/remove-stock/{id}` |
| Locations | `GET api/admin/stock-locations`, `/products/{id}`, `POST api/admin/stock-transfers` |
| Barcodes | `GET Product/barcode/{code}`, `POST Product/barcode/{code}/stock` |
| Catalog | `GET Product/get-all-products`, `/get-products-by-{id}`, `/get-product-by-searching`, `POST Product/get-products-by-filtering`, `POST Product/add-product`, `PUT Product/update-product`, `POST Product/images` |
| Taxonomy | `GET Category/get-all-categories`, `GET Brand/get-all-brands` |

`MAIN: 0` / `MAIN: 1` is only needed on tenant-config and platform routes; none
of the above take it. `KomeroApi.mainHeader(n)` is there if one starts to.

## Firebase (push notifications)

The app builds and runs without Firebase — alerts then arrive only while the app
is open, over the SSE order stream. To enable background push:

1. Create the Firebase project, add an Android app with applicationId
   `ge.komero.komero_mobile` and an iOS app with the same bundle id.
2. Drop `google-services.json` into `android/app/` and
   `GoogleService-Info.plist` into `ios/Runner/`.
3. Add the Google services Gradle plugin:
   - `android/settings.gradle.kts` plugins block:
     `id("com.google.gms.google-services") version "4.4.2" apply false`
   - `android/app/build.gradle.kts` plugins block:
     `id("com.google.gms.google-services")`
4. iOS: enable Push Notifications + Background Modes (remote notifications) in
   Xcode and upload the APNs key to Firebase.

`PushService.init()` catches a missing Firebase config and degrades to
stream-only alerts, so step 1-4 can land later without breaking the build.

## Known backend gaps

These are API limitations, not missing UI. Each is marked in the code where it
bites:

1. **No device-token registration route.** FCM can deliver to a device, but
   nothing in `commerce/` stores which device belongs to which operator, so the
   backend cannot target a push. `PushService.registerDevice` POSTs to
   `api/admin/devices` and swallows the 404 — implement that route (tenant-scoped
   by `X-Client-Domain`, body `{ token, platform }`) and background push starts
   working with no client change.
2. **No payment capture or refund endpoint.** `Order/update-order-status` with
   `Refunded` is the only lever, and it records the refund without moving money.
   The app says so in the confirmation dialog rather than implying a transfer.
   Partial refunds are not expressible at all.
3. **Stock adjustments take no reason.** `Stock/update-stock` and
   `add`/`remove-stock` take a bare number. The app collects a reason
   (Restocked / Damaged / Returned / Theft / Correction) for the operator's sake
   but cannot persist it; pass `reason` through in
   `lib/src/features/inventory/stock_adjust_sheet.dart` once the API accepts one.
4. **Product variants are not editable on mobile.** Variant grouping goes
   through facets and product groups, which is a bigger surface than a phone
   form; the app edits single products and leaves grouping to the web admin.

## Tests

`flutter test` covers `SessionController.normalizeDomain`, the one piece of
logic that silently sends every request to the wrong tenant if it breaks.
