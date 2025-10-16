# Recent Fixes Summary

## 1. Supabase Initialization Race Condition

**Problem:** Supabase was not initialized on first app launch, required hot restart.

**Solution:**

- Moved `supabaseReady = true` to **after** `Supabase.initialize()` completes in `main.dart`
- This ensures the flag is set regardless of success/failure
- Auth provider now polls `supabaseReady` before subscribing to auth state changes

**Files Changed:**

- `frontend/lib/main.dart`
- `frontend/lib/providers/auth_provider.dart`

---

## 2. Auth Flow & Persistence

**Problem:** After login, app stayed on auth page; no persistent login state.

**Solution:**

- Added `SharedPreferences` persistence for `logged_in` flag
- Auth provider writes `logged_in=true/false` on sign in/up/out and auth state changes
- Splash screen now checks `logged_in` + provider status to route correctly

**Files Changed:**

- `frontend/lib/providers/auth_provider.dart`
- `frontend/lib/pages/splash_screen.dart`

---

## 3. Backend Auth & User Creation Errors

**Problems:**

- "Auth session missing!" errors on valid tokens
- "null value in column user_id" when creating users
- "Cannot coerce to single JSON object" on `/users/me`

**Solutions:**

### Backend Middleware Fallback

- Added JWT decode + `auth.admin.getUserById()` fallback in auth middleware
- If `auth.getUser()` fails, decode token and use admin API

### User Creation with Auth Context

- `POST /users` now requires authentication
- Inserts `user_id` from authenticated user (`req.user.id`)
- Ensures `user_id` references the Supabase auth user

### GET /users/me Lookup Strategy

- Primary: lookup by `user_id` (auth uid)
- Fallback: lookup by `email` with `.limit(1).maybeSingle()`
- Prevents multi-row errors

### Supabase Schema Fixes

- Set `user_id` default to `auth.uid()`
- Made `user_id` NOT NULL
- Added unique index on `lower(email)`
- Removed duplicate email records
- Added foreign key: `users.user_id` → `auth.users(id)`

**Files Changed:**

- `backend/middleware/authMiddleware.js`
- `backend/controllers/userController.js`
- `backend/routes/userRoutes.js`
- Supabase `public.users` table (via MCP)

---

## 4. Infinite API Calls from ProfilePage

**Problem:** Profile page triggered repeated API calls every build cycle.

**Solution:**

- Moved provider loads from `build()` (which runs on every rebuild) to `initState()`/`_loadUserData()`
- Only loads edupoints/portfolio/submissions **once** when page initializes
- No longer triggers on every rebuild

**Files Changed:**

- `frontend/lib/pages/profile_admin_pages.dart`

---

## 5. Bottom Nav Re-rendering & Index Management

**Problem:** Bottom nav recreated pages on every tap, causing duplicate loads.

**Solution:**

- Created `MainNavigator` widget with `IndexedStack`
- Caches all 5 bottom nav pages once
- Only switches visible index, doesn't rebuild inactive pages
- Route `/dashboard` now returns `MainNavigator` instead of individual pages

**Files Changed:**

- `frontend/lib/pages/main_navigator.dart` (NEW)
- `frontend/lib/app.dart`

---

## 6. OTP Sign-Up Flow

**Problem:** Sign-up after OTP verification logged out user and re-signed up, causing session loss.

**Solution:**

- Removed sign-out step after OTP verification
- Use `auth.updateUser(UserAttributes(password: ...))` to set password in-place
- Register user in backend with current access token
- Refresh auth provider and navigate to dashboard

**Files Changed:**

- `frontend/lib/pages/verify_otp_page.dart`

---

## 7. Provider Build-Time Errors

**Problem:** "setState() called during build" errors from provider state changes.

**Solution:**

- Wrapped all initial data loads in `WidgetsBinding.instance.addPostFrameCallback()`
- Defers provider calls until after initial build completes

**Files Changed:**

- `frontend/lib/pages/dashboard_page.dart`

---

## Testing Checklist

- [ ] Fresh install → onboarding → sign up via OTP → redirects to dashboard
- [ ] Kill app → relaunch → goes directly to dashboard (uses `logged_in` flag)
- [ ] Sign out → relaunch → goes to auth page
- [ ] Profile page loads data once, no infinite loops
- [ ] Bottom nav switches tabs without rebuilding inactive pages
- [ ] `/users/me` returns 200 with user data
- [ ] Multiple users with same email don't cause 500 errors
- [ ] No "Supabase should be initialized" errors on cold start

---

## Architecture Improvements

### Indexed Page Stack (MainNavigator)

```
/dashboard → MainNavigator
  ├─ Dashboard (index 0)
  ├─ Tasks (index 1)
  ├─ Submissions (index 2)
  ├─ Portfolio (index 3)
  └─ Profile (index 4)
```

All pages cached in memory, only active index visible. Bottom nav switches index without rebuilding.

### Auth Flow

```
Splash → check logged_in flag
  ├─ if false → /auth (UnifiedAuthPage)
  │   └─ sign up → verify OTP → set password → create user → /dashboard
  └─ if true → /dashboard (MainNavigator)
```

### Backend User Lookup

```
GET /users/me:
  1. Try: SELECT * FROM users WHERE user_id = auth.uid()
  2. Fallback: SELECT * FROM users WHERE email = auth.email() LIMIT 1
  3. Error if both fail
```

### Token Validation

```
auth.getUser(token)
  ├─ success → use user
  └─ failure → decode JWT → auth.admin.getUserById(sub) → use user
```

---

## Known Limitations

1. **Email uniqueness:** Case-insensitive index on email, but OTP flow doesn't check for existing users
2. **RLS policies:** Not yet implemented; backend uses service role key
3. **Error messages:** Generic 500 errors don't surface detailed validation failures to frontend
4. **Profile refresh:** Edupoints/portfolio/submissions only load on page init, not on tab switch

---

## Next Steps (Optional)

- Add RLS policies to Supabase tables
- Implement proper error boundaries in Flutter
- Add pull-to-refresh for all provider-backed pages
- Cache provider data with TTL to avoid unnecessary refetches
- Add loading skeletons instead of spinners
