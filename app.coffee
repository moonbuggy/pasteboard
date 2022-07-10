###
# Express Bootstrap
###
express = require "express"
async = require "async"
readinessManager = require "readiness-manager"

app = express()

require("./config/environments").init app, express
require("./config/routes").init	app

webServer = []

readinessManager.register 'webServer', ->
  if process.env.HTTPS
    webServer = require("./webserverssl").init app
  else
    webServer = require("./webserver").init app

readinessManager.register 'socketServer', ->
  webSocketServer = require("./websocketserver").init app, webServer

readinessManager.run()

if process.env.READY_FD
  readinessManager.onReady ->
    if isNaN(fd = parseInt(process.env.READY_FD))
      console.error 'ERROR: Cannot signal readiness, invalid file descriptor:', process.env.READY_FD
    else
      console.log "Signalling readiness on file descriptor #{fd}."
      require('fs').createWriteStream(null, {fd: fd}).write("\n")
