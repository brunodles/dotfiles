# Improvement: Review — Jekyll compose integration

**Source:** Subagent review `deleg_820c16d7`  
**Date:** 2026-06-28

## Issues found

### 1. [MEDIUM] `_config.yml` has no awareness of `/docs`

The `docs_data` volume is mounted at `/srv/jekyll/docs`, but `_config.yml`
has no collection, include, or default-layout for the `docs/` path.

Jekyll will not process markdown files under `/docs` — they'll be served as
raw static files (unrendered) or ignored entirely.

**Fix:** Add a default layout rule for the `docs` path in `_config.yml`.

```yaml
defaults:
  - scope:
      path: "docs"
    values:
      layout: "default"
```

This overrides for `docs/` what the global default already does for `*`,
but makes the intent explicit and ensures docs are always rendered.
