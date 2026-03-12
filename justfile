set shell := ["zsh", "-cu"]

repo_root := justfile_directory()
xdg_config_dir := env_var_or_default("XDG_CONFIG_HOME", env_var("HOME") + "/.config")
brewfile := repo_root + "/Brewfile"
headlessmc_repo := "headlesshq/headlessmc"
headlessmc_version_file := repo_root + "/tools/headlessmc-version"
headlessmc_runtime_version := "8.482.08.1"
headlessmc_runtime_url := "https://corretto.aws/downloads/resources/" + headlessmc_runtime_version + "/amazon-corretto-" + headlessmc_runtime_version + "-macosx-x64.tar.gz"
ghostty_target := xdg_config_dir + "/ghostty"
ghostty_source := repo_root + "/config/ghostty"
starship_target := xdg_config_dir + "/starship.toml"
starship_source := repo_root + "/config/starship.toml"
mise_target := xdg_config_dir + "/mise"
mise_source := repo_root + "/config/mise"
direnv_target := xdg_config_dir + "/direnv"
direnv_source := repo_root + "/config/direnv"
opencode_config_dir := xdg_config_dir + "/opencode"
opencode_json_target := opencode_config_dir + "/opencode.json"
opencode_json_source := repo_root + "/config/opencode/opencode.json"
opencode_package_target := opencode_config_dir + "/package.json"
opencode_package_source := repo_root + "/config/opencode/package.json"
codex_config_target := env_var("HOME") + "/.codex/config.toml"
codex_config_source := repo_root + "/config/codex/config.toml"
claude_config_target := env_var("HOME") + "/.claude.json"
claude_config_source := repo_root + "/config/claude/claude.json"
gitconfig_target := env_var("HOME") + "/.gitconfig"
gitconfig_source := repo_root + "/git/.gitconfig"
gitignore_global_target := env_var("HOME") + "/.gitignore_global"
gitignore_global_source := repo_root + "/git/.gitignore_global"
ssh_config_target := env_var("HOME") + "/.ssh/config"
ssh_config_source := repo_root + "/ssh/config"
zsh_target := env_var("HOME") + "/.zshrc"
zsh_source := repo_root + "/zsh/.zshrc"
hushlogin_target := env_var("HOME") + "/.hushlogin"
hushlogin_source := repo_root + "/zsh/.hushlogin"

default:
  @just --list

bootstrap: brew-tools install install-runtimes

install: ghostty starship mise direnv opencode codex-config claude-config git ssh zsh hushlogin

install-tools: brew-tools

install-runtimes:
  #!/usr/bin/env zsh
  set -eu
  mise install

setup-minecraft: headlessmc headlessmc-runtime

brew-tools:
  #!/usr/bin/env zsh
  set -eu
  if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required but not installed.\n' >&2
    exit 1
  fi
  brew bundle --file "{{brewfile}}"

headlessmc:
  #!/usr/bin/env zsh
  set -eu
  arch="$(uname -m)"
  case "$arch" in
    arm64) asset="headlessmc-launcher-macos-arm64" ;;
    x86_64) asset="headlessmc-launcher-macos-x64" ;;
    *) printf 'Unsupported architecture for HeadlessMC: %s\n' "$arch" >&2; exit 1 ;;
  esac
  version="$(cat "{{headlessmc_version_file}}")"
  install_dir="${HOME}/.local/bin"
  target="${install_dir}/headlessmc"
  mkdir -p "$install_dir"
  curl -fsSL "https://github.com/{{headlessmc_repo}}/releases/download/${version}/${asset}" -o "$target"
  chmod +x "$target"
  printf 'Installed HeadlessMC %s to %s\n' "$version" "$target"

