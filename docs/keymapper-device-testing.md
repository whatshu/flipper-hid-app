> Archived investigation snapshot. For the current source layout and verification, see [development notes](development-notes.md).

# Key Mapper 实机测试（2026-11-06）

后续已将明确的 1.2 构建安装到设备并回读核对 SHA256，Bilibili 与 VLC 播放/暂停
复测通过。见 [最终安装验证](deployment-1.2.md)。下文保留安装最终构建前的调查记录。

## 当前结论

Key Mapper 已安装并试用。当前设备状态下，关闭它之后，Flipper 原生媒体键也
可以控制本轮测试的 Bilibili 和 VLC。因此不能把当前成功归因于 Key Mapper，
也不能认定这台手机必须安装中转应用。11 月 5 日的失败本轮没有复现。

本轮使用了另一段“稍后再看”视频，播放器仍是 UnitedPlaylistActivity；没有重测
11 月 5 日英国农场视频的完全相同播放状态，不能据此宣称旧故障已永久修复。

## 安装与配置

- 源码：`D:\project\flipper\KeyMapper`，官方标签 v4.6.2。
- 提交：`e247ad33a49f737ac1391c6afa973bf1892dd469`，工作区干净，未修改源码。
- 手机安装的是同标签官方 FOSS APK，并非本机构建的 APK。
- 包名：io.github.sds100.keymapper；版本 4.6.2-foss，versionCode 288。
- APK：`D:\project\flipper\env\downloads\keymapper-4.6.2-foss.apk`。
- SHA256：`e087e35765fdbde60b65ed31763c26d131e0550e867da746b733e40ccd007ed0`，与官方发布摘要一致。

使用应用自带导入功能追加了一个映射：

`Remote Eat5elea Keyboard 的 Play/Pause → 暂停 tv.danmaku.bili 的媒体`

这是单向暂停测试映射，不是播放/暂停切换映射。设备限定来自手机实际输入设备
descriptor；原键由映射消费。导入文件位于
`D:\project\flipper\env\flipper-keymapper-pause.json`。

用户明确只允许测试期间启用无障碍和通知使用权。两项均通过系统界面临时授予。
没有授予 root、Shizuku、切换输入法或文件全盘访问权限。

## 观察结果

| 场景 | Key Mapper 状态 | 真实 Flipper OK 的结果 |
| --- | --- | --- |
| Bilibili 普通视频，半屏 | 无障碍与通知使用权开启，暂停映射运行 | PLAYING → PAUSED，位置约 37 秒 |
| Bilibili 普通视频，半屏 | 通过项目官方 API 暂停映射；界面确认“已暂停” | 媒体键仍可暂停，不能据此证明中转是必需的 |
| Bilibili 已暂停的视频 | 恢复单向暂停映射 | 按 OK 后保持 PAUSED，没有被原生切换成播放 |
| 稍后再看，半屏 | 无障碍关闭 | 连续三次 OK：PLAYING → PAUSED → PLAYING → PAUSED |
| 稍后再看，半屏 | 两项权限都关闭，应用 force-stop | PAUSED → PLAYING → PAUSED |
| 稍后再看，实际横屏全屏 | 两项权限都关闭，应用 force-stop | PAUSED → PLAYING → PAUSED，位置 5189 → 7655 ms |
| VLC 本地视频 | 两项权限都关闭，应用停止 | 连续三次 OK：PLAYING → PAUSED → PLAYING → PAUSED |

半屏和全屏通过截图区分，不能只根据 Activity 名称判断全屏。原生按键均记录到
Consumer scan `000c00cd`、KEY_PLAYPAUSE DOWN/UP，且前台 Activity 未切换。
ADB 的 `cmd media_session dispatch play` 只用于部分对照测试的初始播放状态，
没有作为蓝牙控制成功的证据。没有测试快进/快退。

环境：OPPO PKH110，系统 PKH110_16.0.10.501(CN01)；Bilibili 9.17.0
（9170300，安装更新时间 2026-10-29）；VLC 本地视频来自 `/sdcard/my`。
Flipper 运行 Bluetooth Remote / Media (Android)，连接名 Remote Eat5elea。

本轮没有修改或覆盖 Flipper 上的 FAP。设备 FAP 与本地最近一次构建大小均为
90328 字节，但 MD5 不同，不能声称当前设备二进制与本地最新构建完全相同：

- 设备：`0eafd45699640f1ecf0f615ea5456d83`
- 本地 dist：`1e672b0de29154731455507bdbc8d13b`

## 证据与结束状态

诊断文件位于 `D:\project\flipper\env`：

- `keymapper-bili-half-pause.json`：暂停映射开启时的真实按键。
- `keymapper-bili-half-disabled.json`、`keymapper-bili-half-enabled.json`：暂停/恢复映射的对照。
- `native-playlist-half-no-accessibility.json`：完全关闭无障碍后的连续按键。
- `native-playlist-half-no-keymapper.json`：两项权限关闭、应用停止后的半屏测试。
- `native-playlist-actual-fullscreen.png`、`native-playlist-confirmed-fullscreen.json`：实际全屏及其按键结果。
- `native-vlc-no-keymapper.json`：VLC 连续播放/暂停结果。

结束时 Key Mapper 无障碍已关闭，通知使用权已撤销，应用已停止；原有 KDE Connect
通知监听器保留。应用与测试映射保留供复查，但没有权限时不能执行中转控制。
VLC 和 Bilibili 留在暂停状态，未调整音量。USB 常亮在设备调试期间保持开启。
