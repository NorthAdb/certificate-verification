# 证书验证工具 — 项目结构梳理

> **版本：** 0.2.0（Tongsuo + PQC）  
> **更新日期：** 2026-06-23  
> **应用类型：** Electron 9 桌面程序（绿色发行包，双击即用）  
> **密码学引擎：** Tongsuo `openssl.exe` + 四个 OpenSSL Provider（支持 PQC / 复合证 / 国密混合证）

---

## 一、第一次使用指南（`证书验证.exe`）

本节面向**最终用户**：只需本文件夹，**无需安装** Node.js、GmSSL 或 `tlcp-pqc`。

### 1.1 使用前准备


| 项目   | 要求                                                          |
| ---- | ----------------------------------------------------------- |
| 操作系统 | Windows 10 / 11，64 位                                        |
| 安装   | **不需要**安装，整个 `certificate-verification-win32-x64` 文件夹即为完整程序 |
| 拷贝   | 可将整个文件夹复制到 U 盘、桌面或任意路径后使用                                   |
| 网络   | 不需要联网（纯本地验链）                                                |


**注意：** 请保持文件夹内部结构完整，尤其不要单独移动 `证书验证.exe` 或删除 `resources/` 目录。

### 1.2 启动程序

1. 进入 `certificate-verification-win32-x64` 文件夹
2. 双击 `**证书验证.exe`**

若 Windows 提示「未知发布者」，选择「仍要运行」即可（本工具为内部/实验用途的绿色包）。

### 1.3 界面说明

```
┌─────────────────────────────────────────────────────────────┐
│  证书验证                              [ 运行时就绪 ]        │
│  PQC / 混合证书查看与验链                                    │
│                                                             │
│  1 信任锚点证书 (-CAfile)                                    │
│  [路径输入框........................] [选择文件] [查看证书]   │
│                                                             │
│  2 中间证书 (-untrusted，可选)                               │
│  [路径输入框........................] [选择文件] [查看证书]   │
│                                                             │
│  3 待验证证书                                                │
│  [路径输入框........................] [选择文件] [查看证书]   │
│                                                             │
│  选择文件后点击「验证证书」执行 openssl verify   [验证证书]   │
│                                                             │
│  命令输出                                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ （openssl 命令的文本结果）                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```


| 区域         | 作用                                           |
| ---------- | -------------------------------------------- |
| **信任锚点证书** | 验链信任锚（`-CAfile`），通常为根 CA；仅信中间 CA 时选中间证 |
| **中间证书** | 可选（`-untrusted`）；三段链时由用户手动选择，留空则不参与验链 |
| **待验证证书** | 要查看或验证的目标证书（通常为叶子证） |
| **验证证书**   | 对所选证书执行 `openssl verify`                |
| **命令输出**   | 显示 `openssl x509` / `openssl verify` 的完整文本结果 |
| **运行时就绪**  | 右上角状态，表示 Tongsuo 运行时是否完整                     |


支持的证书格式：`.crt`、`.cer`、`.pem`。根证与待验证证均需通过「选择文件」**手动选取**具体证书文件（不能选文件夹）。

### 1.4 使用内置示例证书（手动选择）

`resources/app/certs/` 下预置多组示例证，可按需浏览选择：


| 目录                                     | 证书类型               | 建议选取                                              |
| -------------------------------------- | ------------------ | ------------------------------------------------- |
| `Pure PQC Certificate/`                | 纯 PQC 链            | 根证 `root.crt`，待验证 `user_sig.crt` 或 `user_enc.crt` |
| `Hybrid Concatenated Certificate/`     | ML-DSA+SM2 复合 SPKI | 根证 `root.crt`，待验证 `user_enc.crt` 或 `user_sig.crt` |
| `Hybrid Using Extensions Certificate/` | 国密混合扩展证书           | 根证 `root.crt`，待验证 `user_sig.crt` 或 `user_enc.crt` |
| `Traditional SM2 Certificate/`         | 传统 SM2 证（含 `.key`） | 仅供查看；验链逻辑以 PQC/混合证为主                              |


**操作步骤（三段链示例）：**

1. **信任锚点** →「选择文件」→ 选中 `root.crt`
2. **中间证书** →「选择文件」→ 选中同目录 `yunying.crt`（两段链可留空）
3. **待验证证书** →「选择文件」→ 选中叶子证（如 `user_sig.crt`）
4. 点击「查看证书」查看详情，或点击「验证证书」执行验链
5. 成功时输出末尾出现 `**: OK`**；复合证/混合证可能包含「双重验签」日志

