# tlcp-pqc 与 certificate-verification-win32-x64 工作流

> **文档性质：** 跨目录开发与发布流程说明  
> **更新日期：** 2026-08-21  
> **命令环境：** 以下可复制块均为 **PowerShell**（`.bat` 需加 `.\` 前缀）  
> **适用仓库：** `20240429certificate-verification/`

---

## 1. 两个文件夹各自做什么

| 目录 | 角色 | 谁需要 | 能否独立运行 |
|------|------|--------|--------------|
| **`tlcp-pqc/`** | **密码学构建与 CLI 验证平台** | 开发者、维护者 | 是（命令行 + PowerShell） |
| **`certificate-verification-win32-x64/`** | **Electron GUI 绿色发行包** | 最终用户 | 是（双击 `证书验证.exe`） |

### 1.1 `tlcp-pqc/` — 源码与构建产物

```
tlcp-pqc/
├── Tongsuo/                          # 铜锁 OpenSSL 源码
├── pqmagic/                          # PQC 算法库
├── pqmagic-algorithms-provider/      # pqmagic provider
├── x509-hybrid-spki-provider/        # ML-DSA+SM2 复合 SPKI provider
├── x509-hybrid-verify-provider/      # 混合证验签 provider
├── aigis-provider/               # Aigis X.509 provider（SIG1/ENC1）
├── x509-hybrid-spki-provider/
├── x509-hybrid-verify-provider/
├── certs/                            # 示例证（mlkemdsa / aigis 等）
├── build-*.bat / rebuild-*.bat       # 编译 Tongsuo、providers
├── layout-tlcp-pqc.bat               # 汇总构建产物到 tlcp-pqc/bin、providers、config
├── bin/                              # openssl.exe + libcrypto/libssl DLL（与 GUI tongsuo/bin 同布局）
├── lib/                              # PQMagic 静态库 libpqmagic_std.lib（链接用）
├── providers/                        # 四个 provider DLL
├── config/openssl-all-providers.cnf  # provider 配置（CLI 用）
└── certs/Windows查看与验链命令.md     # ★ CLI 验链权威参考
```

**职责：** 在 Windows 上编译 Tongsuo + Provider，用命令行/PowerShell **证明**「查看证书、验链、双重验签」逻辑正确。

### 1.2 `certificate-verification-win32-x64/` — GUI 封装

```
certificate-verification-win32-x64/
├── 证书验证.exe                        # Electron 壳（一般不需重打）
├── README_项目结构梳理.md              # 用户 + 维护者主文档
├── doc/                                # 其它文档（含本文档）
├── scrpts/
│   └── layout-app-resources.bat        # ★ 从 tlcp-pqc 同步到 app
└── resources/app/
    ├── index.html                      # UI + execFile(openssl) + 环境变量
    ├── main.js
    ├── tongsuo/bin/                    # openssl.exe + DLL（从 tlcp-pqc 复制）
    ├── providers/                      # 四个 provider DLL（从 tlcp-pqc 复制）
    ├── config/                         # cnf（启动时 index.html 按路径重写）
    ├── certs/                          # 示例证（按类型命名的子目录）
    └── scripts/test-openssl-layout.js  # app 内验链自测
```

**职责：** 把 `tlcp-pqc` 已验证的运行时 **打包进** Electron，用图形界面调用同一套 `openssl x509` / `openssl verify`。

---

## 2. 总体关系（一张图）

```
┌─────────────────────────────────────────────────────────────────┐
│                        tlcp-pqc（开发/验证层）                    │
│  源码编译 → layout-tlcp-pqc.bat → bin/ providers/ certs/         │
│  CLI 验证：Set-TlcpEnv + verify-chain.ps1 / openssl verify       │
└────────────────────────────┬────────────────────────────────────┘
                             │ layout-app-resources.bat（复制运行时）
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              certificate-verification-win32-x64（交付层）         │
│  证书验证.exe → index.html → execFile(tongsuo/bin/openssl.exe)    │
│  注入 OPENSSL_CONF / OPENSSL_MODULES / CERT_VERIFY_SO 等          │
└────────────────────────────┬────────────────────────────────────┘
                             │ 拷贝整个文件夹
                             ▼
                      最终用户（U 盘 / 其它电脑）
                      无需 tlcp-pqc、无需 Node.js
