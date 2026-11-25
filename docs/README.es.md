<p align="center">
  <img src="../assets/icon.svg" width="128" alt="trizy">
</p>

<h1 align="center">trizy</h1>

<p align="center"><b>Un único contrato de trabajo para todos los agentes de programación de tu repositorio.</b></p>

<p align="center">Planificar, construir, revisar, pasar el gate y registrar: lo hacen cumplir los hooks de git, está escrito en POSIX sh y no hay nada que instalar salvo git.</p>

<p align="center">
  <a href="https://github.com/ts-ign0re/trizy/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ts-ign0re/trizy/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/ts-ign0re/trizy/releases/latest"><img src="https://img.shields.io/github/v/release/ts-ign0re/trizy?style=flat-square" alt="Latest release"></a>
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/POSIX-sh-4ade80?style=flat-square" alt="POSIX sh">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square" alt="Linux | macOS">
</p>

<p align="center">
  <a href="#qué-es">Qué es</a> ·
  <a href="#instalación">Instalación</a> ·
  <a href="#inicio-rápido">Inicio rápido</a> ·
  <a href="#documentación">Documentación</a>
</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.ru.md">Русский</a> ·
  <b>Español</b> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a>
</p>

---

## Qué es

trizy es un framework que un repositorio instala a la vez para todos sus agentes de programación (Claude Code,
Codex) y todas sus personas. Define cómo se elige una tarea, cómo se construye, se revisa, pasa el gate, se
registra en el diario y se entrega, y los hooks de git lo hacen cumplir, así que las reglas se mantienen incluso
cuando el agente las olvida.

Los agentes escriben buen código pero tienen poca disciplina. Se saltan la revisión, afirman que un test pasó sin
ejecutarlo, construyen de más y repiten un error que alguien corrigió ayer. trizy cierra esas brechas con cuatro
cosas:

1. **Un contrato en el repositorio.** `AGENTS.trizy.md`, las reglas y `CONSTRAINTS.md` se importan en
   `CLAUDE.md` y `AGENTS.md`. Cada corrección de una persona o de un gate se convierte en una línea de
   `CONSTRAINTS.md`, para que ningún agente la repita.
2. **Gates que rechazan.** El hook pre-commit ejecuta tu flujo `commit` y rechaza un commit sin un recibo de
   revisión aprobado exactamente para el árbol preparado (staged). El revisor no puede ser el autor, y no puede
   quedar abierto ningún hallazgo bloqueante o grave. El hook pre-push rechaza los commits que no están en el
   diario de ejecuciones.
3. **Optimalidad por decisión.** Cada archivo, almacén, mecanismo o formato nuevo necesita una línea que nombre
   las opciones más baratas y la restricción que descarta cada una. La skill `ponytail` mantiene el diff corto.
4. **Una memoria de ejecuciones.** Un diario local (`.git/trizy/runs/`, compartido por los worktrees, nunca se
   hace commit). La skill semanal `retro` lo lee y propone cambios en las reglas para que el propietario los
   apruebe.

El nombre es un guiño a TRIZ, la teoría de la resolución de problemas inventivos. Su *resultado final ideal* es la
función entregada sin añadir nada, y eso es lo que la comprobación de optimalidad exige a cada decisión.

## Características

- **Cualquier agente, un solo contrato.** Un bloque marcado en `CLAUDE.md` (que importa Claude Code) y en
  `AGENTS.md` (Codex). Las skills también se enlazan en `.codex/skills/`.
- **Flujos y pasos.** `commit`, `push` y tus propios flujos, formados por pasos `run` de shell e instrucciones
  `ask`, guardados en `.trizy/flows.tsv`.
- **Recibos de revisión.** `trizy review prepare` lista cada archivo preparado con sus reglas de revisión, y la
  skill `review-gate` rellena el recibo.
