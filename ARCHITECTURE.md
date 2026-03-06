# LexiRead 架构与技术方案文档

## 1. 项目概述

**LexiRead** 是一款模仿“薄荷阅读”、“流利说阅读”的英语分级阅读应用程序。
应用的核心目标是通过提供科学分级的英语读物、按天解锁的驱动机制（Drip Content）、沉浸式的富文本阅读器（支持点词翻译、整句音频高亮），以及打卡海报生成等功能，帮助用户培养长期的英语阅读习惯。

## 2. 技术栈选型

本项目采用前后端分离的现代化技术架构，追求跨平台的高效开发与快速交付：

*   **前端应用 (客户端): Flutter**
    *   **原因**: 提供跨越 iOS, Android 和 Web 的高性能统一渲染。特别是在处理长篇“富文本”和复杂的交互动画时，Flutter 的渲染机制具有显著优势。
    *   **核心库**: `flutter_riverpod` (状态管理), `go_router` (声明式路由), `just_audio` (音频处理), `supabase_flutter` (BaaS SDK)。
*   **后端 API 服务: FastAPI (Python 3.10+)**
    *   **原因**: 原生支持异步，性能卓越。更重要的是，Python 是 AI/NLP 的第一语言，极其方便后续接入 LLM (大语言模型)、长难句语法分析和自动分词对齐算法。
*   **数据库与基础服务 (BaaS): Supabase**
    *   **原因**: 提供基于 PostgreSQL 的强大关系型数据库，开箱即用的 Auth（身份验证）和 Storage（对象存储）。极大缩短了 MVP 阶段的开发周期，并提供了安全的 RLS (行级安全) 机制。

## 3. 前端架构设计 (Flutter)

前端采用 **Feature-First (领域驱动)** 目录结构组织代码，保证了高内聚和低耦合。

### 目录结构说明
```text
lib/
├── core/                # 核心层 (基础建设)
│   ├── constants/       # 全局常量
│   ├── router/          # GoRouter 路由配置
│   └── theme/           # AppTheme 亮暗色主题配置
├── features/            # 业务功能层
│   ├── auth/            # 登录、注册、鉴权拦截
│   ├── check_in/        # 生成打卡海报 (RepaintBoundary)
│   ├── learning/        # 课后测试与生词本复习 (记忆曲线机制)
│   ├── library/         # 书库列表、选书、阅读排期展示
│   └── reader/          # 🌟核心：沉浸式阅读器
│       ├── controllers/ # 音频同步、交互控制器
│       ├── models/      # TextToken 数据结构
│       ├── presentation/# UI: 屏幕、组件 (InteractiveParagraph)
│       ├── services/    # 词典 API、翻译服务
│       └── utils/       # 分词解析算法 (TextParser)
├── shared/              # 全局共享层
│   └── widgets/         # 通用按钮、弹窗、加载动画等
└── main.dart            # 应用入口，依赖注入初始化
```

### 核心功能实现方案：阅读器引擎 (Text Engine)
阅读器的难点在于**“文本的点词交互”与“音频的整句高亮”**同步。
1.  **Tokenization (分词)**: 后端下发整段文本后，前端 `TextParser` 使用正则表达式 `([a-zA-Z\-']+)|([^a-zA-Z\-']+)` 将段落拆解为独立的 `TextToken`，并根据标点符号标记其所属的句子索引 (`sentenceIndex`)。
2.  **RichText 渲染**: 使用 `RichText` 和 `TextSpan` 将词流渲染出来。如果是单词，则为其绑定 `TapGestureRecognizer`，实现点击查词。
3.  **音频状态同步**: 使用 `just_audio` 的 `positionStream` 监听播放进度。通过对比后端下发的 `AudioTimestamp`，利用 `ValueNotifier<int?> activeSentenceIndex` 实现局部刷新，使得当前播放的句子背景高亮，达成“卡拉OK”效果。

## 4. 后端与数据库设计 (Supabase + FastAPI)

### 核心数据模型 (Schema - PostgreSQL)
我们设计了以 `UserProgress` 为核心的多对多关系数据库模型：

*   **`users`**: 用户信息、评测词汇量等级。
*   **`books`**: 书籍信息、总天数、难度。
*   **`chapters`**: 每一天的阅读内容、文本段落、对应的音频 URL 和时间戳。
*   **`user_progress`**: 记录用户在某本书的某一天的状态（`locked` / `unlocked` / `completed`）。**按天解锁逻辑的核心所在。**
*   **`user_vocabularies`**: 用户的生词本，包含单词、释义以及非常关键的**原文语境 (context_sentence)**。

### 业务闭环引擎 (状态机)
1.  **Leveling (定级)**: 用户完成词汇量测试后，系统匹配一本 `difficulty_level` 相符的书籍，并向 `user_progress` 插入 `day_number = 1` 的记录，状态设为 `unlocked`。
2.  **Drip Content (按天解锁)**: 当用户打卡完成“第 1 天”的内容后，系统查询“第 2 天”的内容，并向 `user_progress` 插入记录，但将其状态设为 `locked`，同时设定 `unlocked_at` 为**次日凌晨 0 点**。防止用户一次性读完，制造饥饿感。

## 5. 远期 AI 演进路线

本项目在 FastAPI 层预留了充足的 AI 扩展空间：
*   **LLM 语境翻译缓存**: 摒弃传统生硬词典。由后端调用大模型（GPT-4o / DeepSeek）结合句子上下文进行一词多义分析和长难句语法树拆解。并通过 `translation_cache` 表根据 `sentence_hash` 永久缓存，实现前端毫秒级查询。
*   **AI 辅导伴学**: 基于用户的课后测试错题，提供“问问老师”功能，由 LLM 讲解为何选A不选B。

---
*文档更新日期：2026年2月*