headlessmc-runtime:
  #!/usr/bin/env zsh
  set -eu
  runtime_root="${HOME}/.local/share/headlessmc/runtime"
  version="{{headlessmc_runtime_version}}"
  archive_url="{{headlessmc_runtime_url}}"
  versioned_dir="${runtime_root}/amazon-corretto-${version}.jdk"
  linked_dir="${runtime_root}/headlessmc.jdk"
  compat_linked_dir="${runtime_root}/minecraft-compat-java8.jdk"
  java8_linked_dir="${runtime_root}/headlessmc-java8.jdk"
  old_linked_dir="${runtime_root}/amazon-corretto-8.jdk"
  java_bin="${versioned_dir}/Contents/Home/bin/java"
  mkdir -p "$runtime_root"
  if [ ! -x "$java_bin" ]; then
    tmp_dir="$(mktemp -d)"
    archive_path="${tmp_dir}/amazon-corretto-${version}-macosx-x64.tar.gz"
    curl -fsSL "$archive_url" -o "$archive_path"
    tar -xzf "$archive_path" -C "$tmp_dir"
    rm -rf "$versioned_dir"
    mv "${tmp_dir}/amazon-corretto-8.jdk" "$versioned_dir"
    rm -rf "$tmp_dir"
  fi
  if [ -L "$old_linked_dir" ]; then
    rm "$old_linked_dir"
  elif [ -d "$old_linked_dir" ]; then
    backup="${old_linked_dir}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$old_linked_dir" "$backup"
    printf 'Moved existing HeadlessMC Java 8 directory to %s\n' "$backup"
  fi
  if [ -L "$compat_linked_dir" ]; then
    rm "$compat_linked_dir"
  elif [ -d "$compat_linked_dir" ]; then
    backup="${compat_linked_dir}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$compat_linked_dir" "$backup"
    printf 'Moved existing HeadlessMC runtime directory to %s\n' "$backup"
  fi
  if [ -L "$java8_linked_dir" ]; then
    rm "$java8_linked_dir"
  elif [ -d "$java8_linked_dir" ]; then
    backup="${java8_linked_dir}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$java8_linked_dir" "$backup"
    printf 'Moved existing HeadlessMC runtime directory to %s\n' "$backup"
  fi
  if [ -L "$linked_dir" ]; then
    rm "$linked_dir"
  elif [ -d "$linked_dir" ]; then
    backup="${linked_dir}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$linked_dir" "$backup"
    printf 'Moved existing HeadlessMC runtime directory to %s\n' "$backup"
  fi
  ln -s "$versioned_dir" "$linked_dir"
  printf 'Installed HeadlessMC runtime %s to %s\n' "$version" "$java_bin"

check-tools:
  #!/usr/bin/env zsh
  set -eu
  for cmd in ghostty starship bun bunx mise direnv opencode codex claude git ssh headlessmc; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf '%s=%s\n' "$cmd" "$(command -v "$cmd")"
    else
      printf '%s=missing\n' "$cmd"
    fi
  done

ghostty:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "{{xdg_config_dir}}"
  if [ -L "{{ghostty_target}}" ] && [ "$(readlink "{{ghostty_target}}")" = "{{ghostty_source}}" ]; then
    printf 'Ghostty already linked: %s -> %s\n' "{{ghostty_target}}" "{{ghostty_source}}"
    exit 0
  fi
  if [ -e "{{ghostty_target}}" ] && [ ! -L "{{ghostty_target}}" ]; then
    backup="{{ghostty_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{ghostty_target}}" "$backup"
    printf 'Moved existing Ghostty config to %s\n' "$backup"
  elif [ -L "{{ghostty_target}}" ]; then
    rm "{{ghostty_target}}"
  fi
  ln -s "{{ghostty_source}}" "{{ghostty_target}}"
  printf 'Linked %s -> %s\n' "{{ghostty_target}}" "{{ghostty_source}}"

starship:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "{{xdg_config_dir}}"
  if [ -L "{{starship_target}}" ] && [ "$(readlink "{{starship_target}}")" = "{{starship_source}}" ]; then
    printf 'Starship already linked: %s -> %s\n' "{{starship_target}}" "{{starship_source}}"
    exit 0
  fi
  if [ -e "{{starship_target}}" ] && [ ! -L "{{starship_target}}" ]; then
    backup="{{starship_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{starship_target}}" "$backup"
    printf 'Moved existing Starship config to %s\n' "$backup"
  elif [ -L "{{starship_target}}" ]; then
    rm "{{starship_target}}"
  fi
  ln -s "{{starship_source}}" "{{starship_target}}"
  printf 'Linked %s -> %s\n' "{{starship_target}}" "{{starship_source}}"

