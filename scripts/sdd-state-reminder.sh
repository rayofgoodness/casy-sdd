#!/usr/bin/env bash
# casy-sdd PostToolUse hook.
# Тихо завжди, КРІМ випадку коли правили SDD-стан-файл (рівно spec.md / plan.md / tasks.md).
# Тоді — JSON-нагадування Клоду тримати артефакти в синхроні. Нічого не змінює, завжди exit 0.
input="$(cat)"

# Витягни шлях файлу з payload: спершу jq (точно, .tool_input.file_path), інакше — фолбек grep по сирому JSON.
fp=""
if command -v jq >/dev/null 2>&1; then
  fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
fi
if [ -z "$fp" ]; then
  fp="$(printf '%s' "$input" | grep -Eo '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1)"
fi

# Спрацьовуй лише якщо ім'я файлу рівно spec.md / plan.md / tasks.md (анкор по слешу або початку рядка).
if printf '%s' "$fp" | grep -Eq '(^|/)(spec|plan|tasks)\.md"?$'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"casy-sdd: SDD-артефакт змінено — тримай spec.md -> plan.md -> tasks.md у синхроні; онови статус задачі в tasks.md ([ ] -> [~] -> [x])."}}'
fi
exit 0
