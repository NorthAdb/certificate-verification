# 证书验证工具改造计划 — GmSSL → Tongsuo + PQC 证书

> **文档性质：** 实施计划（**已于 2026-06-16 完成主要改造**）  
> **编制日期：** 2026-06-16  
> **参照文档：**
> - `certificate-verification-win32-x64/项目结构梳理.md`（现状）
> - `tlcp-pqc/certs/Windows查看与验链命令.md`（目标命令与证书）
> - 界面截图（仅保留「根证书」「要验证的证书」两个区域）

---

## 1. 需求理解

### 1.1 改造目标（一句话）

将现有基于 **GmSSL + 传统国密示例证书** 的 Electron 桌面工具，改造为基于 **Tongsuo（铜锁）+ tlcp-pqc 三套 PQC/混合证书** 的证书查看与验链工具，并 **精简 UI，只保留根证书与待验证证书两个输入区**。

### 1.2 明确要做的

| 项 | 说明 |
|----|------|
| 密码学引擎替换 | `gmssl.exe` → `openssl.exe`（Tongsuo 构建产物） |
| 运行时依赖替换 | `libcrypto-1_1.dll` / `libssl-1_1.dll` → `libcrypto-3-x64.dll` / `libssl-3-x64.dll` |
| Provider 支持 | 打包 `providers/*.dll` 与 `config/openssl-all-providers.cnf`（PQC 查看与验签必需） |
| 示例证书替换 | 删除/迁出 `ROOTCA.cer`、`demoCA/` 等旧素材，改用 `tlcp-pqc/certs/{1,2,3}/` |
| UI 精简 | **删除** CRL 区域、OCSP 区域；**保留** 根证书、要验证的证书 |
| 命令对齐 | 查看/验签逻辑对齐 `Windows查看与验链命令.md` 中已验证可用的命令 |

### 1.3 明确不做的（本阶段）

| 项 | 说明 |
|----|------|
| CRL 查看/验证 | UI 与逻辑一并移除 |
| OCSP 查询 | UI 与逻辑一并移除 |
| Electron 大版本升级 | 可单列后续任务，不阻塞本次功能改造 |
| preload + contextBridge 安全重构 | 建议第二阶段做，本次可先沿用 `nodeIntegration: true` |
| 重新打包 `证书验证.exe` | 若仅改 `resources/app/` 内明文文件，**可不重打 exe**（与现状一致） |

### 1.4 核心用户场景

用户通过 GUI 完成两类操作：

1. **查看证书**：对根证或待验证证执行 `openssl x509 -text`，能正确显示 ML-DSA / ML-KEM / 复合 SPKI / 混合扩展字段。
2. **验证证书**：对「根证 + 待验证证」执行 `openssl verify`，能完成 tlcp-pqc 三套证书链的验签（含 PQC 双重验签）。

---

## 2. 现状与目标对比

### 2.1 架构对比

```
【现状】
证书验证.exe (Electron 9)
  └── resources/app/
        ├── index.html  → execFile(gmssl.exe)
        ├── gmssl.exe + libcrypto-1_1 + libssl-1_1
        └── 示例：ROOTCA.cer / demoCA / XIDIANCA.cer

【目标】
证书验证.exe (Electron 9，可不变)
  └── resources/app/
        ├── index.html  → execFile(openssl.exe) + env 注入
        ├── tongsuo/    → openssl.exe + lib/*.dll
        ├── providers/  → pqmagic.dll, cert_verify.dll, ...
        ├── config/     → openssl-all-providers.cnf
        └── certs/      → 1/ 2/ 3/ （从 tlcp-pqc 复制）
```

### 2.2 功能映射

| 原功能（GmSSL） | 新功能（Tongsuo） | UI 是否保留 |
|----------------|-------------------|-------------|
| 根证书 — 查看 | `openssl x509 -in <root> -text -noout` | ✅ 保留 |
| CRL — 查看/验证 | — | ❌ 删除 |
| 待验证证 — 查看 | `openssl x509 -in <cert> -text -noout` | ✅ 保留 |
| 待验证证 — 验证 | `openssl verify -CAfile <root> [-untrusted <中间CA>] <cert>` | ✅ 保留（逻辑增强） |
| OCSP — 查询 | — | ❌ 删除 |

