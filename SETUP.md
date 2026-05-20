# CampLink — Setup

CampLink is the Mulungushi University campus shopping app. All 13 spec sections are now implemented (no push-notification gateway, no real payment-provider integration — see "What's implemented" at the bottom).

## 1. Install dependencies

```bash
flutter pub get
```

CampLink supports **Android, iOS, and Web** from one codebase. To run on web, see [section 8: Web setup](#8-web-setup) below.

## 2. Configure Firebase

Already done if `lib/firebase_options.dart` has your real keys. If you ever need to regenerate it:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

In the Firebase console enable:
- **Authentication → Sign-in method → Email/Password**
- **Authentication → Sign-in method → Google** (for "Continue with Google" — see section 2a below)
- **Cloud Firestore**
- **Storage**

## 2a. Enable Google sign-in (one-time)

Google sign-in requires extra Firebase wiring beyond just toggling the provider on.

### 2a.1 Enable the provider

1. Firebase console → your project → **Authentication → Sign-in method**.
2. Click **Google** → toggle **Enable** → set a public-facing project name and your support email → **Save**.

### 2a.2 Add your Android debug SHA-1 fingerprint

Without this, Google sign-in returns the cryptic `ApiException: 10` error on Android.

1. Firebase console → ⚙️ **Project settings** → **Your apps** → pick the Android app (`com.kytriq.camplink.camplink`).
2. Scroll to **SHA certificate fingerprints** → **Add fingerprint**.
3. Paste your debug SHA-1:

   ```
   7C:25:52:45:F9:B2:19:A2:F2:3D:7E:78:74:87:20:A7:95:30:7E:73
   ```

   (Optional — also add SHA-256 from the same list for App Check / Play Integrity later.)
4. Click **Save**.

> When you ship a release build, repeat this with the SHA-1 of your release keystore.

### 2a.3 Re-download `google-services.json`

After adding the SHA, Firebase generates an updated `google-services.json` that contains the OAuth client config.

1. In **Project settings → Your apps**, click the Android app's **`google-services.json`** download button.
2. Replace `android/app/google-services.json` with the freshly-downloaded file.
3. In your terminal: `flutter clean && flutter run` (full rebuild — the OAuth client must be baked in).

### 2a.4 iOS only (skip if Android-only)

`flutterfire configure` already wrote a `GoogleService-Info.plist` for iOS. You also need a URL scheme:

1. Open `ios/Runner/GoogleService-Info.plist`, copy the value of `REVERSED_CLIENT_ID`.
2. Open `ios/Runner/Info.plist` and add (replace `<REVERSED_CLIENT_ID>` with the value):

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string><REVERSED_CLIENT_ID></string>
       </array>
     </dict>
   </array>
   ```

## 3. Firestore data model

Collections used:

| Collection                                 | Purpose |
|--------------------------------------------|---------|
| `users/{uid}`                              | Profile, role (buyer/seller/admin), `suspended` flag |
| `products/{id}`                            | Listings owned by a seller |
| `orders/{id}`                              | Purchases, status, payment info |
| `notifications/{id}`                       | In-app notifications per user |
| `reviews/{id}`                             | Buyer review of a seller after a delivered order |
| `conversations/{convoId}`                  | 1:1 chat metadata; `convoId` is `sortedUidA_sortedUidB` |
| `conversations/{convoId}/messages/{id}`    | Individual chat messages (subcollection) |

### Required Firestore composite indexes

Firestore prints exact "create index" links in the debug console the first time each query runs. Click those to auto-create. Or pre-create:

- `orders`: `buyerId ASC, createdAt DESC`
- `orders`: `sellerId ASC, createdAt DESC`
- `notifications`: `userId ASC, createdAt DESC`
- `notifications`: `userId ASC, read ASC` (for unread badge stream)
- `reviews`: `sellerId ASC, createdAt DESC`
- `conversations`: `participants ARRAY, updatedAt DESC`

### Security rules (Firestore)

Paste this into **Firestore → Rules** in the Firebase console (replacing the starter set if you already have one):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function isSignedIn() { return request.auth != null; }
    function isAdmin() {
      return isSignedIn() &&
             get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{uid} {
      allow read: if isSignedIn();
      // Allow user to create/update own doc; admin can update anyone.
      allow create: if isSignedIn() && request.auth.uid == uid;
      allow update: if isSignedIn() && (request.auth.uid == uid || isAdmin());
      allow delete: if isAdmin();
    }

    match /products/{id} {
      allow read: if true;
      allow create: if isSignedIn()
                    && request.resource.data.sellerId == request.auth.uid;
      allow update: if isSignedIn()
                    && resource.data.sellerId == request.auth.uid;
      allow delete: if isSignedIn()
                    && (resource.data.sellerId == request.auth.uid || isAdmin());
    }

    match /orders/{id} {
      allow read: if isSignedIn()
                  && (resource.data.buyerId == request.auth.uid
                      || resource.data.sellerId == request.auth.uid
                      || isAdmin());
      allow create: if isSignedIn()
                    && request.resource.data.buyerId == request.auth.uid;
      allow update: if isSignedIn()
                    && (resource.data.buyerId == request.auth.uid
                        || resource.data.sellerId == request.auth.uid
                        || isAdmin());
    }

    match /notifications/{id} {
      // Anyone signed in may create a notification (used by order/chat services
      // to notify the other party). Only the recipient (or admin) may read.
      allow read: if isSignedIn()
                  && (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isSignedIn();
      allow update: if isSignedIn()
                    && resource.data.userId == request.auth.uid;
    }

    match /reviews/{id} {
      allow read: if true;
      allow create: if isSignedIn()
                    && request.resource.data.buyerId == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    match /conversations/{convoId} {
      allow read, write: if isSignedIn()
                         && request.auth.uid in
                            (resource == null
                              ? request.resource.data.participants
                              : resource.data.participants);

      match /messages/{msgId} {
        allow read, create: if isSignedIn()
                            && request.auth.uid in
                               get(/databases/$(db)/documents/conversations/$(convoId)).data.participants;
      }
    }
  }
}
```

### Security rules (Storage)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{uid}/{file=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
    match /avatars/{uid}/{file=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 4. Creating the first admin

Admin role can't be self-assigned through the UI. To bootstrap:

1. Register any normal account through the app.
2. In Firebase console → **Firestore Database** → `users` collection → open that user's doc.
3. Change `role` from `buyer` (or `seller`) to `admin`. Save.
4. Sign out and back in; you'll land on the Admin Console (Users / Products / Orders tabs).

From there, any admin can promote others via the user menu in the Users tab.

## 5. Run

```bash
flutter run
```

## 6. What's implemented (all 13 spec sections)

| # | Section | Status |
|---|---------|--------|
| 1 | Registration & login (Buyer/Seller/Admin), reset, logout | ✅ |
| 2 | Profile management, photo upload, hostel/location, order history | ✅ |
| 3 | Seller product CRUD with image upload, all categories | ✅ |
| 4 | Browse, search, category filter, product detail, seller info | ✅ |
| 5 | Cart with qty controls and total | ✅ |
| 6 | Place order (delivery/pickup, location, confirmation), seller status transitions | ✅ |
| 7 | Payment method picker (Cash/MTN/Airtel/Zamtel), payment status — *no real gateway* | ✅ |
| 8 | In-app notifications with unread badge (order events + new message) — *no FCM push* | ✅ |
| 9 | In-app 1:1 chat (Message seller button + Messages inbox) | ✅ |
| 10 | Admin console: users (suspend/role), products (remove), orders (view) | ✅ |
| 11 | Campus location preset (hostels, lecture rooms, main gate, library, etc.) | ✅ |
| 12 | Reviews & 1–5 star ratings on sellers after delivery | ✅ |
| 13 | Auth-gated data; suspended accounts blocked; security rules above | ✅ |

## 7. File layout

```
lib/
  main.dart                       # Firebase init, providers, role-based routing (incl. admin + suspended)
  firebase_options.dart           # Generated by flutterfire configure
  models/                         # AppUser, Product, CartItem, AppOrder,
                                  # AppNotification, Review, Conversation, ChatMessage
  services/                       # Firebase wrappers: auth, products, orders, storage,
                                  # notification, review, chat, admin
  providers/                      # AuthProvider, CartProvider
  screens/
    splash_screen.dart
    auth/                         # login, register, forgot password
    buyer/                        # home/browse, product detail, cart, checkout,
                                  # orders, leave_review, seller_reviews
    seller/                       # dashboard, add/edit product, incoming orders
    admin/                        # admin dashboard (Users / Products / Orders tabs)
    common/                       # profile, notifications, chat list, chat
  widgets/                        # ProductCard, NotificationsBell, SellerRatingView
```

## 8. Web setup

CampLink builds for the web with no code changes — `dart:io` was removed in favour of `XFile.readAsBytes()` so image uploads work in the browser too.

### 8.1 Run locally

```bash
flutter run -d chrome
```

First run downloads the web Flutter SDK shards. Subsequent runs are fast.

### 8.2 Build for production hosting

```bash
flutter build web
```

Output lands in `build/web/`. Deploy that folder to any static host — Firebase Hosting is the easiest:

```bash
npm install -g firebase-tools
firebase login
firebase init hosting       # pick build/web as the public dir, configure as single-page app
firebase deploy --only hosting
```

### 8.3 Enable Firestore on web

In the Firebase console → **Authentication → Settings → Authorized domains**, make sure these are present (Firebase usually adds them automatically):

- `localhost` (for `flutter run -d chrome`)
- Your production domain (e.g. `camplink-8e8f1.web.app`)

Without this, sign-in calls from the browser will fail with `auth/unauthorized-domain`.

### 8.4 Google sign-in on web (one-time)

The Android setup in section 2a doesn't cover web. You need to paste your **Web OAuth Client ID** into `web/index.html`.

1. Open Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=camplink-8e8f1
2. Find the OAuth 2.0 Client ID of type **Web application** — Firebase auto-creates one named "Web client (auto created by Google Service)".
3. Copy its **Client ID** (looks like `123456789-abc...apps.googleusercontent.com`).
4. Open `web/index.html` and replace the `YOUR_WEB_OAUTH_CLIENT_ID...` placeholder in the `<meta name="google-signin-client_id" ...>` tag.
5. Add your dev/prod web origins to that OAuth client's **Authorized JavaScript origins**:
   - `http://localhost:PORT` (Flutter picks a random port — add a few common ones, or `http://localhost:5000`, `http://localhost:8080`)
   - `https://YOUR-PROJECT.web.app`
   - `https://YOUR-PROJECT.firebaseapp.com`

### 8.5 Web caveats

| Feature | Behavior on web |
|---------|-----------------|
| Image picker | Opens browser file chooser. No camera capture — gallery only. |
| Profile / product images | Stored as bytes via `putData` (works identically). |
| Firestore | Real-time streams work. |
| Notifications bell | In-app only (no push). |
| Hot reload | Works via `flutter run -d chrome`. |
| Mobile-only plugins | None used — everything in the dependency tree supports web. |
