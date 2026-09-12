# System Tools Setup

## ubuntu_colors_setup.sh：Ubuntu / WSL 终端浅蓝色配置

把 `ubuntu_colors_setup.sh` 保存好，以后在 Ubuntu 中运行：

```bash
sh ~/projects/useful_scripts/system_tools_setup/ubuntu_colors_setup.sh
. ~/.bashrc
```

使用日常 Ubuntu 用户运行，不需要 `sudo`。安装脚本使用 `#!/bin/sh`，可通过 `sh` 或 `./ubuntu_colors_setup.sh` 执行；配置目标仍是 Bash 的 `~/.bashrc`，终端需要支持真彩色。请执行脚本，不要用 `source` 加载安装脚本；安装后在当前 Bash 中执行 `. ~/.bashrc` 即可生效。

效果：用户名保持绿色；主机名、当前路径和 `ls` 的普通目录名统一使用浅蓝色 `#87CEFA`。现有 `ll`、`la` 等基于 `ls` 的别名也会使用此目录配色。特殊权限目录和符号链接保留各自配色。

脚本将以 `ubuntu_colors_setup` 标记的独立配置块写入当前用户的 `~/.bashrc`，重复运行不会重复添加，并自动迁移旧版 `ubuntu-readable-colors` 配置块。每次实际修改前都会备份原文件为 `~/.bashrc.ubuntu_colors_setup.backup.*`，备份路径在运行时显示。以后打开 Ubuntu 自动生效，清屏不会重置。

这份脚本设置 Ubuntu 内的颜色。Windows 控制台的黑色背景和复制粘贴选项需要在 Windows 中设置。

### 移除脚本配置

```bash
sh ~/projects/useful_scripts/system_tools_setup/ubuntu_colors_setup.sh --uninstall
```

随后退出并重新进入 Ubuntu。移除操作仅删除本脚本添加的配置块，保留其他设置和之后的改动。你这台电脑此前已配置的提示符及 `~/.dircolors` 浅蓝色设置也会保留；移除脚本不代表重置成 Ubuntu 原始主题。


## vscode_shortcuts_setup.sh：VS Code 查看位置后退 / 前进

```bash
sh ~/projects/useful_scripts/system_tools_setup/vscode_shortcuts_setup.sh
```

使用普通用户运行，不要加 `sudo`。脚本使用 `#!/bin/sh`，依赖 `python3`。

| 快捷键 | 动作 |
|---|---|
| Ctrl+← | 回到上一个查看位置（`workbench.action.navigateBack`） |
| Ctrl+→ | 前进到下一个查看位置（`workbench.action.navigateForward`） |

例如 Ctrl+点击跳到函数定义后，Ctrl+← 返回调用处，Ctrl+→ 再次前进。
只在代码编辑器有焦点时生效，替换编辑器中原本按单词左右移动光标的功能。
终端和搜索框保留原有行为。VS Code 会自动重新加载快捷键，一般无需重启。

### 配置位置

- WSL：通过 Windows PowerShell 自动查询当前 Windows 用户的 AppData，
  写入 Windows VS Code 的 `Code/User/keybindings.json`。WSL 窗口的快捷键由 Windows 客户端管理，
  因此不写入 `~/.vscode-server/`。要求 WSL 的 Windows 程序互操作功能可用。
- 原生 Linux：写入 `${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/keybindings.json`。
- 上述自动路径对应 VS Code Stable 的默认 Profile。其他 Profile、Insiders、VSCodium 或便携安装，
  请用 `--keybindings` 指定正在使用的快捷键文件；在 WSL 中使用 `/mnt/...` 形式的路径。

```bash
sh ~/projects/useful_scripts/system_tools_setup/vscode_shortcuts_setup.sh   --keybindings /path/to/keybindings.json
```

脚本保留已有 JSONC 注释和其他快捷键，在数组末尾添加 `vscode_shortcuts_setup` 标记块。
相同按键的原有绑定保留在原位置；编辑器获得焦点时，末尾的新绑定优先。
重复运行不会重复添加。实际修改前备份现有文件为
`keybindings.json.vscode_shortcuts_setup.backup.*`，路径会在运行时显示。
格式有误、标记不完整或目标为符号链接时会报错，不覆盖原文件。

### 移除本脚本添加的快捷键

```bash
sh ~/projects/useful_scripts/system_tools_setup/vscode_shortcuts_setup.sh --uninstall
```

自定义路径需要同时传入原来的 `--keybindings`。只删除本脚本的标记块，保留原有设置。
如果此前手动配置过同样的快捷键，移除标记块后那些手动配置仍然有效。

本脚本只设置这组导航快捷键；Python/Pylance 扩展和项目解释器需要另外配置。
