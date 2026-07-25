# certificate-verification-win32-x64 — 清理与精简总清单

> **用途：** 从 GmSSL 迁移到 Tongsuo+PQC 后的残留清理，以及发行包二次精简参考。  
> **当前架构：** Electron 壳 + `resources/app/tongsuo/bin/openssl.exe` + `providers/*.dll` + 内置示例证 `certs/1|2|3/`。  
> **独立运行：** 日常使用只需本文件夹，**不依赖** 上级 `tlcp-pqc`；仅在重新编译 Tongsuo/Provider 后需跑 `scrpts/layout-app-resources.bat` 更新运行时。

---

## 执行状态总览

| 阶段 | 内容 | 状态 | 约释放空间 |
|------|------|------|------------|
| **阶段一** | GmSSL SDK、旧示例、调试符号等 | ✅ 已完成（2026-06-16） | ~70–75 MB |
| **阶段二** | 重复 DLL、空 node_modules、冗余脚本 | ✅ 已完成（2026-06-16） | ~5.5 MB |
| **阶段三** | 开发/归档文档与脚本（可选） | ⏸ 待你确认 | ~1–5 MB（不含 LICENSES） |

**阶段二已执行项：**

- [x] 删除 `resources/app/tongsuo/lib/`（与 `tongsuo/bin/` 重复的 `libcrypto-3-x64.dll`、`libssl-3-x64.dll`）
- [x] 删除 `resources/app/node_modules/`（仅剩 `.recently_updates.txt`，无实际依赖）
- [x] 删除 `resources/app/scripts/gen-openssl-conf.js`（`index.html` 启动时 `ensureOpensslConf()` 已内联生成）
- [x] 更新 `scrpts/layout-app-resources.bat`：不再创建 `tongsuo/lib`、不再调用 gen 脚本
- [x] 更新 `index.html`：`PATH` 仅注入 `tongsuo/bin`
- [x] 验链自测：`node resources/app/scripts/test-openssl-layout.js` — certs/1、2、3 全部 OK

---

## 阶段一：GmSSL 残留清理（已完成）

> **清理脚本：** `scrpts/cleanup-gmssl.ps1`（可重复执行，已删项会跳过）

### 1.1 整目录删除

| 路径 | 说明 | 约估大小 |
|------|------|----------|
| `resources/app/GmSSL/` | GmSSL SDK 完整残留（html/include/lib/bin 等） | ~70 MB |
| `resources/app/demoCA/` | 旧演示 CA | ~30 KB |
| `demoCA/`（根目录） | 与 app 内重复 | ~30 KB |

### 1.2 独立文件（根目录 + `resources/app/`）

| 类别 | 文件 |
|------|------|
| 可执行/DLL | `gmssl.exe`、`libcrypto-1_1.dll`、`libssl-1_1.dll`（根目录及 app 内各一份） |
| 调试符号 | `*.pdb`（gmssl、libcrypto、libssl，根目录及 app 内） |
| 脚本 | `c_rehash.pl`（根目录及 app 内） |
| 旧示例 | `crl.crl`、`chain.pem`、`chain - 副本.pem`、`baidu.pem`、`1.txt` |
| app 旧示例 | `ROOTCA.cer`、`XIDIANCA.cer`、`2.pem` |
| 前端遗留 | `resources/app/require.js` |

### 1.3 阶段一验证

- [x] `resources/app/` 下无 `gmssl.exe`、`libcrypto-1_1.dll`、`GmSSL/`
- [x] `node resources/app/scripts/test-openssl-layout.js` 通过
- [ ] 人工：双击 `证书验证.exe` →「加载示例」→ 查看/验证证书

---

## 阶段二：Tongsuo 迁移后冗余（已完成）

### 2.1 重复运行时

| 路径 | 说明 | 处理 |
|------|------|------|
| `resources/app/tongsuo/lib/*.dll` | 与 `tongsuo/bin/` 完全重复，为修复 `0xC0000135` 曾双份复制 | ✅ 已删，仅保留 `tongsuo/bin/` |

**说明：** Windows 加载 DLL 时优先在 `openssl.exe` 同目录查找；`PATH` 注入 `tongsuo/bin` 即可，无需 `tongsuo/lib`。

### 2.2 已无用的开发辅助

| 路径 | 说明 | 处理 |
|------|------|------|
| `resources/app/scripts/gen-openssl-conf.js` | 配置生成已内联到 `index.html` | ✅ 已删 |
| `resources/app/node_modules/` | 几乎为空，仅残留元数据 | ✅ 已删 |

**注意：** 若需 `npm start` 本地开发，在 `resources/app/` 下执行 `npm install` 重装依赖。

---

## 阶段三：可选精简（发行版 vs 开发版）

以下文件**不影响**双击 `证书验证.exe` 独立运行，可按场景删除。

### 3.1 仅开发/维护需要（发行可删）

| 路径 | 说明 | 建议 |
|------|------|------|
| `scrpts/cleanup-gmssl.ps1` | 阶段一一次性清理脚本，GmSSL 已清完 | 发行可删；仓库可保留备查 |
| `scrpts/scan-redundant.ps1` | 二次扫描脚本 | 发行可删 |
| `scrpts/layout-app-resources.bat` | 从 `tlcp-pqc` 同步 Tongsuo/Provider/示例证 | **开发必留**；发行可删 |
| `resources/app/scripts/test-openssl-layout.js` | CLI 验链自测 | 发行可删；开发建议保留 |
| `resources/app/package.json` | 仅 `npm start` 开发用 | 发行可删 |
| `resources/app/package-lock.json` | 同上 | 发行可删 |

