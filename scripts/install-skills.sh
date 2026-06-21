#!/usr/bin/env bash
# install-skills.sh — Install dotfiles agent configs into each agent's home
#
# Reads canonical sources from agents/ and copies/transforms them into
# each installed agent's configuration directory.
#
# Usage:
#   ./scripts/install-skills.sh          # normal run
#   ./scripts/install-skills.sh --dry    # dry-run: show what would be done
#
# Behaviour:
# - Skips agents whose directory is missing (not installed).
# - Idempotent — safe to run any number of times.
# - Only overwrites files that changed.

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

SKILLS_SRC="$REPO_DIR/agents/skills"
HERMES_SRC="$REPO_DIR/agents/hermes"
CLAUDE_SRC="$REPO_DIR/agents/claude"
COPILOT_SRC="$REPO_DIR/agents/copilot"
OPENCODE_SRC="$REPO_DIR/agents/opencode"

# Track generated content for repo-level CLAUDE.md and copilot-instructions.md
generated_skills_body=""
generated_skills_copilot=""

# ── Logging ──
info()  { echo "  ✓  $1"; }
skip()  { echo "  –  $1 (skipped — not installed)"; }
dry()   { echo "  ◇  $1"; }
action() {
  local label="$1" src="$2" dst="$3"
  if $DRY_RUN; then
    dry "[$label] $src → $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    info "[$label] $dst"
  fi
}

# ── Helper: strip YAML frontmatter from a SKILL.md ──
# Reads from stdin, writes to stdout. Everything after the second "---" line.
strip_frontmatter() {
  awk 'BEGIN{n=0} /^---$/ && n<2{n++; next} n==2{print}'
}

# ── Helper: extract frontmatter field ──
fm_value() {
  local key="$1" file="$2"
  awk -v k="$key" '
    BEGIN{found=0}
    /^---$/ && found==0{found=1; next}
    /^---$/ && found==1{exit}
    found==1 && index($0, k\": \") == 1 {
      sub(/^[^:]+: /,""); print; exit
    }
  ' "$file"
}

# ════════════════════════════════════════════════
# 1. Hermes
# ════════════════════════════════════════════════
hermes_installed=false
if [ -d "$HOME/.hermes" ]; then
  hermes_installed=true

  # ── Soul / Personality ──
  if [ -f "$HERMES_SRC/soul.md" ]; then
    action "hermes" "$HERMES_SRC/soul.md" "$HOME/.hermes/personalities/soul/soul.md"
  fi

  # ── Skills ──
  for skill in "$SKILLS_SRC"/*/SKILL.md; do
    [ -f "$skill" ] || continue
    name="$(basename "$(dirname "$skill")")"
    action "hermes" "$skill" "$HOME/.hermes/skills/$name/SKILL.md"
  done
fi

# ════════════════════════════════════════════════
# 2. Claude Code
# ════════════════════════════════════════════════
claude_installed=false
if [ -d "$HOME/.claude" ]; then
  claude_installed=true

  # ── Global CLAUDE.md ──
  if [ -f "$CLAUDE_SRC/CLAUDE.md" ]; then
    action "claude" "$CLAUDE_SRC/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  fi

  # ── Rules directory ──
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.claude/rules"
  fi
  for rule in "$CLAUDE_SRC/rules"/*.md; do
    [ -f "$rule" ] || continue
    action "claude" "$rule" "$HOME/.claude/rules/$(basename "$rule")"
  done

  # ── Skills → Rules (stripped frontmatter) ──
  for skill in "$SKILLS_SRC"/*/SKILL.md; do
    [ -f "$skill" ] || continue
    name="$(basename "$(dirname "$skill")")"
    dst="$HOME/.claude/rules/$name.md"
    if $DRY_RUN; then
      dry "[claude] $skill → $dst (stripped)"
    else
      mkdir -p "$(dirname "$dst")"
      strip_frontmatter < "$skill" > "$dst"
      info "[claude] $dst (stripped)"
    fi
  done
fi

# ════════════════════════════════════════════════
# 3. Copilot CLI
# ════════════════════════════════════════════════
copilot_installed=false
if command -v gh &>/dev/null || [ -d "$HOME/.github" ] || [ -d "$HOME/.config/gh" ]; then
  copilot_installed=true

  # ── Global instructions ──
  if [ -f "$COPILOT_SRC/instructions.md" ]; then
    action "copilot" "$COPILOT_SRC/instructions.md" "$HOME/.github/copilot-instructions.md"
  fi
fi

# ════════════════════════════════════════════════
# 4. OpenCode
# ════════════════════════════════════════════════
opencode_installed=false
if command -v opencode &>/dev/null || [ -d "$HOME/.config/opencode" ]; then
  opencode_installed=true

  if [ -f "$OPENCODE_SRC/instructions.md" ]; then
    action "opencode" "$OPENCODE_SRC/instructions.md" "$HOME/.config/opencode/instructions.md"
  fi
fi

# ════════════════════════════════════════════════
# 5. Generate repo-level files from skills
# ════════════════════════════════════════════════

# Collect all skills into body content
for skill in "$SKILLS_SRC"/*/SKILL.md; do
  [ -f "$skill" ] || continue
  name="$(basename "$(dirname "$skill")")"
  desc="$(fm_value "description" "$skill")"
  relpath="agents/skills/$name/SKILL.md"
  body="$(strip_frontmatter < "$skill")"

  generated_skills_body+="
## ${name}

${desc}

Full content: \`${relpath}\`

"
  # For copilot, include the full body inline
  generated_skills_copilot+="
## ${name}

${desc}

${body}

"
done

# ── Regenerate repo-level CLAUDE.md ──
repo_claude="$REPO_DIR/CLAUDE.md"
{
  echo "# dotfiles — Agent Instructions"
  echo ""
  echo "Auto-generated from \`agents/skills/\`. Edit skills there, then run \`scripts/install-skills.sh\` to regenerate."
  echo ""

  if [ -z "$generated_skills_body" ]; then
    echo "_No skills configured yet. Place SKILL.md files in \`agents/skills/<name>/SKILL.md\` and re-run this script._"
  else
    echo "$generated_skills_body"
  fi
} > "$repo_claude"
info "repo CLAUDE.md (regenerated)"

# ── Regenerate repo-level .github/copilot-instructions.md ──
mkdir -p "$REPO_DIR/.github"
repo_copilot="$REPO_DIR/.github/copilot-instructions.md"
{
  echo "# dotfiles — Copilot Instructions"
  echo ""
  echo "Auto-generated from \`agents/skills/\`. Edit skills there, then run \`scripts/install-skills.sh\` to regenerate."
  echo ""

  if [ -z "$generated_skills_copilot" ]; then
    echo "_No skills configured yet. Place SKILL.md files in \`agents/skills/<name>/SKILL.md\` and re-run this script._"
  else
    echo "$generated_skills_copilot"
  fi
} > "$repo_copilot"
info "repo .github/copilot-instructions.md (regenerated)"

# ── Summary ──
echo ""
echo "━━━ Summary ━━━"
$hermes_installed   && echo "  Hermes    ✓  installed"   || echo "  Hermes    –  not installed"
$claude_installed   && echo "  Claude    ✓  installed"   || echo "  Claude    –  not installed"
$copilot_installed  && echo "  Copilot   ✓  installed"   || echo "  Copilot   –  not installed"
$opencode_installed && echo "  OpenCode  ✓  installed"   || echo "  OpenCode  –  not installed"
echo "  Repo      ✓  CLAUDE.md + .github/copilot-instructions.md generated"