**只信任中间 CA 时：** 第 1 步选 `yunying.crt`，第 2 步留空，第 3 步选 `user_sig.crt`（程序自动加 `-partial_chain`）。

### 1.5 验证自己的证书

若你有自己的证书文件（需与本工具支持的 PQC/混合格式兼容）：

1. **信任锚点** → 点击「选择文件」，选中根 CA 的 `.crt` / `.cer` / `.pem`
2. **中间证书** → 若链中有中间 CA，手动选择；无则留空
3. **待验证证书** → 点击「选择文件」，选中目标证书
4. 先点「查看证书」确认内容，再点「验证证书」

### 1.6 如何看懂输出

**查看证书（x509）** 常见内容：

- `Subject` / `Issuer`：主体与颁发者  
- `Validity`：有效期  
- `Subject Public Key Info`：公钥类型（如 ML-DSA-44、SM2、复合 SPKI）  
- `X509v3 extensions`：扩展项（混合证、PQC 相关 OID 等）

**验证证书（verify）** 成功标志：

```
……（中间 CA 与叶子证的验签过程）……
D:\...\user_sig.crt: OK
```

失败时会出现 `error` 字样，或输出区显示**退出码**说明。

#### 根证与待验证证不匹配时（跨目录混选）

典型场景：根证选 `Pure PQC Certificate/root.crt`，待验证证选 `Hybrid Concatenated Certificate/user_sig.crt`（或其它目录的叶子证）。二者**不是同一条证书链**，验证必然失败。

**示例输出：**

```
error 20 at 1 depth lookup: unable to get local issuer certificate
error ...\Hybrid Concatenated Certificate\user_sig.crt: verification failed
退出码: 2
```

**逐条解读：**

| 输出内容 | 含义 |
|----------|------|
| `error 20 ... unable to get local issuer certificate` | **核心错误**：无法从提供的根证构建到待验证证的完整信任链。常见原因是根证与叶子证/中间 CA 不属于同一套 PKI。 |
| `at 1 depth lookup` | 在验链第 1 层（通常是中间 CA 或叶子证向上找颁发者）时失败。 |
| `verification failed` | 该叶子证验链未通过。 |
| `退出码: 2` | `openssl verify` 的标准失败退出码（1 多为用法错误，2 为验链失败）。 |

**为何会失败（结合本工具逻辑）：**

1. 程序执行等价于：`openssl verify -CAfile <信任锚> [-untrusted <中间证>] [-partial_chain] <待验证证>`
2. **中间证仅来自用户第 2 步手动选择**；留空则不会自动查找同目录 `yunying.crt` 等文件。
3. 若根证与叶子证属于三段链但未填中间证，将报 `unable to get local issuer certificate`（预期行为）。
4. 若根证来自目录 A、叶子证来自目录 B，且未正确填写中间证，同样会验链失败。

**正确做法（三段链）：** 分别手动选择信任锚、中间 CA、叶子证，例如：

- 信任锚：`certs/Pure PQC Certificate/root.crt`
- 中间证：`certs/Pure PQC Certificate/yunying.crt`
- 待验证：`certs/Pure PQC Certificate/user_sig.crt`

**可忽略的次要报错：** 验链失败后，输出中有时还会出现 `OPENSSL_sk_value`、`file_store`、`unregistered scheme`、`No store loader found` 等字样。这通常是 OpenSSL 在链构建失败后尝试访问系统证书库时的**连带报错**，**不是**本次不匹配的主因，优先看 `unable to get local issuer certificate` 即可。

**快速自检：** 分别「查看证书」对比根证与待验证证的 `Issuer` / `Subject` 字段，确认颁发者链条能逐级衔接（叶子 → 中间 CA → 根证）。

### 1.7 常见问题

