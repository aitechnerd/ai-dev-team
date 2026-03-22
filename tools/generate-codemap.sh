#!/usr/bin/env bash
# generate-codemap.sh — Grep-based function-level codemap generator
# Produces a compact index of files + their key symbols (functions, classes, routes)
# so Claude Code can jump directly to the right file without exploring.
#
# Usage: ./tools/generate-codemap.sh [project-dir] [output-file]
#   project-dir defaults to current directory
#   output-file defaults to .claude/codemap.md

set -uo pipefail  # no -e, we handle errors manually

PROJECT_DIR="${1:-.}"
OUTPUT="${2:-$PROJECT_DIR/.claude/codemap.md}"
PROJECT_NAME=$(basename "$(cd "$PROJECT_DIR" && pwd)")
DATE=$(date +%Y-%m-%d)

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# --- Skip patterns ---
should_skip() {
  local file="$1"
  case "$file" in
    *_ide_helper*|*vendor/*|*node_modules/*|*__pycache__/*) return 0 ;;
    *.venv/*|*venv/*|*dist/*|*build/*|*target/*|*.git/*) return 0 ;;
    *.min.*|*.generated.*|*.d.ts) return 0 ;;
    */migrations/*|*/versions/*) return 0 ;;
    config/*.php|config/*/*.php) return 0 ;;
    *__init__.py)
      local size
      size=$(wc -c < "$PROJECT_DIR/$file" 2>/dev/null | tr -d ' ')
      [[ "$size" -lt 50 ]] && return 0 ;;
  esac
  return 1
}

