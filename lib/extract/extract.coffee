moment = require "moment"
errorModel = require "../../lib/db/models/error"
intuitExtractor = require("./providers/intuit_extractor").extract
xeroExtractor = require("./providers/xero_extractor").extract

extractObjects = (options = {}, cb) ->
  switch options.provider.toUpperCase()
    when "QB"
      intuitExtractor options, cb
    when "XERO"
      xeroExtractor options, cb

extract = (options = {}, cb) ->
  if options.since
    date = moment options.since
    switch options.grain
      when "monthly"
        date.month(0)
    options.since = date

  extractCb = (err, data) ->
    if err
      message =
        type: "extract"
        batch_id: options.batch.options._id
        company_id: options.companyId
        source_connection_id: options.batch.options.source_connection_id
        destination_connection_id: options.batch.options.destination_connection_id
        batch_start: options.batch.options.created_at
        message: JSON.stringify(err)
      errorModel::create(message)
    cb(err, data)

  extractObjects options, extractCb

module.exports = extract