### 3.2 文档类（内容过时或已归档）

| 路径 | 说明 | 建议 |
|------|------|------|
| `../项目结构梳理.md` | 目录结构 + **首次使用指南**（已按 Tongsuo 架构重写） | **发行建议保留** |
| `改造计划-Tongsuo-PQC.md` | 迁移计划，实施已完成 | 可归档删除；技术细节仍有参考价值 |
| `GmSSL清理清单.md` | 本文档 | 保留（维护清理记录） |
| `README-独立运行.md` | 面向用户的使用说明 | **发行必留** |

### 3.3 体积较大但通常保留

| 路径 | 约大小 | 说明 |
|------|--------|------|
| `LICENSES.chromium.html` | ~4.7 MB | Chromium 开源许可汇总，正式分发建议保留 |
| `locales/*.pak`、`*.pak`、`ffmpeg.dll` 等 | — | Electron/Chromium 运行时，**不可删** |

### 3.4 Provider 说明（勿误删）

| 文件 | 验链是否必需 | 说明 |
|------|--------------|------|
| `pqmagic.dll` | 是 | PQC 算法库 |
| `cert_verify.dll` | 是 | 复合证/混合证验签 |
| `ml_dsa_sm2.dll` | 是 | ML-DSA+SM2 复合证 |
| `aigis_enc.dll` | 否（仅查看/验链） | NTLS 加密用；为与 `tlcp-pqc` 布局一致仍保留 |

---

## 明确保留（运行时必需）

### Electron 壳与 Chromium

`证书验证.exe`、`locales/`、`chrome_*.pak`、`icudtl.dat`、`ffmpeg.dll`、`snapshot_blob.bin`、`v8_context_snapshot.bin`、`vk_swiftshader*`、`swiftshader/`、`d3dcompiler_47.dll`、`libEGL.dll`、`libGLESv2.dll`、`vulkan-1.dll`、`resources.pak`、`LICENSE`、`version`

### 应用与 Tongsuo 运行时

| 类别 | 路径 |
|------|------|
| 入口 | `resources/app/main.js`、`index.html`、`ic.ico` |
| OpenSSL | `resources/app/tongsuo/bin/openssl.exe`、`libcrypto-3-x64.dll`、`libssl-3-x64.dll` |
| Provider | `resources/app/providers/*.dll` |
| 配置 | `resources/app/config/openssl-all-providers.cnf`（启动时可被重写） |
| 示例证 | `resources/app/certs/1/`、`2/`、`3/` |
| 用户文档 | `README-独立运行.md`、`../项目结构梳理.md` |

### 目录结构（精简后）

```
certificate-verification-win32-x64/
├── 证书验证.exe
├── resources/app/
│   ├── main.js, index.html, ic.ico
│   ├── tongsuo/bin/          # openssl.exe + libcrypto/libssl DLL（仅此一处）
│   ├── providers/*.dll
│   ├── config/openssl-all-providers.cnf
│   ├── certs/1,2,3/
│   └── scripts/test-openssl-layout.js   # 开发自测，发行可选
├── scrpts/                              # 维护/开发脚本（发行可选）
│   ├── layout-app-resources.bat        # 开发同步
│   ├── cleanup-gmssl.ps1               # GmSSL 残留清理
│   └── scan-redundant.ps1              # 冗余扫描脚本
├── 项目结构梳理.md                    # 本文档外的目录结构 + 新手指南
└── doc/
    ├── README-独立运行.md
    ├── GmSSL清理清单.md
    └── 改造计划-Tongsuo-PQC.md
```

---

## 删除统计汇总

| 阶段 | 删除内容 | 约释放空间 |
|------|----------|------------|
| 阶段一 | GmSSL/、demoCA/、旧 exe/dll/pdb/示例 | ~70–75 MB |
| 阶段二 | tongsuo/lib 重复 DLL、空 node_modules、gen 脚本 | ~5.5 MB |
| 阶段三（可选） | 开发脚本 + 过时文档 | ~1–5 MB |
| **累计（阶段一+二）** | — | **~75–80 MB** |

---

## 验证清单（每次大改后执行）

```powershell
# 1. 确认无 GmSSL 残留
Get-ChildItem -Recurse -Filter "*gmssl*" -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -Filter "libcrypto-1_1*" -ErrorAction SilentlyContinue

# 2. CLI 验链（三套示例证）
node resources/app/scripts/test-openssl-layout.js

# 3. GUI 人工
# 双击 证书验证.exe → 加载示例 1/2/3 → 查看证书、验证证书链
```

---

## 与 tlcp-pqc 的关系

| 场景 | 是否需要 tlcp-pqc |
|------|-------------------|
| 最终用户双击运行、查看/验链 | **否** |
| 重新编译 Tongsuo 或 Provider 后更新应用内运行时 | **是**（改完后跑 `scrpts/layout-app-resources.bat`） |
| 修改证书示例或验链逻辑 | 视情况（改 `tlcp-pqc` 后 layout，或直接改 app 内文件） |

---

*最后更新：2026-06-16（阶段一+二完成，阶段三待确认是否删除开发/归档文件）*
