# Improvement: Review — docs bootstrap script

**Source:** Subagent review `deleg_66198333`  
**Date:** 2026-06-28

## Issues found

### 1. [MEDIUM] `stacks-up` doesn't call docs bootstrap

`scripts/bootstrap/traefik` is called from both `configure.sh` and `stacks-up`.
`scripts/bootstrap/docs` is only called from `configure.sh`.

If someone runs `stacks-up` directly, the `docs` network and `docs_data` volume
won't exist and `docker compose up` will fail.

**Fix:** Add `"$BOOTSTRAP_DIR/docs"` to `scripts/bootstrap/stacks-up`.

### 2. [LOW] Silent fallback failure

```bash
sudo docker network create docs --internal 2>/dev/null || \
  sudo docker network create docs
info "  docs network created"
```

If both commands fail, the success message still prints.

**Fix:** Check exit code explicitly or restructure with if/else.

### 3. [LOW] Missing closing summary message

The script ends abruptly after creating the volume. Unlike other bootstrap
scripts (traefik prints a closing line), docs doesn't indicate completion.

**Fix:** Add `info "Docs bootstrap complete"` at end.
