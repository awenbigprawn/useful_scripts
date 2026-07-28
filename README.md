# useful_scripts

一个按用途分类的小型脚本仓库，主要用于 Linux 日常维护、桌面环境配置、可执行文件权限处理，以及少量 Python 工具。

## 命名规则

仓库里的脚本统一使用 `snake_case`，并遵循下面两条规则：

- 文件名开头优先放和功能强相关的主题词，便于 `Tab` 补全时先按对象查找。
- `setup`、`install`、`fix`、`lock`、`remove`、`restore` 这类动作词尽量放在后面。

例如：`ibus_rime_setup.sh`、`cpu_freq_lock.sh`、`window_tiling_fix.sh`。

## 目录结构

```text
useful_scripts/
├── executable_related/    # 可执行文件权限、进程优先级观察
├── python/                # 通用 Python 小工具
├── raspberry_pi/          # Raspberry Pi 5 安装、直连网络与 SSH 工具
├── system_tools_setup/    # 系统配置与维护脚本
└── video_transform/       # 视频格式转换脚本
```

## 使用方式

大多数 shell 脚本可以直接执行，并支持 `--help` 查看用途和用法：

```bash
chmod +x path/to/script.sh
./path/to/script.sh
```

如果脚本会修改系统配置、`/sys`、`/boot`、驱动或包管理器，请使用 `sudo`，并先阅读脚本内容：

```bash
sudo ./system_tools_setup/fan_max.sh
```

Python 脚本也支持 `--help`，建议用 `python3 script.py --help` 查看参数。

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
| `cpu_freq_default_restore.sh` | 恢复 CPU 动态调频默认设置 | 是 | `sudo ./system_tools_setup/cpu_freq_default_restore.sh` |
| `cpu_freq_lock.sh` | 锁定 CPU 频率到指定值，并关闭 boost/turbo | 是 | `sudo ./system_tools_setup/cpu_freq_lock.sh 800000` |
| `fan_max.sh` | 将检测到的风扇 PWM 拉满，支持退出时恢复原值 | 是 | `sudo ./system_tools_setup/fan_max.sh --restore-on-exit` |
| `gedit_setup.sh` | 配置 gedit 的右边距、配色和缩进 | 否 | `./system_tools_setup/gedit_setup.sh` |
| `git_setup.sh` | 设置常用 Git alias，安装 `gti` 包装命令，并确保 `~/.local/bin` 在 `PATH` 中 | 否 | `./system_tools_setup/git_setup.sh` |
| `headset_default_set.sh` | 向 ALSA 配置写入耳机模式参数，改善开机耳机识别 | 是 | `sudo ./system_tools_setup/headset_default_set.sh` |
| `ibus_rime_setup.sh` | 安装并配置 IBus Rime 简体拼音，包含横排候选和 `in/ing`、`en/eng` 模糊音 | 否 | `./system_tools_setup/ibus_rime_setup.sh` |
| `kernel_purge.sh` | 清理名称中包含 `budget` 的内核文件和模块目录 | 是 | `sudo ./system_tools_setup/kernel_purge.sh` |
| `nvidia_drivers_install.sh` | 屏蔽 `nouveau` 后下载并静默安装指定版本 NVIDIA 驱动 | 是 | `sudo ./system_tools_setup/nvidia_drivers_install.sh` |
| `snap_remove.sh` | 卸载 snap 及相关残留目录，并 hold `firefox`/`snapd` | 是 | `sudo ./system_tools_setup/snap_remove.sh` |
| `tmux_setup.sh` | 生成简洁的 `~/.tmux.conf`，开启鼠标并改前缀为 `Ctrl+a` | 否 | `./system_tools_setup/tmux_setup.sh` |
| `window_tiling_fix.sh` | 关闭 Tiling Assistant 的补窗弹窗，同时保留左右半屏快捷键 | 否 | `./system_tools_setup/window_tiling_fix.sh` |

### `executable_related/`

| 脚本 | 作用 | 是否需要 `sudo` | 示例 |
| --- | --- | --- | --- |
| `prio_watch.sh` | 持续观察进程/线程优先级，默认筛选 `safebot` | 否 | `./executable_related/prio_watch.sh` |
| `setcap.sh` | 给目标可执行文件添加 `cap_sys_nice` 能力 | 是 | `sudo ./executable_related/setcap.sh /path/to/bin` |
### `raspberry_pi/`

| 脚本 | 作用 | 是否需要 `sudo` | 示例 |
| --- | --- | --- | --- |
| `rpi5_direct_connect.sh` | 恢复笔记本 `e1000e` 网卡、配置共享网线、发现 Pi 5 并可直接 SSH | 脚本按需调用 | `./raspberry_pi/rpi5_direct_connect.sh --connect` |

完整的 Ubuntu Server 烧录、直连网络、SSH、Wi-Fi、GitHub 密钥及内核抢占模型检查流程见 `raspberry_pi/README.md`。


### `python/`

| 脚本 | 作用 | 依赖 | 说明 |
| --- | --- | --- | --- |
| `files_rename.py` | 对指定目录中的文件/目录进行批量重命名 | Python 3 | 当前是定制脚本，路径和替换规则写死，使用前请先修改脚本内容 |

### `video_transform/`

| 脚本 | 作用 | 依赖 | 示例 |
| --- | --- | --- | --- |
| `webm_to_mp4.py` | 使用 `moviepy` 将 `.webm` 转成 `.mp4` | `moviepy`、ffmpeg | `python3 video_transform/webm_to_mp4.py` |

安装 `moviepy` 示例：

```bash
pip install moviepy
```

系统里还需要可用的 `ffmpeg`。

## 风险提示

- `kernel_purge.sh`、`snap_remove.sh`、`nvidia_drivers_install.sh` 都会修改系统关键组件，执行前请确认目标环境和版本。
- `fan_max.sh`、`cpu_freq_lock.sh`、`cpu_freq_default_restore.sh` 会直接写入 `/sys`，只适合明确知道机器状态时使用。
- `rpi5_direct_connect.sh` 只在目标有线接口缺失时重载指定网卡驱动，但仍会短暂改变该驱动管理的网络设备状态。
- `prio_watch.sh` 当前默认筛选关键字 `safebot`。如果你想看别的进程，需要先改脚本里的过滤条件。
- `files_rename.py` 不是通用 CLI，而是一次性批处理脚本，运行前一定要检查硬编码路径。

## 最近命名调整

- `setup-ibus-rime.sh` -> `ibus_rime_setup.sh`
- `window-tiling-fixer.sh` -> `window_tiling_fix.sh`
- `set_headset_default.sh` -> `headset_default_set.sh`
- `restore_cpu_freq_default.sh` -> `cpu_freq_default_restore.sh`
- `lock_cpu_freq.sh` -> `cpu_freq_lock.sh`
- `purge_kernel.sh` -> `kernel_purge.sh`
- `remove_snap.sh` -> `snap_remove.sh`
- `watchprio.sh` -> `prio_watch.sh`
- `rename_files.py` -> `files_rename.py`
- `webm2mp4.py` -> `webm_to_mp4.py`
- `gedit-setup.sh` -> `gedit_setup.sh`
- `git-setup.sh` -> `git_setup.sh`
- `nvidia-drivers-install.sh` -> `nvidia_drivers_install.sh`
- `set-headset-default.sh` -> `headset_default_set.sh`
- `tmux-setup.sh` -> `tmux_setup.sh`

如果你本地有旧的调用方式、别名或笔记，请同步更新。
