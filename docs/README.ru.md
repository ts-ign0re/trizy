<p align="center">
  <img src="../assets/icon.svg" width="128" alt="trizy">
</p>

<h1 align="center">trizy</h1>

<p align="center"><b>Один операционный контракт для всех агентов-кодеров в вашем репозитории.</b></p>

<p align="center">План, сборка, ревью, гейт и журнал: всё обеспечивают git-хуки, написано на POSIX sh, ставить ничего не нужно, кроме git.</p>

<p align="center">
  <a href="https://github.com/ts-ign0re/trizy/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ts-ign0re/trizy/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/ts-ign0re/trizy/releases/latest"><img src="https://img.shields.io/github/v/release/ts-ign0re/trizy?style=flat-square" alt="Latest release"></a>
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/POSIX-sh-4ade80?style=flat-square" alt="POSIX sh">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square" alt="Linux | macOS">
</p>

<p align="center">
  <a href="#что-это">О проекте</a> ·
  <a href="#установка">Установка</a> ·
  <a href="#быстрый-старт">Быстрый старт</a> ·
  <a href="#документация">Документация</a>
</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <b>Русский</b> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a>
</p>

---

## Что это

trizy — фреймворк, который репозиторий устанавливает сразу для всех своих агентов (Claude Code, Codex) и всех
своих людей. Он определяет, как задача выбирается, делается, проходит ревью и гейт, попадает в журнал и
доставляется, а git-хуки следят за его соблюдением, так что правила действуют, даже когда агент о них забывает.

Агенты хорошо пишут код, но плохо держат дисциплину. Они пропускают ревью, заявляют, что тест прошёл, не запустив
его, строят лишнее и повторяют ошибку, которую кто-то исправил вчера. trizy закрывает эти пробелы четырьмя вещами:

1. **Контракт в репозитории.** `AGENTS.trizy.md`, правила и `CONSTRAINTS.md` импортируются в `CLAUDE.md` и
   `AGENTS.md`. Каждое исправление от человека или гейта становится одной строкой в `CONSTRAINTS.md`, чтобы ни
   один агент не повторил ошибку.
2. **Гейты, которые отказывают.** Хук pre-commit запускает ваш флоу `commit` и отклоняет коммит без одобренной
   квитанции ревью ровно для проиндексированного (staged) дерева. Ревьюер не может быть автором, и ни одно
   блокирующее или серьёзное замечание не может оставаться открытым. Хук pre-push отклоняет коммиты, которых нет
   в журнале прогонов.
3. **Оптимальность для каждого решения.** Каждому новому файлу, хранилищу, механизму или формату нужна строка,
   которая называет более дешёвые варианты и ограничение, исключающее каждый из них. Скилл `ponytail` держит дифф
   коротким.
4. **Память прогонов.** Локальный журнал (`.git/trizy/runs/`, общий для всех worktree, никогда не коммитится).
   Еженедельный скилл `retro` читает его и предлагает изменения правил на одобрение владельцу.

Название — отсылка к ТРИЗ, теории решения изобретательских задач. Её *идеальный конечный результат* — функция,
выполненная без добавления чего-либо, и именно этого проверка оптимальности требует от каждого решения.

## Возможности

- **Любой агент, один контракт.** Размеченный блок в `CLAUDE.md` (его импортирует Claude Code) и `AGENTS.md`
  (Codex). Скиллы также подключаются ссылками в `.codex/skills/`.
- **Флоу и шаги.** `commit`, `push` и ваши собственные флоу из shell-шагов `run` и инструкций `ask` хранятся в
  `.trizy/flows.tsv`.
- **Квитанции ревью.** `trizy review prepare` перечисляет каждый проиндексированный файл с его правилами ревью, а
  скилл `review-gate` заполняет квитанцию.
- **Пайплайн `deliver`.** Превращает задачу в план, который одобряет владелец, а затем в пакеты. Каждый пакет
  собирается в своём worktree и проходит независимый гейт, прежде чем его сольют в `deliver/<slug>`.
- **Worktree и очередь тяжёлых команд.** `trizy worktree new` стартует от только что полученной основной ветки.
  `trizy heavy -- make test` ставит тяжёлые команды в очередь, общую для всей машины.
- **Уживается с husky.** Если задан другой путь к хукам, `init` предлагает заменить его или объединиться с ним.
- **В git или в игнор.** Закоммитьте файлы агентов для всей команды или оставьте их локальными в своём клоне.
- **Своя копия в каждом репозитории.** Каждый проект запускает свою копию (`.trizy/bin/trizy`), поэтому у коллег
  без установки хуки тоже работают.

## Установка

### Требования

- **Система:** Linux или macOS с `sh`, `git`, `curl` и `tar`. Windows не поддерживается.
- **Агенты:** Claude Code и/или Codex. trizy работает с любым из них и с людьми, которые не пользуются ни тем, ни
  другим.

### Последний релиз

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

Скрипт скачивает последний релиз, проверяет его контрольную сумму SHA-256, кладёт файлы trizy в
`~/.local/share/trizy`, а команду `trizy` — в `~/.local/bin`. Без sudo. Чтобы установить в другое место, задайте
`TRIZY_HOME` и `TRIZY_BIN`; чтобы поставить конкретный релиз — `TRIZY_VERSION=v0.3.0`.

### Из исходников

```sh
git clone https://github.com/ts-ign0re/trizy && cd trizy
sh install.sh              # installs this checkout's committed HEAD
```

`sh install.sh --uninstall` удаляет команду и установку. Репозитории сохраняют свою копию.

## Быстрый старт

```sh
cd your-repo
trizy init                 # asks: agent files in git (team-wide) or ignored (local)?
$EDITOR .trizy/flows.tsv   # your lint and test commands as commit and push steps
trizy check
```

| Команда | Что делает |
|---|---|
| `trizy init [--track\|--ignore] [--hooks=replace\|merge]` | устанавливает trizy в этот репозиторий |
| `trizy step add commit lint run "make lint"` | добавляет шаг во флоу |
| `trizy flow run <flow>` | запускает шаги флоу, останавливается на первой ошибке, пишет логи в файлы |
| `trizy review prepare \| verify` | квитанция ревью для проиндексированного дерева |
| `trizy log task="..." result=pass` | добавляет запись в журнал прогонов |
| `trizy worktree new <branch>` | worktree от свежей основной ветки |
| `trizy heavy -- <cmd>` | запускает тяжёлую команду через общую для машины очередь |
| `trizy upgrade`, `trizy update` | ставит последний релиз, затем обновляет до него репозиторий |

| Гейт | Отклоняет |
|---|---|
| pre-commit | упавший шаг `commit`; коммит без одобренной квитанции ровно для проиндексированного дерева |
| pre-push | отправляемый коммит, который не является HEAD этой чистой рабочей копии; коммиты, после которых нет записи в журнале; упавший шаг `push` |

## Документация

Документация написана на английском.

- [Справочник](REFERENCE.md) — что устанавливает `init`, обновление, флоу и шаги, порядок каждой задачи,
  инструменты, ретро
- [Контракт](../template/.trizy/AGENTS.trizy.md) и [правила](../template/.trizy/rules/)
- [Журнал изменений](../CHANGELOG.md)

Разработка: `sh tests/run.sh` прогоняет 99 проверок на одноразовых репозиториях, а
`TRIZY_SH=dash sh tests/run.sh` запускает CLI в строгой POSIX-оболочке.

## Лицензия

trizy распространяется по лицензии **MIT**. Полный текст — в файле [LICENSE](../LICENSE).

Встроенные сторонние скиллы и их лицензии перечислены в
[THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md).
