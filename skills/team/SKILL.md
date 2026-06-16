---
name: team
description: Запускає ПАРАЛЕЛЬНУ SDD-розробку командою агентів (agent teams) — лід + implementers + validator працюють одночасно над незалежними задачами з tasks.json. Використовуй коли tasks готові і треба гнати реалізацію командою, а не послідовно. Потребує CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.
argument-hint: [feature-slug]
effort: high
---

Ти — лід SDD-команди. Веди ПАРАЛЕЛЬНУ реалізацію фічі `$ARGUMENTS` командою тіммейтів через Claude Code agent teams. Координаційні тули (`TeamCreate`, `SendMessage`, `TaskCreate`/`TaskList`/`TaskGet`/`TaskUpdate`/`TaskStop`) доступні авто в team-сесії. Тіммейтів формуй через `TeamCreate`.

## Крок 0 — передумова + конфіг

Agent teams — експериментальна фіча (off by default, CC v2.1.32+). Прямо перевірити флаг не можна — запитай юзера, чи ввімкнено `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, або дізнайся при першому `TeamCreate` (провал = не ввімкнено). Якщо ні — СТОП, скажи додати в `~/.claude/settings.json`:

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

і перезапустити. Плагін сам це ввімкнути НЕ може — у плагінному `settings.json` дозволені лише `agent`/`subagentStatusLine`, не `env`.

**Конфіг:** якщо `.casy-sdd.local.md` у корені проєкту відсутній — створи його з дефолтами й коментарями (`max_team_size: 5`, `fail_escalate_at: 3`, `run_tests_on_validate: true`, `knex_required: true`) і додай рядок `.casy-sdd.local.md` у `.gitignore`. Читай ці ключі далі; нема файлу — дефолти.

## Крок 1 — артефакти (gate)

`specs/$ARGUMENTS/{spec,plan,tasks}.md` + `tasks.json` мають існувати. Бракує хоч одного — СТОП, назви який і яку команду (`/casy-sdd:write-spec|write-plan|write-tasks $ARGUMENTS`). spec/plan серійні — паралелити нема що, доки tasks не готові.

## Крок 2 — партиціювання файлів (із tasks.json)

Прочитай `specs/$ARGUMENTS/tasks.json`. Поле `files_hint` кожної задачі дає детермінований розподіл — НЕ парси прозу plan.md. Задачі з перетином `files_hint` НЕ давай паралельно: серіалізуй через `deps` або віддай одному тіммейту.

## Крок 3 — дзеркало задач у спільний список

Для кожної відкритої задачі зі `tasks.json` — `TaskCreate`: назва `T0X <title>`, у тілі тип `[backend]`/`[frontend]` + `acs` + `files_hint`, залежності з `deps`. `tasks.md` лишається durable-правдою; спільний список — ефемерний координатор.

## Крок 4 — сформуй команду

`TeamCreate` до `max_team_size` тіммейтів (дефолт 5, рекомендація 3–5): `sdd-implementer-backend` ×1–2, `sdd-implementer-frontend` ×1–2, `sdd-validator` ×1. Кожному імʼя + конкретний набір файлів (із кроку 2).

## Крок 5 — координація (гілкуйся за статус-токенами, не прозою)

Токени та щаблі → [`../_shared/escalation-policy.md`](../_shared/escalation-policy.md). Щабель визначай за `<!-- fail:N -->` на рядку задачі в `tasks.md` (відсутній = 0):
- Імплементер `STATUS:IMPLEMENTED` (поставив `[~]`) → валідатор.
- Валідатор `VERDICT:PASS` → імплементер фіналізує (`[x]` + completed, `STATUS:DONE`).
- Валідатор `VERDICT:FAIL` → ескалація за щаблями: fail:1 → ретрай з фідбеком валідатора; fail:2 → ретрай + вимагай дослівний перечит AC+контрактів; fail ≥ `fail_escalate_at` (дефолт 3) → імплементер поверне `STATUS:ESCALATE`, ти `TaskStop` задачу й ескалуй користувачу.
- Idle-сповіщення приходять авто — не поллі.

## Крок 6 — синхрон і фініш

Під час роботи `tasks.md` пишуть ЛИШЕ імплементери — ти його не чіпаєш (інакше гонка писарів). Усі тіммейти idle → звір спільний список із `tasks.md`, допиши пропущене (append-only). Усі `[x]`/completed → cleanup team, відзвітуй: фіча `$ARGUMENTS` завершена, що зробив кожен тіммейт, які файли торкнуті.

## Межі

- Один лід, одна команда за раз, без вкладених команд.
- Кожен тіммейт володіє своїм набором файлів (`files_hint`); перетин = конфлікти/перезаписи.
