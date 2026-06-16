---
name: write-plan
description: Формує plan.md зі spec.md — підхід, модель даних, контракти, пофайловий план, технічні рішення, ризики. Використовуй коли spec.md готовий і час проєктувати реалізацію.
disable-model-invocation: true
argument-hint: [feature-slug]
arguments: feature
---

**Gate:** якщо `specs/$feature/spec.md` не існує — СТОП, надрукуй «spec.md відсутній — спершу `/casy-sdd:write-spec $feature`». (Якщо `$feature` порожній — визнач активну фічу або спитай назву.)

Створи `specs/$feature/plan.md` зі `specs/$feature/spec.md`:

1. **Approach** — рішення і чому так.
2. **Data model** — сутності/таблиці/поля, міграції, індекси.
3. **Contracts** — ендпоінти/функції/типи: вхід, вихід, помилки.
4. **File-level plan** — які файли створюємо/міняємо і навіщо (з нього task-splitter візьме `files_hint`).
5. **Tech decisions** — рішення + обґрунтування + відкинуті альтернативи.
6. **Risks** — ризики й залежності.

Дотримуйся наявного стеку. Backend Casy: **Knex обовʼязково, ORM заборонено** (повна версія — [`../_shared/stack-rules.md`](../_shared/stack-rules.md)). Кожне рішення мапиться на acceptance-критерій спеки.

> Увага: прямий виклик скіла обходить `sdd-orchestrator` і його СТОП-підтвердження переходів. Скіл — для швидкого соло-чернетки артефакту; повний керований цикл — через оркестратор.

## Handoff (друкуй ОСТАННІМ; формат — [`../_shared/handoff.md`](../_shared/handoff.md))

Три секції: **Що зробив** (`specs/$feature/plan.md` + коміт) · **Перевір** (`specs/$feature/plan.md` — кожна секція мапиться на ≥1 AC; §4 має конкретні файли) · **Далі** — `/casy-sdd:write-tasks $feature` у fenced-блоці.
