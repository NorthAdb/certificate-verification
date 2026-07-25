/**
 * CLI smoke test for app OpenSSL layout (same env as index.html).
 */
const path = require('path')
const fs = require('fs')
const { execFileSync } = require('child_process')

const appRoot = path.join(__dirname, '..')
const opensslExe = path.join(appRoot, 'tongsuo', 'bin', 'openssl.exe')
const providers = path.join(appRoot, 'providers')

function env () {
  const sep = path.delimiter
  return Object.assign({}, process.env, {
    PATH: [path.join(appRoot, 'tongsuo', 'bin'), path.join(appRoot, 'tongsuo', 'lib'), process.env.PATH].join(sep),
    OPENSSL_CONF: path.join(appRoot, 'config', 'openssl-all-providers.cnf'),
    OPENSSL_MODULES: providers,
    PQMAGIC_STD_LIB: path.join(providers, 'pqmagic.dll'),
    CERT_VERIFY_SO: path.join(providers, 'cert_verify.dll'),
    CERT_VERIFY_VERIFY_INFO: '1'
  })
}

function run (args) {
  return execFileSync(opensslExe, args, { cwd: appRoot, env: env(), encoding: 'utf8' })
}

let failed = 0
for (const set of ['1', '2', '3']) {
  const base = path.join(appRoot, 'certs', set)
  const root = path.join(base, 'root.crt')
  const untrusted = path.join(base, 'yunying.crt')
  const leaf = set === '2' ? 'user_enc.crt' : 'user_sig.crt'
  const cert = path.join(base, leaf)
  try {
    const out = run(['verify', '-CAfile', root, '-untrusted', untrusted, cert])
    console.log('certs/' + set + ' OK:', out.trim())
  } catch (e) {
    failed++
    console.error('certs/' + set + ' FAIL:', e.stdout || e.message, e.stderr || '')
  }
}
process.exit(failed ? 1 : 0)
