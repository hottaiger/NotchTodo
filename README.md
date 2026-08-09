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
