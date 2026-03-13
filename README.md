# dot-files

Minimal dotfiles repo with a simple `just`-based install flow.

## Bootstrap

Install the CLI/app dependencies managed by this repo, then link configs:

```sh
just bootstrap
```

Or split the steps:

```sh
just install-tools
just install
just install-runtimes
```

## Included

- Ghostty config at `config/ghostty/config`
- Custom light/dark Ghostty themes in `config/ghostty/themes/`
- Starship config at `config/starship.toml`
- Starship prompt reset from `catppuccin-powerline` with Nerd Font symbol overrides
- mise config at `config/mise/config.toml`
- direnv config at `config/direnv/direnv.toml`
- OpenCode config at `config/opencode/opencode.json`
- Codex config at `config/codex/config.toml`
- Claude Code config at `config/claude/claude.json`
- HeadlessMC install version in `tools/headlessmc-version`
- Git config at `git/.gitconfig`
- Global gitignore at `git/.gitignore_global`
- Gradle template at `gradle/gradle.properties.example`
- SSH config at `ssh/config`
- Zsh bootstrap at `zsh/.zshrc`
- Modular Zsh config snippets in `zsh/rc.d/`
- `zsh/.hushlogin` to suppress macOS `Last login:` messages in new shells
- Optional untracked machine overrides via `config/ghostty/local.conf`

## Install

```sh
just install
```

Tool installation is managed by:

```sh
Brewfile
```

HeadlessMC is installed separately by `just setup-minecraft` into:

```sh
~/.local/bin/headlessmc
```

The `hmc` shell function runs HeadlessMC from:

```sh
~/.local/share/headlessmc
```

and automatically writes the Java runtime paths HeadlessMC needs, so older Minecraft versions like `1.8.9` can use Java 8 without creating `HeadlessMC/` folders in random working directories.

`just setup-minecraft` also installs the HeadlessMC runtime needed for old Minecraft on Apple Silicon:

```sh
~/.local/share/headlessmc/runtime/headlessmc.jdk
```

That runtime is used for old Minecraft versions that still depend on x86_64 LWJGL natives.

That links this repo's managed files to:

- `$XDG_CONFIG_HOME/ghostty`
- `$XDG_CONFIG_HOME/starship.toml`
- `$XDG_CONFIG_HOME/mise`
- `$XDG_CONFIG_HOME/direnv`
- `$XDG_CONFIG_HOME/opencode/opencode.json`
- `$XDG_CONFIG_HOME/opencode/package.json`
- `~/.codex/config.toml`
- `~/.claude.json`
- `~/.gitconfig`
- `~/.gitignore_global`
- `~/.ssh/config`
- `~/.gradle/gradle.properties`
- `~/.zshrc`
- `~/.hushlogin`
- or `~/.config/ghostty` when `XDG_CONFIG_HOME` is unset
- or `~/.config/starship.toml` when `XDG_CONFIG_HOME` is unset

## Customize Ghostty

Edit the tracked defaults:

```sh
$EDITOR config/ghostty/config
```

For local-only overrides:

```sh
cp config/ghostty/local.conf.example config/ghostty/local.conf
$EDITOR config/ghostty/local.conf
```

Edit the tracked Starship config:

```sh
$EDITOR config/starship.toml
```

## Runtime And Env Tools

The repo manages global config for `mise` and `direnv` without pinning lots of personal runtime versions.

`mise` is activated from:

```sh
zsh/rc.d/30-mise.zsh
```

Global `mise` defaults live in:

```sh
config/mise/config.toml
```

Managed global runtimes:

- `bun@latest`
- `java@21`
- `java@corretto-8.482.08.1`

Project workflow is still:

```sh
cd your-project
mise use node@20
mise use python@3.12
```

That creates a project-local `mise.toml` instead of forcing versions from this dotfiles repo.

`direnv` is activated from:

```sh
zsh/rc.d/90-direnv.zsh
```

Global `direnv` defaults live in:

```sh
config/direnv/direnv.toml
```

Typical project flow:

```sh
cd your-project
echo 'use mise' > .envrc
direnv allow
```

Install the managed global runtimes with:

```sh
just install-runtimes
```

## AI Tools

The repo manages MCP setup for OpenCode, Codex, and Claude Code.

Configured MCP servers:

- `context7`
- `linear`
- `chrome-devtools`

OpenCode also enables:

- `opencode-gemini-auth`

Managed files:

```sh
config/opencode/opencode.json
config/opencode/package.json
config/codex/config.toml
config/claude/claude.json
```

Auth notes:

- `context7` and `linear` require authentication.
- For Codex, run:

```sh
codex mcp login context7
codex mcp login linear
```

- For OpenCode, run:

```sh
opencode mcp auth context7
opencode mcp auth linear
```

- Claude Code uses its own MCP auth flow for HTTP servers when needed.

The `chrome-devtools` MCP server is launched via `bunx`, so it depends on the global `bun` runtime managed by `mise`.

## Git And SSH

Global Git identity and defaults are managed in:

```sh
git/.gitconfig
git/.gitignore_global
```

The current global Git identity is:

- `Bastien S.`
- `siniak.bastien@gmail.com`

SSH host aliases are managed in:

```sh
ssh/config
```

Current managed host:

- `seaven-prod` -> `ansible@prod-server-1`

Connect with:

```sh
ssh seaven-prod
```

## Gradle

For local Gradle credentials like GitHub Packages / GPR, the repo manages the file shape but not the secret values.

Create your local file from:

```sh
cp gradle/gradle.properties.example gradle/gradle.properties
```

Then fill in your real values in:

```sh
gradle/gradle.properties
```

That file is intentionally untracked and `just install` will link it to:

```sh
~/.gradle/gradle.properties
```

## Customize Zsh

The repo manages `~/.zshrc` with a thin bootstrap that sources files from `zsh/rc.d/`.

Starship is initialized from:

```sh
zsh/rc.d/20-starship.zsh
```

The current Spicetify PATH tweak is preserved in:

```sh
zsh/rc.d/10-paths.zsh
```

That same file also adds:

```sh
$HOME/.local/bin
```

so repo-managed local binaries like `headlessmc` are available in your shell.

For local-only shell overrides:

```sh
cp zsh/rc.d/99-local.zsh.example zsh/rc.d/99-local.zsh
$EDITOR zsh/rc.d/99-local.zsh
```

`zsh/rc.d/99-local.zsh` is intentionally untracked.

To suppress the macOS `Last login:` banner in new Ghostty tabs, the repo also manages:

```sh
zsh/.hushlogin
```
