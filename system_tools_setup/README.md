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
