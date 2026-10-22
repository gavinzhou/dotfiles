# dotfiles

Gavin 的 Mac 配置，由 [chezmoi](https://www.chezmoi.io/) 管理。

## 新 Mac

登录 Apple ID 后，在终端运行：

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply --use-builtin-git true --source ~/Code/gavin/dotfiles gavinzhou
```

<img src="mac-bootstrap.svg" alt="一条命令初始化 Mac 的流程" width="360">

中途需要你做的事：

1. 装 Homebrew 时输入一次开机密码。
2. 系统弹窗时，给 Karabiner、Ghostty 打开「辅助功能」等权限。
3. 运行 `gh auth login`，再运行一次 `chezmoi apply`，记忆仓库就会克隆到 `~/.agents/memory`。

## 平时

| 想做的事 | 命令 |
|---|---|
| 改配置文件 | `chezmoi edit ~/.zshrc`，然后 `chezmoi apply` |
| 加一个软件 | 在 `Brewfile` 里加一行，然后 `chezmoi apply` |
| 看本机和仓库差在哪 | `chezmoi diff` |
| 立刻同步一次 | `dotfiles-sync` |

每天 10:00，`dotfiles-sync`（launchd）会自动拉取并应用仓库更新。如果本机配置被改过、装了 Brewfile 以外的软件，或者 Brewfile 里有软件没装上，它会发系统通知。日志在 `~/Library/Logs/dotfiles-sync.log`。

## 仓库里有什么

| 文件 | 作用 |
|---|---|
| `dot_zshrc`、`dot_gitconfig`、`dot_digrc`、`dot_mise.toml` | 写到 `~/` 下的配置文件 |
| `Brewfile` | 软件清单 |
| `.install-prereqs.sh` | 每次运行 chezmoi 前执行，确保 Homebrew 和 1Password 已安装 |
| `run_onchange_after_10-brew-bundle.sh.tmpl` | Brewfile 改动后装软件 |
| `run_onchange_after_20-macos.sh` | 系统设置：Dock、Finder、轻点点按、大写锁定键改 Control |
| `run_onchange_after_30-mise.sh.tmpl` | 装 node、python、terraform |
| `run_after_40-agents.sh` | 建 `~/Code/<组>`，装 Claude Code，克隆记忆仓库 |
| `run_onchange_after_50-dotfiles-sync.sh` | 安装每天的自动同步任务 |

## 不放进仓库的东西

这个仓库是公开的。密钥和只属于这台机器的设置放在：

- `~/.secrets.zsh`（权限 600）：token 等密钥，来源是 1Password。
- `~/.zshrc.local`：不是密钥、但也不适合公开的设置。
- `~/.ssh/config`：主机清单。SSH 密钥在 1Password 的 SSH agent 里。