### 2.3 证书素材对比

| 原示例 | 新示例（tlcp-pqc） |
|--------|-------------------|
| `ROOTCA.cer`、`XIDIANCA.cer`、`demoCA/` | `certs/1/` 纯 PQC |
| `2.pem`、`baidu.pem` 等 | `certs/2/` 复合 SPKI |
| — | `certs/3/` 国密混合证 |

每套固定 4 张证：`root.crt`、`yunying.crt`（中间 CA）、`user_sig.crt`、`user_enc.crt`。

---

## 3. UI 改造设计

### 3.1 目标界面线框（对照截图精简后）

```
┌─────────────────────────────────────────┐
│  证书验证                                │
├─────────────────────────────────────────┤
│ 根证书 ─────────────────────────────    │
│  [路径]  [选择文件]  [查看证书]           │
├─────────────────────────────────────────┤
│ 要验证的证书 ─────────────────────────   │
│  [路径]  [选择文件]  [查看证书]           │
│                          [验证证书]      │
└─────────────────────────────────────────┘
```

### 3.2 相对原 `index.html` 的删减

| 删除内容 | 涉及 DOM / 函数 |
|----------|----------------|
| CRL 整段 UI | `inputFile2`、`inputFileAgent2`、`viewCrl()`、`verifyCrl()` |
| OCSP 整段 UI | `inputOcspUrl`、`queryOcsp()` |
| 验证证书中的 CRL 分支 | `verifyCert()` 内 `-crl_check -CRLfile` 逻辑 |

### 3.3 建议的 UI 增强（不改变「两项」原则）

在仍只有「根证书」「要验证的证书」两个选区的前提下，可增加 **非输入类** 辅助控件（可选，实施时二选一）：

| 方案 | 说明 | 推荐度 |
|------|------|--------|
| **A. 示例快捷填充** | 下拉「certs/1」「certs/2」「certs/3」，一键填入内置 `root.crt` + `user_sig.crt` 路径 | ⭐ 推荐（零学习成本） |
| **B. 仅手动选文件** | 用户自行浏览选择，无预设 | 可用 |
| **C. 增加中间 CA 选区** | 三输入框，最符合通用验链 | ❌ 与「只保留两项」冲突，不作为默认方案 |

**推荐方案 A**：界面上仍只有两个证书选区，额外增加一个「加载示例」下拉，不改变主流程字段数量。

### 3.4 窗口尺寸

原窗口 `510×500`；删除 CRL/OCSP 后内容变少，可缩小高度至约 `510×280`，或预留底部 **结果展示区**（见 §6.2）。

---

## 4. 命令与运行时环境设计

> 权威参考：`tlcp-pqc/certs/Windows查看与验链命令.md`

### 4.1 环境变量（`execFile` 的 `env` 参数注入）

Electron 子进程不会自动执行 `Set-TlcpEnv.ps1`，须在 `runOpenssl()` 中构造 `env`：

| 变量 | 值（相对 `resources/app/tongsuo/`） |
|------|-------------------------------------|
| `PATH` | `{app}/tongsuo/bin;{app}/tongsuo/lib;{系统PATH}` |
| `OPENSSL_CONF` | `{app}/config/openssl-all-providers.cnf` |
| `OPENSSL_MODULES` | `{app}/providers` |
| `PQMAGIC_STD_LIB` | `{app}/providers/pqmagic.dll` |
| `CERT_VERIFY_SO` | `{app}/providers/cert_verify.dll` |
| `CERT_VERIFY_VERIFY_INFO` | `1`（可选，验证时输出双重验签日志） |

`openssl-all-providers.cnf` 内 `module =` 路径需改为 **打包后的相对/绝对路径**（实施时写死为 `{app}/providers/*.dll` 的绝对路径生成逻辑，或发布前替换为相对安装目录的路径）。

