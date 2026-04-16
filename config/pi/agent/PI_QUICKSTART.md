# Pi Agent — быстрый старт

## 1) Установка Pi

### Требования

- macOS/Linux
- Node.js 20+
- npm
- git

### Установка

#### Ubuntu 24.04 LTS

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
mkdir -p ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
```

```bash
npm install -g @mariozechner/pi-coding-agent
```

Проверка:

```bash
pi --version
```

### Авторизация

Используем только FLANT ключ:

```bash
export FLANT_API_KEY="<your_flant_key>"
pi
```

---

## 2) Обязательные плагины (packages)

Ниже — минимальный набор, который стоит поставить сразу.

### 2.1 `danilrwx/pi-core` (обязательно)

```bash
pi install git:github.com/danilrwx/pi-core
```

Что дает:

- набор базовых skills для повседневной работы;
- полезные extensions, например LSP, handoff/session-query и др.;
- удобную основу для agent workflow.

### 2.2 `fox.../pi-virtualization-extras` (обязательно)

```bash
pi install git:git@fox.flant.com:team/virtualization/pi-virtualization-extras.git
```

Что дает:

- skills для работы с deckhouse/virtualization;
- вспомогательные навыки для коммитов, PR и Kaiten.

### 2.3 `fox.../pi-flant-provider` (обязательно)

```bash
pi install git:git@fox.flant.com:team/virtualization/pi-flant-provider.git
```

Что дает:

- провайдер `flant` в Pi для корпоративных моделей;
- команду `/flant-update-models` для обновления списка моделей.

### 2.4 `pi-permissions` (рекомендуется)

```bash
pi install npm:pi-permissions
```

Что дает:

- allow/deny rules для tool calls агента;
- контроль над тем, какие `bash`, `read`, `write`, `edit` действия разрешены;
- возможность явно запретить опасные операции, например `git push` или запись в чувствительные файлы.

Базовая идея:

- `deny`-правила блокируют действие всегда;
- `allow`-правила позволяют собрать whitelist для нужных операций;
- конфиг можно хранить локально в проекте (`.pi/permissions.json`) или глобально (`~/.pi/agent/permissions.json`).

Минимальный пример `.pi/permissions.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git commit *)",
      "Read(*)",
      "Edit(*)",
      "Write(*)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(rm -rf *)",
      "Write(*.env)",
      "Edit(*.env)"
    ]
  }
}
```

После изменения `permissions.json` внутри Pi выполни:

```text
/reload
```

---

## 3) Краткая выжимка по обязательным плагинам

## `danilrwx/pi-core`

### Основные skills

- **agent-browser** — автоматизация браузера: открыть сайт, кликнуть, заполнить форму, снять скриншот, собрать данные.
- **github** — работа с GitHub через `gh`: PR, checks, runs, issue, API.
- **web-search** — быстрый веб-поиск через Jina API.
- **tmux** — управление интерактивными CLI-процессами в tmux.
- **session-query** — запрос данных из прошлых сессий Pi.
- **skill-creator** — шаблон/гайд для создания новых skills.

### Основные extensions

- **lsp-pi** — language server операции: definition, references, diagnostics, rename.
- **interactive-shell** — удобная работа с интерактивными shell-сценариями.
- **session-query / handoff** — поддержка передачи и чтения контекста между сессиями.
- **model-price** — информация по стоимости моделей.
- **golangci-lint** — авто-запуск `golangci-lint run --fix` для изменённых Go-файлов.

### Дополнительно: `lsp-pi`, `golangci-lint`, `jina-web`

#### `lsp-pi`

Что умеет:

- on-demand LSP tool: `definition`, `references`, `hover`, `symbols`, `diagnostics`, `workspace-diagnostics`, `signature`, `rename`, `codeAction`;
- авто-диагностика изменённых файлов, обычно в конце ответа агента.

Полезные примеры:

```bash
lsp action=definition file=src/main.ts query=createClient
lsp action=references file=src/main.ts query=createClient
lsp action=diagnostics file=src/main.ts severity=error
lsp action=workspace-diagnostics files=["src/a.ts","src/b.ts"] severity=warning
```

Настройка режима авто-диагностики:

- команда `/lsp` в интерактивной сессии;
- режимы: `agent_end` (по умолчанию), `edit_write`, `disabled`.

#### `golangci-lint`

Как работает:

- отслеживает изменения через `write/edit` только для `*.go`;
- в конце ответа агента запускает `golangci-lint run --fix --timeout 5m ./...` в затронутых Go-модулях;
- отправляет результат отдельным follow-up сообщением.

Требования:

- `golangci-lint` должен быть в `PATH`;
- в модуле должен быть `go.mod`;
- желательно иметь конфиг `.golangci.yml|yaml|toml|json`.

#### `jina-web`

Что даёт:

- tool `web_search` — поиск через `https://s.jina.ai`;
- tool `fetch_content` — чтение страниц через `https://r.jina.ai` в markdown-формате.

