---
name: write-tasks
description: Розбиває spec.md + plan.md на tasks.md + tasks.json — атомарні задачі з ID, типом, залежностями, acceptance, files_hint і чекбоксами. Використовуй коли plan.md готовий і час нарізати роботу.
disable-model-invocation: true
argument-hint: [feature-slug]
arguments: feature
---

**Gate:** якщо `specs/$feature/spec.md` АБО `specs/$feature/plan.md` відсутній — СТОП, назви якого бракує і яку команду запустити (`/casy-sdd:write-spec $feature` / `/casy-sdd:write-plan $feature`). (Якщо `$feature` порожній — визнач активну фічу або спитай.)

Створи `specs/$feature/tasks.md` (для людей) І `specs/$feature/tasks.json` (для машини) зі `spec.md` + `plan.md`, з одного проходу.

Формат задачі (tasks.md):

```
- [ ] T01 [backend] Коротка назва
      Залежить: —
      Acceptance: що має бути правдою щоб задача була done
      Файли: src/x.ts, migrations/NN_x.ts
```

tasks.json — за схемою [`../_shared/tasks-schema.md`](../_shared/tasks-schema.md): `{slug, tasks:[{id, title, type, deps, acs, dod, files_hint}]}`. Перед записом перевір: `deps` лише наявні id, граф **ациклічний** (структурний проксі: топологічний порядок — задача залежить лише від менших T-номерів), обидва файли збігаються (ID/типи/залежності/файли).

- ID стабільні; тип `[backend]`/`[frontend]`; порядок за залежностями (backend-контракти перед frontend).
- Статуси: `[ ]` → `[~]` (чекає валідації) → `[x]`; веде імплементер.
- `files_hint` бери з §4 plan.md «File-level plan» — реальні шляхи (детермінує партиціювання в team-режимі).
- Сума задач покриває весь scope, без дір і надмірного дроблення.

> Увага: прямий виклик скіла обходить `sdd-orchestrator` і його СТОП-підтвердження переходів. Скіл — для швидкого соло-чернетки артефакту; повний керований цикл — через оркестратор.

## Handoff (друкуй ОСТАННІМ; формат — [`../_shared/handoff.md`](../_shared/handoff.md))

Три секції: **Що зробив** (`tasks.md` + `tasks.json`, N задач + коміт) · **Перевір** (`specs/$feature/tasks.md` — покриття scope, залежності) · **Далі** — `/casy-sdd:team $feature` (паралельно, agent teams) АБО веди через `sdd-orchestrator` (послідовно) у fenced-блоці.
