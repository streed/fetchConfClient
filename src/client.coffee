path = require 'path'
log4js = require 'log4js'
request = require 'request'
Q = require 'q'
yaml = require 'js-yaml'
fs = require 'fs'

resolvePath = (string) ->
  if string.substr(0,1) == '~'
    homedir = process.env.HOME
    if process.platform.substr(0, 3) == 'win'
      homedir = process.env.HOMEPATH
    string = homedir + string.substr(1)

  return path.resolve(string)

root = exports ? this
class Client
  instance = null
  @get: (client_id, client_secret, api_url="http://elt.li") ->
    if not instance
      instance = InnerClient.Builder()
        .setClientId(client_id)
        .setClientSecret(client_secret)
        .setApiUri(api_url)
        .build()

    return instance

  @loadLocal: (location) ->
    if not location
      location = '~/.local.config'
    location = resolvePath location
    console.log location
    local = yaml.safeLoad(fs.readFileSync(location, 'utf8'))
    builder = InnerClient.Builder()
      .setClientId local.client_id
      .setClientSecret local.client_secret

    if local.api_url
      builder.setApiUri local.api_url

    return builder.build(local.overrides)

  class InnerClient
    LOG = log4js.getLogger("client")

    class InnerBuilder
      constructor: () ->
        @_clientId = ""
        @_clientSecret = ""
        @_apiUri = "http://elt.li/"

      setClientId: (@_clientId) ->
        @

      setClientSecret: (@_clientSecret) ->
        @
      
      setApiUri: (@_apiUri) ->
        @

      build: (overrides) ->
        client = new InnerClient(@_clientId, @_clientSecret, @_apiUri)
        return client.auth(overrides)

    @Builder: () ->
      return new InnerBuilder

    constructor: (@_clientId, @_clientSecret, @_apiUri) ->

    auth: (overrides) ->
      authDeferred = Q.defer()
      data = {
        grant_type: "client_credentials"
        client_id: @_clientId
        client_secret: @_clientSecret
      }
      self = @
      request.post @_apiUri + "oauth/token", {form: data}, (err, response, body) ->
        body = JSON.parse body
        self._accessToken = body.access_token
        self._refreshToken = body.refresh_token
        self._config = {}
        self._overrides = overrides
        authDeferred.resolve(self)
      return authDeferred.promise

    configs: () ->
      configsDeferred = Q.defer()
      url = @_apiUri + "api/config"
      self = @
      request.get {url: url, headers: { "Authorization": "Bearer "+@_accessToken}}, (err, resp, body) ->
        body = JSON.parse body
        self._config = body
        configsDeferred.resolve(body)
      return configsDeferred.promise

    config: (name...) ->
      configsDeferred = Q.defer()
      name = name.join(",")
      url = @_apiUri + "api/config/" + name
      self = @
      request.get {url: url, headers: { "Authorization": "Bearer "+@_accessToken}}, (err, resp, body) ->
        body = JSON.parse body
        self._config = body
        configsDeferred.resolve(body)
      return configsDeferred.promise

    get: (key) ->
      if key of @_overrides
        return @_overrides[key]
      else
        return @_config[key]

root.Client = Client

