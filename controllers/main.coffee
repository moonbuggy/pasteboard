###
# Main (Index) Controller
###
fs = require "fs-extra"
async = require "async"
undici = require "undici"
formidable = require "formidable"
auth = require "../auth"
helpers = require "../helpers/common"
useragent = require "useragent"
readinessManager = require "readiness-manager"

FILE_SIZE_LIMIT = 10 * 1024 * 1024 # 10 MB

get = {}
post = {}

# The index page
get.index = (req, res) ->
  viewData =
    port: req.app.get "port"
    redirected: false
    useAnalytics: false
    trackingCode: ""
    browser: useragent.parse(req.headers["user-agent"]).family
    uploads: []

  # Use Google Analytics when not running locally
  if not req.app.get("localrun") and auth.google_analytics
    viewData.useAnalytics = true
    viewData.trackingCode =
      if req.app.settings.env is "development"
      then auth.google_analytics.development
      else auth.google_analytics.production

  # Check cookies for recent uploads
  for name, value of req.cookies
    continue unless /^pb_/.test name
    image = name.replace("pb_", "")

    viewData.uploads.push {
      link: image,
      raw: helpers.imageURL req, image
    }

  # Show a welcome banner for redirects from PasteShack
  if req.cookies.redirected
    viewData.redirected = true
    res.clearCookie "redirected"

  res.render "index", viewData

# Handle redirects from PasteShack
get.redirected = (req, res) ->
  res.cookie "redirected", true
  res.redirect "/"

# Proxy for external images, used get around
# cross origin restrictions
get.imageProxy = (req, res) ->
  # undici stream
  undici.stream (decodeURIComponent req.params.image)

  , ({ statusCode, headers, opaque }) ->
    res.status statusCode
    res.set headers
    return res

  , (err) ->
    console.log 'ERROR', err
    res.send "Failure", 500

  # undici request
  # undici.request (decodeURIComponent req.params.image)
  # .then (response) ->
  #   response.pipe res
  # .catch(err) ->
  #   res.send "Failure", 500

get.statusCheck = (req, res) ->
  status =
    uptime: process.uptime()
    timestamp: Date.now()
    message: 'OK'
    readiness: readinessManager.status()
    ready: readinessManager.ready
  try
    res.send status
  catch error
    statuscheck.message = error
    res.status(503).send(status)

# Preuploads an image and stores it in /tmp
post.preupload = (req, res) ->
  form = new formidable.IncomingForm()
  incomingFiles = []

  form.on "fileBegin", (name, file) ->
    incomingFiles.push file

  form.on "aborted", ->
    # Remove temporary files that were in the process of uploading
    for file in incomingFiles
      fs.unlink file.filepath, (-> )

  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id]
    if client
      # Remove the old file
      fs.unlink(client.file.filepath, (-> )) if client.file
      client.file = files.file

    res.send "Received file"

# Upload the file to the cloud (or to a local folder).
# If the file has been preuploaded, upload that, else
# upload the file that should have been posted with the
# request.
post.upload = (req, res) ->
  form = new formidable.IncomingForm()
  knox = req.app.get "knox-mime"
  incomingFiles = []

  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id] if fields.id

    # Check for either a posted or preuploaded file
    if files.file
      file = files.file
    else if client and client.file and not client.uploading[client.file.filepath]
      file = client.file
      client.uploading[file.filepath] = true

    unless file
      console.log("Missing file")
      return res.send "Missing file", 500

    if file.size > FILE_SIZE_LIMIT
      console.log("File too large")
      return res.send "File too large", 500

    fileName = helpers.generateFileName(file.mimetype.replace "image/", "")
    domain = if req.app.get "localrun" then req.headers.host else req.app.get "domain"
    protocol = req.protocol
    longURL = "#{protocol}://#{domain}/#{fileName}"
    sourcePath = file.filepath

    parallels = {}
    if knox
      # Upload to amazon
      parallels.upload = (callback) ->
        knox.putFile(
          sourcePath,
          "#{req.app.get "amazonFilePath"}#{fileName}",
            "Content-Type": file.mimetype
            "x-amz-acl": "private"
          ,
          callback
        )
    else
      # Upload to local file storage
      parallels.upload = (callback) ->
        fs.move(
          sourcePath,
          "#{req.app.get "localStorageFilePath"}#{fileName}",
          callback
        )

    series = []
    if fields.cropImage
      series.push (callback) ->
        cropPath = "/tmp/#{fileName}"
        require("easyimage").crop(
          src: sourcePath
          dst: cropPath
          cropwidth: fields["crop[width]"]
          cropheight: fields["crop[height]"]
          x: fields["crop[x]"]
          y: fields["crop[y]"]
          gravity: "NorthWest"
        , ->
          fs.unlink sourcePath, (-> )
          sourcePath = cropPath
          callback null
        )

    series.push (callback) ->
      async.parallel parallels, (err, results) ->
        if err
          console.log err
          return res.send "Failed to upload file", 500

        fs.unlink sourcePath, (-> )
        helpers.setImageOwner res, fileName
        res.json
          url: longURL
        callback null

    async.series series

  form.on "fileBegin", (name, file) ->
    incomingFiles.push file

  form.on "aborted", ->
    # Remove temporary files that were in the process of uploading
    fs.unlink(incomingFile.filepath, (-> ))  for incomingFile in incomingFiles


# Remove a preuploaded file from the given client ID, called
# whenever an image is discarded or the user leaves the site
post.clearfile = (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id]
    if client and client.file
      fs.unlink client.file.filepath, (-> )
      client.file = null;
    res.send "Cleared"

exports.routes =
  get:
    "": get.index
    "redirected": get.redirected
    "imageproxy/:image": get.imageProxy
    "status": get.statusCheck
  post:
    "upload": post.upload
    "clearfile": post.clearfile
    "preupload": post.preupload
