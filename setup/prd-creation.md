# PRD Creation

Generate, refine, and manage structured PRDs that Loom executes autonomously.

## When to Use

- You have spec documents, design files, or planning notes to decompose into actionable stories
- You want dependency tracking, gate prioritization, and parallel execution
- You're starting a new project or adding a major feature to an existing one

## Step 1: Write Good Specs

The PRD generator transforms your specs mechanically — it copies source content verbatim into story fields, preserving every requirement, constraint, and edge case. The quality of your PRD depends on the quality of your specs.

### What makes a good spec file

- **Structured headings** — each section becomes one or more stories. Use h1-h6 to organize logically.
- **Requirements as bullet lists** — each bullet becomes an acceptance criterion 1:1. Don't bury requirements in paragraphs.
- **Concrete values** — "password must be at least 12 characters" not "password must be secure"
- **Edge cases explicitly stated** — "returns 404 if user not found" not "handles errors gracefully"
- **Conditional language** — "only if", "unless", "except when" — these become explicit acceptance criteria
- **Implementation hints** — constraints, tech choices, existing patterns to follow

### Example spec structure

```markdown
# User Authentication

## Login Endpoint
POST /auth/login accepts email and password.
Returns JWT on success, 401 on invalid credentials.

Requirements:
- Email must be a valid email format
- Password is compared using bcrypt
- JWT expires after 15 minutes
- Failed login attempts rate-limited to 5 per 10 minutes per IP
- Returns 429 with Retry-After header when rate limited

## Signup Endpoint
POST /auth/signup creates a new user account.

Requirements:
- Email must be unique (409 if exists)
- Password must be at least 12 characters
- Password must contain uppercase, lowercase, and digit
- Returns JWT on successful creation
```

## Step 2: Generate the PRD

### Basic usage

```bash
# From Claude Code (recommended)
/prd specs/auth.md specs/api.md specs/frontend.md

# Any number of files, any format
/prd design.md architecture.md wireframes.md meeting-notes.md
```

### With options

```bash
# Custom story ID prefix (default: project dir name, uppercased, 5 chars max)
/prd specs/auth.md prefix AUTH

# Limit total stories (useful for large specs)
/prd specs/*.md max 30

# Combine options
/prd specs/auth.md specs/api.md prefix API max 20
```

### Standalone script

```bash
.loom/prd.sh specs/auth.md specs/api.md
```

## Step 3: Review the Output

### Quick stats

```bash
# Overview
jq '{
  project: .project,
  stories: (.stories | length),
  gates: (.gates | length),
  ready: [.stories[] | select(.blockedBy == [] and .status == "pending")] | length,
  blocked: [.stories[] | select(.blockedBy != [])] | length
}' .loom/prd.json
```

### Gate breakdown

```bash
jq '.gates[] | "\(.priority) \(.name) — \(.stories | length) stories"' -r .loom/prd.json
```

### Check for issues

```bash
# Stories with empty acceptance criteria (bad — every story needs testable criteria)
jq '[.stories[] | select(.acceptanceCriteria | length == 0)] | .[] | .id' .loom/prd.json

# Stories with no files predicted (may need attention)
jq '[.stories[] | select(.files | length == 0)] | .[] | {id, title}' .loom/prd.json

# Stories with tool requirements (need MCP servers installed)
jq '[.stories[] | select(.tools | length > 0)] | .[] | {id, title, tools}' .loom/prd.json

# Check dependency chains (find the critical path)
jq '[.stories[] | select(.blockedBy | length > 0)] | .[] | {id, blockedBy}' .loom/prd.json
```

## Step 4: Refine

### Append more stories

```bash
# Add stories from additional specs without touching existing ones
/prd specs/new-feature.md append

# Append continues ID numbering from the highest existing ID
```

### Manual edits

Use targeted `jq` edits or the Edit tool — never rewrite the entire file:

```bash
# Fix a story's acceptance criteria
jq '(.stories[] | select(.id == "APP-005")).acceptanceCriteria += ["New criterion"]' .loom/prd.json > tmp.json && mv tmp.json .loom/prd.json

# Change a story's priority
jq '(.stories[] | select(.id == "APP-010")).priority = "P0"' .loom/prd.json > tmp.json && mv tmp.json .loom/prd.json

# Add a dependency
jq '(.stories[] | select(.id == "APP-010")).blockedBy += ["APP-005"]' .loom/prd.json > tmp.json && mv tmp.json .loom/prd.json
```

### Add tool requirements

If `/prd` didn't auto-detect that a story needs browser/mobile/design tools:

```bash
# Mark a story as needing browser testing
jq '(.stories[] | select(.id == "APP-012")).tools = ["browser"]' .loom/prd.json > tmp.json && mv tmp.json .loom/prd.json
```

## How /prd Works Internally

Understanding the pipeline helps you write better specs:

1. **Index** — extracts heading tree from each file using `mdq` (no full-file reads)
2. **Extract** — pulls individual sections on demand using `mdq '# Section Name'`
3. **Dispatch** — one subagent per section transforms it into a story JSON object
4. **Assemble** — stories are grouped into gates, dependencies are set
5. **Auto-detect tools** — scans acceptance criteria for capability keywords:
   - `browser`, `web UI`, `screenshots`, `DOM`, `CSS`, `responsive`, `HTML`, `page`, `viewport`, `click`, `form`, `input`, `button`, `navigation`, `render` → `["browser"]`
   - `mobile app`, `simulator`, `emulator`, `gesture`, `tap`, `swipe`, `pinch`, `press`, `hold`, `drag`, `iOS`, `Android`, `app screen`, `push notification` → `["mobile"]`
   - `Figma`, `design fidelity`, `design tokens`, `pixel-matching`, `design system`, `design spec`, `color tokens`, `typography tokens`, `spacing tokens`, `component library` → `["design"]`
6. **Verify** — coverage, verbatim, nuance, and completeness checks against source
7. **Write** — outputs `.loom/prd.json`

### Source preservation

The generator copies source content verbatim into story fields:
- **Paragraphs** → `description` (exact wording, not paraphrased)
- **Requirement lists** → `acceptanceCriteria` (1:1, not merged)
- **Implementation steps** → `actionItems` (1:1)
- **Subsections** → `details` (keyed by section heading)
- **File/section backlinks** → `sources` (traceable chain from spec to story)

This means the subagent implementing a story never needs to read the original spec — the story is self-contained.

## Tips

- **One feature per `/prd` run.** Don't mix unrelated features in one PRD. Use separate PRD runs with `append` to add features incrementally.
- **Heading depth matters.** Each h2/h3 section typically becomes one story. If a section is too large for a single subagent (~15-30 min), split it into subsections.
- **Requirements as bullets, not prose.** Bullets become acceptance criteria 1:1. Requirements buried in paragraphs may be missed or merged.
- **State edge cases explicitly.** "Returns 404 if user not found" is an acceptance criterion. "Handles errors" is not.
- **Review before running.** A 5-minute review of the generated PRD prevents hours of misdirected work. Check that story count is reasonable, dependencies make sense, and no requirements were dropped.