| 现象                                            | 可能原因                               | 处理办法                                                        |
| --------------------------------------------- | ---------------------------------- | ----------------------------------------------------------- |
| 双击无反应或闪退                                      | `resources/app/tongsuo/bin/` 被删或损坏 | 重新获取完整文件夹，或联系维护者执行 `scrpts/layout-app-resources.bat`        |
| 退出码 `0xC0000135`                              | 找不到 `libcrypto-3-x64.dll`          | 确认 `resources\app\tongsuo\bin\` 下同时存在 `openssl.exe` 与两个 DLL |
| 退出码 `0xC000001D`                              | CPU 不支持 AVX-512 而使用了错误编译的 PQMagic  | 需维护者用「可移植」选项重新编译并更新 `providers\pqmagic.dll`                 |
| 提示「必须是证书文件，不能是目录」                             | 选择了文件夹而非 `.crt` 文件                 | 选具体证书文件                                                     |
| 验证失败 `unable to get local issuer certificate` | 信任锚选错，或未手动选择所需中间 CA | 检查三段链是否已填中间证；对比各证 `Issuer` / `Subject` 是否衔接 |


更简短的说明见 `doc/README-独立运行.md`。

---

## 二、项目总览


| 项目    | 说明                                                |
| ----- | ------------------------------------------------- |
| 产品名   | 证书验证                                              |
| 技术栈   | Electron 9.x + 原生 HTML/JS（无 React/Vue）            |
| 入口    | `resources/app/main.js` → 加载 `index.html`         |
| 业务逻辑  | 全部在 `resources/app/index.html` 内联脚本中              |
| 密码学引擎 | `tongsuo/bin/openssl.exe` + Provider DLL          |
| 打包形态  | electron-packager 输出的 **win32-x64 绿色发行包**         |
| 独立性   | **自包含**，运行时均在 `resources/app/` 内，不依赖上级 `tlcp-pqc` |


### 与上级仓库的关系

```
20240429certificate-verification/          # 上层仓库（文档、OpenSpec、tlcp-pqc 等）
├── certificate-verification-win32-x64/    # ★ 本工具（用户实际使用的发行包）
├── tlcp-pqc/                              # Tongsuo/PQC 源码与编译（仅开发更新时需要）
├── openspec/、.cursor/ …                  # 工程配置，与普通用户无关
└── PKI实验.pdf 等资料
```

**普通用户**只需 `certificate-verification-win32-x64` 文件夹。  
**维护者**在重新编译 Tongsuo 或 Provider 后，于 `scrpts/` 下执行 `layout-app-resources.bat` 同步运行时。

### 架构示意

```
证书验证.exe  (Electron / Chromium 壳)
    │
    └── resources/app/
            ├── index.html ──execFile──► tongsuo/bin/openssl.exe
            │                              │
            │                              ├── 读取 config/openssl-all-providers.cnf
            │                              └── 加载 providers/*.dll
            ├── main.js（窗口、菜单）
            └── certs/（示例证，按类型分子目录）
```

---

## 三、目录结构（规整）

```
certificate-verification-win32-x64/
│
├── 证书验证.exe                    # ★ 用户入口：双击启动
│
├── 【Electron / Chromium 运行时 — 勿删】
├── locales/                        # 界面多语言包（约 50+ 个 .pak）
├── swiftshader/                    # 软件渲染备用
├── chrome_100_percent.pak
├── chrome_200_percent.pak
├── resources.pak
├── icudtl.dat
├── snapshot_blob.bin
├── v8_context_snapshot.bin
├── ffmpeg.dll
├── d3dcompiler_47.dll
├── libEGL.dll / libGLESv2.dll
├── vk_swiftshader.dll / vk_swiftshader_icd.json
├── vulkan-1.dll
├── LICENSE / LICENSES.chromium.html / version
│
├── 【文档】
├── README_项目结构梳理.md          # 本文档（项目主文档，根目录）
└── doc/
    ├── README-独立运行.md          # 简短独立运行说明
    ├── GmSSL清理清单.md           # 历史清理与精简记录
    └── 改造计划-Tongsuo-PQC.md    # 迁移实施记录（已完成）
│
├── 【开发 / 维护 — 普通用户可忽略】
├── scrpts/
│   ├── layout-app-resources.bat   # 从 tlcp-pqc 同步运行时到 resources/app
│   ├── cleanup-gmssl.ps1          # GmSSL 残留清理（已执行完毕）
│   └── scan-redundant.ps1         # 冗余扫描脚本
│
└── resources/
    └── app/                        # ★ 应用源码 + 密码学运行时 + 示例证
        ├── main.js                 # Electron 主进程
        ├── index.html              # UI + 全部业务逻辑
        ├── package.json            # 开发用（npm start）
        ├── package-lock.json
        ├── ic.ico                  # 窗口图标
        │
        ├── tongsuo/
        │   └── bin/                # openssl.exe + DLL（仅此一处，无 tongsuo/lib）
        │       ├── openssl.exe
        │       ├── libcrypto-3-x64.dll
        │       └── libssl-3-x64.dll
        │
        ├── providers/
        │   ├── pqmagic.dll
        │   ├── cert_verify.dll
        │   ├── libml_dsa_sm2_provider.dll
        │   └── aigis_enc.dll
        │
        ├── config/
        │   └── openssl-all-providers.cnf   # 启动时可按路径重写
        │
        ├── certs/
        │   ├── Pure PQC Certificate/
        │   ├── Hybrid Concatenated Certificate/
        │   ├── Hybrid Using Extensions Certificate/
        │   └── Traditional SM2 Certificate/
        │       └── 各目录含 root.crt、yunying.crt、user_sig.crt、user_enc.crt 等
        │
        └── scripts/
            └── test-openssl-layout.js    # CLI 验链自测（开发用）
```

### 维护脚本与 app 内脚本的区别


| 位置                                             | 用途                                           | 何时使用                    |
| ---------------------------------------------- | -------------------------------------------- | ----------------------- |
| `scrpts/layout-app-resources.bat`              | 从 `tlcp-pqc/bin/`、`providers/` **复制**运行时与示例证到 `resources/app/` | 重新编译并 layout 后 |
| `scrpts/cleanup-gmssl.ps1`                     | 清理 GmSSL 残留（一次性）                             | 迁移维护                    |
| `scrpts/scan-redundant.ps1`                    | 扫描发行包冗余文件                                    | 精简发行包时                  |
| `resources/app/scripts/test-openssl-layout.js` | **验证** app 内 OpenSSL 布局与验链是否正常               | layout 后或改 app 后自测      |


---

## 四、核心文件说明

### 4.1 用户侧（关心 `证书验证.exe` 即可）


| 路径                           | 说明                   |
| ---------------------------- | -------------------- |
| `证书验证.exe`                   | 程序主入口                |
| `resources/app/index.html`   | 界面与验链逻辑（修改功能主要改此文件）  |
| `resources/app/tongsuo/bin/` | OpenSSL 可执行文件与依赖 DLL |
| `resources/app/providers/`   | PQC 验签所需动态库          |
| `resources/app/certs/`       | 内置示例证书（按类型分子目录）      |


### 4.2 维护侧


| 路径                                             | 说明                                         |
| ---------------------------------------------- | ------------------------------------------ |
| `resources/app/main.js`                        | 创建窗口、关闭菜单栏                                 |
| `scrpts/layout-app-resources.bat`              | 从 `../tlcp-pqc` 复制 tongsuo、providers、certs |
| `resources/app/scripts/test-openssl-layout.js` | 无 GUI 快速验证验链是否正常                           |
| `doc/GmSSL清理清单.md`                             | 已删除的 GmSSL 残留与可选精简项                        |


### 4.3 Electron 运行时（勿删）

`locales/`、`*.pak`、`ffmpeg.dll`、`icudtl.dat`、`snapshot_blob.bin` 等为 Chromium 运行所需。缺少任一关键文件会导致 `证书验证.exe` 无法启动。`LICENSES.chromium.html` 体积较大，为开源许可汇总，正式分发建议保留。

---

## 五、工作原理

### 5.1 启动流程

1. `证书验证.exe` 启动 Electron，加载 `resources/app/main.js`
2. `main.js` 打开无边栏菜单的窗口，加载 `index.html`
3. `index.html` 执行 `ensureOpensslConf()`，按当前 `__dirname` 生成/更新 `config/openssl-all-providers.cnf`（保证文件夹移动后仍可用）
4. 静默检查 `tongsuo/bin/openssl.exe` 与 `libcrypto-3-x64.dll` 是否存在

### 5.2 调用 OpenSSL 时的环境

`buildOpensslEnv()` 为每次 `execFile` 注入：


| 变量                        | 值                                        |
| ------------------------- | ---------------------------------------- |
| `PATH`                    | `{app}/tongsuo/bin` + 系统 PATH            |
| `OPENSSL_CONF`            | `{app}/config/openssl-all-providers.cnf` |
| `OPENSSL_MODULES`         | `{app}/providers`                        |
| `PQMAGIC_STD_LIB`         | `{app}/providers/pqmagic.dll`            |
| `CERT_VERIFY_SO`          | `{app}/providers/cert_verify.dll`        |
| `CERT_VERIFY_VERIFY_INFO` | `1`（输出详细验签信息）                            |


### 5.3 查看证书

```
openssl x509 -in <证书路径> -text -noout
```

### 5.4 验证证书链

```
openssl verify -CAfile <信任锚> [-untrusted <中间证>] [-partial_chain] <待验证证>
```

逻辑要点（见 `index.html` 中 `buildCertVerifyArgs()`）：

- 信任锚、待验证证必须为**文件**，且路径有效  
- **中间证由用户在第 2 步手动选择**；留空则不传 `-untrusted`  
- 未填中间证且信任锚**非自签根**时，自动加 `-partial_chain`（以中间 CA 为信任锚验叶子）  
- 未填中间证且为三段链时，OpenSSL 将报 `unable to get local issuer certificate`

### 5.5 与旧版（GmSSL）的差异


| 项目       | 旧版                  | 现行                               |
| -------- | ------------------- | -------------------------------- |
| CLI      | `gmssl.exe`         | `tongsuo/bin/openssl.exe`        |
| DLL      | `libcrypto-1_1.dll` | `libcrypto-3-x64.dll`（OpenSSL 3） |
| Provider | 无                   | 必须加载四个 provider DLL              |
| 功能       | 含 CRL、OCSP          | 仅根证 + 待验证证                       |
| 示例       | ROOTCA.cer、demoCA   | `certs/` 下按类型命名的子目录              |
| 示例加载     | —                   | 用户手动「选择文件」，无内置快捷填充               |


---

## 六、开发与自测（可选）

仅维护者需要；**最终用户无需执行本节命令。**  
完整工具安装说明与换机清单见 **§七**。

### 6.1 从 tlcp-pqc 更新运行时

前提：上级目录存在已编译好的 `tlcp-pqc`（已跑 `layout-tlcp-pqc.bat`，`bin/` 含 `openssl.exe` 与两个 DLL，`providers/` 含四个 provider DLL）。

```powershell
Set-Location D:\20240429certificate-verification\certificate-verification-win32-x64
.\scrpts\layout-app-resources.bat
if (-not $?) { exit 1 }
```

脚本从 `tlcp-pqc/bin/`、`tlcp-pqc/providers/` 复制到 `resources/app/`（与 CLI 运行时布局一致）。

### 6.2 开发模式（改代码后即时预览）

```powershell
Set-Location D:\20240429certificate-verification\certificate-verification-win32-x64\resources\app
npm install   # 首次
npm start
```

### 6.3 命令行验链自测

```powershell
Set-Location D:\20240429certificate-verification\certificate-verification-win32-x64
node .\resources\app\scripts\test-openssl-layout.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

（注：若 `test-openssl-layout.js` 仍引用旧版 `certs/1、2、3` 路径，需与当前 `certs/` 目录结构同步后使用。）

---

## 七、开发环境与换机工具清单

本节面向**维护者 / 开发者**：说明从零编译 `tlcp-pqc`、改 GUI、打绿色包分别需要哪些工具，以及换电脑后应重新安装什么。

### 7.1 按角色划分：你需要装什么？

| 角色 | 典型工作 | 需要安装的工具 |
|------|----------|----------------|
| **最终用户** | 双击 `证书验证.exe` 验链 | **无**（绿色包自包含 OpenSSL + Provider） |
| **GUI 维护者** | 改 `index.html`、同步运行时、本地预览 | **Git** + **Node.js**（`npm install` / `npm start`） |
| **密码学全栈维护者** | 编译 Tongsuo、Provider、CSR/验链补丁 | **VS 2022 Build Tools** + **CMake** + **Strawberry Perl** + **Git**；建议再加 **Node.js** |
| **调试辅助（可选）** | 跑 `verify-csr-certs2.py` 等备用脚本 | **Python 3**（系统 `python` / `python3` 即可） |

> **结论：** 你记得的 **VS**、**Perl** 属于「全量编译链」；只改界面或只跑已编好的发行包时，**不必**装 VS / Perl。

### 7.2 工具明细表

| 工具 | 版本建议 | 脚本中的默认路径 | 主要用途 | 换机必装？ |
|------|----------|------------------|----------|------------|
| **Visual Studio 2022 Build Tools** | 含 MSVC v143、Windows 10/11 SDK | `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat` | `nmake` 编 Tongsuo；`cl` 编 `mldsa_sign_sm3.exe`；CMake 生成 VS 工程编 Provider / PQMagic | ✅ 全量编译必装 |
| **CMake** | ≥ 3.20 | `C:\Program Files\CMake\bin\cmake.exe` | 构建 PQMagic、四个 OpenSSL Provider | ✅ 全量编译必装 |
| **Strawberry Perl** | 5.x（需能跑 `Configure`） | `C:\Strawberry\perl\bin`（脚本会 prepend 到 `PATH`） | Tongsuo `perl Configure VC-WIN64A ...` | ✅ 编 Tongsuo 必装 |
| **Git** | 任意较新版本 | — | 克隆/同步仓库、版本管理 | ✅ 开发机建议装 |
| **Node.js** | LTS（如 18 / 20） | — | `resources/app` 下 `npm install`、`npm start`（Electron 9 开发预览）；`node test-openssl-layout.js` 自测 | ✅ 改 GUI 建议装 |
| **Python 3** | 3.8+ | — | `tlcp-pqc/bin/verify-csr-certs2.py` 等调试脚本（**非**主流程必需） | ⚪ 可选 |
| **NASM** | 最新稳定版 | — | Tongsuo 汇编优化；当前 `build-tongsuo.bat` 使用 `no-asm`，**可不装** | ⚪ 可选 |
| **electron-packager** | 与 `electron@9` 配套 | 通过 `npm` 全局或项目 devDep 安装 | 重新打出 `证书验证.exe` 绿色包（仓库内打包脚本尚待自动化） | ⚪ 仅重打包时需要 |

#### Visual Studio 2022 Build Tools 安装勾选

使用 [Visual Studio Build Tools 2022](https://visualstudio.microsoft.com/zh-hans/downloads/) 安装器时，至少勾选：

- **使用 C++ 的桌面开发**（Desktop development with C++）
- **MSVC v143 - VS 2022 C++ x64/x86 生成工具**
- **Windows 10/11 SDK**（任一新版即可）

Community 完整版 VS 2022 亦可，脚本调用的是同一套 `vcvars64.bat`。

#### Strawberry Perl 说明

- 推荐 [Strawberry Perl](https://strawberryperl.com/)（Windows 原生，自带常用模块）。
- Tongsuo 的 `Configure` 依赖 Perl；若报缺少 `Text::Template`，在 Strawberry 下执行：`cpan Text::Template`。
- 项目 bat 脚本**写死** `C:\Strawberry\perl\bin`，若安装到其它目录，需改各 `build-*.bat` 里的 `PATH`。

#### Node.js 与 Electron

- 发行包 `证书验证.exe` **已内置** Chromium/Electron 运行时，用户端**不需要** Node.js。
- 开发时在 `resources/app/` 执行 `npm install` 会拉取 `electron@^9.1.1`（见 `package.json`），用于 `npm start` 热预览。
- `node_modules/` **不要**提交进 Git；换机后在该目录重新 `npm install` 即可。

### 7.3 各工具在构建链中的位置

```
【全量编译 tlcp-pqc】
  Git clone 仓库
       │
       ├─ VS Build Tools (vcvars64) + Perl ──► build-tongsuo.bat ──► openssl.exe + libcrypto/libssl
       │
       └─ VS Build Tools + CMake ────────────► build-providers.bat ──► pqmagic.dll、cert_verify.dll 等
                                                    │
                                                    └─ layout-tlcp-pqc.bat ──► tlcp-pqc/bin、providers/

【同步到 GUI】
  layout-app-resources.bat ──► resources/app/tongsuo、providers、certs

【GUI 开发预览】
  Node.js ──► cd resources/app && npm install && npm start

【最终用户】
  证书验证.exe（无需上述任何工具）
```

### 7.4 换电脑：必须重新下载 / 安装什么？

#### A. 系统级工具（新电脑上要重装）

| 序号 | 操作 | 说明 |
|------|------|------|
| 1 | 安装 **VS 2022 Build Tools**（含 C++ 工作负载） | 编译 Tongsuo / Provider 必需 |
| 2 | 安装 **CMake** 并加入 PATH | Provider / PQMagic 构建 |
| 3 | 安装 **Strawberry Perl** 到 `C:\Strawberry\` 或改脚本路径 | Tongsuo `Configure` |
| 4 | 安装 **Git** | 拉取仓库 |
| 5 | 安装 **Node.js LTS** | GUI 开发与自测（若只做全量 C++ 编译可暂缓） |
| 6 | （可选）安装 **Python 3** | 仅跑 CSR 调试脚本时需要 |

#### B. 不必从官网重装（随仓库或构建产生）

| 内容 | 来源 | 说明 |
|------|------|------|
| `openssl.exe`、`libcrypto-3-x64.dll`、`libssl-3-x64.dll` | `build-tongsuo.bat` 产出，或从旧机复制 `tlcp-pqc/tongsuo-install/` | 可整机拷贝已编译产物，跳过 Tongsuo 编译 |
| `providers/*.dll` | `build-providers.bat` 产出 | 同上 |
| `证书验证.exe` 与 Chromium 运行时 | 已打包在发行目录 | 最终用户直接拷贝整个文件夹 |
| `resources/app/node_modules/` | `npm install` 生成 | 换机后在 `resources/app` 重装即可 |
| 示例证书 `certs/` | 仓库内 | `git clone` 即有 |

#### C. 换机后必须检查 / 修改的配置

当前多个 bat 脚本**写死**路径 `D:\20240429certificate-verification\tlcp-pqc`，换盘符或目录后需批量替换，至少包括：

| 文件 | 需改内容 |
|------|----------|
| `tlcp-pqc/build-tongsuo.bat` | `cd` 目标、`--prefix=` 安装前缀 |
| `tlcp-pqc/build-tongsuo-resume.bat`、`build-tongsuo-libs-apps.bat` | Tongsuo 源码目录 |
| `tlcp-pqc/build-providers.bat` 及 `rebuild-*.bat` | `TLCP_ROOT=` |
| `tlcp-pqc/bin/build-mldsa-sign.bat` | `TLCP_ROOT=` |
| `certificate-verification-win32-x64/scrpts/layout-app-resources.bat` | 指向 `tlcp-pqc` 的相对/绝对路径（若仓库布局变化） |

若 VS / CMake / Perl 未装在默认路径，还需改各 bat 中的 `vcvars64.bat`、`cmake.exe`、`Strawberry\perl\bin`。

### 7.5 换机快速上手（维护者）

**场景 1：只维护 GUI，不编译密码学**

```powershell
git clone <仓库地址> D:\20240429certificate-verification
cd D:\20240429certificate-verification\certificate-verification-win32-x64\resources\app
npm install
npm start
```

**场景 2：从零编译完整运行时**

```powershell
# 1. 安装 §7.2 中 VS + CMake + Perl + Git
# 2. 修改 bat 内 TLCP_ROOT / 盘符路径
cd D:\20240429certificate-verification\tlcp-pqc
.\build-tongsuo.bat
.\build-providers.bat

cd ..\certificate-verification-win32-x64
.\scrpts\layout-app-resources.bat
node .\resources\app\scripts\test-openssl-layout.js
```

**场景 3：新电脑只跑工具、不开发**

- 拷贝整个 `certificate-verification-win32-x64` 文件夹即可，**无需安装任何开发工具**（见 §一）。

更细的编译步骤与脚本对照见 `doc/tlcp-pqc与GUI工作流.md`、`tlcp-pqc/Windows证书查看与验链移植方案B.md`。

---

## 八、相关文档索引


| 文档                                 | 读者       | 内容                 |
| ---------------------------------- | -------- | ------------------ |
| **本文档**                            | 用户 + 维护者 | 结构梳理 + 首次使用指南      |
| `doc/README-独立运行.md`               | 用户       | 极简独立运行说明           |
| `doc/GmSSL清理清单.md`                 | 维护者      | 清理历史与发行精简建议        |
| `doc/改造计划-Tongsuo-PQC.md`          | 维护者      | GmSSL→Tongsuo 迁移记录 |
| `doc/tlcp-pqc与GUI工作流.md`           | 维护者      | tlcp-pqc 与 GUI 跨目录工作流 |
| `tlcp-pqc/certs/Windows查看与验链命令.md` | 维护者      | 命令行验链参考（仓库上级目录）    |
| `tlcp-pqc/Windows证书查看与验链移植方案B.md` | 维护者 | 开发环境、分步构建与 MSVC 说明 |


---

*文档随项目结构更新；若发现目录与本文不一致，以实际文件为准。*