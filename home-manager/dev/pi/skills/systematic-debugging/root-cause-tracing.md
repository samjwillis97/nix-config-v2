# Root Cause Tracing

Trace bugs backward through the call stack to find the original trigger.

## The Technique

When you have a bug deep in a call stack, don't fix where the error appears — trace BACKWARD to find where the bad value originated:

1. **Start at the error** — what value is wrong?
2. **Where does that value come from?** — trace the variable to its source
3. **What called this function with the bad value?** — go up one level
4. **Keep tracing** until you find the FIRST place the value went wrong
5. **Fix at THAT point** — not where the error manifested

## Example

```
Error: Cannot read property 'name' of undefined at line 42

Line 42: user.name         → user is undefined
Line 38: const user = getUser(id)  → getUser returned undefined
Line 20: function getUser(id) { return users[id] }  → users[id] is undefined
Line 10: users = fetchUsers()      → fetchUsers returned empty object
Line 5:  fetchUsers()              → API returned 401, silently returned {}

Root cause: Auth token expired, API returns 401, fetchUsers swallows error
Fix: Handle 401 in fetchUsers, not null check at line 42
```

## The Backward Trace Process

```
1. Note the error and the wrong value
2. Find where the wrong value was assigned
3. Read the assignment — is the RHS wrong? Trace it.
4. Find the caller — what passed this value?
5. Repeat until you find the FIRST corruption point
6. Fix at that point
```

## Common Mistakes

- **Fixing at the symptom** (null check at line 42) instead of the source (auth handling)
- **Stopping too early** (fixing getUser without checking why users is empty)
- **Not tracing all the way back** (assuming the first upstream caller is the source)
- **Fixing at multiple levels** instead of the root — creates defensive code that hides future bugs

## When to Use

- Error is deep in call stack
- Fix at error site would be a band-aid
- Same error keeps appearing in different places (shared root cause)
- Error message is misleading (symptom is far from cause)

## When NOT to Use

- Error is at the entry point (nothing to trace back to)
- Error is in a self-contained function with no callers
- The wrong value is a literal in the failing function itself
