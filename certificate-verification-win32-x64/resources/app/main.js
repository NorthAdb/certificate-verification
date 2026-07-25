const { app, BrowserWindow, Menu } = require('electron')

Menu.setApplicationMenu(null)

function createWindow () {
  const win = new BrowserWindow({
    width: 1020,
    height: 900,
    minWidth: 880,
    minHeight: 700,
    title: '抗量子数字证书验证工具',
    webPreferences: {
      nodeIntegration: true,
      enableRemoteModule: true
    }
  })

  win.loadFile('index.html')
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

process.env['ELECTRON_DISABLE_SECURITY_WARNINGS'] = 'true'
