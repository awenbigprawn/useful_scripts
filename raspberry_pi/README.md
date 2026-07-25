# Raspberry Pi 5 Ubuntu Server 与笔记本直连教程

本目录记录一套已经实际验证的 Raspberry Pi 5 配置：笔记本通过网线直接管理 Pi，笔记本自身通过 Wi-Fi 上网，并利用 NetworkManager 为 Pi 提供 DHCP、DNS 转发和 NAT。

## 文件

- `rpi5_direct_connect.sh`：在笔记本上恢复有线网卡、配置共享网线、发现 Pi 地址，并可直接打开 SSH。
- `README.md`：完整安装、连接和排障流程。

## 已验证的环境

### 笔记本

- Ubuntu
- Wi-Fi：`wlp0s20f3`
- 有线控制器：Intel I219-LM
- 有线驱动：`e1000e`
- 有线接口：`enp0s31f6`
- NetworkManager 配置：`Wired connection 1`
- 直连地址：`10.42.0.1/24`

### Raspberry Pi 5

- Ubuntu Server 24.04.4 LTS
- 主机名：`rpi5-realsense`
- 用户：`safebot`
- 有线接口：`eth0`
- 当前常见 DHCP 地址：`10.42.0.45`
- Wi-Fi 接口：`wlan0`

DHCP 地址可能变化，不要把 `10.42.0.45` 当成永久固定地址。脚本会根据直连邻居表和 Pi 的以太网 MAC 地址重新发现它。

## 网络结构

```text
Internet
   |
笔记本 Wi-Fi
   |
NetworkManager：DHCP + DNS + NAT
   |
笔记本 enp0s31f6：10.42.0.1/24
   |
网线
   |
Pi 5 eth0：10.42.0.x
```

## 日常使用

脚本应当在笔记本上运行，不要在 Pi 上运行：

```bash
cd ~/useful_scripts/raspberry_pi
./rpi5_direct_connect.sh --status
./rpi5_direct_connect.sh --connect
```

以后恢复网络并直接连接 Pi，只需：

```bash
~/useful_scripts/raspberry_pi/rpi5_direct_connect.sh --connect
```

脚本会依次：

1. 检查 `enp0s31f6` 是否存在；
2. 仅在接口缺失时重新加载 `e1000e`；
3. 创建或修复 NetworkManager 共享配置；
4. 激活 `10.42.0.1/24`；
5. 等待网线 carrier 和 Pi 的 DHCP 地址；
6. 输出直连 IP，并按需启动 SSH。

查看全部参数：

```bash
./rpi5_direct_connect.sh --help
```

## Raspberry Pi Imager 初始设置

写入 SD 卡之前建议设置：

- OS：Ubuntu Server 24.04 LTS 64-bit
- hostname：`rpi5-realsense`
- user：`safebot`
- 启用 SSH
- 导入笔记本的公钥，不要复制私钥
- 按需配置备用 Wi-Fi
- timezone：`Europe/Brussels`
- wireless country：`BE`

第一次开机时 cloud-init 需要数分钟完成初始化。

## 手工配置笔记本共享网线

```bash
sudo nmcli connection modify "Wired connection 1" \
    ipv4.method shared \
    ipv4.addresses 10.42.0.1/24 \
    ipv6.method disabled \
    connection.autoconnect yes

sudo nmcli connection down "Wired connection 1"
sudo nmcli connection up "Wired connection 1"
```

验证：

```bash
nmcli device status
ip -4 address show enp0s31f6
```

预期地址：

```text
inet 10.42.0.1/24
```

`ipv4.method shared` 会启动 DHCP 和 DNS 转发，并通过笔记本当前的默认网络提供 NAT。

## `e1000e` 启动失败

### 现象

GNOME Settings 的 Network 页面只显示 VPN 和 Proxy。即使网线已经插入，`nmcli device status` 也没有 Ethernet 接口。

NetworkManager 配置通常没有丢失；GUI 中缺少有线网络意味着内核没有成功创建接口。

检查：

```bash
lspci -s 00:1f.6 -nnk
lsmod | grep '^e1000e'
readlink /sys/bus/pci/devices/0000:00:1f.6/driver
journalctl -k -b --no-pager | grep -i e1000e
```