# --- Language detection ---
has_ts=false; has_py=false; has_rs=false; has_rb=false; has_go=false; has_php=false; has_java=false
[[ -f "$PROJECT_DIR/package.json" || -f "$PROJECT_DIR/tsconfig.json" ]] && has_ts=true
[[ -f "$PROJECT_DIR/requirements.txt" || -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/Pipfile" || -f "$PROJECT_DIR/setup.py" ]] && has_py=true
[[ -f "$PROJECT_DIR/Cargo.toml" ]] && has_rs=true
[[ -f "$PROJECT_DIR/Gemfile" ]] && has_rb=true
[[ -f "$PROJECT_DIR/go.mod" ]] && has_go=true
[[ -f "$PROJECT_DIR/composer.json" ]] && has_php=true
find "$PROJECT_DIR" -maxdepth 2 -name "*.java" -not -path '*/node_modules/*' 2>/dev/null | head -1 | grep -q . && has_java=true || true

# --- File discovery ---
get_files() {
  local ext="$1"
  if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" ls-files "*.${ext}" 2>/dev/null
  else
    find "$PROJECT_DIR" -name "*.${ext}" \
      -not -path '*/node_modules/*' -not -path '*/.venv/*' \
      -not -path '*/venv/*' -not -path '*/dist/*' \
      -not -path '*/build/*' -not -path '*/target/*' \
      -not -path '*/__pycache__/*' -not -path '*/.git/*' \
      -not -path '*/vendor/*' \
      2>/dev/null | sed "s|^$PROJECT_DIR/||"
  fi
}

# --- Symbol extractors ---
# All use grep WITHOUT -n, then sed to extract just the symbol name.
# macOS sed -E doesn't support \s, so we use [ ] or [[:space:]]

extract_ts() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local exports classes routes types symbols=""

  exports=$(grep -E '^[[:space:]]*export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]+[A-Za-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -10 | tr '\n' ',' | sed 's/,$//')
  classes=$(grep -E '^[[:space:]]*export[[:space:]]+(default[[:space:]]+)?class[[:space:]]+[A-Za-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -5 | tr '\n' ',' | sed 's/,$//')
  types=$(grep -E '^[[:space:]]*export[[:space:]]+(interface|type)[[:space:]]+[A-Za-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*(interface|type)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\2/' | head -8 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$classes" ]] && symbols="class: $classes"
  [[ -n "$exports" ]] && symbols="${symbols:+$symbols | }$exports"
  [[ -n "$types" ]] && symbols="${symbols:+$symbols | }types: $types"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_py() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local classes funcs routes symbols=""

  classes=$(grep -E '^class[[:space:]]+[A-Za-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -8 | tr '\n' ',' | sed 's/,$//')
  funcs=$(grep -E '^(async[[:space:]]+)?def[[:space:]]+[A-Za-z]' "$fp" 2>/dev/null \
    | sed -E 's/.*(async[[:space:]]+)?def[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\2/' \
    | grep -v '^_' | head -10 | tr '\n' ',' | sed 's/,$//')
  routes=$(grep -E '@(app|router|api)\.(get|post|put|patch|delete|route)' "$fp" 2>/dev/null \
    | sed -E 's/.*\.(get|post|put|patch|delete|route)[[:space:]]*\([[:space:]]*['"'"'"]([^'"'"'"]*).*/\U\1\E:\2/' \
    | head -8 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$classes" ]] && symbols="$classes"
  [[ -n "$funcs" ]] && symbols="${symbols:+$symbols | }$funcs"
  [[ -n "$routes" ]] && symbols="${symbols:+$symbols | }routes: $routes"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_rs() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local types funcs symbols=""

  types=$(grep -E '^[[:space:]]*pub[[:space:]]+(struct|enum|trait)[[:space:]]+[A-Za-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*[[:space:]](struct|enum|trait)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\2/' \
    | head -8 | tr '\n' ',' | sed 's/,$//')
  funcs=$(grep -E '^[[:space:]]*pub[[:space:]]+(async[[:space:]]+)?fn[[:space:]]+[a-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*fn[[:space:]]+([a-z_][a-z0-9_]*).*/\1/' \
    | head -10 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$types" ]] && symbols="$types"
  [[ -n "$funcs" ]] && symbols="${symbols:+$symbols | }$funcs"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_rb() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local classes methods symbols=""

  classes=$(grep -E '^[[:space:]]*class[[:space:]]+[A-Z]' "$fp" 2>/dev/null \
    | sed -E 's/.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_:]*).*/\1/' | head -5 | tr '\n' ',' | sed 's/,$//')
  methods=$(grep -E '^[[:space:]]+def[[:space:]]+[a-z_]' "$fp" 2>/dev/null \
    | sed -E 's/.*def[[:space:]]+([a-z_][a-z0-9_?!]*).*/\1/' | head -12 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$classes" ]] && symbols="$classes"
  [[ -n "$methods" ]] && symbols="${symbols:+$symbols | }$methods"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_go() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local types funcs symbols=""

  types=$(grep -E '^type[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]+(struct|interface)' "$fp" 2>/dev/null \
    | sed -E 's/type[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -8 | tr '\n' ',' | sed 's/,$//')
  funcs=$(grep -E '^func[[:space:]]+' "$fp" 2>/dev/null \
    | sed -E 's/^func[[:space:]]+\([^)]*\)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/; s/^func[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' \
    | head -12 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$types" ]] && symbols="$types"
  [[ -n "$funcs" ]] && symbols="${symbols:+$symbols | }$funcs"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_php() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local classes funcs symbols=""

  classes=$(grep -E '^[[:space:]]*(abstract[[:space:]]+)?class[[:space:]]+[A-Z]' "$fp" 2>/dev/null \
    | sed -E 's/.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -5 | tr '\n' ',' | sed 's/,$//')
  funcs=$(grep -E '^[[:space:]]*public[[:space:]]+(static[[:space:]]+)?function[[:space:]]+[a-z]' "$fp" 2>/dev/null \
    | sed -E 's/.*function[[:space:]]+([a-z_][a-z0-9_A-Z]*).*/\1/' \
    | head -12 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$classes" ]] && symbols="$classes"
  [[ -n "$funcs" ]] && symbols="${symbols:+$symbols | }$funcs"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

extract_java() {
  local file="$1" fp="$PROJECT_DIR/$1"
  local classes methods symbols=""

  classes=$(grep -E '^[[:space:]]*(public[[:space:]]+)?(abstract[[:space:]]+)?class[[:space:]]+[A-Z]' "$fp" 2>/dev/null \
    | sed -E 's/.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/' | head -5 | tr '\n' ',' | sed 's/,$//')
  methods=$(grep -E '^[[:space:]]*(public|protected)[[:space:]]+' "$fp" 2>/dev/null \
    | grep -v 'class\|interface\|import' \
    | sed -E 's/.*[[:space:]]([a-z][A-Za-z0-9_]*)[[:space:]]*\(.*/\1/' | head -12 | tr '\n' ',' | sed 's/,$//')

  [[ -n "$classes" ]] && symbols="$classes"
  [[ -n "$methods" ]] && symbols="${symbols:+$symbols | }$methods"
  [[ -n "$symbols" ]] && echo "$file — $symbols"
}

# --- Main ---
{
  echo "# Codemap"
  echo ""
  echo "Generated: $DATE | Project: $PROJECT_NAME"
  echo "Function-level index so Claude jumps directly to the right file."
  echo ""

  process_lang() {
    local ext="$1" label="$2" extract_fn="$3"
    local files
    files=$(get_files "$ext")
    [[ -z "$files" ]] && return 0

    local current_dir="" output="" count=0

    while IFS= read -r f; do
      should_skip "$f" && continue
      local result
      result=$($extract_fn "$f" 2>/dev/null) || true
      [[ -z "$result" ]] && continue

      local dir
      dir=$(dirname "$f")
      if [[ "$dir" != "$current_dir" ]]; then
        current_dir="$dir"
        output+="# ${dir}/"$'\n'
      fi
      output+="$result"$'\n'
      count=$((count + 1))
    done <<< "$(echo "$files" | sort)"

    if [[ $count -gt 0 ]]; then
      echo "## $label ($count files)"
      echo ""
      echo '```'
      printf '%s' "$output"
      echo '```'
      echo ""
    fi
  }

  # TS/JS — combine extensions
  if $has_ts; then
    all_files=""
    for ext in ts tsx js jsx mjs; do
      f=$(get_files "$ext" 2>/dev/null) || true
      [[ -n "$f" ]] && all_files="${all_files:+$all_files
}$f"
    done
    if [[ -n "$all_files" ]]; then
      current_dir="" output="" count=0
      while IFS= read -r f; do
        should_skip "$f" && continue
        result=$(extract_ts "$f" 2>/dev/null) || true
        [[ -z "$result" ]] && continue
        dir=$(dirname "$f")
        if [[ "$dir" != "$current_dir" ]]; then
          current_dir="$dir"
          output+="# ${dir}/"$'\n'
        fi
        output+="$result"$'\n'
        count=$((count + 1))
      done <<< "$(echo "$all_files" | sort)"

      if [[ $count -gt 0 ]]; then
        echo "## TypeScript/JavaScript ($count files)"
        echo ""
        echo '```'
        printf '%s' "$output"
        echo '```'
        echo ""
      fi
    fi
  fi

  $has_py && process_lang "py" "Python" "extract_py"
  $has_rs && process_lang "rs" "Rust" "extract_rs"
  $has_rb && process_lang "rb" "Ruby" "extract_rb"
  $has_go && process_lang "go" "Go" "extract_go"
  $has_php && process_lang "php" "PHP" "extract_php"
  $has_java && process_lang "java" "Java" "extract_java"

} > "$TMP"

lines=$(wc -l < "$TMP" | tr -d ' ')
if [[ $lines -gt 300 ]]; then
  echo "⚠  Warning: codemap is $lines lines (target: <200). Consider adding skip patterns." >&2
fi

mkdir -p "$(dirname "$OUTPUT")"
cp "$TMP" "$OUTPUT"
echo "✅ Codemap: $OUTPUT ($lines lines)"
