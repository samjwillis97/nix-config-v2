# Defense in Depth

After finding and fixing the root cause, add validation at multiple layers to prevent similar issues.

## The Principle

A single point of validation is a single point of failure. After fixing a bug's root cause, consider adding validation at boundaries between components so the same class of bug can't silently propagate again.

## When to Apply

- After fixing a bug where bad data flowed through multiple layers undetected
- When the root cause was silent failure (function returned null/undefined instead of throwing)
- When data crosses trust boundaries (user input, API responses, config files)
- When the same bug class could recur with different data

## Layers of Defense

1. **Input validation** — validate at entry points (API handlers, CLI parsers, config loaders)
2. **Type contracts** — use the type system to make invalid states unrepresentable
3. **Boundary assertions** — validate at module boundaries, especially when data changes shape
4. **Fail-fast** — throw/return errors immediately rather than propagating bad state silently

## Example

**Bug:** User with empty email passed validation, caused crash in email sender.

```
Layer 1 (Input):    Validate email format in API handler
Layer 2 (Domain):   User type requires non-empty email (type-level)
Layer 3 (Boundary): Email sender asserts email is valid before send
Layer 4 (Fail-fast): createUser() throws if email is empty, not silently creates
```

Each layer catches the bug independently. If one layer's validation has a bug of its own, the others still catch it.

## Don't Overdo It

- Add defense at **boundaries**, not every function call
- Validate data when it **enters your system**, not every time it's passed internally
- Balance safety with code readability — defensive code everywhere obscures intent
- If the type system already prevents the bad state, you don't need a runtime check too

## After the Fix

When you've fixed a root cause and added defense in depth:

1. The root cause fix prevents THIS bug
2. The defense layers prevent the same CLASS of bug
3. Document what layers you added and why in your commit message
