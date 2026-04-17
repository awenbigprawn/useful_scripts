# useful_scripts

一个按用途分类的小型脚本仓库，主要用于 Linux 日常维护、系统配置、可执行文件权限处理，以及少量 Python 工具。

仓库里的脚本命名现在统一为 `snake_case`，全部使用下划线，不再使用 `-`。

## 目录结构

```text
useful_scripts/
├── executable_related/    # 可执行文件权限、进程优先级观察
├── python/                # 通用 Python 小工具
├── system_tools_setup/    # 系统配置与维护脚本
└── video_transform/       # 视频格式转换脚本
```

## 使用方式

大多数 shell 脚本可以直接执行：

```bash
chmod +x path/to/script.sh
./path/to/script.sh
```

如果脚本会修改系统配置、`/sys`、`/boot`、驱动或包管理器，请使用 `sudo`，并先阅读脚本内容：

```bash
sudo ./system_tools_setup/fan_max.sh
```

Python 脚本建议使用虚拟环境运行：

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip
```

## 脚本说明

### `system_tools_setup/`

| 脚本 | 作用 | 是否需要 `sudo` | 示例 |
| --- | --- | --- | --- |
| `fan_max.sh` | 将检测到的风扇 PWM 拉满，支持退出时恢复原值 | 是 | `sudo ./system_tools_setup/fan_max.sh --restore-on-exit` |
| `lock_cpu_freq.sh` | 锁定 CPU 频率到指定值，并关闭 boost/turbo | 是 | `sudo ./system_tools_setup/lock_cpu_freq.sh 800000` |
| `restore_cpu_freq_default.sh` | 恢复 CPU 动态调频默认设置 | 是 | `sudo ./system_tools_setup/restore_cpu_freq_default.sh` |
| `purge_kernel.sh` | 清理名称中包含 `budget` 的内核文件和模块目录 | 是 | `sudo ./system_tools_setup/purge_kernel.sh` |
| `remove_snap.sh` | 卸载 snap 及相关残留目录，并 hold `firefox`/`snapd` | 是 | `sudo ./system_tools_setup/remove_snap.sh` |
| `gedit_setup.sh` | 配置 gedit 的右边距、配色和缩进 | 否 | `./system_tools_setup/gedit_setup.sh` |
| `git_setup.sh` | 设置常用 Git alias，并补充 `gti='git'` shell alias | 否 | `./system_tools_setup/git_setup.sh` |
| `tmux_setup.sh` | 生成简洁的 `~/.tmux.conf`，开启鼠标并改前缀为 `Ctrl+a` | 否 | `./system_tools_setup/tmux_setup.sh` |
| `set_headset_default.sh` | 向 ALSA 配置写入耳机模式参数，改善开机耳机识别 | 是 | `sudo ./system_tools_setup/set_headset_default.sh` |
| `nvidia_drivers_install.sh` | 屏蔽 `nouveau` 后下载并静默安装指定版本 NVIDIA 驱动 | 是 | `sudo ./system_tools_setup/nvidia_drivers_install.sh` |

### `executable_related/`

| 脚本 | 作用 | 是否需要 `sudo` | 示例 |
| --- | --- | --- | --- |
| `setcap.sh` | 给目标可执行文件添加 `cap_sys_nice` 能力 | 是 | `sudo ./executable_related/setcap.sh /path/to/bin` |
| `watchprio.sh` | 持续观察进程/线程优先级，默认筛选 `safebot` | 否 | `./executable_related/watchprio.sh` |

### `python/`

| 脚本 | 作用 | 依赖 | 说明 |
| --- | --- | --- | --- |
| `rename_files.py` | 对指定目录中的文件/目录进行批量重命名 | Python 3 | 当前是定制脚本，路径和替换规则写死，使用前请先修改脚本内容 |

### `video_transform/`

| 脚本 | 作用 | 依赖 | 示例 |
| --- | --- | --- | --- |
| `webm2mp4.py` | 使用 `moviepy` 将 `.webm` 转成 `.mp4` | `moviepy`、ffmpeg | `python3 video_transform/webm2mp4.py` |

安装 `moviepy` 示例：

```bash
pip install moviepy
```

系统里还需要可用的 `ffmpeg`。

## 风险提示

- `purge_kernel.sh`、`remove_snap.sh`、`nvidia_drivers_install.sh` 都会修改系统关键组件，执行前请确认目标环境和版本。
- `fan_max.sh`、`lock_cpu_freq.sh`、`restore_cpu_freq_default.sh` 会直接写入 `/sys`，只适合明确知道机器状态时使用。
- `watchprio.sh` 当前默认筛选关键字 `safebot`。如果你想看别的进程，需要先改脚本里的过滤条件。
- `rename_files.py` 不是通用 CLI，而是一次性批处理脚本，运行前一定要检查硬编码路径。

## 最近命名调整

以下脚本已从连字符命名改为下划线命名：

- `gedit-setup.sh` -> `gedit_setup.sh`
- `git-setup.sh` -> `git_setup.sh`
- `nvidia-drivers-install.sh` -> `nvidia_drivers_install.sh`
- `set-headset-default.sh` -> `set_headset_default.sh`
- `tmux-setup.sh` -> `tmux_setup.sh`

如果你本地有旧的调用方式、别名或笔记，请同步更新。