### 4.2 查看证书命令

```text
openssl x509 -in <证书路径> -text -noout
```

- 调用方式：`execFile(opensslExe, ['x509','-in', certPath, '-text','-noout'], { cwd, env })`
- 根证、待验证证共用同一实现。

### 4.3 验证证书命令

tlcp-pqc 三套证均为 **三级链**：`root → yunying（中间 CA）→ 叶子`。

```text
openssl verify -CAfile <root.crt> -untrusted <yunying.crt> <待验证.crt>
```

| 待验证证 | 是否需要 `-untrusted yunying.crt` |
|----------|-----------------------------------|
| `yunying.crt` | 需要（中间 CA 由根签发） |
| `user_sig.crt` / `user_enc.crt` | 需要 |
| `root.crt`（自签） | 不需要，仅 `-CAfile root root` |

#### 关键设计：UI 只有两个选区，中间 CA 如何处理？

**推荐策略（自动推断，不增加 UI 字段）：**

1. 取待验证证所在目录 `dir`。
2. 若同目录存在 `yunying.crt`，则验证命令自动加 `-untrusted dir/yunying.crt`。
3. 若不存在，退化为 `openssl verify -CAfile <root> <cert>`（兼容用户自选的两级链场景）。
4. 若待验证证文件名即为 `root.crt` 且与根证选区相同，走自签验证。

该策略与 `tlcp-pqc/certs/{1,2,3}/` 目录布局完全吻合。

### 4.4 三套证书验签预期

| 套别 | 验证时额外输出 | 成功标志 |
|------|----------------|----------|
| certs/1 | 无（标准 ML-DSA 验签） | `xxx.crt: OK` |
| certs/2 | `[openssl-verify ML-DSA-44-SM2 复合证 双重验签]` | 双重 OK + `xxx.crt: OK` |
| certs/3 | `[openssl-verify 国密混合证 双重验签]` | SM2 + ML-DSA 均 OK |

### 4.5 函数重构命名（计划）

| 原函数 | 新函数 |
|--------|--------|
| `runGmssl(args)` | `runOpenssl(args, options?)` |
| `gmsslExe` | `opensslExe`（指向 `tongsuo/bin/openssl.exe`） |

---

## 5. 运行时资源打包方案

### 5.1 建议目录布局（`resources/app/` 下）

```text
resources/app/
├── main.js
├── index.html
├── package.json
├── ic.ico
├── tongsuo/
│   ├── bin/openssl.exe
│   └── lib/
│       ├── libcrypto-3-x64.dll
│       └── libssl-3-x64.dll
├── providers/
│   ├── pqmagic.dll
│   ├── libml_dsa_sm2_provider.dll
│   ├── cert_verify.dll
│   └── aigis_enc.dll
├── config/
│   └── openssl-all-providers.cnf   # module 路径指向 providers/
└── certs/
    ├── 1/  root.crt yunying.crt user_sig.crt user_enc.crt
    ├── 2/  ...
    └── 3/  ...
```

### 5.2 从 tlcp-pqc 复制的产物清单

| 源路径（tlcp-pqc） | 目标路径（app 内） |
|-------------------|-------------------|
| `bin/openssl.exe` | `tongsuo/bin/openssl.exe` |
| `lib/libcrypto-3-x64.dll` | `tongsuo/lib/` |
| `lib/libssl-3-x64.dll` | `tongsuo/lib/` |
| `providers/*.dll` | `providers/` |
| `config/openssl-all-providers.cnf` | `config/`（**需改写 module 路径**） |
| `certs/1`、`certs/2`、`certs/3` 下 `*.crt` | `certs/{1,2,3}/` |

**注意：** 必须使用 `PQMAGIC_MSVC_PORTABLE=ON` 构建的 provider（已在 tlcp-pqc 侧修复 AVX-512 崩溃问题），复制时取最新构建产物。

### 5.3 可删除的旧资源（改造后）

