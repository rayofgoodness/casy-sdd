# casy-sdd

Spec-driven development як Claude Code плагін. Оркестратор + воркери + шаблони артефактів. Працює в будь-якому проєкті (Casy backend, Casy client, Pink Code).

## Встановлення (з GitHub-маркету)

Репо саме є маркетплейсом (`.claude-plugin/marketplace.json`). У Claude Code:

```
/plugin marketplace add rayofgoodness/casy-sdd
/plugin install casy-sdd@casy-sdd
```

Оновлення прилітають коли бампнуто `version` у `plugin.json` (інакше — git SHA кожного коміту).

## Як працює

SDD-цикл крутиться навколо трьох стан-файлів у `specs/<feature>/`:

| Файл | Що це |
|------|-------|
| `spec.md` | що будуємо: user stories, acceptance, scope, edge cases |
| `plan.md` | як будуємо: архітектура, дані, контракти, пофайловий план |
| `tasks.md` | атомарні задачі зі статусами |

Оркестратор читає ці файли, визначає стан і делегує воркерам. Стан — завжди з файлів, не з памʼяті.

### Статуси задач

`[ ]` відкрита → `[~]` реалізована (чекає валідації) → `[x]` провалідована. Лічильник провалів — інлайн `<!-- fail:N -->`. Статус веде імплементер; валідатор лише виносить вердикт PASS/FAIL і у файл не пише.

Цикл по задачі: implementer ставить `[~]` → validator виносить вердикт → на PASS implementer ставить `[x]`, на FAIL implementer повторює (бампає `fail:N`, ескалація при N≥3).

## Компоненти

| Файл | Агент/скіл | Tools |
|------|------------|-------|
| `agents/orchestrator.md` | `sdd-orchestrator` — послідовний координатор, делегує | Read, Glob, Grep, Agent |
| `agents/team-lead.md` | `sdd-team-lead` — лід паралельної команди (agent teams) | Read, Glob, Grep, Agent, Write |
| `agents/specifier.md` | `sdd-specifier` — пише `spec.md` | Read, Glob, Grep, Write, Edit |
| `agents/architect.md` | `sdd-architect` — пише `plan.md` | Read, Glob, Grep, Write, Edit |
| `agents/task-splitter.md` | `sdd-task-splitter` — пише `tasks.md` | Read, Glob, Grep, Write, Edit |
| `agents/implementer-backend.md` | `sdd-implementer-backend` — backend-код (Knex, no ORM) | + Edit, Write, Bash |
| `agents/implementer-frontend.md` | `sdd-implementer-frontend` — frontend-код | + Edit, Write, Bash |
| `agents/validator.md` | `sdd-validator` — вердикт PASS/FAIL | Read, Glob, Grep, Bash |
| `agents/debugger.md` | `sdd-debugger` — read-only слідчий дебагу | Read, Glob, Grep, Bash |
| `skills/write-spec`, `write-plan`, `write-tasks` | шаблони артефактів, ручні (`/casy-sdd:write-spec <feature>` …) | — |
| `skills/team` | `/casy-sdd:team` — плейбук запуску паралельної команди | — |
| `skills/debug` | `/casy-sdd:debug` — режим дебагу (розслідування → інтервʼю → фікс) | — |
| `hooks/hooks.json` + `scripts/sdd-state-reminder.sh` | нагадування синхрону (опційно, тихе) | — |

## Запуск (dev, без встановлення)

```bash
claude --plugin-dir ./casy-sdd
```

Кілька плагінів одразу: `claude --plugin-dir ./a --plugin-dir ./b`.

Усередині сесії:
- `/agents` — перевір що зʼявились `sdd-*` агенти
- `/casy-sdd:write-spec` — виклич скіл напряму (соло-чернетка, без гейтів оркестратора)
- Або опиши фічу — `sdd-orchestrator` підхопиться за описом і поведе керований цикл

Після правок плагіна:

```
/reload-plugins
```

Підхоплює агентів, хуки, MCP. Зміни в `SKILL.md` діють одразу без релоуду.

## Валідація

```bash
claude plugin validate ./casy-sdd            # warnings — ок
claude plugin validate ./casy-sdd --strict   # warnings = errors
```

## Авто-завантаження без флага

```bash
claude plugin init casy-sdd
```

Кладе плагін у `~/.claude/skills/casy-sdd/`; наступна сесія вантажить як `casy-sdd@skills-dir` без `--plugin-dir`.

## Правила стеку

Backend Casy: **Knex обовʼязково, ORM заборонено**. Вшито в `sdd-architect` і `sdd-implementer-backend`. Frontend-правила — в `sdd-implementer-frontend`. Розширюй під свій проєкт прямо в цих файлах.

## Скіли vs оркестратор