mise:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "{{xdg_config_dir}}"
  if [ -L "{{mise_target}}" ] && [ "$(readlink "{{mise_target}}")" = "{{mise_source}}" ]; then
    printf 'mise already linked: %s -> %s\n' "{{mise_target}}" "{{mise_source}}"
    exit 0
  fi
  if [ -e "{{mise_target}}" ] && [ ! -L "{{mise_target}}" ]; then
    backup="{{mise_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{mise_target}}" "$backup"
    printf 'Moved existing mise config to %s\n' "$backup"
  elif [ -L "{{mise_target}}" ]; then
    rm "{{mise_target}}"
  fi
  ln -s "{{mise_source}}" "{{mise_target}}"
  printf 'Linked %s -> %s\n' "{{mise_target}}" "{{mise_source}}"

direnv:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "{{xdg_config_dir}}"
  if [ -L "{{direnv_target}}" ] && [ "$(readlink "{{direnv_target}}")" = "{{direnv_source}}" ]; then
    printf 'direnv already linked: %s -> %s\n' "{{direnv_target}}" "{{direnv_source}}"
    exit 0
  fi
  if [ -e "{{direnv_target}}" ] && [ ! -L "{{direnv_target}}" ]; then
    backup="{{direnv_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{direnv_target}}" "$backup"
    printf 'Moved existing direnv config to %s\n' "$backup"
  elif [ -L "{{direnv_target}}" ]; then
    rm "{{direnv_target}}"
  fi
  ln -s "{{direnv_source}}" "{{direnv_target}}"
  printf 'Linked %s -> %s\n' "{{direnv_target}}" "{{direnv_source}}"

opencode:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "{{opencode_config_dir}}"
  if [ -L "{{opencode_json_target}}" ] && [ "$(readlink "{{opencode_json_target}}")" = "{{opencode_json_source}}" ]; then
    printf 'opencode config already linked: %s -> %s\n' "{{opencode_json_target}}" "{{opencode_json_source}}"
  else
    if [ -e "{{opencode_json_target}}" ] && [ ! -L "{{opencode_json_target}}" ]; then
      backup="{{opencode_json_target}}.backup-$(date +%Y%m%d%H%M%S)"
      mv "{{opencode_json_target}}" "$backup"
      printf 'Moved existing opencode config to %s\n' "$backup"
    elif [ -L "{{opencode_json_target}}" ]; then
      rm "{{opencode_json_target}}"
    fi
    ln -s "{{opencode_json_source}}" "{{opencode_json_target}}"
    printf 'Linked %s -> %s\n' "{{opencode_json_target}}" "{{opencode_json_source}}"
  fi
  if [ -L "{{opencode_package_target}}" ] && [ "$(readlink "{{opencode_package_target}}")" = "{{opencode_package_source}}" ]; then
    printf 'opencode package already linked: %s -> %s\n' "{{opencode_package_target}}" "{{opencode_package_source}}"
    exit 0
  fi
  if [ -e "{{opencode_package_target}}" ] && [ ! -L "{{opencode_package_target}}" ]; then
    backup="{{opencode_package_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{opencode_package_target}}" "$backup"
    printf 'Moved existing opencode package to %s\n' "$backup"
  elif [ -L "{{opencode_package_target}}" ]; then
    rm "{{opencode_package_target}}"
  fi
  ln -s "{{opencode_package_source}}" "{{opencode_package_target}}"
  printf 'Linked %s -> %s\n' "{{opencode_package_target}}" "{{opencode_package_source}}"