| 路径 | 说明 |
|------|------|
| `gmssl.exe`、`libcrypto-1_1.dll`、`libssl-1_1.dll` | GmSSL 运行时 |
| `GmSSL/` 整个目录 | SDK 残留 |
| `demoCA/`、`ROOTCA.cer`、`XIDIANCA.cer`、`2.pem` | 旧示例 |
| 根目录及 app 内冗余 `gmssl` 副本 | 见《项目结构梳理》§5 |

### 5.4 体积预估

| 组件 | 约大小 |
|------|--------|
| Tongsuo bin + lib | ~10 MB |
| 4 个 provider DLL | ~0.2 MB |
| 12 张示例 .crt | <1 MB |
| **新增合计** | ~11 MB |
| **可删 GmSSL 相关** | ~70+ MB |

净效果：发行包体积可能 **减小**。

---

## 6. 代码改造要点（实施阶段参考，本文不落地）

### 6.1 `index.html` 改造清单

- [ ] 删除 CRL、OCSP 相关 HTML 与脚本
- [ ] `runGmssl` → `runOpenssl`，注入 §4.1 环境变量
- [ ] `viewRootCert` / `viewCert` 改用 `openssl x509`
- [ ] `verifyCert` 改用 `openssl verify`，实现 §4.3 中间 CA 自动推断
- [ ] （可选）增加示例套别下拉 + 一键填充路径
- [ ] （可选）将 `alert()` 改为页面内 `<pre>` 结果区，避免 PQC 输出过长多次点击

### 6.2 `main.js` 改造清单

- [ ] 窗口高度调整（若 UI 变矮或增加结果区）
- [ ] （可选第二阶段）`contextIsolation` + `preload.js`

### 6.3 `openssl-all-providers.cnf` 路径处理

实施时二选一：

| 方案 | 做法 |
|------|------|
| **构建时生成** | 增加 `scripts/gen-openssl-conf.js`，根据 `__dirname` 写出绝对路径 |
| **发布脚本替换** | `layout-app.bat` 复制 cnf 时替换 `module =` 为目标路径 |

推荐 **构建时生成**，避免开发机与安装路径不一致。

### 6.4 `package.json`

- [ ] 产品描述改为「Tongsuo PQC 证书验证」
- [ ] 清理未使用的 `jquery`、`require` 依赖（可选）

---

## 7. 分阶段实施计划

### 阶段 0：准备（0.5 天）

- [ ] 确认 tlcp-pqc 侧 `verify-chain-all.ps1` 三套全部 OK
- [ ] 编写 `scrpts/layout-app-resources.bat`：从 tlcp-pqc 复制运行时到 `resources/app/`
- [ ] 生成适配 app 目录的 `openssl-all-providers.cnf`

### 阶段 1：运行时替换（1 天）

- [ ] 按 §5.1 布局复制 Tongsuo + providers + certs
- [ ] 删除 GmSSL 旧文件
- [ ] 命令行抽离测试：在 `resources/app/` 目录用 Node 脚本模拟 `execFile` 环境，验证查看/验签

### 阶段 2：UI 精简与逻辑改造（1 天）

- [ ] 按 §3 删减 CRL/OCSP UI
- [ ] 实现 `runOpenssl` + 查看/验证四个按钮
- [ ] 实现中间 CA 自动推断（§4.3）
- [ ] （可选）示例套别快捷填充

### 阶段 3：联调与验收（0.5～1 天）

- [ ] 执行 §8 验收用例
- [ ] 更新 `项目结构梳理.md` 为 Tongsuo 版本
- [ ] 在 `certs/Windows查看与验链命令.md` 增加「GUI 工具」一节（可选）

### 阶段 4：后续增强（非本次必须）

- [ ] Electron 升级 + preload 安全改造
- [ ] 结果面板 UI 美化
- [ ] 打包脚本自动化（electron-packager）

**预估总工期：2.5～3.5 天**

---

## 8. 验收标准

### 8.1 环境