- **Оркестратор** (`sdd-orchestrator`) — повний керований цикл зі СТОП-підтвердженнями на переходах spec→plan. Авто-шлях: артефакти пишуть агенти (`sdd-specifier`/`-architect`/`-task-splitter`).
- **Скіли** (`/casy-sdd:write-spec|write-plan|write-tasks <feature>`) — **ручні** (`disable-model-invocation`): не спрацьовують самі, лише за явним викликом. Швидка соло-чернетка одного артефакту в `specs/<feature>/`; гейти оркестратора обходяться. Аргумент — slug фічі.

### Конфіг скілів

| Скіл | Авто-виклик | Аргумент | effort |
|------|-------------|----------|--------|
| `write-spec/plan/tasks` | ні (ручні) | `feature` | — |
| `team` | так | `feature-slug` | high |
| `debug` | так | ціль | high |

## Два режими реалізації

| Режим | Координатор | Як працює | Потребує |
|-------|-------------|-----------|----------|
| **Послідовний** (дефолт) | `sdd-orchestrator` | одна задача за раз: implement → validate → next | нічого |
| **Команда** (паралельний) | `sdd-team-lead` + `/casy-sdd:team` | багато тіммейтів одночасно над незалежними задачами | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |

Фази `spec → plan → tasks` завжди послідовні (серійні за природою). Паралелиться лише **реалізація**.

## Режим команди (agent teams)

Розробка командою агентів-тіммейтів: лід дзеркалить `tasks.md` у спільний task-list, формує команду implementer'ів + validator, ті паралельно клеймлять незалежні задачі.

### Увімкнути

Agent teams — **експериментальна** фіча Claude Code (off by default, CC v2.1.32+). Додай у `~/.claude/settings.json`:

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

і перезапусти сесію. Плагін сам це ввімкнути НЕ може — у плагінному `settings.json` дозволені лише ключі `agent`/`subagentStatusLine`, не `env`.

### Запустити

```
/casy-sdd:team <feature-slug>
```

Поточна сесія стає лідом і веде плейбук: перевіряє флаг → переконується, що `spec/plan/tasks.md` готові → дзеркалить задачі у спільний список → формує 3–5 тіммейтів → координує → синхронить `tasks.md`. Або: `claude --agent sdd-team-lead`.

### Як координується

- **Спільний task-list** (`~/.claude/tasks/<team>/`) — рантайм-координатор; `tasks.md` лишається durable-джерелом правди (комітиться).
- **Тіммейти** самоклеймлять незаблоковані задачі свого типу (file-lock проти гонок), реалізують, повідомляють валідатора через `SendMessage`. PASS → `[x]`+completed; FAIL → фідбек, ретрай.
- **Координаційні тули** (`TeamCreate`, `SendMessage`, `Task*`) інжектяться авто в team-сесії — їх не вказують у `tools` агентів.

### Важливі застереження

- **Конфлікти файлів**: авто-локів файлів між тіммейтами нема. Лід дає кожному імплементеру РІЗНИЙ набір файлів; задачі на спільний файл — серіалізуй через `Залежить:`.
- **Масштаб**: 3–5 тіммейтів, одна команда за раз, без вкладених команд (рекомендації доки). Кожен тіммейт = окреме контекстне вікно → вартість росте лінійно.
- **Worktree-ізоляція** не береться: для команд не авто + нема авто-merge (фрагментує роботу по гілках). Партиціювання файлів простіше для інтегрованого коду.
- Фіча експериментальна — можливі шорсткості з resume/cleanup тіммейтів.

## Режим дебагу

Інтерактивний дебаг наявного коду — окремий від SDD-пайплайну (не потребує spec/plan/tasks).

```
/casy-sdd:debug <що дебажити: симптом / файл / фіча>
```

Цикл:
1. **Розслідування** — `sdd-debugger` (read-only) простежує як код працює зараз, шукає очевидні баги з `file:line`, формулює питання.
2. **Інтервʼю** — головна сесія показує тобі поточну поведінку + підозри, питає очікувану (симптом, як має бути, репро) і ЧЕКАЄ відповідей.
3. **Діагноз** — зіставляє факт vs очікування, показує корінь + запропонований фікс, чекає згоди.
4. **Виправлення** — лише за згодою: мінімальний фікс під корінь (backend: Knex/no-ORM), перевірка через репро. Великий фікс делегується імплементеру.

`sdd-debugger` нічого не редагує — інтервʼю та фікс веде головна сесія (subagent не може павзитись і питати користувача). Очікувану поведінку завжди дає користувач, агент її не вигадує.

## Контракти й конфіг (v1.3 — запозичено з genkovich/sdd)

### tasks.json + `files_hint`