API key:

- переменная окружения: `JINA_API_KEY`;
- получить ключ можно в личном кабинете Jina AI: `https://jina.ai/`.

Пример:

```bash
export JINA_API_KEY="<your_jina_key>"
```

VPN:

- для стабильного доступа к `s.jina.ai` и `r.jina.ai` в корпоративной сети часто нужен VPN;
- если видишь timeout, connection error или HTTP ошибки на Jina endpoints — сначала проверь VPN.

---

## 4) Изоляция агента: используем `nono`

Вместо старого `sandbox` теперь для изоляции Pi рекомендуем использовать `nono`.

Важно не путать `nono` и `pi-permissions`:

- **`pi-permissions`** — это слой правил для самого агента: какие tool calls разрешены, что нужно ограничить, что надо явно запретить;
- **`nono`** — это слой системной изоляции процесса Pi: доступ к файловой системе, рантаймам, сетям и другим ресурсам окружения.

То есть `pi-permissions` отвечает за **policy/approval на уровне действий агента**, а `nono` — за **изоляцию на уровне ОС/ядра и runtime environment**. Они не заменяют друг друга, а закрывают разные классы рисков.

### Установка `nono`

#### macOS

```bash
brew install nono
```

#### Ubuntu/Debian

Смотри актуальный способ установки в репозитории/релизах `nono` для своей системы.

### Базовая идея

Pi запускается через `nono` с профилем, который ограничивает доступ к файловой системе, но оставляет доступ к нужным рабочим директориям, кэшу и сетям.

Практически это стоит использовать вместе с `pi-permissions`:

- `pi-permissions` ограничивает, **что агенту логически можно делать**;
- `nono` ограничивает, **к чему процесс технически имеет доступ**, даже если агент или extension попробует сделать лишнее.

Пример запуска:

```bash
nono run -p pi -- pi
```

Если нужен старт сразу в проекте:

```bash
cd ~/work/my-project
nono run -p pi -- pi
```

### Пример профиля `~/.config/nono/profiles/pi.json`

```json
{
  "meta": {
    "name": "pi",
    "version": "1.0.0",
    "description": "Profile for the Pi coding agent"
  },
  "interactive": true,
  "workdir": {
    "access": "readwrite"
  },
  "security": {
    "groups": [
      "node_runtime",
      "python_runtime",
      "go_runtime",
      "unlink_protection",
      "system_read_macos",
      "system_write_macos",
      "user_caches_macos"
    ]
  },
  "filesystem": {
    "allow": [
      "$HOME/.pi",
      "$HOME/.cache",
      "$TMPDIR"
    ],
    "read": [
      "$HOME/dotfiles",
      "$HOME/.kube",
      "$HOME/.kubeconfigs",
      "$HOME/.agents",
      "$HOME/.config/gh",
      "$HOME/.config/git",
      "$HOME/.local/share/uv"
    ],
    "write": [],
    "allow_file": [],
    "read_file": [
      "$HOME/AGENTS.md",
      "$HOME/.gitconfig",
      "$HOME/.gitignore_global"
    ],
    "write_file": []
  },
  "policy": {
    "override_deny": [
      "$HOME/.ssh"
    ],
    "add_allow_readwrite": [
      "$HOME/.ssh"
    ]
  },
  "network": {
    "block": false
  }
}
```

