assert = require("assert")
Client = require('../src/client').Client

describe 'Client', ->
  describe 'loadLocal', ->
    it 'should load the local file', ->
      Client.loadLocal("./test/test.yml").then (client) ->
        assert.equal 'hello world', client.get('test.key')
        assert.equal undefined, client.get('test.key.no')
