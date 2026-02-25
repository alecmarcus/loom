# Testing

Configure your project's test suite so Loom can run, write, and fix tests autonomously.

## How Loom Uses Tests

Loom is test-framework agnostic. It doesn't have a built-in test runner — subagents discover your project's test setup, write tests appropriate to your framework, and run the suite using your existing tooling.

The test lifecycle within each iteration:

1. **Subagents implement features** and write test files alongside them
2. **Orchestrator runs the full test suite** after all subagents complete
3. **If tests fail**, the orchestrator attempts fixes (up to 3 retries)
4. **Only green code gets committed** — failing tests block commits
5. **Failing tests are reported in `status.md`** and become top priority in the next iteration

This means your project needs a working test setup *before* starting Loom. If there's no test runner, subagents won't know how to verify their work.

## Language-Specific Setup

### JavaScript / TypeScript

#### Jest

```bash
# Install
npm install --save-dev jest @types/jest ts-jest

# Verify
npx jest --version
```

Ensure `package.json` has a test script:

```json
{
  "scripts": {
    "test": "jest"
  }
}
```

Or `jest.config.ts` / `jest.config.js` for custom configuration.

#### Vitest

```bash
# Install
npm install --save-dev vitest

# Verify
npx vitest --version
```

```json
{
  "scripts": {
    "test": "vitest run"
  }
}
```

Use `vitest run` (not `vitest`) in the script — `vitest` without `run` starts watch mode, which hangs in unattended Loom runs.

#### Playwright (e2e)

```bash
# Install
npm install --save-dev @playwright/test
npx playwright install

# Verify
npx playwright --version
```

```json
{
  "scripts": {
    "test:e2e": "playwright test"
  }
}
```

For Playwright as an MCP validation tool (screenshots, DOM inspection during development), see the [Playwright validation guide](validation/playwright.md). This section covers Playwright as a static test runner.

### Python

#### pytest

```bash
# Install
pip install pytest

# Verify
pytest --version
```

Configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
```

Or `pytest.ini` / `setup.cfg` for legacy projects.

#### unittest

No installation needed — it's in the standard library. Loom subagents will use `python -m pytest` if pytest is available, falling back to `python -m unittest discover`.

### Rust

```bash
# Verify (built into cargo)
cargo test --no-run
```

No setup needed. Rust's test framework is built in — `cargo test` discovers and runs all `#[test]` functions.

Subagents write tests in the same file (unit tests in `#[cfg(test)]` modules) or in `tests/` (integration tests).

### Go

```bash
# Verify (built into go)
go test ./... -count=1 -short
```

No setup needed. Go's testing is built in — `go test ./...` runs all `*_test.go` files.

Subagents write tests in `*_test.go` files alongside the code they're testing.

### Swift

```bash
# Verify
swift test --skip-build
```

For Swift packages, tests live in `Tests/` and run via `swift test`. For Xcode projects, use `xcodebuild test`.

### Other Languages

Loom subagents adapt to whatever test framework they find. The key requirements:

1. **A discoverable test command** — `package.json` scripts, `Makefile` targets, `pyproject.toml` config, or conventional runners (`cargo test`, `go test`)
2. **Non-interactive execution** — the test command must run to completion without prompts
3. **Clear pass/fail output** — exit code 0 for pass, non-zero for fail
4. **Reasonable speed** — the full suite runs within the iteration timeout (default 3 hours)

## Helping Loom Find Your Tests

Loom subagents search for test configuration in this order:

1. **`package.json` scripts** — `test`, `test:unit`, `test:e2e`
2. **Config files** — `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pyproject.toml`, `Cargo.toml`, `go.mod`
3. **Conventional directories** — `tests/`, `test/`, `__tests__/`, `spec/`
4. **CLAUDE.md** — project-level instructions that mention test commands

### Add test commands to CLAUDE.md

The most reliable way to tell Loom how to run tests:

```markdown
## Testing

Run all tests:
\`\`\`bash
npm test
\`\`\`

Run a specific test file:
\`\`\`bash
npx jest src/auth/__tests__/login.test.ts
\`\`\`
```

Subagents read `CLAUDE.md` before starting work (enforced by the `subagent-recall.sh` hook), so test commands documented here are always discovered.

## Writing Good Acceptance Criteria for Tests

The quality of tests Loom generates depends on acceptance criteria in your PRD stories. Specific, testable criteria produce better tests.

### Good criteria (produce strong tests)

```json
"acceptanceCriteria": [
  "POST /auth/login returns 200 with a JWT when credentials are valid",
  "POST /auth/login returns 401 when password is incorrect",
  "POST /auth/login returns 429 after 5 failed attempts in 10 minutes",
  "JWT payload contains user_id, role, and tenant_id fields",
  "JWT expires after 15 minutes"
]
```

Each criterion maps to a single test case with clear input → output.

### Weak criteria (produce vague tests)

```json
"acceptanceCriteria": [
  "Login works correctly",
  "Error handling is robust",
  "The API is secure"
]
```

These are not testable — the subagent has to guess what "works correctly" means.

## The Test-Fix-Retry Loop

After subagents complete their work, the orchestrator:

1. **Runs the full test suite**
2. If tests fail:
   - Reads the failure output (test name, file, error message)
   - Attempts to fix the failing tests
   - Re-runs the suite
   - Repeats up to **3 times**
3. If tests still fail after 3 attempts:
   - Changes are **not committed** (left uncommitted for the next iteration)
   - Failures are recorded in `status.md`
   - Next iteration treats failing tests as **top priority**

This means persistent test failures don't block the loop — they're carried forward and retried with fresh context.

## Cross-Iteration Test Persistence

`status.md` tracks test state across iterations:

| Section | What it records |
|---------|----------------|
| **Failing Tests** | Every currently-failing test: name, file, error message |
| **Uncommitted Changes** | What was left uncommitted because tests failed |
| **Fixed This Iteration** | Previously-failing tests that now pass |
| **Tests Added / Updated** | New or modified test files |

The next iteration reads `status.md` first and prioritizes fixing any reported failures before picking up new stories.

## Tips

- **Have a working test suite before starting Loom.** Even one passing test is enough — it proves the runner works. Zero tests means subagents have no framework to build on.
- **Document your test command in CLAUDE.md.** This is the single most impactful thing you can do. Subagents always check CLAUDE.md first.
- **Use `vitest run`, not `vitest`.** Watch mode hangs in unattended runs. Same for `jest --watch` — use `jest` or `jest --ci`.
- **Keep tests fast.** The full suite runs after every subagent batch. A 30-minute test suite means 30 minutes of waiting per iteration.
- **Separate unit and e2e tests.** If you have both, document both commands in CLAUDE.md. Subagents will run unit tests for logic changes and e2e tests for UI changes.
- **Tests and features share stories.** Loom's PRD format keeps a feature and its tests in the same story (`"No over-decomposition"` rule). Don't create separate "write tests for X" stories — the subagent implementing X writes its tests too.