### Что важно учесть

- профиль выше — только пример, его надо адаптировать под свои директории;
- если работаешь не только в `~/dotfiles`, добавь нужные project paths в `filesystem.read` или выдай нужный режим через `workdir`;
- если используешь `gh`, `git`, `ssh`, `kubectl`, `uv`, убедись, что нужные конфиги и runtime-пути доступны из профиля;
- для Linux набор security groups и filesystem paths может отличаться.

---

## 5) Кратко по `pi-flant-provider` (обязательный)

### `pi-flant-provider`

Назначение:

- добавляет в Pi провайдер моделей `flant` (`https://llm-api.flant.ru/v1`);
- хранит кэш метаданных моделей в `~/.pi/agent/extensions/flant-provider/models.json`;
- обновляет список моделей командой `/flant-update-models`.

Установка:

```bash
pi install git:git@fox.flant.com:team/virtualization/pi-flant-provider.git
```

Минимальная настройка:

```bash
export FLANT_API_KEY="<your_flant_key>"
```

Первичная инициализация после установки:

```text
/flant-update-models
```

Что важно по работе:

- провайдер использует whitelist моделей из расширения;
- цены и контекст подтягиваются из OpenRouter metadata;
- если `models.json` пустой или отсутствует, сначала выполни `/flant-update-models`.

### `npm:pi-cursor-agent` (опционально)

Назначение:

- добавляет провайдер Cursor Agent в Pi;
- позволяет использовать модели Cursor по подписке Cursor.

Установка:

```bash
pi install npm:pi-cursor-agent
```

Авторизация:

1. Запусти `pi`
2. Выполни `/login`
3. Выбери провайдер **Cursor Agent**
4. В браузере залогинься в Cursor

Требования:

- `pi >= 0.52.10`;
- активная подписка Cursor.

Важно:

- `FLANT_API_KEY` для этого провайдера не используется;
- это дополнительный, а не обязательный провайдер.

### `rtk` (рекомендуется)

`rtk` больше не приезжает автоматически через `pi-core`, поэтому его надо поставить отдельно.

Зачем нужен:

- снижает расход токенов на shell-командах, обычно на **60–90%**;
- сжимает и фильтрует шумный вывод: `git`, тесты, линтеры, логи;
- помогает дольше держать контекст в целевых 30%.

Установка:

