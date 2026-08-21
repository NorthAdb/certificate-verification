# 证书验证工具 — 独立运行说明

本目录 **自包含** 全部运行时，**不需要** 同级的 `tlcp-pqc` 文件夹即可使用。

## 使用方式

1. 将整个 `certificate-verification-win32-x64` 文件夹复制到任意位置（U 盘、其他电脑均可）
2. 双击 **`证书验证.exe`**
3. 在界面「加载示例」中选择 certs/1、2 或 3，点击「查看证书」或「验证证书」

## 内置资源（均在 `resources/app/`）

| 目录 | 内容 |
|------|------|
| `tongsuo/bin/` | Tongsuo `openssl.exe` + `libcrypto-3-x64.dll`、`libssl-3-x64.dll` |
| `providers/` | pqmagic、cert_verify、ml_dsa_sm2、aigis |
| `config/` | `openssl-all-providers.cnf`（启动时按实际路径自动生成） |
| `certs/1,2,3/` | 三套 PQC/混合示例证书 |

## 开发与更新（可选）

仅当需要 **从源码重新编译** Tongsuo/provider 时才需要 `tlcp-pqc` 仓库，然后执行：

```cmd
scrpts\layout-app-resources.bat
```

普通用户 **无需** `tlcp-pqc`。

## 开发模式

```cmd
cd resources\app
npm install
npm start
```

## 命令行自测（可选）

```cmd
node resources\app\scripts\test-openssl-layout.js
```

三套证均应输出 `OK`。
