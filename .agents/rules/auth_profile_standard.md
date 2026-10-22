# Rule: Zero-Trust Authentication & Atomic Username Reservation Standards

## Core Principles
1. **Atomic Username Reservation**:
   - In Firestore (or any NoSQL store without UNIQUE constraints), unique usernames must be registered in an immutable `usernames/{lowercase_username}` collection.
   - Any registration or claim must occur inside a `runTransaction` that validates non-existence of the username document before creating both `usernames/{username}` and `users/{uid}`.
2. **Provider Agnostic Identity**:
   - Google Sign-In, Apple, and Email/Password must map to a standardized user profile model.
   - When users start anonymously or with an existing email, use account linking (`linkWithPopup`) so in-progress learning data, ratings, and puzzle progress are never dropped.
3. **Zero-Trust Security Rules**:
   - Firestore security rules must enforce that `usernames/{username}` can only be created by an authenticated user matching the payload `uid`.
   - Modifying or deleting username locks is prohibited.
   - Subcollections (e.g. `users/{uid}/puzzle_progress/{id}`) are private to `request.auth.uid == userId`.
