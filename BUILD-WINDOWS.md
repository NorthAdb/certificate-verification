# Tongsuo Windows 编译指南

提供两种编译方案，任选其一即可。

---

## 方案一：Visual Studio (MSVC)

### 环境要求

| 工具 | 说明 |
|------|------|
| **Visual Studio** | 2019 / 2022 均可，Community / Professional / Enterprise 任意版本，需勾选「使用 C++ 的桌面开发」工作负载 |
| **Perl** | [Strawberry Perl](http://strawberryperl.com/) 或 ActiveState Perl，版本 ≥ 5.10.0 |
| **NASM** | 汇编器，从 <https://www.nasm.us> 下载，加入 `%PATH%` |

### 编译步骤

**1. 打开 Visual Studio 开发者命令行**

开始菜单 → Visual Studio → **x64 Native Tools Command Prompt**

（或直接用 `cmd` 运行 `vcvarsall.bat x86_amd64`）

**2. 确保 Perl 和 NASM 在 PATH 中**

```cmd
perl --version
nasm --version
```

**3. 配置**

```cmd
cd E:\AI-Tech\Tongsuo

REM 64 位
perl Configure VC-WIN64A

REM 如果不需要依赖检查，可加速配置：
perl Configure VC-WIN64A no-makedepend
```

> 其他可选目标：`VC-WIN32`（32 位）、`VC-WIN64-ARM`（ARM64）

**4. 编译**

```cmd
nmake
```

> 只编译不安装，到此为止。不要执行 `nmake install`。

### 加速编译

全量编译（含 307 个测试程序、fuzz、引擎等）耗时很长。日常开发只需编译核心库和命令行工具即可。

#### 方式一：Configure 时裁剪（推荐）

```cmd
REM 最小配置：只编译静态库，跳过测试、模块、文档
perl Configure VC-WIN64A no-tests no-module no-legacy no-shared no-makedepend no-docs

REM 或：保留动态库，只跳过测试
perl Configure VC-WIN64A no-tests no-makedepend
```

| 参数 | 效果 | 节省 |
|------|------|------|
| `no-tests` | 跳过 307 个测试程序 | ⭐⭐⭐ 最大头 |
| `no-module` | 跳过动态引擎（`engines/*.dll`） | ⭐⭐ |
| `no-legacy` | 跳过低版本遗留算法 | ⭐⭐ |
| `no-shared` | 只编译静态库，不编 DLL | ⭐⭐ |
| `no-makedepend` | 跳过 C 头文件依赖扫描 | ⭐ |
| `no-asm` | 用 C 代替手写汇编 | ⭐（编译快但运行慢） |
| `no-deprecated` | 跳过已废弃的 API | ⭐ |
| `no-docs` | 跳过文档生成 | —（本身不耗时） |

#### 方式二：指定 Makefile 构建目标

Configure 之后，可以不跑全量 `nmake`，只编译你需要的部分：

```cmd
nmake build_libs          REM 只编 libcrypto + libssl（最快）
nmake build_apps          REM 只编 apps/openssl.exe
nmake build_libs build_apps  REM 库 + 命令行工具（推荐日常使用）
```

构建目标层级关系：

```
build_sw  (默认，nmake 不带参数等价于此)
  ├── build_libs        → libcrypto + libssl
  ├── build_modules     → providers + engines
  └── build_programs    → build_apps + build_tests
        ├── build_apps  → openssl.exe
        └── build_tests → 307 个测试 .exe
```

> **日常开发推荐组合：**
> ```
> perl Configure VC-WIN64A no-tests no-makedepend
> nmake
> ```
> 跳过测试即可节省大量时间，库和 openssl.exe 照常编译。

### 清理命令

```cmd
nmake clean       REM 删除编译产物，保留 Makefile 和配置
nmake distclean   REM 删除所有生成文件，恢复到 Configure 之前
```

| 命令 | 删除内容 | 保留内容 | 重编译方式 |
|------|---------|---------|-----------|
| `nmake clean` | 所有 `.obj`、`.lib`、`.dll`、`.exe` | `Makefile`、配置头文件 | 直接 `nmake` |
| `nmake distclean` | 上述 + `Makefile`、配置头文件 | 只有原始源码 | 需重新 `perl Configure` |

### MSVC 编译产物清单

核心产物位于源码根目录 `E:\AI-Tech\Tongsuo\`：

| 文件 | 类型 | 说明 |
|------|------|------|
| `libcrypto.lib` | 静态库 / 导入库 | 加密库 |
| `libssl.lib` | 静态库 / 导入库 | SSL/TLS 库 |
| `libcrypto-3-x64.dll` | 动态库 | 加密库运行时 |
| `libssl-3-x64.dll` | 动态库 | SSL 库运行时 |
| `apps/openssl.exe` | 可执行文件 | 命令行工具 |

> **注意：** MSVC 下 `.lib` 可能是静态库也可能是 DLL 导入库（取决于是否启用 `no-shared`），不像 MinGW 用 `.a`/`.dll.a` 明确区分。

---

## 方案二：MinGW-w64 (MSYS2)

### 环境要求

| 工具 | 说明 |
|------|------|
| **MSYS2** | 从 <https://www.msys2.org/> 安装 |
| **GCC (MinGW-w64)** | UCRT64 工具链，`pacman -S mingw-w64-ucrt-x86_64-gcc` |
| **Perl** | MSYS2 自带 |
| **make** | `pacman -S make` |
| **NASM** | `pacman -S nasm` |

### ⚠️ 必须在 MSYS2 UCRT64 原生 Shell 中编译

**不要在 Git Bash 中直接执行 `make`！** Git Bash 的 `/usr/bin/as`（汇编器）与 MinGW-w64 GCC 不兼容，会导致：

```
Cannot create temporary file in C:\WINDOWS\: Permission denied
make[1]: *** Error 127
```

**正确做法：** 打开 **开始菜单 → MSYS2 → MSYS2 UCRT64**，在其中操作。

如果非要从 Git Bash 调用，必须这样：

```bash
/c/msys64/usr/bin/bash -l -c '
    export MSYSTEM=UCRT64
    export PATH="/ucrt64/bin:/usr/bin:$PATH"
    cd /e/AI-Tech/Tongsuo
    make -j$(nproc)
'
```

### 为什么要这样做

| 组件 | 正确路径 | 错误路径（Git Bash） |
|------|----------|---------------------|
| GCC | `/ucrt64/bin/gcc` | — |
| AS (汇编器) | `/ucrt64/bin/as` | `/usr/bin/as`（Git Bash 自带的） |

GCC 虽然通过 `COMPILER_PATH` 查找 `as`，但 Git Bash 的 PATH 会优先匹配到自己的 `/usr/bin/as`，导致汇编阶段失败。

### 编译步骤

```bash
# 1. 打开 MSYS2 UCRT64 Shell（开始菜单 → MSYS2 UCRT64）

# 2. 安装依赖（仅首次）
pacman -S make nasm

# 3. 配置
cd /e/AI-Tech/Tongsuo
./Configure mingw64

# 4. 编译
make -j$(nproc)
```

### 加速编译

同 MSVC 方案，用 Configure 参数 + 构建目标组合：

```bash
# 最小配置：只编静态库
./Configure mingw64 no-tests no-module no-legacy no-shared no-makedepend

# 只编库 + openssl
make build_libs build_apps -j$(nproc)
```

| 命令 | 产物 |
|------|------|
| `make build_libs` | 只有 `libcrypto.a` + `libssl.a` |
| `make build_apps` | 只有 `apps/openssl.exe` |
| `make build_libs build_apps` | 库 + 命令行工具（推荐日常） |
| `make`（= `make build_sw`） | 全部：库 + 模块 + 程序 + 测试 |

详细参数说明见上方「方案一 → 加速编译」的表格，Configure 参数两种方案通用。

### 清理命令

```bash
cd /e/AI-Tech/Tongsuo

make clean       # 删除编译产物，保留 Makefile 和配置
make distclean   # 删除所有生成文件，恢复到 Configure 之前
```

| 命令 | 删除内容 | 保留内容 | 重编译方式 |
|------|---------|---------|-----------|
| `make clean` | 所有 `.obj`、`.a`、`.dll`、`.exe` | `Makefile`、`configdata.pm`、`.h` 头文件 | 直接 `make` |
| `make distclean` | 上述 + `Makefile`、配置头文件 | 只有原始源码 | 需重新 `./Configure` |

### MinGW 编译产物清单

核心产物位于源码根目录 `E:\AI-Tech\Tongsuo\`：

| 文件 | 类型 | 说明 |
|------|------|------|
| `libcrypto.a` | 静态库 | 加密库 |
| `libssl.a` | 静态库 | SSL/TLS 库 |
| `libcrypto.dll.a` | DLL 导入库 | 加密库 |
| `libssl.dll.a` | DLL 导入库 | SSL 库 |
| `libcrypto-3-x64.dll` | 动态库 | 加密库运行时 |
| `libssl-3-x64.dll` | 动态库 | SSL 库运行时 |
| `apps/openssl.exe` | 可执行文件 | 命令行工具 |

其他子模块：

| 路径 | 说明 |
|------|------|
| `apps/libapps.a` | 应用程序辅助库 |
| `providers/libcommon.a` | Provider 公共库 |
| `providers/libdefault.a` | 默认 Provider |
| `providers/liblegacy.a` | 遗留算法 Provider |
| `engines/*.dll` | 6 个引擎模块 |
| `providers/legacy.dll` | 遗留算法 Provider 模块 |

---

## 编译前后对比（两种方案通用）

### 编译前已有的目录

```
apps/             — 命令行工具源码
Configurations/   — 构建配置模板
crypto/           — 加密库源码
engines/          — 引擎源码
external/         — 外部依赖
fuzz/             — 模糊测试
include/          — 头文件
providers/        — Provider 源码
ssl/              — SSL/TLS 库源码
test/             — 测试代码
util/             — 构建工具脚本
Configure         — 配置脚本
Makefile.in       — Makefile 模板
```

### 编译后新增的文件

#### 配置阶段生成

| 文件 | 说明 |
|------|------|
| `Makefile` | 由 `Makefile.in` 生成的构建文件 |
| `configdata.pm` | 配置数据 Perl 模块 |
| `builddata.pm` | 构建数据 |
| `installdata.pm` | 安装数据 |
| `include/openssl/configuration.h` | 平台配置头文件 |
| `include/crypto/bn_conf.h` | 大数配置 |
| `include/crypto/dso_conf.h` | DSO 配置 |
| `include/internal/param_names.h` | 参数名头文件 |
| `include/openssl/comp.h` | 压缩头文件 |
| `include/openssl/core_names.h` | 核心名称 |
| `crypto/params_idx.c` | 参数索引 |

#### MinGW 编译阶段生成

| 类别 | 数量 | 位置 |
|------|------|------|
| `.obj` 文件 | **2582** 个 | 遍布 `crypto/`、`ssl/`、`apps/`、`providers/`、`test/`、`engines/`、`fuzz/` |
| `.a` 静态库 | **10** 个 | 根目录、`apps/`、`providers/`、`test/` |
| `.dll` 动态库 | **17** 个 | 根目录、`apps/`、`engines/`、`providers/`、`test/`、`fuzz/` |
| `.exe` 可执行文件 | **~338** 个 | `apps/`（1）、`test/`（307）、`fuzz/`（~30） |
| `.pc` pkg-config | **3** 个 | 根目录 |

> MSVC 下 `.a` 换成 `.lib`，`.obj` 和 `.exe` 数量相近。总体规模相当。

---

## 两种方案对比

| | VS 2022 (MSVC) | MinGW-w64 |
|------|------|------|
| 编译命令 | `nmake` | `make` |
| Configure 目标 | `VC-WIN64A` | `mingw64` |
| 静态库后缀 | `.lib` | `.a` |
| 导入库后缀 | `.lib`（与静态库同名） | `.dll.a`（明确区分） |
| 运行时依赖 | VC 运行时（系统自带） | UCRT64 运行时 DLL |
| 与 Windows 生态集成 | 原生、最佳 | 可接受 |
| 清理命令 | `nmake clean` / `nmake distclean` | `make clean` / `make distclean` |
| 推荐场景 | 配合 VS 项目开发 | 配合同理 Unix 的开发环境 |
