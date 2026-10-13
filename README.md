# 抗量子数字证书验证

> **更新日期：** 2026-10-13

本仓库提供 **PQC / 国密混合证书** 的查看、验链、吊销检查与 CSR 生成。最终用户只需绿色 GUI 包，开发者才需要密码库源码。

## 仓库组成

仓库分两大块，职责互不重叠：

```
20240429certificate-verification/
├── certificate-verification-win32-x64/   # 用户端：Electron 绿色发行包
└── tlcp-pqc/                             # 开发端：Tongsuo + Provider 密码库（git submodule）
```

| 目录 | 给谁用 | 做什么 |
|------|--------|--------|
| `certificate-verification-win32-x64/` | 最终用户 | 双击 `证书验证.exe`，图形界面查看证书、验链、吊销检查、生成 / 验签 CSR |
| `tlcp-pqc/` | 开发 / 维护者 | 编译 Tongsuo 与 Provider，用命令行验证密码学能力，再同步进 GUI |

GUI 已自包含运行时，**不依赖** `tlcp-pqc`，也不需要安装 Node.js 或 OpenSSL。

可运行绿色包见 [GitHub Releases](https://github.com/NorthAdb/certificate-verification/releases)：下载 `certificate-verification-win32-x64.zip`，解压后双击 `证书验证.exe`。主程序 exe 超过 GitHub 单文件 100MB 限制，**不进 git**，只通过 Release 分发。

---

## 快速上手：用户端 GUI

### 启动

1. 从 Release 解压，或将整个 `certificate-verification-win32-x64` 文件夹拷到任意位置（桌面、U 盘均可）。
2. 双击 **`证书验证.exe`**。
3. 右上角显示「运行时就绪」即可开始。

要求：Windows 10 / 11（64 位）。请保持文件夹内部结构完整，不要单独挪走 `证书验证.exe` 或删除 `resources/`。

左侧两个功能页：

- **证书验证** — 查看证书、验证证书链、可选吊销检查
- **CSR 生成与验证** — 生成 ML-DSA / Aigis 纯 PQC 或复合 CSR，并做自签验签

### 证书验证

界面按顺序填写，再点「验证证书」：

| 步骤 | 填什么 | 说明 |
|------|--------|------|
| 1 信任锚点 | 通常选根 CA `root.crt` | 对应 `openssl verify -CAfile` |
| 2 中间证书 | 三段链时选运营 CA，如 `ca.crt` | 可选；留空则不传 `-untrusted` |
| 3 待验证证书 | 叶子证，如 `student02_sig.crt` | 要查看或验证的目标 |
| 4 吊销列表 | 运营 CA 的 `ca.crl`（可选） | 选后追加 `-CRLfile` 与 `-crl_check`，只查第 3 步那张证 |

常用组合：

- **两段链**（根直接签叶子）：填 1、3，第 2 步留空。
- **三段链**（根 → 中间 → 叶子）：1、2、3 都填，且必须来自**同一套证书**。
- **只信任中间 CA**：第 1 步选中间证，第 2 步留空，第 3 步选叶子证（程序自动加 `-partial_chain`）。
- **顺带查吊销**：在三段链基础上选同套 `ca.crl`；叶子证请用其颁发者签发的列表。

每一步都可以先点「查看证书」或「查看吊销列表」，底部输出区会显示完整解析。

### 用内置示例走一遍

示例证书在 `resources/app/certs/`。推荐用 BESTI 命名套件（`0x-…` 目录）做三段链：

1. 信任锚点 → `certs/Pure PQC Certificate/02-int-pqc-pure/root.crt`
2. 中间证书 → 同目录 `ca.crt`
3. 待验证证书 → 同目录 `student02_sig.crt`（有效叶子；`student01_*` 已吊销）
4. （可选）吊销列表 → 同目录 `ca.crl`
5. 点击「验证证书」

成功时输出末尾为：

```
...\student02_sig.crt: OK
```

其它可试用的套件：

| 目录 | 类型 |
|------|------|
| `Traditional SM2 Certificate/01-sm2` | 传统 SM2 |
| `Pure PQC Certificate/02-int-pqc-pure` | 纯 ML-DSA / ML-KEM |
| `Pure PQC Certificate/03a-sm-pqc-pure-aigis` | 纯 Aigis-SIG1 / Enc-1 |
| `Hybrid Concatenated Certificate/04-int-pqc-serial` | ML-DSA ‖ SM2 串联 |
| `Hybrid Using Extensions Certificate/05-int-pqc-extension` | SM2 外层 + ML-DSA 扩展 |
| `Hybrid Concatenated Certificate/07a-sm-pqc-serial-aigis` | Aigis ‖ SM2 串联 |
| `Hybrid Using Extensions Certificate/08a-sm-pqc-extension-aigis` | SM2 外层 + Aigis 扩展 |

同一大类下还有旧目录名（如 `mlkemdsa`、`aigis`、`aigissm2`、`sm2extaigis`），用法相同。**不要跨目录混选。** 例如根证来自 Pure PQC、叶子证来自 Hybrid Concatenated，必然失败（`unable to get local issuer certificate`）。

自备证书时，格式支持 `.crt` / `.cer` / `.pem`，必须选具体文件，不能选文件夹。

### CSR 生成与验证

切到左侧「CSR 生成与验证」：

1. 选算法（当前均已接入）：

   | 算法 | 说明 | 同目录私钥 |
   |------|------|------------|
   | `ML-DSA-44-SPKI` | 纯国际 PQC | `<name>.key` |
   | `ML-DSA-44-SM2` | ML-DSA + SM2 复合 | `<name>.mldsa.key`、`<name>.sm2.key` |
   | `Aigis-SIG1-SPKI` | 纯国产 Aigis | `<name>.key` |
   | `Aigis-SIG1-SM2` | Aigis + SM2 复合 | `<name>.aigis.key`、`<name>.sm2.key` |

2. 按需改主题 DN（须以 `/` 开头）。
3. 「指定保存位置」选一个 `.csr` 路径。
4. 点「生成 CSR」。程序会在同目录自动写出私钥，并立刻做自签验签。

串联证书与扩展证书共用同一种复合 CSR（公钥 / 签名都是「PQC ‖ SM2」拼法）；扩展形态是 CA 签发时再包装进证书扩展，申请侧不必单独选「扩展 CSR」。

已有 CSR 时，用第 2 步「选择 CSR」→「查看 CSR」/「验签 CSR」即可。样例 CSR 在各 BESTI 目录下（如 `03a` / `07a` / `08a` 的 `ca.csr`、`student*_sig.csr`）。

### 看懂输出

查看证书时重点看：`Subject` / `Issuer`、`Validity`、`Subject Public Key Info`（公钥类型）、扩展项。

验链失败时，优先看 `error` 行，而不是后面一串 OpenSSL 连带提示。常见情况：

| 现象 | 原因 | 处理 |
|------|------|------|
| `unable to get local issuer certificate` | 三段链没填中间证，或根/叶子不是同一套 PKI | 补选运营 CA，或改选同一目录的证 |
| `unable to get certificate CRL` | 用叶子 CRL 去验根 / 中间 CA | 叶子证请选其颁发者签发的 `ca.crl` |
| 提示「必须是证书文件，不能是目录」 | 选了文件夹 | 选具体 `.crt` 文件 |
| 双击无反应 / 退出码 `0xC0000135` | `tongsuo/bin` 下 DLL 缺失 | 重新拷贝完整文件夹或重下 Release |
| 右上角不是「运行时就绪」 | 运行时不完整 | 不要拆散发行包 |

更细的错误解读见 `certificate-verification-win32-x64/README_项目结构梳理.md`。

---

## tlcp-pqc 密码库

面向开发者。GUI 底层调用的就是这里编出来的 Tongsuo `openssl.exe` 和 Provider DLL（含 `pqmagic`、`aigis`、`cert_verify` 等）。本目录为 git submodule：[`NorthAdb/tlcp-pqc`](https://github.com/NorthAdb/tlcp-pqc)。

职责可以概括成三句话：

1. 在 Windows 上编译铜锁（Tongsuo）与 PQC / 混合证书 Provider。
2. 用 CLI 证明查看证书、验链、CSR 双重验签是正确的。
3. 通过 layout 脚本把产物复制进 GUI 发行包。

```
改源码 / 改证书
    → tlcp-pqc 编译（build-tongsuo.bat + build-providers.bat / rebuild-aigis…）
    → CLI 验收（Set-TlcpEnv + verify-chain-all.ps1）
    → layout-app-resources.bat 同步到 GUI
    → 双击 证书验证.exe
```

普通用户可以忽略本目录。需要编译或改算法时，从这里读起：

- [`tlcp-pqc/doc/usage-guide.md`](tlcp-pqc/doc/usage-guide.md) — 环境导入、编译、CSR、验链
- [`certificate-verification-win32-x64/doc/tlcp-pqc与GUI工作流.md`](certificate-verification-win32-x64/doc/tlcp-pqc与GUI工作流.md) — 两目录如何同步

---

## 发布说明（维护者）

1. 先推 submodule `tlcp-pqc`，再推本仓库 `master`。
2. 用当前 `certificate-verification-win32-x64/` 打 zip（建议排除 `*.key`），上传到 GitHub Release；exe 只走 Release，不提交进 git。

```powershell
tar -a -cf certificate-verification-win32-x64.zip --exclude="*.key" certificate-verification-win32-x64
gh release create vX.Y.Z certificate-verification-win32-x64.zip --title "vX.Y.Z" --notes "..."
```

---

## 相关文档

| 文档 | 内容 |
|------|------|
| [`certificate-verification-win32-x64/README_项目结构梳理.md`](certificate-verification-win32-x64/README_项目结构梳理.md) | GUI 使用细节、目录说明、维护清单 |
| [`certificate-verification-win32-x64/doc/README-独立运行.md`](certificate-verification-win32-x64/doc/README-独立运行.md) | 发行包极简说明 |
| [`certificate-verification-win32-x64/resources/app/certs/BESTI-PQC-certificates文件说明.md`](certificate-verification-win32-x64/resources/app/certs/BESTI-PQC-certificates文件说明.md) | BESTI 样证目录与算法对照 |
| [`tlcp-pqc/certs/Windows查看与验链命令.md`](tlcp-pqc/certs/Windows查看与验链命令.md) | CLI 验链命令 |
| [Releases](https://github.com/NorthAdb/certificate-verification/releases) | 绿色包下载 |
