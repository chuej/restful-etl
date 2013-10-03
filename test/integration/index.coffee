process.env.NODE_ENV ||= "test"
process.env.PORT     ||= 5001

path = require "path"
nock = require "nock"
_ = require "underscore"
Batch = require("../../lib/batch").Batch
intuitExtractor = require("../../lib/extract/providers/intuit_extractor")
connectionModel = require "../../lib/db/models/connection"

app     = require path.join(__dirname, "../../api")
db      = require path.join(__dirname, "../../lib/db")

describe "Check xero extractor", ->
  before (done)->
    connection = db.conn.connection
    connection.on "connected", ->
      connection.db.dropDatabase (err)->
        done()

  it "create a xero connection and receive data", (done)->
    connectioin =
      name: "XERO connection"
      provider: "XERO"
      oauth_consumer_key: "0001"
      oauth_consumer_secret: "0002"
      oauth_access_key: "0003"
      oauth_access_secret: "0004"

    options =
      tenant_id: "tenant_id_test"
      source_connection_id: "source_connection_id"
      destination_connection_id: "destination_connection_id_test"
      jobs: [
        extract:
          object: "Accounts"
      ,
        extract:
          object: "Items"
      ]

    connectionModel::create connectioin, (err, model) ->
      options.source_connection_id = model._id
      nock("https://api.xero.com")
        .get("/api.xro/2.0/Accounts")
        .reply(200, "done");
      nock("https://api.xero.com")
        .get("/api.xro/2.0/Items")
        .reply(200, "done");
      batch = new Batch(options)
      batch.run (err, jobs) ->
        if err then done(err)
        else done()


describe "Check intuit extractor", ->
  it "create a intuit connection and receive data", (done)->
    connectioin =
      name: "intuit connection"
      provider: "QBO"
      oauth_consumer_key: "0001"
      oauth_consumer_secret: "0002"
      oauth_access_key: "0003"
      oauth_access_secret: "0004"
      realm: "12345"

    options =
      tenant_id: "tenant_id_test"
      source_connection_id: "source_connection_id"
      destination_connection_id: "destination_connection_id_test"
      jobs: [
        extract:
          object: "Account"
      ]

    connectionModel::create connectioin, (err, model) ->
      options.source_connection_id = model._id
      nock("https://qb.sbfinance.intuit.com")
        .get("/v3/company/12345/query?query=%20select%20count(*)%20from%20Account")
        .reply(200, '{"QueryResponse":{"totalCount":1},"time":"2013-10-03T05:10:07.823-07:00"}');

      nock("https://qb.sbfinance.intuit.com")
        .get("/v3/company/12345/query?query=%20select%20*,%20MetaData.CreateTime%20from%20Account%20%20startposition%201%20maxresults%20500")
        .reply(200, '{"QueryResponse":{"Account":[{"name":"tempName"}]},"time":"2013-10-03T05:10:07.823-07:00"}');

      batch = new Batch(options)
      batch.run (err, jobs) ->
        if err then done(err)
        else done()

  it "create a intuit connection and receive big data", (done)->
    intuitExtractor.maxResults 1

    connectioin =
      name: "intuit connection 2"
      provider: "QBO"
      oauth_consumer_key: "0001"
      oauth_consumer_secret: "0002"
      oauth_access_key: "0003"
      oauth_access_secret: "0004"
      realm: "12345"

    options =
      tenant_id: "tenant_id_test"
      source_connection_id: "source_connection_id"
      destination_connection_id: "destination_connection_id_test"
      jobs: [
        extract:
          object: "Account"
      ]

    connectionModel::create connectioin, (err, model) ->
      options.source_connection_id = model._id
      nock("https://qb.sbfinance.intuit.com")
        .get("/v3/company/12345/query?query=%20select%20count(*)%20from%20Account")
        .reply(200, '{"QueryResponse":{"totalCount":2},"time":"2013-10-03T05:10:07.823-07:00"}');

      nock("https://qb.sbfinance.intuit.com")
        .get("/v3/company/12345/query?query=%20select%20*,%20MetaData.CreateTime%20from%20Account%20%20startposition%201%20maxresults%201")
        .reply(200, '{"QueryResponse":{"Account":[{"name":"tempName1"}]},"time":"2013-10-03T05:10:07.823-07:00"}');

      nock("https://qb.sbfinance.intuit.com")
        .get("/v3/company/12345/query?query=%20select%20*,%20MetaData.CreateTime%20from%20Account%20%20startposition%202%20maxresults%201")
        .reply(200, '{"QueryResponse":{"Account":[{"name":"tempName2"}]},"time":"2013-10-03T05:10:07.823-07:00"}');

      batch = new Batch(options)
      batch.run (err, jobs) ->
        if err then done(err)
        else
          find = (list, item) ->
            _.find list, (obj) ->
              return true if obj.name is item
              return false
          data = jobs[0].extract._data
          if find(data, "tempName1") and find(data, "tempName2")
            done()
          else
            done("objects not found")
