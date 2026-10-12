# BESTI-PQC-certificates 文件说明

## 1. 文档目的

本文档说明目录文件中生成的根 CA、运营 CA、两套终端证书、私钥、证书请求、证书吊销列表（CRL）以及 CA 状态文件的用途。

本证书集合具有以下统一规则：

- 根 CA、运营 CA和终端证书的有效期均为 `3650` 天，即 10 年。
- 同一套根 CA 和运营 CA 分别签发 `student01`、`student02` 两套终端证书。
- `student01` 的终端签名证书和终端加密证书已吊销。
- `student02` 的终端签名证书和终端加密证书保持有效。
- 普通、纯净、串联和扩展证书使用一份运营 CA CRL；变色龙证书分别生成基础证书 CRL 和差量证书 CRL。

## 2. 总体目录结构

```text
/BESTI-PQC-certificates/
├── 01-sm2/
├── 02-int-pqc-pure/
├── 03a-sm-pqc-pure-aigis/
├── 03b-sm-pqc-pure-lac/
├── 04-int-pqc-serial/
├── 05-int-pqc-extension/
├── 06-int-pqc-chameleon/
├── 07a-sm-pqc-serial-aigis/
├── 07b-sm-pqc-serial-lac/
├── 08a-sm-pqc-extension-aigis/
├── 08b-sm-pqc-extension-lac/
├── 09a-sm-pqc-chameleon-aigis/
└── 09b-sm-pqc-chameleon-lac/
```

目录关键字含义：

| 关键字 | 含义 |
| --- | --- |
| `int` | 国际 PQC 算法，即 ML-DSA 和 ML-KEM |
| `sm` | 国内 PQC 算法，即 Aigis 或 Aigis+LAC |
| `pure` | 纯净 PQC 证书，不组合 SM2 公钥和签名 |
| `serial` | PQC 与 SM2 公钥、签名采用串联组合 |
| `extension` | 外层为 SM2 证书，PQC 信息保存在扩展项中 |
| `chameleon` | SM2 基础证书携带 DCD，可得到对应的 PQC 差量证书 |
| `aigis` | 加密证书的 PQC 加密算法为 Aigis-Enc-1 |
| `lac` | 加密证书的 PQC 加密算法为 LAC-128 |

## 3. 证书主题

| 证书体系 | 根 CA 的 CN | 运营 CA 的 CN |
| --- | --- | --- |
| SM2 | `BESTI SM2 Root CA` | `BESTI SM2 CA` |
| 国际纯净 PQC | `BESTI Int PQC Root CA` | `BESTI Int PQC CA` |
| 国际 PQC 混合 | `BESTI Int PQC Hybrid Root CA` | `BESTI Int PQC Hybrid CA` |
| 国内纯净 PQC | `BESTI SM PQC Root CA` | `BESTI SM PQC CA` |
| 国内 PQC 混合 | `BESTI SM PQC Hybrid Root CA` | `BESTI SM PQC Hybrid CA` |

## 4. 通用文件类型

| 文件或后缀 | 说明 |
| --- | --- |
| `*.key` | 私钥文件，必须保密，不能作为公开测试材料分发 |
| `*.csr` | 证书签名请求，包含申请者主题和公钥信息 |
| `*.crt` | PEM 编码的 X.509 证书 |
| `*.crl` | PEM 编码的证书吊销列表 |
| `*_base.crt` | 变色龙基础证书，主体公钥为 SM2，并携带 DCD 扩展 |
| `*_delta.crt` | 变色龙差量证书，主体公钥为 PQC 公钥 |

## 5. 证书体系汇总

