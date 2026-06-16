# tasks.json — машино-читний DAG задач (канонічна схема)

> Reference-only. Не скіл. `write-tasks` / `sdd-task-splitter` пишуть `tasks.md` (для людей) І `tasks.json` (для машини) з одного проходу. `sdd-team-lead` читає `tasks.json` для партиціювання файлів; імплементери беруть `files_hint` як скоуп файлів.

## Схема

```json
{
  "slug": "<feature-slug>",
  "tasks": [
    {
      "id": "T01",
      "title": "Коротка назва",
      "type": "backend",
      "deps": [],
      "acs": ["acceptance-критерій 1"],
      "dod": "що має бути правдою щоб задача була done",
      "files_hint": ["src/path/file.ts", "migrations/NN_x.ts"]
    }
  ]
}
```

`type` ∈ `backend` | `frontend`.

## Правила

- `id` стабільні (T01…), збігаються з `tasks.md`.
- `deps` — лише наявні `id`; граф **ациклічний** (`write-tasks` перевіряє перед записом).
- `files_hint` — конкретні файли/шляхи, які задача створює/міняє (з `plan.md` «File-level plan»). Робить партиціювання в team-режимі детермінованим, не з прози.
- Задачі з перетином `files_hint` у team-режимі НЕ йдуть паралельно — серіалізуй через `deps` або віддай одному тіммейту.
- `tasks.md` — людське дзеркало; `tasks.json` — машинний контракт. Тримати синхронними (статуси веде імплементер у `tasks.md`).