```

**原则：**

1. **先在 `tlcp-pqc` 用 CLI 跑通**，再同步到 GUI。  
2. **GUI 不重新编译** Tongsuo/Provider，只 **复制产物 + 调命令**。  
3. **改 `index.html` 逻辑** 时，命令应对齐 `certs/Windows查看与验链命令.md`。

---

## 3. 产物同步路径（构建 → CLI → GUI）

### 3.0 `layout-tlcp-pqc.bat` 复制映射（Windows）

> **Windows 上 `nmake install_sw` 把运行时 DLL 装在 `tongsuo-install/bin/`**（与 `openssl.exe` 同目录），不是 `tongsuo-install/lib/`（那里主要是 `.lib` 与 engines）。layout 按 **方案 A**：三个运行时文件都汇总到 **`tlcp-pqc/bin/`**。

| 源 | 目标（tlcp-pqc） |
|----|------------------|
| `tongsuo-install/bin/openssl.exe` | `bin/openssl.exe` |
| `tongsuo-install/bin/libcrypto-3-x64.dll` | `bin/libcrypto-3-x64.dll` |
| `tongsuo-install/bin/libssl-3-x64.dll` | `bin/libssl-3-x64.dll` |
| `pqmagic-install/lib/libpqmagic_std.lib` | `lib/libpqmagic_std.lib` |
| `pqmagic-algorithms-provider/build/Release/pqmagic.dll` | `providers/pqmagic.dll` |
| `x509-hybrid-spki-provider/build/Release/libml_dsa_sm2_provider.dll` | `providers/libml_dsa_sm2_provider.dll` |
| `x509-hybrid-verify-provider/build/Release/cert_verify.dll` | `providers/cert_verify.dll` |
| `aigis-provider/build/Release/aigis.dll` | `providers/aigis.dll` |
| `x509-hybrid-verify-provider/build/Release/verify_certs.exe`（若存在） | `bin/verify_certs.exe` |
| （若不存在）脚本内生成 | `config/openssl-all-providers.cnf` |

`Set-TlcpEnv.ps1` 只需把 `bin/`、`lib/` 加入 PATH；**不再依赖** `tongsuo-install/bin` 兜底加载 DLL。

### 3.1 产物同步路径（tlcp-pqc → GUI）

| 源（tlcp-pqc） | 目标（resources/app） | 同步方式 |
|----------------|----------------------|----------|
| `bin/openssl.exe` | `tongsuo/bin/openssl.exe` | `layout-app-resources.bat` |
| `bin/libcrypto-3-x64.dll` | `tongsuo/bin/` | 同上 |
| `bin/libssl-3-x64.dll` | `tongsuo/bin/` | 同上 |
| `providers/*.dll` | `providers/` | 同上（含 **`aigis.dll`**） |
| `certs/.../mlkemdsa|aigis|aigissm2|sm2extaigis/*.crt` | `certs/...` | 同上 |
| — | `config/openssl-all-providers.cnf` | **app 启动时** `index.html` 按 `__dirname` 自动生成 |

**两层 layout：**

| 脚本 | 作用范围 |
|------|----------|
| `tlcp-pqc/layout-tlcp-pqc.bat` | 构建产物 → `tlcp-pqc/bin`、`providers`、`config` |
| `certificate-verification-win32-x64/scrpts/layout-app-resources.bat` | `tlcp-pqc` → `resources/app/` |

---

## 3.2 tlcp-pqc 编译脚本详解（对应工作流 ②）

> 所有脚本均在 **`tlcp-pqc/` 根目录** 下执行（路径写死为 `D:\20240429certificate-verification\tlcp-pqc`，换机器需改脚本内路径）。  
> **前置环境：** Visual Studio 2022 BuildTools（`vcvars64.bat`）、CMake、Strawberry Perl（编 Tongsuo 需要）。

### 3.2.1 脚本总览（共 7 个 `.bat`）

| 脚本 | 类型 | 编译什么 | 是否含 `layout-tlcp-pqc.bat` |
|------|------|----------|-------------------------------|
| **`build-tongsuo.bat`** | 全量 | Tongsuo（Configure + nmake + install） | ❌ |
| **`build-tongsuo-resume.bat`** | 增量 | Tongsuo（跳过 Configure，只 nmake + install） | ❌ |
| **`build-providers.bat`** | 全量 | PQMagic + 4 个 provider（见下表 5 步） | ✅ 末尾自动调用 |
| **`build-providers-resume.bat`** | 增量 | 从 spki / cert_verify / aigis 续编（跳过 PQMagic 全量） | ✅ 末尾自动调用 |
| **`rebuild-pqmagic-portable.bat`** | 专项 | 重配 PQMagic（可移植）+ 4 个 provider 全量重编 | ✅ |
| **`rebuild-cert-verify.bat`** | 专项 | 仅 `cert_verify.dll` | ❌（仅 copy 到 `providers/`） |
| **`rebuild-aigis-provider.bat`** | 专项 | PQMagic + `pqmagic.dll` + `aigis_enc.dll` | ✅ |

另有 **`layout-tlcp-pqc.bat`**：不编译，把 `tongsuo-install/bin/`、各 provider 的 `build/Release/` **复制**到 `tlcp-pqc/bin`、`providers/`、`config/`（详见 §3.0；若已跑过 `build-providers.bat` 则不必单独再跑）。

---

### 3.2.2 全量编译：最少跑几个脚本？

**从零构建完整 CLI 运行时，只需 2 个脚本（按顺序）。** 在 PowerShell 中执行 `.bat` 必须加 **`.\` 前缀**（见 §3.3）。

```powershell
Set-Location D:\20240429certificate-verification\tlcp-pqc

# ① 编译 Tongsuo → 输出到 tongsuo-install/
.\build-tongsuo.bat
if (-not $?) { exit 1 }

# ② 编译 PQMagic + 4 个 provider → 末尾自动 layout-tlcp-pqc.bat
.\build-providers.bat
if (-not $?) { exit 1 }
```

| 顺序 | 脚本 | 内部做什么 | 主要产物 |
|------|------|------------|----------|
| 1 | `build-tongsuo.bat` | `perl Configure` → `nmake build_libs build_apps` → `nmake install_sw` | `tongsuo-install/bin/openssl.exe`、`libcrypto-3-x64.dll`、`libssl-3-x64.dll` |
| 2 | `build-providers.bat` | 见下节 **[1/5]～[5/5]**，最后 `layout-tlcp-pqc.bat` | `bin/openssl.exe` + 两个 DLL、`providers/*.dll`、`config/openssl-all-providers.cnf` |

> **说明：** 原工作流写「② 编译 → ③ layout」；若使用 **`build-providers.bat`**，③ 已包含在②末尾，**无需再单独跑** `layout-tlcp-pqc.bat`。仅当用了 `rebuild-cert-verify.bat` 等不含 layout 的脚本时，才需手动补跑 `layout-tlcp-pqc.bat`。

---

### 3.2.3 `build-providers.bat` 内部 5 步

一个脚本串行完成 **5 个子项目**编译（每步失败即退出）：

| 步骤 | 子项目 | 源码目录 | 产出（Release） |
|------|--------|----------|-----------------|
| **[1/5]** | PQMagic 静态库 | `pqmagic/` | `pqmagic-install/lib/libpqmagic_std.lib` |
| **[2/5]** | pqmagic provider | `pqmagic-algorithms-provider/` | `build/Release/pqmagic.dll` |
| **[3/5]** | ML-DSA+SM2 复合 SPKI | `x509-hybrid-spki-provider/` | `build/Release/libml_dsa_sm2_provider.dll` |
| **[4/5]** | 混合证验签 | `x509-hybrid-verify-provider/` | `build/Release/cert_verify.dll` |
| **[5/5]** | NTLS Aigis 加密 | `ntls-aigis-provider/` | `build/Release/aigis_enc.dll` |
| 末尾 | layout | — | 复制到 `tlcp-pqc/bin/`（openssl + DLL）、`providers/`、`config/` |

**PQMagic 关键选项：** `build-providers.bat` 默认 `-DPQMAGIC_MSVC_PORTABLE=ON`（避免无 AVX-512 的 CPU 上非法指令 `0xC000001D`）。

---

### 3.2.4 增量 / 专项脚本：什么时候用？

不必每次全量。按改动范围选 **1 个**脚本即可：

| 你改了什么 | 推荐脚本 | 大约耗时 |
|------------|----------|----------|
| 只改了 `Tongsuo/` 且已 Configure 过 | `build-tongsuo-resume.bat` | 较短 |
| 只改了 `x509-hybrid-verify-provider/` | `rebuild-cert-verify.bat` | 最短（仅 cert_verify） |
| PQMagic 要改可移植 / 算法选项 | `rebuild-pqmagic-portable.bat` | 中等（会重编 4 个 provider） |
| 只动 Aigis / pqmagic provider | `rebuild-aigis-provider.bat` | 中等 |
| provider 编到一半失败，从 spki 续编 | `build-providers-resume.bat` | 较短 |
| 不确定 / 换机器首次构建 | `build-tongsuo.bat` + `build-providers.bat` | 最长 |

**注意 `rebuild-cert-verify.bat`：** 只编译并 `copy` 到 `providers/cert_verify.dll`，**不会**调用 `layout-tlcp-pqc.bat`；若还要更新 `bin/` 下其它文件，需手动再跑 `layout-tlcp-pqc.bat`。

---

### 3.2.5 编译后的目录（layout 之后）

```
tlcp-pqc/
├── tongsuo-install/          # build-tongsuo 安装前缀（layout 的源，开发/链接用）
├── pqmagic-install/          # build-providers [1/5] 产出
├── bin/
│   ├── openssl.exe           # layout ← tongsuo-install/bin
│   ├── libcrypto-3-x64.dll   # layout ← tongsuo-install/bin
│   ├── libssl-3-x64.dll      # layout ← tongsuo-install/bin
│   └── verify_certs.exe      # 可选
├── lib/
│   └── libpqmagic_std.lib    # layout ← pqmagic-install/lib
├── providers/
│   ├── pqmagic.dll
│   ├── libml_dsa_sm2_provider.dll
│   ├── cert_verify.dll
│   └── aigis_enc.dll
└── config/openssl-all-providers.cnf
```

---

### 3.2.6 编译完成后的 CLI 验收（进入工作流 ④）

```powershell
Set-ExecutionPolicy -Scope Process Bypass
Set-Location D:\20240429certificate-verification\tlcp-pqc
. .\bin\Set-TlcpEnv.ps1
openssl version -a
openssl list -providers    # 应含 default、pqmagic、ml_dsa_sm2、cert_verify、aigis_enc
powershell -File .\bin\verify-chain-all.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

三套证全部 OK 后，再执行 §3.3 **场景 A 步骤 4** 同步到 GUI。

---

### 3.3 完整复现命令（PowerShell，维护者用）

> **约定：** 本文档所有可复制命令均按 **PowerShell** 编写。  
> 在 PowerShell 中运行当前目录下的 `.bat` **必须**写 `.\脚本名.bat`，不能直接写 `build-tongsuo.bat`（会报 CommandNotFoundException）。

路径变量（可按机器修改）：

```powershell
$RepoRoot = 'D:\20240429certificate-verification'
$TlcpRoot = Join-Path $RepoRoot 'tlcp-pqc'
$GuiRoot  = Join-Path $RepoRoot 'certificate-verification-win32-x64'
```

#### 场景 A — 只改了 Tongsuo（不重编 provider）

```powershell
Set-ExecutionPolicy -Scope Process Bypass
$RepoRoot = 'D:\20240429certificate-verification'
$TlcpRoot = Join-Path $RepoRoot 'tlcp-pqc'
$GuiRoot  = Join-Path $RepoRoot 'certificate-verification-win32-x64'

# 1 编译 Tongsuo（较久，数分钟～数十分钟）
Set-Location $TlcpRoot
.\build-tongsuo.bat
if (-not $?) { exit 1 }

# 2 汇总运行时到 tlcp-pqc/bin、providers、config
.\layout-tlcp-pqc.bat
if (-not $?) { exit 1 }

# 3 检查 bin/ 三件套
Get-ChildItem (Join-Path $TlcpRoot 'bin\openssl.exe'),
              (Join-Path $TlcpRoot 'bin\libcrypto-3-x64.dll'),
              (Join-Path $TlcpRoot 'bin\libssl-3-x64.dll') | Select-Object Name, Length

# 4 CLI 验收（必须全部 : OK）
. (Join-Path $TlcpRoot 'bin\Set-TlcpEnv.ps1')
openssl version -a
openssl list -providers
powershell -File (Join-Path $TlcpRoot 'bin\verify-chain-all.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 5 同步到 GUI
Set-Location $GuiRoot
.\scrpts\layout-app-resources.bat
if (-not $?) { exit 1 }

# 6 app 内验链自测
node (Join-Path $GuiRoot 'resources\app\scripts\test-openssl-layout.js')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'ALL OK' -ForegroundColor Green
```

**成功标志（逐步比对）：**

| 步骤 | 期望 |
|------|------|
| 1 | 末尾 `=== DONE ===`，`apps\openssl.exe version -a` 有 Tongsuo 版本 |
| 2 | `$?` 为 True；`bin/` 含 `openssl.exe` + 两个 DLL |
| 4 | `openssl list -providers` 五个 provider 均为 `active`；验链脚本 exit `0`，每张证 `: OK` |
| 5 | 输出 `=== DONE: ...\resources\app ===` |
| 6 | 三行 `certs/1 OK`、`certs/2 OK`、`certs/3 OK`；exit `0` |

#### 场景 B — 从零全量 / 改了 Provider

将场景 A 的 **步骤 1～2** 替换为：

```powershell
Set-Location $TlcpRoot
.\build-tongsuo.bat
if (-not $?) { exit 1 }
.\build-providers.bat    # 内含 [1/5]…[5/5] + layout-tlcp-pqc.bat
if (-not $?) { exit 1 }
```

然后从场景 A **步骤 3** 继续。

#### 场景 A′ — 仅 Tongsuo 增量（已 Configure 过）

```powershell
Set-Location $TlcpRoot
.\build-tongsuo-resume.bat
if (-not $?) { exit 1 }
.\layout-tlcp-pqc.bat
if (-not $?) { exit 1 }
# 接场景 A 步骤 3～6
```

#### 专项脚本（PowerShell 调用方式相同）

```powershell
Set-Location D:\20240429certificate-verification\tlcp-pqc
.\rebuild-cert-verify.bat          # 仅 cert_verify.dll；不含 layout，需手动 .\layout-tlcp-pqc.bat
.\rebuild-pqmagic-portable.bat     # PQMagic 可移植 + 全 provider + layout
.\rebuild-aigis-provider.bat       # pqmagic + aigis + layout
.\build-providers-resume.bat       # 从 spki 续编 + layout
```

#### 开发模式预览 GUI（可选，步骤 7）

```powershell
Set-Location D:\20240429certificate-verification\certificate-verification-win32-x64\resources\app
npm install   # 首次
npm start
```

---

## 4. 日常两种使用模式

### 4.1 最终用户（只要 GUI）

1. 复制整个 `certificate-verification-win32-x64/`  
2. 双击 `证书验证.exe`  
3. 手动选择根证、待验证证 → 查看 / 验证  

**不需要** `tlcp-pqc`、不需要编译、不需要 Node.js。

### 4.2 开发者（改密码学或 GUI）

```text
① tlcp-pqc：改源码 / 改证 / 改 provider
② tlcp-pqc：编译（详见 §3.2、完整命令 §3.3）
    全量：.\build-tongsuo.bat → .\build-providers.bat（后者含 layout）
    仅 Tongsuo：.\build-tongsuo.bat → .\layout-tlcp-pqc.bat
    增量：按 §3.2.4 选一个 .\rebuild-*.bat 或 .\*-resume.bat
③ tlcp-pqc：若 ② 未含 layout，再跑 .\layout-tlcp-pqc.bat
④ tlcp-pqc：Set-TlcpEnv + verify-chain-all.ps1  → 必须全部 OK
⑤ certificate-verification-win32-x64：.\scrpts\layout-app-resources.bat
⑥ app：node resources\app\scripts\test-openssl-layout.js
⑦ GUI：双击 证书验证.exe 或 npm start（§3.3）
⑧ 更新文档（README_项目结构梳理.md、Windows查看与验链命令.md 等）
```

---

## 5. 关键脚本对照

| 目的 | tlcp-pqc | certificate-verification-win32-x64 |
|------|----------|-----------------------------------|
| 导入 OpenSSL 环境 | `bin/Set-TlcpEnv.ps1` / `.bat` | `index.html` 内 `buildOpensslEnv()` |
| 查看单张证 | `openssl x509 -in … -text -noout` | 界面「查看证书」 |
| 验整条链 | `bin/verify-chain.ps1 -CertSet N` | 界面「验证证书」 |
| 三套全验 | `bin/verify-chain-all.ps1` | 手动 GUI 或 `test-openssl-layout.js` |
| 汇总构建产物 | `layout-tlcp-pqc.bat` | — |
| 同步到 GUI | — | `scrpts/layout-app-resources.bat` |

**GUI 验链等价命令（`index.html`）：**

```text
openssl verify -CAfile <根证> [-untrusted <待验证证同目录/yunying.crt>] <待验证证>
```

环境变量（与 CLI 对齐）：

| 变量 | GUI 中的值 |
|------|------------|
| `PATH` | `{app}/tongsuo/bin` + 系统 PATH |
| `OPENSSL_CONF` | `{app}/config/openssl-all-providers.cnf` |
| `OPENSSL_MODULES` | `{app}/providers` |
| `PQMAGIC_STD_LIB` | `{app}/providers/pqmagic.dll` |
| `CERT_VERIFY_SO` | `{app}/providers/cert_verify.dll` |
| `CERT_VERIFY_VERIFY_INFO` | `1` |

---

## 6. 当前已知差异（维护时注意）

| 项 | tlcp-pqc | GUI app（当前） | 说明 |
|----|----------|-----------------|------|
| 示例证目录 | `certs/1`、`2`、`3` | `certs/Pure PQC Certificate/` 等具名目录 | `layout-app-resources.bat` 仍按 `1/2/3` 复制，**若 app 改用具名目录，需同步改 layout 脚本** |
| 自测脚本 | `verify-chain-all.ps1` | `test-openssl-layout.js` 仍引用 `certs/1、2、3` | 需与 app 内 `certs/` 结构保持一致 |
| PQMagic 可移植编译 | `PQMAGIC_MSVC_PORTABLE=ON` | 必须使用可移植版 `pqmagic.dll` | 否则部分 CPU 上 `0xC000001D` 非法指令 |
| 根证角色 | `-CAfile` 必须是 `root.crt` | 「根证书」输入框 | 不可用 `yunying.crt` 代替 root 验叶子证 |

---

## 7. 变更类型与推荐流程

按变更性质选择路径，**不必每次都走全流程**。

| 变更类型 | 主要改动位置 | 是否必须重编 tlcp-pqc | 是否必须 layout-app | 是否必须重打 exe |
|----------|--------------|----------------------|---------------------|------------------|
| A. Provider / Tongsuo 源码 | `tlcp-pqc` 各子项目 | ✅ | ✅ | ❌（通常） |
| B. 示例证书内容 | `tlcp-pqc/certs/` | ❌ | ✅（复制 cert） | ❌ |
| C. GUI 验链/查看逻辑 | `index.html` | ❌ | ❌ | ❌ |
| D. 仅 UI 样式 | `index.html`、`main.js` | ❌ | ❌ | ❌ |
| E. 新增 provider DLL | `tlcp-pqc` + `index.html` cnf | ✅ | ✅ | ❌ |
| F. 文档 | `doc/`、`README_*.md` | ❌ | ❌ | ❌ |

---

## 8. 举例：新变更如何落地

### 示例 A — 修复 `cert_verify.dll` 验签 bug

**目标：** 复合证双重验签在 CLI 与 GUI 均正确。

| 步骤 | 操作 | 验收 |
|------|------|------|
| 1 | 在 `tlcp-pqc/x509-hybrid-verify-provider/` 改代码 | — |
| 2 | `rebuild-cert-verify.bat` 或对应 build 脚本 | 生成新 `cert_verify.dll` |
| 3 | `tlcp-pqc\layout-tlcp-pqc.bat` | `providers/` 更新 |
| 4 | `Set-TlcpEnv.ps1` 后跑 `verify-chain-all.ps1` | 三套证 CLI 全 OK |
| 5 | `certificate-verification-win32-x64\scrpts\layout-app-resources.bat` | app 内 DLL 更新 |
| 6 | `node resources\app\scripts\test-openssl-layout.js` | 自测 OK |
| 7 | GUI 选同目录 `root.crt` + `user_sig.crt` 验证 | 输出 `: OK` |
| 8 | 更新 `Windows查看与验链命令.md`（若命令有变） | 文档一致 |

---

### 示例 B — 新增一套示例证「Hybrid Using Extensions Certificate」到 GUI

**目标：** 用户在 `resources/app/certs/` 下能看到并验证新套证。

| 步骤 | 操作 | 验收 |
|------|------|------|
| 1 | 在 `tlcp-pqc/certs/` 准备或生成新套 `.crt` | CLI 下 `verify-chain.ps1` 可验 |
| 2 | 修改 `scrpts/layout-app-resources.bat`：增加复制到新目录 `certs/Hybrid Using Extensions Certificate/` | layout 后文件存在 |
| 3 | 跑 `layout-app-resources.bat` | app 内证书齐全 |
| 4 | GUI 手动选该目录 `root.crt` + `user_sig.crt` | 查看、验证 OK |
| 5 | 更新 `README_项目结构梳理.md` 示例证表格 | 文档一致 |
| 6 | （可选）更新 `test-openssl-layout.js` 覆盖新目录 | 自动化自测 |

> 若仅改 GUI 内证书、不改 tlcp-pqc，也可 **直接复制 `.crt` 到 app/certs/**，但长期应以 tlcp-pqc 为 **单一来源**，避免两套证漂移。

---

### 示例 C — 仅改 GUI：输出区滚动、错误提示文案

**目标：** 不动密码学，只改体验。

| 步骤 | 操作 | 验收 |
|------|------|------|
| 1 | 改 `resources/app/index.html`（及必要时 `main.js`） | `npm start` 预览 |
| 2 | 用现有 app 内 `certs/` 做查看、验链、故意错配验链 | 行为符合预期 |
| 3 | **不需要** 跑 `layout-app-resources.bat` | — |
| 4 | 若改动了验链命令参数，对照 `Windows查看与验链命令.md` 复核 | CLI 与 GUI 一致 |

---

### 示例 D — 升级 Tongsuo 版本

**目标：** 使用新版本 `openssl.exe`。

| 步骤 | 操作 | 验收 |
|------|------|------|
| 1 | 更新 `tlcp-pqc/Tongsuo` 源码 | — |
| 2 | `build-tongsuo.bat` / `build-tongsuo-resume.bat` | `tongsuo-install/` 有新 exe |
| 3 | 视情况重编全部 provider（与 Tongsuo ABI 相关） | `build-providers.bat` |
| 4 | `layout-tlcp-pqc.bat` → CLI 全验 | `verify-chain-all.ps1` OK |
| 5 | `layout-app-resources.bat` | app 运行时更新 |
| 6 | GUI 全回归 | 查看 + 验链 + 错误场景 |

---

## 9. 验收清单（每次跨目录同步后）

### tlcp-pqc 侧（CLI）

```powershell
Set-ExecutionPolicy -Scope Process Bypass
. D:\20240429certificate-verification\tlcp-pqc\bin\Set-TlcpEnv.ps1
openssl list -providers    # 应含 default、pqmagic、ml_dsa_sm2、cert_verify、aigis_enc
powershell -File D:\20240429certificate-verification\tlcp-pqc\bin\verify-chain-all.ps1
```

### GUI 侧（app）

```powershell
Set-Location D:\20240429certificate-verification\certificate-verification-win32-x64
.\scrpts\layout-app-resources.bat
if (-not $?) { exit 1 }
node .\resources\app\scripts\test-openssl-layout.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

然后双击 `证书验证.exe`：

- [ ] 运行时就绪（右上角绿色）
- [ ] 同目录 `root.crt` + `user_sig.crt` 验证 → `: OK`
- [ ] 跨目录混选 → 失败且错误可读（见 README §1.6）

---

## 10. 相关文档索引

| 文档 | 路径 | 内容 |
|------|------|------|
| CLI 验链命令（权威） | `tlcp-pqc/certs/Windows查看与验链命令.md` | openssl 命令、环境、三套证 |
| Windows 移植方案 | `tlcp-pqc/Windows证书查看与验链移植方案B.md` | 组件架构、构建细节 |
| GUI 使用与结构 | `certificate-verification-win32-x64/README_项目结构梳理.md` | 用户指南、目录、错误解读 |
| GUI 独立运行 | `certificate-verification-win32-x64/doc/README-独立运行.md` | 简短说明 |
| 迁移记录 | `certificate-verification-win32-x64/doc/改造计划-Tongsuo-PQC.md` | GmSSL→Tongsuo 历史 |
| **本文档** | `certificate-verification-win32-x64/doc/tlcp-pqc与GUI工作流.md` | 跨目录工作流 |

---

*维护建议：`tlcp-pqc` 为密码学「单一事实来源」；GUI 通过 layout 同步产物。任何需在 GUI 落地的密码学能力，应先在 CLI 验证通过。*