codex-config:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "${HOME}/.codex"
  if [ -L "{{codex_config_target}}" ] && [ "$(readlink "{{codex_config_target}}")" = "{{codex_config_source}}" ]; then
    printf 'Codex config already linked: %s -> %s\n' "{{codex_config_target}}" "{{codex_config_source}}"
    exit 0
  fi
  if [ -e "{{codex_config_target}}" ] && [ ! -L "{{codex_config_target}}" ]; then
    backup="{{codex_config_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{codex_config_target}}" "$backup"
    printf 'Moved existing Codex config to %s\n' "$backup"
  elif [ -L "{{codex_config_target}}" ]; then
    rm "{{codex_config_target}}"
  fi
  ln -s "{{codex_config_source}}" "{{codex_config_target}}"
  printf 'Linked %s -> %s\n' "{{codex_config_target}}" "{{codex_config_source}}"

claude-config:
  #!/usr/bin/env zsh
  set -eu
  if [ -L "{{claude_config_target}}" ] && [ "$(readlink "{{claude_config_target}}")" = "{{claude_config_source}}" ]; then
    printf 'Claude config already linked: %s -> %s\n' "{{claude_config_target}}" "{{claude_config_source}}"
    exit 0
  fi
  if [ -e "{{claude_config_target}}" ] && [ ! -L "{{claude_config_target}}" ]; then
    backup="{{claude_config_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{claude_config_target}}" "$backup"
    printf 'Moved existing Claude config to %s\n' "$backup"
  elif [ -L "{{claude_config_target}}" ]; then
    rm "{{claude_config_target}}"
  fi
  ln -s "{{claude_config_source}}" "{{claude_config_target}}"
  printf 'Linked %s -> %s\n' "{{claude_config_target}}" "{{claude_config_source}}"

git:
  #!/usr/bin/env zsh
  set -eu
  if [ -L "{{gitconfig_target}}" ] && [ "$(readlink "{{gitconfig_target}}")" = "{{gitconfig_source}}" ]; then
    printf 'Git config already linked: %s -> %s\n' "{{gitconfig_target}}" "{{gitconfig_source}}"
  else
    if [ -e "{{gitconfig_target}}" ] && [ ! -L "{{gitconfig_target}}" ]; then
      backup="{{gitconfig_target}}.backup-$(date +%Y%m%d%H%M%S)"
      mv "{{gitconfig_target}}" "$backup"
      printf 'Moved existing Git config to %s\n' "$backup"
    elif [ -L "{{gitconfig_target}}" ]; then
      rm "{{gitconfig_target}}"
    fi
    ln -s "{{gitconfig_source}}" "{{gitconfig_target}}"
    printf 'Linked %s -> %s\n' "{{gitconfig_target}}" "{{gitconfig_source}}"
  fi
  if [ -L "{{gitignore_global_target}}" ] && [ "$(readlink "{{gitignore_global_target}}")" = "{{gitignore_global_source}}" ]; then
    printf 'Global gitignore already linked: %s -> %s\n' "{{gitignore_global_target}}" "{{gitignore_global_source}}"
    exit 0
  fi
  if [ -e "{{gitignore_global_target}}" ] && [ ! -L "{{gitignore_global_target}}" ]; then
    backup="{{gitignore_global_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{gitignore_global_target}}" "$backup"
    printf 'Moved existing global gitignore to %s\n' "$backup"
  elif [ -L "{{gitignore_global_target}}" ]; then
    rm "{{gitignore_global_target}}"
  fi
  ln -s "{{gitignore_global_source}}" "{{gitignore_global_target}}"
  printf 'Linked %s -> %s\n' "{{gitignore_global_target}}" "{{gitignore_global_source}}"

ssh:
  #!/usr/bin/env zsh
  set -eu
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  if [ -L "{{ssh_config_target}}" ] && [ "$(readlink "{{ssh_config_target}}")" = "{{ssh_config_source}}" ]; then
    printf 'SSH config already linked: %s -> %s\n' "{{ssh_config_target}}" "{{ssh_config_source}}"
    exit 0
  fi
  if [ -e "{{ssh_config_target}}" ] && [ ! -L "{{ssh_config_target}}" ]; then
    backup="{{ssh_config_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{ssh_config_target}}" "$backup"
    printf 'Moved existing SSH config to %s\n' "$backup"
  elif [ -L "{{ssh_config_target}}" ]; then
    rm "{{ssh_config_target}}"
  fi
  ln -s "{{ssh_config_source}}" "{{ssh_config_target}}"
  printf 'Linked %s -> %s\n' "{{ssh_config_target}}" "{{ssh_config_source}}"

