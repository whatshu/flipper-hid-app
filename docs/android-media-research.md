> Archived investigation snapshot. For the current source layout and verification, see [development notes](development-notes.md).

# Android / OPPO 媒体控制调研

日期：2026-11-05。对象：OPPO Find N5（PKH110）、Android 16，系统属性
`ro.build.version.oplusrom=V16.1.0`，构建 `PKH110_16.0.10.501(CN01)`。

**2026-11-06 实测更新：** Key Mapper 源码已克隆并安装官方 4.6.2 FOSS。
单键暂停映射已导入并测试。后续完全关闭其无障碍、撤销通知使用权并停止应用，
Bilibili 列表播放器的半屏、全屏及 VLC 仍能通过真实 Flipper OK 播放/暂停。
旧故障本轮未复现，尚不能认定外置应用是必需条件或本次恢复的原因。
详见 [实测记录](keymapper-device-testing.md)；以下保留 11 月 5 日的调研依据。

## 结论

Android 的标准方案是播放器提供 MediaSession，遥控端发送媒体控制命令。
正常支持这套接口的播放器不应普遍依赖额外助手。目前没有找到 OPPO 官方资料
要求通过外置应用才能使用标准媒体键，也不能把这次问题直接归因于省电设置。

11 月 5 日，Flipper 候选构建已经能发送真正的播放/暂停媒体键，VLC 前台暂停成功。
Bilibili 前台不响应；打开通知栏后，同一个蓝牙按键可以控制它；通过系统媒体
会话分发的诊断命令也能控制它。因此后续应优先验证绕过前台键盘分发、直接控制
MediaSession 的现成工具，而不是继续试 Space、Enter 或点击坐标。
这是根据本机对照测试作出的推断，尚未定位到 Bilibili 或 ColorOS 的具体代码。

## 标准处理路径

1. Flipper 当前使用 BLE HID。Consumer usage `0x0C/0xCD` 表示播放/暂停；
   本机已经记录到对应 KEY_PLAYPAUSE 及 Android keyCode 85。
2. Android 文档说明，可见 Activity 先接收媒体按键；未处理时，系统寻找可处理
   的媒体会话。Android 8.0 起，这通常涉及最近播放本地音频的 MediaSession。
3. 控制指定媒体会话则可以调用 `MediaController.TransportControls.pause()`、
   `play()`，无需把另一个普通键盘事件再送给前台界面。

依据：[Android 媒体按键处理](https://developer.android.com/media/legacy/media-buttons)、
[TransportControls](https://developer.android.com/reference/android/media/session/MediaController.TransportControls)。

蓝牙耳机和 Flipper HID 的路径也有区别：经典蓝牙耳机的 AVRCP 控制由 Android
蓝牙服务转交 `AudioManager.dispatchMediaKeyEvent()`；当前 Flipper 是 HID 输入设备。
所以“耳机暂停正常”不能直接证明同机的 HID 媒体键也会经过完全相同的分发路径。
该区别来自 [AOSP AVRCP 实现](https://android.googlesource.com/platform/packages/modules/Bluetooth/+/b2dfcaf71aa0342edc790966f93e75ed6743c6f7/android/app/src/com/android/bluetooth/avrcp/AvrcpTargetService.java#490)，
不代表已经验证本机耳机或 OPPO 私有实现。

## 已有项目：Key Mapper

优先候选为 [keymapperorg/KeyMapper](https://github.com/keymapperorg/KeyMapper)，
GPL-3.0 开源项目。调研时官方最新稳定版为
[4.6.2](https://github.com/keymapperorg/KeyMapper/releases/tag/v4.6.2)，
发布于 2026-10-22；官方提供 FOSS APK。调研时尚未安装，后续安装与实测见上方更新。

核对的是 v4.6.2 源码，而不只是功能介绍：

| 所需能力 | 项目已有实现 |
| --- | --- |
| 接收外置键盘/Flipper 按键 | 无障碍 onKeyEvent，可按外部输入设备限定触发器 |
| 暂停指定播放器 | ControlMediaForApp.Pause 支持播放器包名 |
| 直接暂停会话 | AndroidMediaAdapter.pause() 检查 ACTION_PAUSE 后调用 transportControls.pause() |
| 播放/暂停切换 | 读取会话播放状态后调用 pause/play |
| 处理会话能力差异 | 支持动作优先使用 TransportControls，否则向媒体会话分发媒体按键 |
| 后续按时间跳转 | StepForward/StepBackward 在 ACTION_SEEK_TO 可用时调用 seekTo |

来源：[媒体适配器源码](https://github.com/keymapperorg/KeyMapper/blob/v4.6.2/system/src/main/java/io/github/sds100/keymapper/system/media/AndroidMediaAdapter.kt)、
[动作执行源码](https://github.com/keymapperorg/KeyMapper/blob/v4.6.2/base/src/main/java/io/github/sds100/keymapper/base/actions/PerformActionsUseCase.kt)、
[指定播放器动作模型](https://github.com/keymapperorg/KeyMapper/blob/v4.6.2/base/src/main/java/io/github/sds100/keymapper/base/actions/ActionData.kt)、
[外部设备触发器文档](https://keymapper.app/user-guide/keymaps/#key-device)。

这条方案需要：

- **无障碍服务**：在前台应用处理之前接收并消费触发键。
- **通知使用权**：项目通过已启用的 NotificationListener 获取其他应用的活跃
  MediaSession，再创建控制器。这不是“允许应用发通知”的普通通知权限。

Android 官方分别说明了
[无障碍按键过滤的先后顺序](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService#onKeyEvent(android.view.KeyEvent))
及 [getActiveSessions 的通知监听器授权方式](https://developer.android.com/reference/android/media/session/MediaSessionManager#getActiveSessions(android.content.ComponentName))。
上述暂停功能代码路径没有要求 root、Shizuku 或切换输入法。项目其他功能可能
需要不同权限；不能据此一次性授予所有权限。尚未实测 ColorOS 16 上能否稳定
接收这个特定媒体键，或其后台存活情况。

## 下一步验证配置

采用现成 Key Mapper，不开发自己的安卓中转应用。先做一个最小映射：

1. 触发器限定为 Remote Eat5elea Keyboard 的播放/暂停键；保留默认的消费原键
   行为，避免一次按键触发两遍。可加 Bilibili 在前台的约束。
2. 动作选项目内置的“暂停媒体”，指定 tv.danmaku.bili；不要选输入 keyCode 85。
3. Bilibili 播放时，在半屏和全屏各按一次真实 Flipper OK，确认 MediaSession
   从 PLAYING 变为 PAUSED、画面停止，并且界面焦点不移动。
4. 暂停通过后再改成播放/暂停切换，验证每次只有一次状态变化；复测 VLC。

如果 Key Mapper 录不到媒体键，先排查无障碍过滤和其他按键服务竞争；如需独立
普通键作为触发器，可在既有项目中配置后验证，不再猜测播放器的键盘快捷键。
这是 11 月 5 日拟定的验证方案；实际安装、权限恢复与测试结果见后续实测记录。

快进/快退继续后置。本机 Bilibili 会话报告的 actions=823 包含 SEEK_TO、PLAY、
PAUSE、PLAY_PAUSE、上一项和下一项等，但不包含 FAST_FORWARD/REWIND。
这只是声明的能力；以后应验证“按时间步进”的 seekTo 行为，不能把上一集/下一集
当作视频内快退/快进。
