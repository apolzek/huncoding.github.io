#!/usr/bin/env bash
set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────
cyan()  { printf '\033[0;36m%s\033[0m' "$*"; }
green() { printf '\033[0;32m%s\033[0m' "$*"; }
bold()  { printf '\033[1m%s\033[0m' "$*"; }

ask() {
  local prompt="$1" default="${2:-}" var
  if [[ -n "$default" ]]; then
    read -rp "$(cyan "  $prompt") [$(bold "$default")]: " var
    echo "${var:-$default}"
  else
    while true; do
      read -rp "$(cyan "  $prompt"): " var
      [[ -n "$var" ]] && break
      echo "  → obrigatório, tente novamente." >&2
    done
    echo "$var"
  fi
}

ask_optional() {
  local prompt="$1"
  read -rp "$(cyan "  $prompt") (Enter para pular): " var
  echo "$var"
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null \
    | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//'
}

# ── cabeçalho ─────────────────────────────────────────────────────────────────
echo ""
echo "$(bold '╔══════════════════════════════════════╗')"
echo "$(bold '║   HunCoding — Novo Post              ║')"
echo "$(bold '╚══════════════════════════════════════╝')"
echo ""

# ── data ─────────────────────────────────────────────────────────────────────
TODAY=$(date '+%Y-%m-%d')
DATE=$(ask "Data do post (YYYY-MM-DD)" "$TODAY")

# ── slugs ────────────────────────────────────────────────────────────────────
echo ""
echo "$(bold '── Slug (PT-BR) ──')"
echo "  Usado na URL e no nome do arquivo. Exemplo: go-channels-padroes-avancados"
SLUG_PTBR=$(ask "Slug PT-BR")
SLUG_EN=$(ask "Slug EN" "$(echo "$SLUG_PTBR" | sed 's/$/-en/')")

# ── títulos e subtítulos ──────────────────────────────────────────────────────
echo ""
echo "$(bold '── Títulos ──')"
TITLE_PTBR=$(ask "Título PT-BR")
SUBTITLE_PTBR=$(ask_optional "Subtítulo PT-BR")
TITLE_EN=$(ask "Título EN")
SUBTITLE_EN=$(ask_optional "Subtítulo EN")

# ── categorias e tags ─────────────────────────────────────────────────────────
echo ""
echo "$(bold '── Categorias e Tags ──')"
echo "  Separe por vírgula. Exemplo: Go, Testing, Concurrency"
CATEGORIES_RAW=$(ask "Categorias" "Go")
TAGS_RAW=$(ask "Tags" "go, golang")

# converte "Go, Testing" → [Go, Testing]
fmt_list() {
  echo "$1" | sed 's/^/[/; s/$/]/'
}
CATEGORIES=$(fmt_list "$CATEGORIES_RAW")
TAGS=$(fmt_list "$TAGS_RAW")

# ── imagem ────────────────────────────────────────────────────────────────────
echo ""
echo "$(bold '── Imagem ──')"
DEFAULT_IMG="/assets/img/posts/${DATE}-${SLUG_PTBR}.png"
IMAGE=$(ask "Caminho da imagem" "$DEFAULT_IMG")

# ── YouTube ──────────────────────────────────────────────────────────────────
echo ""
echo "$(bold '── YouTube (opcional) ──')"
YT_ID=$(ask_optional "ID do vídeo YouTube (ex: BeTQmkPlWZ0)")
YT_TITLE=$([ -n "$YT_ID" ] && ask_optional "Título do vídeo" || true)

build_youtube_block() {
  if [[ -n "$YT_ID" ]]; then
    echo "youtube_videos:"
    echo "  - id: \"$YT_ID\""
    if [[ -n "$YT_TITLE" ]]; then
      echo "    title: \"$YT_TITLE\""
    fi
  fi
}

YT_BLOCK=$(build_youtube_block)

# ── resumo ────────────────────────────────────────────────────────────────────
FOLDER="_posts/${DATE}-${SLUG_PTBR}"
FILE_PTBR="${FOLDER}/${DATE}-${SLUG_PTBR}.md"
FILE_EN="${FOLDER}/${DATE}-${SLUG_EN}.md"

echo ""
echo "$(bold '── Resumo ──────────────────────────────────────')"
printf "  Pasta     : %s\n" "$FOLDER"
printf "  PT-BR     : %s\n" "$FILE_PTBR"
printf "  EN        : %s\n" "$FILE_EN"
printf "  Título PT : %s\n" "$TITLE_PTBR"
printf "  Título EN : %s\n" "$TITLE_EN"
printf "  Imagem    : %s\n" "$IMAGE"
[[ -n "$YT_ID" ]] && printf "  YouTube   : %s\n" "$YT_ID"
echo ""

read -rp "$(cyan '  Criar os arquivos? [s/N]') " CONFIRM
[[ "$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')" == "s" ]] || { echo "Cancelado."; exit 0; }

# ── gera arquivos ─────────────────────────────────────────────────────────────
mkdir -p "$FOLDER"

# ── escreve frontmatter + conteúdo inicial ────────────────────────────────────
write_post() {
  local file="$1" title="$2" subtitle="$3" lang="$4" original_post="$5" opener="$6"
  {
    echo "---"
    echo "layout: post"
    echo "title: \"$title\""
    [[ -n "$subtitle" ]] && echo "subtitle: \"$subtitle\""
    echo "author: otavio_celestino"
    echo "date: $DATE 08:00:00 -0300"
    echo "categories: $CATEGORIES"
    echo "tags: $TAGS"
    echo "comments: true"
    echo "image: \"$IMAGE\""
    echo "lang: $lang"
    [[ -n "$original_post" ]] && echo "original_post: \"/$original_post/\""
    [[ -n "$YT_BLOCK" ]] && echo "$YT_BLOCK"
    echo "---"
    echo ""
    echo "$opener"
    echo ""
    echo "<!-- $([ "$lang" = "pt-BR" ] && echo 'Escreva o post aqui' || echo 'Write the post here') -->"
  } > "$file"
}

write_post "$FILE_PTBR" "$TITLE_PTBR" "$SUBTITLE_PTBR" "pt-BR" "" "E aí, pessoal!"
write_post "$FILE_EN"   "$TITLE_EN"   "$SUBTITLE_EN"   "en"    "$SLUG_PTBR" "Hey everyone!"

echo ""
echo "$(green '✓') Arquivos criados:"
echo "  $(green '→') $FILE_PTBR"
echo "  $(green '→') $FILE_EN"
echo ""
