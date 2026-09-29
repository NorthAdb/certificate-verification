# 抗量子数字证书验证

> **更新日期：** 2026-09-17

本仓库提供 **PQC / 国密混合证书** 的查看、验链与 CSR 生成。最终用户只需绿色 GUI 包，开发者才需要密码库源码。

## 仓库组成

仓库分两大块，职责互不重叠：

```
20240429certificate-verification/
├── certificate-verification-win32-x64/   # 用户端：Electron 绿色发行包
└── tlcp-pqc/                             # 开发端：Tongsuo + Provider 密码库
```

| 目录 | 给谁用 | 做什么 |
|------|--------|--------|
| `certificate-verification-win32-x64/` | 最终用户 | 双击 `证书验证.exe`，图形界面查看证书、验链、生成 CSR |
| `tlcp-pqc/` | 开发 / 维护者 | 编译 Tongsuo 与 Provider，用命令行验证密码学能力，再同步进 GUI |

GUI 已自包含运行时，**不依赖** `tlcp-pqc`，也不需要安装 Node.js 或 OpenSSL。

---

## 快速上手：用户端 GUI

### 启动

1. 将整个 `certificate-verification-win32-x64` 文件夹拷到任意位置（桌面、U 盘均可）。
2. 双击 **`证书验证.exe`**。
3. 右上角显示「运行时就绪」即可开始。

要求：Windows 10 / 11（64 位）。请保持文件夹内部结构完整，不要单独挪走 `证书验证.exe` 或删除 `resources/`。

左侧两个功能页：

- **证书验证** — 查看证书、验证证书链
- **CSR 生成与验证** — 生成 PQC / 复合 CSR，并做自签验签

### 证书验证

界面按顺序填三项，再点「验证证书」：

| 步骤 | 填什么 | 说明 |
|------|--------|------|
| 1 信任锚点 | 通常选根 CA `root.crt` | 对应 `openssl verify -CAfile` |
| 2 中间证书 | 三段链时选 `yunying.crt` | 可选；留空则不传 `-untrusted` |
| 3 待验证证书 | 叶子证，如 `user_sig.crt` | 要查看或验证的目标 |

常用组合：

- **两段链**（根直接签叶子）：填 1、3，第 2 步留空。
- **三段链**（根 → 中间 → 叶子）：1、2、3 都填，且必须来自**同一套证书**。
- **只信任中间 CA**：第 1 步选中间证，第 2 步留空，第 3 步选叶子证（程序自动加 `-partial_chain`）。

每一步都可以先点「查看证书」，底部输出区会显示 `openssl x509 -text` 的完整解析。

### 用内置示例走一遍

示例证书在 `resources/app/certs/`，按类型分子目录。建议从纯 PQC 三段链开始：

1. 信任锚点 → `certs/Pure PQC Certificate/mlkemdsa/root.crt`
2. 中间证书 → 同目录 `yunying.crt`
3. 待验证证书 → 同目录 `user_sig.crt`（或 `user_enc.crt`）
4. 点击「验证证书」

成功时输出末尾为：

```
...\user_sig.crt: OK
```

其它可试用的套件：

| 目录 | 类型 |
|------|------|
| `Pure PQC Certificate/mlkemdsa` | 纯 ML-DSA / ML-KEM |
| `Pure PQC Certificate/aigis` | 纯 Aigis |
| `Hybrid Concatenated Certificate/mlkemdsa` | ML-DSA + SM2 复合 SPKI |
| `Hybrid Concatenated Certificate/aigissm2` | Aigis ‖ SM2 串联 |
| `Hybrid Using Extensions Certificate/mlkemdsa` | SM2 主体 + ML-DSA 扩展 |
| `Hybrid Using Extensions Certificate/sm2extaigis` | SM2 主体 + Aigis 扩展 |

**不要跨目录混选。** 例如根证来自 Pure PQC、叶子证来自 Hybrid Concatenated，必然失败（`unable to get local issuer certificate`）。

自备证书时，格式支持 `.crt` / `.cer` / `.pem`，必须选具体文件，不能选文件夹。

### CSR 生成与验证

切到左侧「CSR 生成与验证」：

1. 选算法：`ML-DSA-44-SPKI`（纯 PQC）或 `ML-DSA-44-SM2`（PQC + SM2 复合）。
2. 按需改主题 DN（须以 `/` 开头）。
3. 「指定保存位置」选一个 `.csr` 路径。
4. 点「生成 CSR」。程序会在同目录自动写出私钥，并立刻做自签验签。

生成结果：

- 纯 PQC：`<name>.csr` + 同名 `.key`
- 复合：`<name>.csr` + `<name>.mldsa.key` + `<name>.sm2.key`

已有 CSR 时，用第 2 步「选择 CSR」→「查看 CSR」/「验签 CSR」即可。

### 看懂输出

查看证书时重点看：`Subject` / `Issuer`、`Validity`、`Subject Public Key Info`（公钥类型）、扩展项。

验链失败时，优先看 `error` 行，而不是后面一串 OpenSSL 连带提示。常见情况：

| 现象 | 原因 | 处理 |
|------|------|------|
| `unable to get local issuer certificate` | 三段链没填中间证，或根/叶子不是同一套 PKI | 补选 `yunying.crt`，或改选同一目录的证 |
| 提示「必须是证书文件，不能是目录」 | 选了文件夹 | 选具体 `.crt` 文件 |
| 双击无反应 / 退出码 `0xC0000135` | `tongsuo/bin` 下 DLL 缺失 | 重新拷贝完整文件夹 |
| 右上角不是「运行时就绪」 | 运行时不完整 | 不要拆散发行包 |

更细的错误解读见 `certificate-verification-win32-x64/README_项目结构梳理.md`。

---

## tlcp-pqc 密码库

面向开发者。GUI 底层调用的就是这里编出来的 Tongsuo `openssl.exe` 和四个 Provider DLL。

职责可以概括成三句话：

1. 在 Windows 上编译铜锁（Tongsuo）与 PQC / 混合证书 Provider。
2. 用 CLI 证明查看证书、验链、CSR 双重验签是正确的。
3. 通过 layout 脚本把产物复制进 GUI 发行包。

```
改源码 / 改证书
    → tlcp-pqc 编译（build-tongsuo.bat + build-providers.bat）
    → CLI 验收（Set-TlcpEnv + verify-chain-all.ps1）
    → layout-app-resources.bat 同步到 GUI
    → 双击 证书验证.exe
```

普通用户可以忽略本目录。需要编译或改算法时，从这里读起：

- [`tlcp-pqc/doc/usage-guide.md`](tlcp-pqc/doc/usage-guide.md) — 环境导入、编译、CSR、验链
- [`certificate-verification-win32-x64/doc/tlcp-pqc与GUI工作流.md`](certificate-verification-win32-x64/doc/tlcp-pqc与GUI工作流.md) — 两目录如何同步
- [`doc/architecture/repo-architecture.html`](doc/architecture/repo-architecture.html) — 架构图

---

## 相关文档

| 文档 | 内容 |
|------|------|
| [`certificate-verification-win32-x64/README_项目结构梳理.md`](certificate-verification-win32-x64/README_项目结构梳理.md) | GUI 使用细节、目录说明、维护清单 |
| [`certificate-verification-win32-x64/doc/README-独立运行.md`](certificate-verification-win32-x64/doc/README-独立运行.md) | 发行包极简说明 |
| [`tlcp-pqc/certs/Windows查看与验链命令.md`](tlcp-pqc/certs/Windows查看与验链命令.md) | CLI 验链命令 |
