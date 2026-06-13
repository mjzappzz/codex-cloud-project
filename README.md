# Codex Skills

Codex 的自定义 **Skill** 集合 — 26 个工程技能知识包，覆盖代码审查、调试、CI/CD、安全、性能优化等开发全流程。

每个 Skill 是一个独立目录，内含 `SKILL.md` 定义文件，按需加载到对话中提供专业知识。

---

## 目录

- [简介](#简介)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [Skills 一览](#skills-一览)
  - [工程基础](#工程基础)
  - [开发流程](#开发流程)
  - [质量与测试](#质量与测试)
  - [安全与运维](#安全与运维)
  - [设计与架构](#设计与架构)
  - [辅助工具](#辅助工具)
- [使用方式](#使用方式)
- [Skill 详解](#skill-详解)
- [创建你自己的 Skill](#创建你自己的-skill)
- [最佳实践](#最佳实践)
- [维护指南](#维护指南)
- [许可证](#许可证)

---

## 简介

**Codex** 是另一种 AI 编程辅助工具（类似 Claude Code），也支持自定义 **Skill** 机制：

- **Skill** 是一个目录，内含 `SKILL.md` 入口文件，定义技能的角色、知识和输出规范
- 通过 `SKILL.md` 的 YAML frontmatter（`name`、`description`）标识和路由
- 可选的 `scripts/`、`references/`、`assets/` 子目录存放辅助资源

本仓库是您的个人工程技能知识库，涵盖从编码、调试到发布的全生命周期技能。

---

## 快速开始

```bash
# 1. 克隆本仓库
git clone <repo-url> ~/.codex/skills

# 2. 在 Codex 对话中，通过技能名称触发
# 例如需要代码审查时，加载 code-review-and-quality 技能
# 需要调试时，加载 debugging-and-error-recovery 技能

# 3. 查看所有可用技能
ls ~/.codex/skills/*/SKILL.md
```

---

## 目录结构

```
~/.codex/skills/
├── api-and-interface-design/      # 👉 API 与接口设计
├── browser-testing-with-devtools/ # 👉 浏览器测试
├── ci-cd-and-automation/          # 👉 CI/CD 自动化
├── code-review-and-quality/       # 👉 代码审查
├── code-simplification/           # 👉 代码简化
├── context-engineering/           # 👉 上下文工程
├── debugging-and-error-recovery/  # 👉 调试与错误恢复
├── deprecation-and-migration/     # 👉 废弃与迁移
├── documentation-and-adrs/        # 👉 文档与架构决策
├── doubt-driven-development/      # 👉 质疑驱动开发
├── frontend-ui-engineering/       # 👉 前端 UI 工程
├── git-workflow-and-versioning/   # 👉 Git 工作流
├── idea-refine/                   # 👉 创意提炼
├── incremental-implementation/    # 👉 增量实现
├── interview-me/                  # 👉 需求澄清
├── observability-and-instrumentation/ # 👉 可观测性
├── performance-optimization/      # 👉 性能优化
├── planning-and-task-breakdown/   # 👉 任务拆解
├── security-and-hardening/        # 👉 安全加固
├── shipping-and-launch/           # 👉 发布上线
├── source-driven-development/     # 👉 源码驱动开发
├── spec-driven-development/       # 👉 规范驱动开发
├── stress-report/                 # 👉 压力测试报告
├── test-driven-development/       # 👉 测试驱动开发
├── ui-ux-pro-max/                 # 👉 UI/UX 设计
├── using-agent-skills/            # 👉 技能路由指南
├── .system/                       # 系统管理（可选）
└── README.md                      # 本文件
```

每个 Skill 目录结构：

| 文件/目录 | 用途 | 必需 |
|-----------|------|------|
| `SKILL.md` | Skill 入口文件 — 角色定义、知识库、输出规范 | ✅ |
| `scripts/` | 辅助脚本（如自动化工具、模板生成） | ❌ |
| `references/` | 参考文档、示例代码 | ❌ |
| `assets/` | 静态资源、模板文件 | ❌ |

---

## Skills 一览

### 工程基础

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `code-review-and-quality` | 多维代码审查 — 正确性、可读性、架构、安全、性能 | 合入前审查任何代码变更 |
| `code-simplification` | 代码简化 — 降低复杂度、提升可维护性 | 代码过长、嵌套过深、重复逻辑 |
| `debugging-and-error-recovery` | 系统化调试 — Stop-the-Line 三阶段流程 | 测试失败、构建错误、运行时异常 |
| `performance-optimization` | 性能优化 — Profile → 定位 → 修复闭环 | 响应慢、CPU高、内存泄漏 |

### 开发流程

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `git-workflow-and-versioning` | Git 工作流与版本管理 | 分支策略、提交规范、版本发布 |
| `incremental-implementation` | 增量实现 — 小步快跑 | 多项变更按小步骤分次交付 |
| `planning-and-task-breakdown` | 任务拆解 — 将需求转化为有序任务 | 需求清晰后的执行规划 |
| `spec-driven-development` | 规范驱动开发 — 先写规范再实现 | 重要功能或 API 开发前 |
| `source-driven-development` | 源码驱动 — 基于官方来源做决策 | 使用新框架/库时的最佳实践 |
| `test-driven-development` | 测试驱动开发 — 测试先行 | 任何需要验证的行为变更 |
| `deprecation-and-migration` | 废弃与迁移计划 | 移除旧代码、升级依赖、数据迁移 |

### 质量与测试

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `ci-cd-and-automation` | CI/CD 质量门禁与自动化 | 设置流水线、自动化检查 |
| `browser-testing-with-devtools` | 浏览器行为验证 | 使用 Chrome DevTools 调试前端 |
| `stress-report` | 压力测试报告生成 | 服务器性能瓶颈分析 |
| `doubt-driven-development` | 质疑驱动 — 对抗性审查 | 对非平凡决策进行压力测试 |

### 安全与运维

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `security-and-hardening` | 安全加固 — 输入、认证、数据保护 | 涉及用户输入、认证、数据集成 |
| `observability-and-instrumentation` | 可观测性 — 日志、指标、链路、告警 | 添加监控、排查线上问题 |
| `shipping-and-launch` | 发布上线 — 部署、监控、回滚计划 | 准备生产发布 |

### 设计与架构

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `api-and-interface-design` | API 与接口设计 — 稳定、清晰的接口契约 | 定义模块边界、API 设计 |
| `frontend-ui-engineering` | 前端 UI 工程 — 高质量用户界面 | 构建或审查前端界面 |
| `ui-ux-pro-max` | UI/UX 设计指导 — 多技术栈 | 需要设计规范和最佳实践 |
| `documentation-and-adrs` | 文档与架构决策记录 | 记录架构决策、编写文档 |

### 辅助工具

| Skill | 用途 | 使用场景 |
|-------|------|---------|
| `context-engineering` | 上下文工程 — 管理项目上下文和 Agent 指令 | 优化 Agent 工作效果 |
| `interview-me` | 需求澄清 — 通过提问明确模糊需求 | 需求不清晰时 |
| `idea-refine` | 创意提炼 — 将模糊想法转化为可执行概念 | 从零开始构思功能 |
| `using-agent-skills` | 技能路由指南 — 发现和路由工作到合适的 Skill | 不确定该用哪个技能时 |

---

## 使用方式

### 在 Codex 中

```bash
# Codex 会自动根据任务描述匹配合适的技能
# 你也可以在对话中直接引用技能名称

# 例如需要代码审查时提及审查需求
帮我审查这段代码

# 需要调试时描述错误
我的测试失败了，帮我找到根因

# 需要安全性评估时
检查这个接口的安全漏洞
```

### 手动引用

每个 Skill 的 `description` frontmatter 定义了触发条件，Codex 会自动匹配。你也可以在提示中明确要求。

---

## Skill 详解

### code-review-and-quality

> 五轴代码审查 — 合入前的质量门禁

审查标准：

| 维度 | 检查项 |
|------|--------|
| **正确性** | 是否符合需求、边界条件、错误处理 |
| **可读性** | 命名、注释、代码结构是否清晰 |
| **架构** | 设计模式、模块边界、依赖是否合理 |
| **安全** | 输入验证、注入防护、敏感数据处理 |
| **性能** | 不必要的分配、循环效率、缓存机会 |

**原则：** 只要变更确实改进了整体代码健康度就批准，不需要代码完美。

### debugging-and-error-recovery

> Stop-the-Line 系统化调试流程

```
1. STOP — 停止添加功能或修改
2. PRESERVE — 保留证据（错误输出、日志、复现步骤）
3. DIAGNOSE — 用结构化的排查清单诊断
4. FIX — 修复根因
5. GUARD — 防止复发
```

**排查清单：**
- 最近改了什么？
- 假设是什么？（列出所有）
- 能稳定复现吗？
- 错误出现的时间和频率？
- 最小复现条件是什么？

### incremental-implementation

> 小步快跑，每个步骤都可验证

```
Step 1: 理解现状 → 分析当前代码结构
Step 2: 规划步骤 → 拆解为独立可验证的小步
Step 3-: 逐步骤实现 → 每步后运行验证
Final: 整体回归 → 全量测试
```

**每步标准：** 可独立验证、可回滚、不影响已有功能。

### doubt-driven-development

> 针对非平凡决策的对抗性审查

适用场景：
- 架构设计决策
- 第三方依赖选择
- 数据模型设计
- 安全方案
- 任何"感觉不对劲"的决定

**方法：** 列出决策背后的所有假设 → 逐一尝试证伪 → 记录剩余风险。

### security-and-hardening

> 代码安全加固检查清单

| 检查项 | 说明 |
|--------|------|
| 输入验证 | 所有外部输入需校验类型、长度、范围 |
| SQL 注入 | 使用参数化查询，避免字符串拼接 |
| XSS | 输出编码，CSP 头 |
| 认证 | 会话管理、密码存储（bcrypt/argon2） |
| 授权 | 越权检查、最小权限原则 |
| 敏感数据 | 密钥管理、环境变量、不硬编码 |
| 依赖安全 | 已知漏洞扫描 |

### stress-report

> 压力测试与性能报告生成

生成内容：
- 测试环境与配置
- 压测结果数据（QPS、延迟、错误率）
- 资源使用分析（CPU、内存、IO）
- 瓶颈定位
- 优化建议

### planning-and-task-breakdown

> 将需求转化为可执行的任务

```
需求 → 功能拆解 → 任务列表 → 依赖排序 → 估算 → 排期
```

每个任务包含：
- 明确的目标
- 验收标准
- 涉及的代码/文件
- 依赖的前置任务

### documentation-and-adrs

> 架构决策记录（ADR）与项目文档

ADR 格式：

```markdown
# ADR-001: 选择 PostgreSQL 作为主数据库

## 状态
已接受 | 提议 | 废弃

## 上下文
为什么需要这个决策？当前存在的问题是什么？

## 决策
我们决定做什么？

## 后果
这样做带来的收益和成本是什么？

## 替代方案
考虑过的其他选项及放弃的原因
```

---

## 创建你自己的 Skill

在 `~/.codex/skills/` 下新建目录并编写 `SKILL.md`：

```markdown
---
name: my-custom-skill
description: Short description of when to use this skill. Use when [触发条件].
---

# My Custom Skill

## Overview

简要描述这个技能是做什么的、为什么需要它。

## When to Use

- 场景 1: 什么时候用
- 场景 2: 什么时候用

## Core Principles

### 原则 1
详细说明...

### 原则 2
详细说明...

## Process / Checklist

清晰的步骤或检查清单...

## Examples

### 示例 1
输入 → 输出

### 示例 2
输入 → 输出
```

**可选资源目录：**

```bash
mkdir -p ~/.codex/skills/my-custom-skill/{scripts,references,assets}
```

---

## 最佳实践

### 使用建议

- **遇到问题先选对技能** — 调试用 `debugging-and-error-recovery`，审查用 `code-review-and-quality`
- **复杂任务多技能组合** — 例如：先 `planning` 拆解任务，然后 `incremental-implementation` 逐步实现
- **重要决策先 `doubt-driven-development`** — 对抗性审查能发现很多隐藏问题
- **准备上线前跑 `shipping-and-launch`** — 确保有完整的发布、监控和回滚计划

### 技能设计原则

- **每个技能专注一个领域** — 不要做大而全
- **description 写明触发条件** — 这是 Codex 自动匹配的关键
- **提供可操作的步骤** — 不要只描述"做什么"，要说明"怎么做"
- **检查清单优先** — 结构化的清单比长段落描述更有用
- **保持轻量** — 长示例和参考文档放在 `references/`，不要塞进 `SKILL.md`

### 已知 Skill 组合

| 场景 | 推荐技能组合 |
|------|-------------|
| 新功能开发 | `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `code-review-and-quality` |
| Bug 修复 | `debugging-and-error-recovery` → `test-driven-development` → `code-review-and-quality` |
| 性能优化 | `performance-optimization` → 修复 → `code-review-and-quality` |
| 安全审查 | `security-and-hardening` → `doubt-driven-development` |
| 发布上线 | `ci-cd-and-automation` → `shipping-and-launch` → `observability-and-instrumentation` |
| 重构 | `code-simplification` → `test-driven-development` → `incremental-implementation` |
| 架构设计 | `api-and-interface-design` → `documentation-and-adrs` → `doubt-driven-development` |

---

## 维护指南

### 日常维护

```bash
# 检查是否有未跟踪的本地文件
find . -maxdepth 3 -type f \
  ! -path './.git/*' \
  ! -path './.codex/*' \
  ! -path './.agents/*' \
  | sort
```

### 注意事项

- 不要提交密钥、Token、私钥、许可证文件、客户数据或机器特定的运行时输出
- 每个技能保持专注，一个技能只做一件事
- 大型示例、脚本和参考文档放在 `SKILL.md` 外部，按需加载
- 推送前检查是否包含不应公开的文件

### Git 初始化（首次）

```bash
git init
git add README.md */SKILL.md
git commit -m "Initial commit: Codex skills"
git remote add origin <repo-url>
git push -u origin main
```

---

## 许可证

MIT

---

**相关资源：**
- [Claude Skills 仓库](https://github.com/mjzappzz/claude-skills) —（如果已分开托管）
- [Claude Agents 仓库](https://github.com/mjzappzz/claude-agents) — 100+ 领域专家 Agent