```bash
brew install rtk
# или
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

Проверка:

```bash
rtk --version
rtk gain
```

Базовая инициализация hook:

```bash
rtk init -g
```

После этого перезапусти агент или терминал.

Примечание для Pi + RTK optimizer:

- команда `/rtk` управляет режимом source filtering, если расширение доступно;
- если точечный `edit` не попадает в текст, временно отключи filtering через `/rtk`, перечитай файл, внеси правку и включи обратно.

Другие сторонние pi packages ставятся аналогично через `pi install <source>`.

Примеры:

```bash
pi install npm:@scope/pi-package
pi install git:github.com/user/repo
pi install /path/to/local/package
```

---

## 6) Полезные переменные окружения

### `PI_OFFLINE=1`

Если не хочешь, чтобы Pi при каждом запуске делал стартовые сетевые операции, включая проверку обновлений, включи offline mode:

```bash
export PI_OFFLINE=1
```

Что это даёт:

- отключает стартовые сетевые операции;
- отключает проверку обновлений при старте;
- удобно для медленных сетей, VPN-проблем и предсказуемого запуска.

Разовый запуск без изменения shell-профиля:

```bash
PI_OFFLINE=1 pi
```

Либо через CLI-флаг:

```bash
pi --offline
```

Если нужен только пропуск проверки версии без полного offline режима, можно использовать:

```bash
export PI_SKIP_VERSION_CHECK=1
```

Чтобы включить `PI_OFFLINE=1` постоянно, добавь в `~/.zshrc` или `~/.bashrc`:

```bash
echo 'export PI_OFFLINE=1' >> ~/.zshrc
```

---

## 7) Полезные команды после установки

```bash
pi list                      # какие пакеты установлены
pi update                    # обновить не зафиксированные версии
pi remove git:github.com/danilrwx/pi-core
```

Внутри сессии Pi:

```bash
/skill:github
/skill:agent-browser
/skill:virtualization
/flant-update-models
```

---

## 8) Workflow: как пользоваться агентом

Рекомендуемый рабочий цикл:

1. Запусти `pi` в нужной директории проекта.
2. В начале сессии сформулируй задачу коротко и с контекстом: что сделать, где, критерий готовности.
3. Если задача большая — разбивай на этапы; переход между этапами делай через `/handoff`.
4. После изменений `pi` сам запустит линтеры и при необходимости поправит ошибки.
5. Для новой независимой задачи — делай новую сессию через `/new`.
6. Продолжить прошлую сессию можно через `/resume`.
7. Если всё готово к коммиту, можно попросить агента сделать коммит — он использует skill по конвенциям репозитория.
8. Когда PR готов, можно попросить агента обновить его описание — он заполнит его по шаблону.

### Основные команды в сессии

```bash
/model                 # выбрать модель
/new                   # новая сессия
/resume                # открыть прошлую сессию
/session               # информация по текущей сессии
/tree                  # дерево сообщений и ветвление
/fork                  # форк текущей ветки в отдельную сессию
/compact               # сжать контекст вручную
/settings              # настройки агента
/reload                # перезагрузить skills/extensions/prompts
/skill:github          # принудительно вызвать skill
/flant-update-models   # обновить модели провайдера flant
/rtk                   # настройки RTK/source filtering, если доступно
/quit                  # выход
```

### `/handoff` — передача контекста в новую сессию

В `pi-core` есть handoff extension, который переносит важный контекст в новый тред.

Когда использовать:

- текущий тред разросся и уходит в шум;
- нужно переключиться на подзадачу;
- хочешь сменить модель или режим под следующий шаг.

Примеры:

```bash
/handoff доделай тесты для текущего фикса
/handoff -mode rush проверь все похожие места в коде
/handoff -model anthropic/claude-haiku-4-5 подготовь только рефакторинг без новых фич
```

Что происходит:

- расширение собирает ключевые решения и файлы из текущего диалога;
- формирует стартовый prompt для новой сессии;
- ты продолжаешь работу в более чистом контексте.

### Рекомендация по контексту

Держи загрузку контекста **не выше 30%**.

Практика:

- на 20–30% уже планируй `/compact` или `/handoff`;
- не копи длинные логи целиком — давай только релевантные куски;
- большие задачи дроби на отдельные сессии.

---

## 9) Быстрый bootstrap

```bash
npm install -g @mariozechner/pi-coding-agent
pi install git:github.com/danilrwx/pi-core
pi install git:git@fox.flant.com:team/virtualization/pi-virtualization-extras.git
pi install git:git@fox.flant.com:team/virtualization/pi-flant-provider.git
pi install npm:pi-permissions

# отдельно ставим rtk, если хотим экономить токены на shell-output
brew install rtk
# или
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

export FLANT_API_KEY="<your_flant_key>"
pi
# внутри pi выполнить:
# /flant-update-models
```

Готово: после этого у тебя будет рабочий Pi с обязательными корпоративными навыками, провайдером FLANT, rules layer через `pi-permissions`, изоляцией через `nono` и отдельным `rtk` для оптимизации shell-вывода.
