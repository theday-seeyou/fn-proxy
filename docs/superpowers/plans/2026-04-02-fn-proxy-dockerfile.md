# fn-proxy Dockerfile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the root Dockerfile with a deployment-oriented image that packages the local `proxy/` release artifacts and starts `proxy` in HTTP mode on port 9000 by default.

**Architecture:** Use a single-stage Alpine runtime image. Copy the existing `proxy/` directory into `/opt/proxy`, mark the bundled binary executable, expose port 9000, and use `ENTRYPOINT` plus overridable `CMD` so Docker and Alibaba Cloud FC can reuse the same image while still allowing runtime argument overrides.

**Tech Stack:** Docker, Alpine Linux, bundled Linux release binary in `proxy/`

---

### Task 1: Replace the root Dockerfile

**Files:**
- Modify: `Dockerfile:1-26`
- Reference: `proxy/proxy`

- [ ] **Step 1: Inspect the current Dockerfile and confirm it still uses source compilation**

Read `Dockerfile` and verify it contains the current multi-stage `golang:1.19-alpine` build flow and `git clone`-based build so the replacement is scoped correctly.

- [ ] **Step 2: Replace the file with a runtime-only Dockerfile**

Write this exact content to `Dockerfile`:

```dockerfile
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /opt/proxy

COPY proxy/ /opt/proxy/

RUN chmod +x /opt/proxy/proxy

EXPOSE 9000

ENTRYPOINT ["/opt/proxy/proxy"]
CMD ["http", "-p", ":9000"]
```

- [ ] **Step 3: Verify the Dockerfile matches the approved design**

Read `Dockerfile` back and confirm all required behaviors are present:
- no `git clone`
- no `go build`
- copies `proxy/`
- executable bit set on `/opt/proxy/proxy`
- exposes `9000`
- default command is `http -p :9000`

- [ ] **Step 4: Commit the Dockerfile change**

Run:

```bash
git add Dockerfile
git commit -m "build: package bundled proxy binary for docker deployment"
```

Expected: a new commit containing only the root Dockerfile change if the user has asked for a commit.

### Task 2: Verify the image definition locally

**Files:**
- Test: `Dockerfile`
- Dependency: `proxy/proxy`

- [ ] **Step 1: Build the image**

Run:

```bash
docker build -t fn-proxy .
```

Expected: successful build using `alpine:3.20`, with no source compilation stage.

- [ ] **Step 2: Verify the default command path is valid**

Run:

```bash
docker run --rm fn-proxy --help
```

Expected: the container starts `/opt/proxy/proxy` and prints the proxy help/usage output.

- [ ] **Step 3: Verify the default HTTP-mode command starts**

Run:

```bash
docker run --rm fn-proxy
```

Expected: the container starts with `http -p :9000` as the default arguments. If the process stays running, that is expected for a listening proxy container.

- [ ] **Step 4: Optionally verify host port mapping for local testing**

Run:

```bash
docker run --rm -p 9000:9000 fn-proxy
```

Expected: the container listens on host port 9000 for manual smoke testing, if Docker networking is available in the environment.

- [ ] **Step 5: Commit verification-related follow-up only if code changed**

If verification requires no file changes, do not create another commit. If a Dockerfile adjustment is needed after verification, stage only the updated file and create a new commit describing the fix.