- **El pipeline `deliver`.** Convierte una tarea en un plan que aprueba el propietario y luego en paquetes. Cada
  paquete se construye en su propio worktree y pasa un gate independiente antes de fusionarse en
  `deliver/<slug>`.
- **Worktrees y una cola de comandos pesados.** `trizy worktree new` parte de la rama principal recién
  descargada. `trizy heavy -- make test` encola los comandos pesados para toda la máquina.
- **Convive con husky.** Si hay otra ruta de hooks configurada, `init` ofrece reemplazarla o combinarse con ella.
- **Versionar o ignorar.** Haz commit de los archivos de agentes para todo el equipo o mantenlos locales en tu
  clon.
- **Fijado por repositorio.** Cada proyecto ejecuta su propia copia (`.trizy/bin/trizy`), así que los compañeros
  que no lo tienen instalado siguen teniendo hooks que funcionan.

## Instalación

### Requisitos

- **Sistema:** Linux o macOS con `sh`, `git`, `curl` y `tar`. Windows no está soportado.
- **Agentes:** Claude Code y/o Codex. trizy funciona con cualquiera de los dos y con personas que no usan
  ninguno.

### Última versión

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

El script descarga la última versión, verifica su suma de comprobación SHA-256, coloca el kit en
`~/.local/share/trizy` y el comando `trizy` en `~/.local/bin`. Sin sudo. Define `TRIZY_HOME` y `TRIZY_BIN` para
instalarlo en otro lugar, o `TRIZY_VERSION=v0.3.0` para instalar una versión concreta.

### Desde el código fuente

```sh
git clone https://github.com/ts-ign0re/trizy && cd trizy
sh install.sh              # installs this checkout's committed HEAD
```

`sh install.sh --uninstall` elimina el comando y la instalación. Los repositorios conservan su propia copia.

## Inicio rápido

```sh
cd your-repo
trizy init                 # asks: agent files in git (team-wide) or ignored (local)?
$EDITOR .trizy/flows.tsv   # your lint and test commands as commit and push steps
trizy check
```

| Comando | Qué hace |
|---|---|
| `trizy init [--track\|--ignore] [--hooks=replace\|merge]` | instala trizy en este repositorio |
| `trizy step add commit lint run "make lint"` | añade un paso a un flujo |
| `trizy flow run <flow>` | ejecuta los pasos de un flujo, se detiene en el primer fallo y escribe los logs en archivos |
| `trizy review prepare \| verify` | el recibo de revisión del árbol preparado |
| `trizy log task="..." result=pass` | añade una entrada al diario de ejecuciones |
| `trizy worktree new <branch>` | un worktree desde la rama principal recién descargada |
| `trizy heavy -- <cmd>` | ejecuta un comando pesado a través de la cola de toda la máquina |
| `trizy upgrade`, `trizy update` | instala la última versión y luego actualiza un repositorio a ella |

| Gate | Rechaza |
|---|---|
| pre-commit | un paso `commit` que falla; un commit sin un recibo aprobado exactamente para el árbol preparado |
| pre-push | un commit enviado que no es el HEAD de esta copia de trabajo limpia; commits sin una entrada del diario posterior a ellos; un paso `push` que falla |

## Documentación

La documentación está en inglés.

- [Referencia](REFERENCE.md): qué instala `init`, la actualización, flujos y pasos, cada tarea, herramientas, la
  retro
- [El contrato](../template/.trizy/AGENTS.trizy.md) y [las reglas](../template/.trizy/rules/)
- [Registro de cambios](../CHANGELOG.md)

Desarrollo: `sh tests/run.sh` ejecuta 99 comprobaciones sobre repositorios desechables, y
`TRIZY_SH=dash sh tests/run.sh` ejecuta la CLI en un shell POSIX estricto.

## Licencia

trizy se distribuye bajo la **licencia MIT**. El texto completo está en [LICENSE](../LICENSE).

Las skills de terceros incluidas y sus licencias se enumeran en
[THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md).
