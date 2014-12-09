
should = require('should')


module.exports = (s, request, execenv) ->

  beforeEach (done) ->
    # console.log("\n... Resetting execenv")
    # for i in execenv.res
    #   console.log i[0]
    execenv.res = []
    done()

  it "must create all this groups for further tests", (done) ->
    for i in [0..3]
      request 'POST', "#{s}/group/", {name: "group #{i}"}, (err, res) ->
        return done err if err
        res.statusCode.should.eql 201
    setTimeout () ->
      done()
    , 400
