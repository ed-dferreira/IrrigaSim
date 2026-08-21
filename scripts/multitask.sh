#!/usr/bin/env bash
#
# multitask.sh — roda várias tarefas em paralelo, cada uma com um agente
# opencode isolado em seu próprio git worktree, visíveis em janelas tmux.
#
# Uso:
#   bash scripts/multitask.sh <spec>...
#
# Specs aceitas:
#   #N              → issue N do GitHub (título+corpo viram o prompt)
#   nome::prompt    → tarefa livre; "nome" vira slug do branch/worktree
#
# Variáveis de ambiente:
#   MULTITASK_SESSION       nome da sessão tmux      (padrão: multitask)
#   MULTITASK_MAX_PARALLEL  agentes simultâneos      (padrão: 3)
#
# Exemplos:
#   bash scripts/multitask.sh '#5' '#6' '#7'
#   bash scripts/multitask.sh 'docs::Reescreva o README com badges'
#
set -euo pipefail

SESSION="${MULTITASK_SESSION:-multitask}"
MAX_PARALLEL="${MULTITASK_MAX_PARALLEL:-3}"
DRY_RUN=0

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

[ "$#" -ge 1 ] || { echo "uso: $0 [--dry-run] <spec>...  (ex.: '#5' ou 'nome::prompt')"; exit 1; }

command -v gh >/dev/null || { echo "erro: gh (GitHub CLI) não encontrado no PATH"; exit 1; }
if [ "$DRY_RUN" = 0 ]; then
  command -v tmux >/dev/null || { echo "erro: tmux não instalado. Rode: sudo apt install tmux"; exit 1; }
  command -v opencode >/dev/null || { echo "erro: opencode não encontrado no PATH"; exit 1; }
fi

ROOT="$(git rev-parse --show-toplevel)"
BASE="$(basename "$ROOT")"
LOG_DIR="$ROOT/.multitask"
mkdir -p "$LOG_DIR"

slugify() {
  tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-40
}

window_exists() {
  tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -Fxq "$1"
}

NAMES=()
declare -A SEEN=()

add_task() { # $1=name $2=prompt
  local name=$1 prompt=$2
  if [ -z "$name" ] || [ -z "$prompt" ]; then
    echo "aviso: spec inválida (nome ou prompt vazio), ignorando" >&2
    return
  fi
  if [ -n "${SEEN[$name]:-}" ]; then
    echo "aviso: tarefa duplicada '$name', ignorando" >&2
    return
  fi
  SEEN[$name]=1
  NAMES+=("$name")
  printf '%s' "$prompt" > "$LOG_DIR/$name.prompt"
}

for spec in "$@"; do
  if [[ "$spec" =~ ^#[0-9]+$ ]]; then
    n="${spec#\#}"
    name="issue-$n"
    if ! title=$(gh issue view "$n" --json title -q .title 2>/dev/null); then
      echo "aviso: issue #$n não encontrada, ignorando" >&2
      continue
    fi
    body=$(gh issue view "$n" --json body -q .body)
    prompt="Você está trabalhando sozinho neste repositório, dentro de um git worktree isolado no branch mt/$name.

# Issue #$n: $title

$body

## Instruções
- Implemente a issue por completo, editando os arquivos necessários.
- NÃO faça commit e NÃO abra PR. Deixe as mudanças apenas no diretório de trabalho.
- Se o projeto tiver lint/typecheck configurados, rode ao final e corrija problemas que você introduziu.
- Resuma ao final o que foi alterado."
    add_task "$name" "$prompt"
  elif [[ "$spec" == *::* ]]; then
    add_task "$(slugify "${spec%%::*}")" "${spec#*::}"
  else
    echo "aviso: spec '$spec' não é '#N' nem 'nome::prompt', ignorando" >&2
  fi
done

[ "${#NAMES[@]}" -ge 1 ] || { echo "nenhuma tarefa válida"; exit 1; }

echo "sessão tmux : $SESSION"
echo "paralelismo : $MAX_PARALLEL"
echo "logs/prompts: $LOG_DIR"
echo

for name in "${NAMES[@]}"; do
  branch="mt/$name"
  wt="$ROOT/../$BASE-mt-$name"

  if [ "$DRY_RUN" = 1 ]; then
    echo "[dry-run] $name → branch $branch | worktree $wt | prompt $(wc -c <"$LOG_DIR/$name.prompt") bytes"
    continue
  fi

  # worktree (reutiliza se já existir)
  if [ -d "$wt/.git" ]; then
    echo "[$name] worktree já existe, reutilizando: $wt"
  elif git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt" "$branch" >/dev/null
    echo "[$name] branch existente, novo worktree: $wt"
  else
    git worktree add -b "$branch" "$wt" >/dev/null
    echo "[$name] criados branch $branch + worktree $wt"
  fi

  # fila: espera haver slot livre (marcadores órfãos são limpos)
  while :; do
    for r in "$LOG_DIR"/.running-*; do
      [ -e "$r" ] || break
      rn=${r##*/.running-}
      window_exists "$rn" || rm -f "$r"
    done
    running=$(find "$LOG_DIR" -maxdepth 1 -name '.running-*' | wc -l)
    [ "$running" -lt "$MAX_PARALLEL" ] && break
    sleep 3
  done

  touch "$LOG_DIR/.running-$name"

  prompt_q=$(printf '%q' "$(cat "$LOG_DIR/$name.prompt")")
  log_q=$(printf '%q' "$LOG_DIR/$name.log")
  run_q=$(printf '%q' "$LOG_DIR/.running-$name")
  done_q=$(printf '%q' "$LOG_DIR/.done-$name")
  inner="opencode run --auto $prompt_q 2>&1 | tee -a $log_q; rm -f $run_q; touch $done_q; echo; echo '[multitask] agente finalizou esta tarefa — janela livre para inspeção'; exec bash"

  if ! tmux new-window -d -t "$SESSION" -n "$name" -c "$wt" "$inner" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -n main -c "$ROOT"
    tmux new-window -d -t "$SESSION" -n "$name" -c "$wt" "$inner"
  fi
  echo "[$name] lançado na janela tmux '$name'"
done

echo
echo "Resumo:"
for name in "${NAMES[@]}"; do
  st="agendada"
  [ -f "$LOG_DIR/.done-$name" ] && st="concluída"
  [ -f "$LOG_DIR/.running-$name" ] && st="rodando"
  printf '  %-20s branch mt/%s | ../%s-mt-%s | log .multitask/%s.log [%s]\n' \
    "$name" "$name" "$BASE" "$name" "$name" "$st"
done
echo
echo "Acompanhe com: tmux attach -t $SESSION   (Ctrl+B n = próxima janela)"