- [ ] 双击 `证书验证.exe` 或 `npm start` 均可启动
- [ ] 不依赖用户本机安装 Tongsuo / 不依赖 `Set-TlcpEnv.ps1`（环境在 app 内自包含）

### 8.2 查看证书

| 操作 | 输入 | 预期 |
|------|------|------|
| 查看根证 | `certs/2/root.crt` | 显示 `ML-DSA-44-SM2`、`ML-DSA-44-SM2-with-SM3` |
| 查看叶子证 | `certs/2/user_enc.crt` | 显示 `ML-KEM-512-SM2` 公钥 |
| 查看混合证 | `certs/3/user_sig.crt` | 显示 `sm2` + `PQC-Subject-Public-Key` 扩展 |

### 8.3 验证证书

| 操作 | 根证 | 待验证证 | 预期 |
|------|------|----------|------|
| certs/1 叶子 | `certs/1/root.crt` | `certs/1/user_sig.crt` | `OK` |
| certs/2 叶子 | `certs/2/root.crt` | `certs/2/user_enc.crt` | 双重验签 OK + `OK` |
| certs/3 叶子 | `certs/3/root.crt` | `certs/3/user_sig.crt` | 混合双重验签 OK + `OK` |
| 中间 CA | `certs/*/root.crt` | `certs/*/yunying.crt` | `OK` |
| 根自签 | `certs/1/root.crt` | `certs/1/root.crt` | `OK` |

### 8.4 UI

- [ ] 界面仅含「根证书」「要验证的证书」两个区域（+ 可选示例下拉）
- [ ] 无 CRL、OCSP 相关按钮与输入框

### 8.5 回归

- [ ] 进程不崩溃（`0xC000001D`）
- [ ] 含空格的路径可正常选择验证

---

## 9. 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| PQMagic 使用 AVX-512 编译 | 部分 CPU 验签崩溃 | 仅打包 `PQMAGIC_MSVC_PORTABLE=ON` 构建产物 |
| `openssl-all-providers.cnf` 路径错误 | provider 加载失败，公钥显示不全 | 发布时生成绝对路径 cnf |
| 用户只选根+叶，未放同目录 `yunying.crt` | 三级链验证失败 | 文档说明 + 示例快捷填充 + 同目录自动查找 |
| PQC 输出很长 | `alert()` 体验差 | 第二阶段改结果面板 |
| Electron 9 安全警告 | 低风险桌面工具 | 已知接受，后续升级 |

---

## 10. 与仓库其他目录的关系

```text
20240429certificate-verification/
├── tlcp-pqc/                          # 构建源：Tongsuo + providers + certs
│   └── certs/Windows查看与验链命令.md    # 命令权威参考
├── certificate-verification-win32-x64/  # 本改造目标：Electron GUI
│   ├── 项目结构梳理.md                   # 改造后需同步更新
│   └── 改造计划-Tongsuo-PQC.md         # 本文档
└── BUILD-WINDOWS.md                     # tlcp-pqc 构建说明（复制产物时参照）
```

**职责划分：**

- `tlcp-pqc`：负责 **构建与命令验证**（CLI 已通）
- `certificate-verification-win32-x64`：负责 **GUI 封装与资源打包**（本次改造）

---

## 11. 确认清单（开工前）

- [x] 理解：GmSSL → Tongsuo 替换
- [x] 理解：示例证书 → `tlcp-pqc/certs/{1,2,3}`
- [x] 理解：UI 只保留根证书 + 要验证的证书
- [x] 理解：CRL / OCSP 整段移除
- [x] 理解：验链命令需 `-untrusted yunying.crt`（通过同目录自动推断）
- [ ] 确认：是否增加「示例套别」下拉（建议增加，不增加主输入项）
- [ ] 确认：验证输出用 `alert` 还是页面结果区（建议本次至少改为单块 `<pre>`）

---

*本文档为 Plan，实施时请按阶段 0→3 执行；代码变更以本文档 + `Windows查看与验链命令.md` 为准。*
