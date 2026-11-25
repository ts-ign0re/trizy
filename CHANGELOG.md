# Changelog

0.3.0 — first public release, as trizy (formerly agent-kit, unpublished).
        Releases by tags: a `v*` tag builds `trizy.tar.gz` with its SHA-256; install.sh installs the latest release
        (TRIZY_VERSION for a given one) and `trizy upgrade [--version]` does the same for the user install.
        init over a foreign core.hooksPath (husky…) asks replace (recommended) or merge (`--hooks=replace|merge`).
        Coming from agent-kit: the directory, command, markers and variables are now `.trizy/`, `trizy`,
        `trizy:begin` and `TRIZY_*`; remove `.agent-kit/` and its blocks, then run `trizy init`.
