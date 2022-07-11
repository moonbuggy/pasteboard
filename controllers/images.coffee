###
# Images Controller
###
undici = require "undici"
auth = require "../auth"
helpers = require "../helpers/common"

get = {}
post = {}

# The image display page
exports.index = get.index = (req, res) ->
  viewData =
    imageName: req.params.image
    imageURL: "/storage/#{req.params.image}"
    longURL: "#{req.app.get("domain")}/#{req.params.image}"
    embedURL: helpers.imageURL req, req.params.image
    useAnalytics: false
    trackingCode: ""
    isImageOwner: helpers.isImageOwner req, req.params.image

  # Use Google Analytics when not running locally
  if not req.app.get("localrun") and auth.google_analytics
    viewData.useAnalytics = true
    viewData.trackingCode =
      if req.app.settings.env is "development"
      then auth.google_analytics.development
      else auth.google_analytics.production

  res.render "image", viewData

# Image download URL
get.download = (req, res) ->
  #undici stream
  undici.stream helpers.imageURL(req, req.params.image),
    headers:
      "Referer": req.headers.referer

    , ({ statusCode, headers, opaque }) ->
      res.status statusCode
      if statusCode==200
        res.append "Content-Disposition", "attachment; filename=#{req.params.image}"

      res.set headers
      return res

    , (err) ->
      console.log 'ERROR', err
      res.status(500).end()

  #undici request
  # imageRequest = undici.request helpers.imageURL(req, req.params.image),
  #   method: 'GET'
  #   headers:
  #     "Referer": req.headers.referer
  #
  # .then (response) ->
  #   res.set "Content-Disposition", "attachment; filename=#{req.params.image}"
  #   response.body.pipe res
  #
  # .catch (error) ->
  #   console.log 'ERROR', error
  #   res.status(500).end()

# Delete the image
post.delete = (req, res) ->
  if helpers.isImageOwner req, req.params.image
    knox = req.app.get "knox-mime"
    if knox
      knox.deleteFile "#{req.app.get "amazonFilePath"}#{req.params.image}", ->
    else
      localPath = "#{req.app.get "localStorageFilePath"}#{req.params.image}"
      require("fs").unlink localPath, (-> )

    if auth.cloudflare
      params =
        url: "https://api.cloudflare.com/client/v4/zones/#{auth.cloudflare.ZONE_ID}/purge_cache"
        json: true
        headers:
          "X-Auth-Email": auth.cloudflare.EMAIL
          "X-Auth-Key": auth.cloudflare.KEY
        body: {
          files: [helpers.imageURL req, req.params.image]
        }
        method: 'DELETE'

      undici.request(params)
        .catch(error) ->
          console.log("Cloudflare error", error)

    helpers.removeImageOwner res, req.params.image
    res.send "Success"

  res.send "Forbidden", 403

exports.routes =
  get:
    ":image/download": get.download
  post:
    ":image/delete": post.delete
