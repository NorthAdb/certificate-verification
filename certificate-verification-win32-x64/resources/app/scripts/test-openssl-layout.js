/**
 * CLI smoke test for app OpenSSL layout (same env as index.html).
 * Covers mlkemdsa + aigis sample chains.
 */
const path = require('path')
const fs = require('fs')
const { execFileSync } = require('child_process')

const appRoot = path.join(__dirname, '..')
const opensslExe = path.join(appRoot, 'tongsuo', 'bin', 'openssl.exe')
const providers = path.join(appRoot, 'providers')

function writeConf () {
  const mod = function (name) {
    return path.join(providers, name).replace(/\\/g, '/')
  }
  const cnf = [
    'config_diagnostics = 0',
    'openssl_conf = openssl_init',
    '',
    '[openssl_init]',
    'providers = provider_sect',
    '',
    '[provider_sect]',
    'default = default_sect',
    'pqmagic = pqmagic_sect',
    'ml_dsa_sm2 = ml_dsa_sm2_sect',
    'cert_verify = cert_verify_sect',
    'aigis = aigis_sect',
    '',
    '[default_sect]',
    'activate = 1',
    '',
    '[pqmagic_sect]',
    'module = ' + mod('pqmagic.dll'),
    'activate = 1',
    '',
    '[ml_dsa_sm2_sect]',
    'module = ' + mod('libml_dsa_sm2_provider.dll'),
    'activate = 1',
    '',
    '[cert_verify_sect]',
    'module = ' + mod('cert_verify.dll'),
    'activate = 1',
    '',
    '[aigis_sect]',
    'module = ' + mod('aigis.dll'),
    'activate = 1',
    ''
  ].join('\n')
  const outDir = path.join(appRoot, 'config')
  fs.mkdirSync(outDir, { recursive: true })
  fs.writeFileSync(path.join(outDir, 'openssl-all-providers.cnf'), cnf, 'utf8')
}

function env () {
  const sep = path.delimiter
  return Object.assign({}, process.env, {
    PATH: [path.join(appRoot, 'tongsuo', 'bin'), process.env.PATH].join(sep),
    OPENSSL_CONF: path.join(appRoot, 'config', 'openssl-all-providers.cnf'),
    OPENSSL_MODULES: providers,
    PQMAGIC_STD_LIB: path.join(providers, 'pqmagic.dll'),
    CERT_VERIFY_SO: path.join(providers, 'cert_verify.dll'),
    AIGIS_PROVIDER: path.join(providers, 'aigis.dll'),
    CERT_VERIFY_VERIFY_INFO: '1'
  })
}

function run (args) {
  return execFileSync(opensslExe, args, { cwd: appRoot, env: env(), encoding: 'utf8' })
}

const chains = [
  ['Pure PQC Certificate', 'mlkemdsa'],
  ['Hybrid Concatenated Certificate', 'mlkemdsa'],
  ['Hybrid Using Extensions Certificate', 'mlkemdsa'],
  ['Pure PQC Certificate', 'aigis'],
  ['Hybrid Concatenated Certificate', 'aigissm2'],
  ['Hybrid Using Extensions Certificate', 'sm2extaigis']
]

writeConf()

let failed = 0
console.log('--- providers ---')
try {
  console.log(run(['list', '-providers']))
} catch (e) {
  failed++
  console.error('list -providers FAIL', e.stderr || e.message)
}

for (const [family, set] of chains) {
  const label = family + '/' + set
  const base = path.join(appRoot, 'certs', family, set)
  const root = path.join(base, 'root.crt')
  const untrusted = path.join(base, 'yunying.crt')
  const cert = path.join(base, 'user_sig.crt')
  if (!fs.existsSync(cert)) {
    console.log('SKIP missing:', label)
    continue
  }
  try {
    const text = run(['x509', '-in', cert, '-noout', '-subject'])
    if (/Unable to load Public Key/i.test(text)) throw new Error('Unable to load Public Key')
    const out = run(['verify', '-CAfile', root, '-untrusted', untrusted, cert])
    console.log(label + ' OK:', out.trim().split(/\r?\n/).pop())
  } catch (e) {
    failed++
    console.error(label + ' FAIL:', e.stdout || e.message, e.stderr || '')
  }
}
process.exit(failed ? 1 : 0)
