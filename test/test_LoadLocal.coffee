assert = require("assert")
Client = require('../src/client').Client

describe 'Client', ->
  describe 'loadLocal', ->
    it 'should load the local file', ->
      client = Client.loadLocal("./test/test.yml")