本机观察到的错误：

```text
e1000e: probe of 0000:00:1f.6 failed with error -2
```

此时模块可能已经加载，但 PCI 设备仍处于 `unbound`，不会出现 `enp0s31f6`。仅仅插入物理网线不能绕过驱动问题。

### 手工恢复

```bash
sudo modprobe -r e1000e
sudo modprobe e1000e
nmcli device status
```

恢复成功后，日志中会出现类似：

```text
enp0s31f6: NIC Link is Up 1000 Mbps Full Duplex
```

`rpi5_direct_connect.sh` 仅在接口不存在时进行这一步，不会在接口正常工作时无条件重载驱动。

## 查找并连接 Pi

```bash
ip neigh show dev enp0s31f6
```

示例：

```text
10.42.0.45 lladdr d8:3a:dd:dc:cf:3b REACHABLE
```

直接连接：

```bash
ssh safebot@10.42.0.45
```

笔记本 `~/.ssh/config` 中可加入：

```sshconfig
Host rpi5-realsense
    HostName rpi5-realsense.local
    User safebot
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

之后使用：

```bash
ssh rpi5-realsense
```

注意：`.local` 可能解析成 Pi 的 Wi-Fi 地址。若无线网络启用了客户端隔离，笔记本无法访问该地址。脚本会优先发现并使用 `10.42.0.x` 的直连地址。

## 查看 Pi 的 Wi-Fi

本配置中的 Ubuntu Server 使用 Netplan 和 `systemd-networkd`：

```bash
networkctl status wlan0
ip -4 address show wlan0
ip route
ping -I wlan0 -c 3 1.1.1.1
```

测试中的 `AirSOFT` 允许 Pi 通过 Wi-Fi 上网，但阻止笔记本通过无线地址 SSH 到 Pi。因此应保留网线用于管理和实验。

## Pi 上的 GitHub SSH 密钥

为 Pi 生成独立密钥，不要复制笔记本私钥：

```bash
ssh-keygen \
    -t ed25519 \
    -C "rpi5-realsense" \
    -f ~/.ssh/id_ed25519_github
```

将 `~/.ssh/id_ed25519_github.pub` 添加到 GitHub Authentication Key，然后在 Pi 的 `~/.ssh/config` 中加入：

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
```

测试和克隆：

```bash
ssh -T git@github.com

mkdir -p ~/program
cd ~/program
git clone --recurse-submodules \
    git@github.com:awenbigprawn/rs-camera.git
```

GitHub 成功认证后仍可能返回非零状态，因为 GitHub 不提供交互式 shell；以 `successfully authenticated` 消息为准。

## 检查 Pi 的内核抢占模型

```bash
uname -a
kernel_release=$(uname -r)
grep -E 'CONFIG_PREEMPT(_DYNAMIC|_RT)?=' \
    "/boot/config-${kernel_release}"
```

已测试环境：

```text
6.8.0-1060-raspi
CONFIG_PREEMPT=y
CONFIG_PREEMPT_DYNAMIC=y
PREEMPT_RT disabled
CONFIG_HZ=1000
```

`PREEMPT_DYNAMIC` 的 `full` 模式不等于 `PREEMPT_RT`。查看当前动态抢占模式：

```bash
sudo cat /sys/kernel/debug/sched/preempt
```

## 安全重启和关机

重启：

```bash
sudo systemctl reboot
```

断电或拔 SD 卡之前关机：

```bash
sudo systemctl poweroff
```

存储活动灯停止后再等待数秒，才能断开电源。

## 常见问题

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| Settings 只显示 VPN 和 Proxy | 有线驱动没有绑定 | 重载 `e1000e` |
| Ethernet 一直显示 getting IP configuration | 两端都是 DHCP 客户端 | 笔记本使用 `ipv4.method shared` |
| `.local` 能解析但 SSH 超时 | 解析成被隔离的 Wi-Fi 地址 | 查找并使用 `10.42.0.x` |
| GitHub 报 `Permission denied (publickey)` | 自定义密钥文件未被选中 | 在 Pi SSH config 添加 `IdentityFile` |
| `/sys/kernel/realtime` 不存在 | 当前不是 PREEMPT_RT | 实验时安装或构建真正的 RT 内核 |
