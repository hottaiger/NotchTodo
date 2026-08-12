# NotchTodo

macOS 14+ 原生刘海待办工具。收起时显示在刘海右侧，点击或按 `Option + Space` 展开双列任务看板。

## 功能

- 刘海右侧贴合式待办胶囊
- 现在 / 稍后双列任务看板
- SwiftData 本地存储、每日归档、30 天清理与恢复
- JSON 导入、导出与数据损坏恢复提示
- 全局快捷键、菜单栏操作、开机启动与无障碍支持

## 要求

- macOS 14+
- Swift 5.9+

## 开发

```bash
swift test
swift run
```

构建应用包：

```bash
zsh scripts/build-app.sh
open .build/release/NotchTodo.app
```

## 安装与分发

当前发布包为 Apple Silicon（M 系列芯片）版本。没有 Apple Developer 签名和公证时，macOS 会对从浏览器、微信等渠道下载的 App 标记隔离属性；这不是压缩包损坏。

下载并解压后，先在 Finder 中右键 `NotchTodo.app`，选择“打开”，再在系统确认框中选择“打开”。

若仍提示“已损坏”或无法打开，请仅在确认来源可信时执行：

```bash
xattr -dr com.apple.quarantine ~/Downloads/NotchTodo.app
open ~/Downloads/NotchTodo.app
```

如果 App 不在“下载”目录，请将命令中的路径替换为实际路径。

面向普通用户正式发布时，需要使用 Apple Developer 的 `Developer ID Application` 证书签名，并提交 Apple 公证；完成后即可正常双击安装，无需上述操作。
