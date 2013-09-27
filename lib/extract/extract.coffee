intuitExtractor = require "./providers/intuit_extractor.coffee"
xeroExtractor = require "./providers/xero_extractor.coffee"

extractObjects = (options = {}, cb) ->
  switch options.provider.toUpperCase()
    when "QBD"
      intuitExtractor options, cb
    when "QBO"
      intuitExtractor options, cb
    when "XERO"
      xeroExtractor options, cb


extract = (options = {}, cb) ->
  switch options.grain
    when "daily"
      console.log "grain daily"
    when "monthly"
      console.log "grain daily"
  extractObjects options, cb


module.exports = extract