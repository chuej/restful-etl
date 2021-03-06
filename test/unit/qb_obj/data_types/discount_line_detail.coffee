lineTranform = require("../../../../lib/load/providers/activecell/utils/utils").lineTranform
assert  = require("chai").assert

describe "qbd ActiveCell", ->
  describe "DiscountLineDetail", ->
    beforeEach () ->
      @qbdObj =
        Id: "QB:123"
        Amount: 500
        DetailType: "DiscountLineDetail"
        DiscountLineDetail:
          Discount:
            DiscountAccountRef: {value: 'QB:678'}

    it "can find an account based on the discount account ref", ->
      resultObj =
        Id: "QB:123"
        amount_cents: 500
        account_id: "QB:678" #@accountLookup('QB:678')

      assert.deepEqual lineTranform(@qbdObj), resultObj