`sdd-task-splitter` / `/casy-sdd:write-tasks` пишуть `tasks.md` (для людей) **і** `tasks.json` (для машини) з одного проходу. Схема — [`skills/_shared/tasks-schema.md`](skills/_shared/tasks-schema.md): `{slug, tasks:[{id,title,type,deps,acs,dod,files_hint}]}`. `files_hint` (з §4 plan.md «File-level plan») робить партиціювання файлів у team-режимі детермінованим — лід читає `tasks.json`, не парсить прозу.

### Статус-токени

Воркери звітують машино-читним токеном ОСТАННІМ рядком; координатори (`sdd-orchestrator`/`sdd-team-lead`/`debug`) гілкуються за ним, не за прозою. Канон — [`skills/_shared/escalation-policy.md`](skills/_shared/escalation-policy.md):
- імплементер: `STATUS:IMPLEMENTED` / `STATUS:DONE` / `STATUS:ESCALATE:<чому>`
- валідатор: `VERDICT:PASS` / `VERDICT:FAIL`

### 3-щаблева ескалація

На `VERDICT:FAIL`: fail:1 → ретрай з фідбеком; fail:2 → ретрай + примусовий дослівний перечит AC(spec)+контрактів(plan); fail ≥ `fail_escalate_at` (дефолт 3) → стоп + ескалація.

### Hard-refuse гейти

Скіли самі перевіряють передумови: `write-plan` стоп без `spec.md`; `write-tasks` стоп без spec+plan; `team` стоп без усіх трьох + `tasks.json`. Закриває діру коли прямий виклик скілу обходить оркестратор.

### Handoff-блок

Кожен `write-*` скіл наприкінці друкує: **Що зробив / Перевір (шляхи) / Далі (копі-реді команда)**. Формат — [`skills/_shared/handoff.md`](skills/_shared/handoff.md).

### `.casy-sdd.local.md` (per-project конфіг)

Авто-створюється `/casy-sdd:team` на першому запуску (+ рядок у `.gitignore`). Ключі: `max_team_size` (5), `fail_escalate_at` (3), `run_tests_on_validate` (true), `knex_required` (true). Нема файлу → дефолти.

### `skills/_shared/` (де-дуб)

Канонічні контракти в одному місці: `stack-rules.md`, `escalation-policy.md`, `tasks-schema.md`, `handoff.md`. Скіли лінкують відносним шляхом; агенти тримають короткий essential інлайн + вказівник (їхній рантайм-контекст не гарантує читання plugin-файлів).

### model / effort

Агенти мають `model: inherit` (поважає `/model` — не форсить даунгрейд) + `effort` (specifier/architect/validator/debugger high, решта medium/low). `effort` — advisory, ефект залежить від білда CC; надійний оверайд — env `CLAUDE_CODE_EFFORT_LEVEL`. Хочеш економити — постав `model: sonnet` дешевим ролям.

## Нотатки дизайну та відомі обмеження

- `sdd-specifier` / `sdd-architect` / `sdd-task-splitter` мають `Write` — бо саме вони створюють `spec.md` / `plan.md` / `tasks.md`. Read-only тут неможливий.
- `sdd-validator` — hard read-only щодо коду й артефактів (Read/Glob/Grep/Bash; Bash лише для тестів/лінта). Статус у `tasks.md` пише імплементер, не валідатор.
- `sdd-orchestrator` без Edit/Write — тільки делегує через `Agent` (старий аліас `Task` ще працює).
- **Обмеження**: імплементери мають незаскоупований `Edit`/`Write` — формально могли б зачепити `spec.md`/`plan.md`. Заборона лише в промпті, не в tools (CC не дає path-scoped tool-grant у frontmatter). Якщо це критично — рознеси артефакти й код по окремих репо.
- **Делегування**: оркестратор спавнить воркерів через `Agent`. Якщо твоя версія CC обмежує вкладене делегування (subagent → subagent) — веди цикл із головної сесії за тією ж машиною станів (головний Claude підхопить опис оркестратора).

## Хук (опційно)

`hooks/hooks.json` + `scripts/sdd-state-reminder.sh` — на PostToolUse після Write/Edit. Тихий: спрацьовує лише коли правили рівно `spec.md`/`plan.md`/`tasks.md`, тоді шле Клоду `additionalContext`-нагадування тримати артефакти в синхроні. Нічого не змінює, завжди exit 0. Потребує `jq` (є фолбек на `grep`). Вимкнути — прибери теку `hooks/`.

## Шаринг

1. Цей `README.md`.
2. Версії: бампай `version` у `plugin.json` (інакше Claude Code бере git commit SHA — кожен коміт = нова версія).
3. GitHub репо → marketplace: <https://code.claude.com/docs/en/plugin-marketplaces>
