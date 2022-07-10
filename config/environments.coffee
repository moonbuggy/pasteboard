###
# Environment Configuration
###
auth = require "../auth"
url = require "url"

methodOverride = require "method-override"
cookieParser = require "cookie-parser"
serveFavicon = require "serve-favicon"
errorHandler = require "errorhandler"
morgan = require "morgan"

exports.init = (app, express) ->

  # Use
  app.use serveFavicon("#{__dirname}/../public/images/favicon.ico")
  app.use express.json({ limit: '10MB' });
  app.use morgan("dev") if process.env.LOCAL
  app.use cookieParser()
  app.use methodOverride("X-HTTP-Method")
  app.use methodOverride("X-HTTP-Method-Override")
  app.use methodOverride("X-Method-Override")
  app.use require("connect-assets")(sourceMaps : false)
  app.use express.static("#{__dirname}/../public")

  # Set
  app.set "localrun", process.env.LOCAL or false
  app.set "port", process.env.PORT or 3000

  if process.env.ORIGIN
      app.set "domain", process.env.ORIGIN
      app.set "externalPort", url.parse(process.env.ORIGIN).port or 443
  else
      app.set "domain", "http://pasteboard.co"
      app.set "externalPort", app.get "port"

  # Amazon S3 connection settings (using knox)
  if auth.amazon
    app.set "knox", require("knox-mime").createClient
      key: auth.amazon.S3_KEY,
      secret: auth.amazon.S3_SECRET,
      bucket: auth.amazon.S3_BUCKET
      region: "eu-west-1"

    app.set "amazonFilePath", "/#{auth.amazon.S3_IMAGE_FOLDER}"

  # File storage options when not using Amazon S3
  app.set "localStorageFilePath", "#{__dirname}/../public/storage/"
  app.set "localStorageURL", "/storage/"

  app.set "views", "#{__dirname}/../views"
  app.set "view engine", "ejs"

  app.set "trust proxy", process.env.TRUST_PROXY if process.env.TRUST_PROXY

  # Development
  if app.get('env') == 'development'
    # Use
    app.use errorHandler()

    # Set
    app.set "port", process.env.PORT or 4000
    app.set "domain", "http://dev.pasteboard.co"