zsh:
  #!/usr/bin/env zsh
  set -eu
  if [ -L "{{zsh_target}}" ] && [ "$(readlink "{{zsh_target}}")" = "{{zsh_source}}" ]; then
    printf 'Zsh already linked: %s -> %s\n' "{{zsh_target}}" "{{zsh_source}}"
    exit 0
  fi
  if [ -e "{{zsh_target}}" ] && [ ! -L "{{zsh_target}}" ]; then
    backup="{{zsh_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{zsh_target}}" "$backup"
    printf 'Moved existing Zsh config to %s\n' "$backup"
  elif [ -L "{{zsh_target}}" ]; then
    rm "{{zsh_target}}"
  fi
  ln -s "{{zsh_source}}" "{{zsh_target}}"
  printf 'Linked %s -> %s\n' "{{zsh_target}}" "{{zsh_source}}"

hushlogin:
  #!/usr/bin/env zsh
  set -eu
  if [ -L "{{hushlogin_target}}" ] && [ "$(readlink "{{hushlogin_target}}")" = "{{hushlogin_source}}" ]; then
    printf 'hushlogin already linked: %s -> %s\n' "{{hushlogin_target}}" "{{hushlogin_source}}"
    exit 0
  fi
  if [ -e "{{hushlogin_target}}" ] && [ ! -L "{{hushlogin_target}}" ]; then
    backup="{{hushlogin_target}}.backup-$(date +%Y%m%d%H%M%S)"
    mv "{{hushlogin_target}}" "$backup"
    printf 'Moved existing hushlogin file to %s\n' "$backup"
  elif [ -L "{{hushlogin_target}}" ]; then
    rm "{{hushlogin_target}}"
  fi
  ln -s "{{hushlogin_source}}" "{{hushlogin_target}}"
  printf 'Linked %s -> %s\n' "{{hushlogin_target}}" "{{hushlogin_source}}"

unlink:
  @if [ -L "{{ghostty_target}}" ]; then rm "{{ghostty_target}}"; printf 'Removed %s\n' "{{ghostty_target}}"; else printf 'No Ghostty symlink at %s\n' "{{ghostty_target}}"; fi
  @if [ -L "{{starship_target}}" ]; then rm "{{starship_target}}"; printf 'Removed %s\n' "{{starship_target}}"; else printf 'No Starship symlink at %s\n' "{{starship_target}}"; fi
  @if [ -L "{{mise_target}}" ]; then rm "{{mise_target}}"; printf 'Removed %s\n' "{{mise_target}}"; else printf 'No mise symlink at %s\n' "{{mise_target}}"; fi
  @if [ -L "{{direnv_target}}" ]; then rm "{{direnv_target}}"; printf 'Removed %s\n' "{{direnv_target}}"; else printf 'No direnv symlink at %s\n' "{{direnv_target}}"; fi
  @if [ -L "{{opencode_json_target}}" ]; then rm "{{opencode_json_target}}"; printf 'Removed %s\n' "{{opencode_json_target}}"; else printf 'No opencode config symlink at %s\n' "{{opencode_json_target}}"; fi
  @if [ -L "{{opencode_package_target}}" ]; then rm "{{opencode_package_target}}"; printf 'Removed %s\n' "{{opencode_package_target}}"; else printf 'No opencode package symlink at %s\n' "{{opencode_package_target}}"; fi
  @if [ -L "{{codex_config_target}}" ]; then rm "{{codex_config_target}}"; printf 'Removed %s\n' "{{codex_config_target}}"; else printf 'No Codex config symlink at %s\n' "{{codex_config_target}}"; fi
  @if [ -L "{{claude_config_target}}" ]; then rm "{{claude_config_target}}"; printf 'Removed %s\n' "{{claude_config_target}}"; else printf 'No Claude config symlink at %s\n' "{{claude_config_target}}"; fi
  @if [ -L "{{gitconfig_target}}" ]; then rm "{{gitconfig_target}}"; printf 'Removed %s\n' "{{gitconfig_target}}"; else printf 'No Git config symlink at %s\n' "{{gitconfig_target}}"; fi
  @if [ -L "{{gitignore_global_target}}" ]; then rm "{{gitignore_global_target}}"; printf 'Removed %s\n' "{{gitignore_global_target}}"; else printf 'No global gitignore symlink at %s\n' "{{gitignore_global_target}}"; fi
  @if [ -L "{{ssh_config_target}}" ]; then rm "{{ssh_config_target}}"; printf 'Removed %s\n' "{{ssh_config_target}}"; else printf 'No SSH config symlink at %s\n' "{{ssh_config_target}}"; fi
  @if [ -L "{{zsh_target}}" ]; then rm "{{zsh_target}}"; printf 'Removed %s\n' "{{zsh_target}}"; else printf 'No Zsh symlink at %s\n' "{{zsh_target}}"; fi
  @if [ -L "{{hushlogin_target}}" ]; then rm "{{hushlogin_target}}"; printf 'Removed %s\n' "{{hushlogin_target}}"; else printf 'No hushlogin symlink at %s\n' "{{hushlogin_target}}"; fi

