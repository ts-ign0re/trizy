
### Install

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
```

The script downloads the latest release, verifies its SHA-256 checksum, puts the kit in `~/.local/share/trizy` and the `trizy` command in `~/.local/bin`. Then run `trizy init` in a repository.

To install exactly this version rather than the latest one:

```sh
curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | TRIZY_VERSION={{TAG}} sh
```

Already installed? `trizy upgrade` installs the latest release, and `trizy update` brings a repository to it.

### Downloads

| File | What it is |
|---|---|
| `trizy.tar.gz` | the kit: POSIX sh, runs on Linux and macOS |
| `trizy.tar.gz.sha256` | its checksum: `shasum -a 256 -c trizy.tar.gz.sha256` |

### Requirements

`sh`, `git`, `curl` and `tar`. Windows is not supported.

Licensed under MIT.
