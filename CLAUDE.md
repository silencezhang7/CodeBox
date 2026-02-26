# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

CodeBox 是一个 iOS/iPadOS 剪贴板管理应用，自动识别并分类剪贴板内容（取件码、验证码、其他），支持正则引擎与 AI 大模型双通道识别。

## 构建与运行

```bash
# 命令行构建（需要 Xcode 26+）
xcodebuild -project CodeBox.xcodeproj -scheme CodeBox -destination 'platform=iOS Simulator,name=iPhone 16' build

# 运行测试
xcodebuild -project CodeBox.xcodeproj -scheme CodeBox -destination 'platform=iOS Simulator,name=iPhone 16' test
```

日常开发推荐直接使用 Xcode IDE（`Cmd+B` 构建，`Cmd+U` 测试）。

## 架构

**技术栈：** Swift + SwiftUI + SwiftData，最低部署目标 iOS/iPadOS。

**目录结构（已完成 SRP 拆分）：**

```
CodeBox/
├── Models/
│   ├── ClipboardItem.swift   — SwiftData 模型（取件码/验证码/其他）
│   ├── AIModel.swift         — SwiftData 模型，存储用户配置的 AI 模型
│   ├── AIProvider.swift      — 枚举：OpenAI / Anthropic / 自定义
│   └── AppTheme.swift        — 枚举：系统/亮色/深色主题
├── Views/
│   ├── ItemListView.swift    — 按类型过滤的列表视图（含剪贴板轮询逻辑）
│   ├── ItemRowView.swift     — 单条记录行视图
│   ├── AddClipboardItemView.swift — 手动添加条目的 Sheet
│   ├── ProfileView.swift     — "我的"页：主题切换、AI 模型管理入口
│   ├── ModelListView.swift   — AI 模型列表管理
│   ├── ModelRowView.swift    — 单条 AI 模型行视图
│   ├── AddModelView.swift    — 添加/编辑 AI 模型的 Sheet
│   └── LiquidGlassModifier.swift — 毛玻璃视觉效果 ViewModifier
└── Utils/
    ├── RecognitionEngine.swift    — 正则识别引擎（菜鸟/丰巢/顺丰等 + 验证码）
    ├── AIRecognitionService.swift — AI 识别服务（调用 OpenAI/Anthropic 兼容接口）
    └── ModelTestService.swift     — AI 模型连通性测试
```

**识别流程：** `ItemListView` 轮询剪贴板 → 优先用 `RecognitionEngine`（正则，无网络）→ 若用户配置了 AI 模型则回退到 `AIRecognitionService`（HTTP JSON）→ 结果写入 SwiftData。

**AI 接口兼容性：** `AIRecognitionService` 同时支持 Anthropic Messages API（`/v1/messages`）和 OpenAI Chat Completions API（`/chat/completions`），通过 `AIModel.provider` 字段区分请求头与响应解析路径。

**主题：** `AppTheme` 通过 `@AppStorage("app_theme")` 持久化，在 `ContentView` 顶层注入 `preferredColorScheme`。