paths:
  @printf 'repo_root=%s\n' "{{repo_root}}"
  @printf 'brewfile=%s\n' "{{brewfile}}"
  @printf 'headlessmc_repo=%s\n' "{{headlessmc_repo}}"
  @printf 'headlessmc_version_file=%s\n' "{{headlessmc_version_file}}"
  @printf 'xdg_config_dir=%s\n' "{{xdg_config_dir}}"
  @printf 'ghostty_source=%s\n' "{{ghostty_source}}"
  @printf 'ghostty_target=%s\n' "{{ghostty_target}}"
  @printf 'starship_source=%s\n' "{{starship_source}}"
  @printf 'starship_target=%s\n' "{{starship_target}}"
  @printf 'mise_source=%s\n' "{{mise_source}}"
  @printf 'mise_target=%s\n' "{{mise_target}}"
  @printf 'direnv_source=%s\n' "{{direnv_source}}"
  @printf 'direnv_target=%s\n' "{{direnv_target}}"
  @printf 'opencode_json_source=%s\n' "{{opencode_json_source}}"
  @printf 'opencode_json_target=%s\n' "{{opencode_json_target}}"
  @printf 'opencode_package_source=%s\n' "{{opencode_package_source}}"
  @printf 'opencode_package_target=%s\n' "{{opencode_package_target}}"
  @printf 'codex_config_source=%s\n' "{{codex_config_source}}"
  @printf 'codex_config_target=%s\n' "{{codex_config_target}}"
  @printf 'claude_config_source=%s\n' "{{claude_config_source}}"
  @printf 'claude_config_target=%s\n' "{{claude_config_target}}"
  @printf 'gitconfig_source=%s\n' "{{gitconfig_source}}"
  @printf 'gitconfig_target=%s\n' "{{gitconfig_target}}"
  @printf 'gitignore_global_source=%s\n' "{{gitignore_global_source}}"
  @printf 'gitignore_global_target=%s\n' "{{gitignore_global_target}}"
  @printf 'ssh_config_source=%s\n' "{{ssh_config_source}}"
  @printf 'ssh_config_target=%s\n' "{{ssh_config_target}}"
  @printf 'zsh_source=%s\n' "{{zsh_source}}"
  @printf 'zsh_target=%s\n' "{{zsh_target}}"
  @printf 'hushlogin_source=%s\n' "{{hushlogin_source}}"
  @printf 'hushlogin_target=%s\n' "{{hushlogin_target}}"
