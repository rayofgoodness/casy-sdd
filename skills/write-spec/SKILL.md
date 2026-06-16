---
name: write-spec
description: Формує spec.md для нової фічі — user stories, нумеровані тестовані acceptance-критерії, межі скоупу, edge cases. Використовуй коли починається нова фіча або користувач просить специфікацію.
disable-model-invocation: true
argument-hint: [feature-slug]
arguments: feature
---

Створи `specs/$feature/spec.md` за шаблоном [`./templates/spec.md`](./templates/spec.md) (його `<!-- instruction -->` коменти = per-секційний контракт). Якщо `$feature` порожній — визнач активну фічу або спитай назву.

Секції: 1) User stories · 2) Acceptance criteria · 3) Out of scope · 4) Edge cases · 5) Open questions.

Перед записом прочитай дотичний код, щоб критерії відповідали реальності проєкту.

**FORBIDDEN у acceptance-критеріях**: HTTP-дієслова (GET/POST/PUT/DELETE/PATCH), URL-шляхи (`/api/...`), коди статусів (200/404/...), SQL-конструкції (SELECT/JOIN/...), назви фреймворків/бібліотек/таблиць — це все у `plan.md`. AC = бізнес-спостережувана поведінка, вимірювана (без «швидко»/«зручно»). ≥1 AC на кожну user story; типи happy / error / authorization / domain-invariant / cross-context.

> Увага: прямий виклик скіла обходить `sdd-orchestrator` і його СТОП-підтвердження переходів. Скіл — для швидкого соло-чернетки артефакту; повний керований цикл — через оркестратор.

## Handoff (друкуй ОСТАННІМ; формат — [`../_shared/handoff.md`](../_shared/handoff.md))

Три секції: **Що зробив** (`specs/$feature/spec.md` + коміт `spec($feature): …`) · **Перевір** (`specs/$feature/spec.md` — кожен AC тестований і без реалізації) · **Далі** — команда `/casy-sdd:write-plan $feature` у fenced-блоці.
