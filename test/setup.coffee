process.env.NODE_ENV = 'test'
{ flow } = require 'lodash'
async = require 'async'
chai = require 'chai'
mockery = require 'mockery'
global.assert = chai.assert
global.expect = chai.expect
global.should = chai.should()
chai.use require 'chai-things'

global.trap = (done, scenario) ->
  (err, res) ->
    [ res, err ] = [ err, undefined ] if arguments.length < 2
    return done err if err?
    try scenario(res) catch err then done err

global.sinon = require 'sinon'

local_dynamo = require 'local-dynamo'
local_dynamo.launch null, 7654

AWS = require 'aws-sdk'
AWS.config.update
  accessKeyId: 'bogus'
  secretAccessKey: 'bogus'
  region: 'us-east-1'
  endpoint: 'http://localhost:7654'
dynamodb = new AWS.DynamoDB()

global.doc_client = new AWS.DynamoDB.DocumentClient()

global.clean_db = (done) ->
  dynamodb.listTables {}, (err, data) ->
    async.each data.TableNames,
      (name, next) ->
        dynamodb.deleteTable TableName: name, next
      (err) ->
        console.log "DB Init error: #{err}" if err?
        require('./test_tables') dynamodb, done