| 目录 | 证书形态 | 签名算法体系 | 加密/KEM 算法体系 | 吊销文件 |
| --- | --- | --- | --- | --- |
| `01-sm2` | 传统 | SM2/SM3 | SM2 | `ca.crl` |
| `02-int-pqc-pure` | 纯净 PQC | ML-DSA-44 | ML-KEM-512 | `ca.crl` |
| `03a-sm-pqc-pure-aigis` | 纯净 PQC | Aigis-Sig-1 | Aigis-Enc-1 | `ca.crl` |
| `03b-sm-pqc-pure-lac` | 纯净 PQC | Aigis-Sig-1 | LAC-128 | `ca.crl` |
| `04-int-pqc-serial` | 串联 | ML-DSA-44+SM2 | ML-KEM-512+SM2 | `ca.crl` |
| `05-int-pqc-extension` | 扩展 | SM2 外层+ML-DSA 扩展 | SM2 外层+ML-KEM 扩展 | `ca.crl` |
| `06-int-pqc-chameleon` | 变色龙 | SM2 基础+ML-DSA 差量 | SM2 基础+ML-KEM 差量 | `ca_base.crl`、`ca_delta.crl` |
| `07a-sm-pqc-serial-aigis` | 串联 | Aigis-Sig-1+SM2 | Aigis-Enc-1+SM2 | `ca.crl` |
| `07b-sm-pqc-serial-lac` | 串联 | Aigis-Sig-1+SM2 | LAC-128+SM2 | `ca.crl` |
| `08a-sm-pqc-extension-aigis` | 扩展 | SM2 外层+Aigis 扩展 | SM2 外层+Aigis-Enc 扩展 | `ca.crl` |
| `08b-sm-pqc-extension-lac` | 扩展 | SM2 外层+Aigis 扩展 | SM2 外层+LAC 扩展 | `ca.crl` |
| `09a-sm-pqc-chameleon-aigis` | 变色龙 | SM2 基础+Aigis 差量 | SM2 基础+Aigis-Enc 差量 | `ca_base.crl`、`ca_delta.crl` |
| `09b-sm-pqc-chameleon-lac` | 变色龙 | SM2 基础+Aigis 差量 | SM2 基础+LAC 差量 | `ca_base.crl`、`ca_delta.crl` |

## 6.相关说明

### 6.1 混合证书与私钥文件的对应关系

PQC混合证书（串联、扩展、变色龙）中，一个终端证书对应两个私钥文件，分别是SM2私钥和PQC私钥。

以SM2+Aigis混合串联证书为例：

​	student01_sig.crt  终端签名证书，对应

​		student01_sig_aigis.key  终端Aigis签名私钥

​		student01_sig_sm2.key  终端SM2签名私钥

​	student01_enc.crt  终端加密证书，对应

​		student01_enc_aigis.key  终端Aigis加密私钥

​		student01_enc_sm2.key  终端SM2加密私钥

### 6.2 私钥封装格式

SM2私钥：PKCS#8 ASN.1 DER格式封装后，做base64编码

PQC私钥：底层算法生成完整原始私钥字节串后，做base64编码

### 6.3 变色龙base证书和delta证书

- 哪个是变色龙证书？

​	base证书就是变色龙证书，对外可直接使用base证书。

- base证书是什么？

​	base 证书是对外主要使用的基础证书，采用SM2算法：

​		主体公钥是 SM2 公钥，证书由 SM2 体系签名，外形接近普通 X.509 证书。

​		包含一个特殊的 `deltaCertificateDescriptor`（DCD）扩展。DCD 扩展记录了 Delta 证书与 Base 证书之间不同的部分，例如：Delta 证书的 PQC 公钥、PQC 算法标识、Delta 证书签名信息、其他需要替换的证书字段。

- delta证书是什么？

  delta 证书是与 base 证书对应的 PQC 证书：

  ​	签名证书使用 Aigis-Sig 或 ML-DSA 公钥。

  ​	加密证书使用 Aigis-Enc、LAC 或 ML-KEM 公钥。

  ​	由对应的 PQC CA 签名。

  ​	本身也是一个完整的 PEM X.509 证书。

​	生成base证书后，额外做了一步还原操作，还原出了delta证书。
