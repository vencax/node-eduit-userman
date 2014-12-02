
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    group =
      name: 'elves'

  _post = (url, body, cb) ->
    _makeReq('POST', url, body, cb)

  created = undefined

  it "must not create if requred param (name) is missing", (done) ->
    withoutname = _getObj()
    delete withoutname['name']

    request "POST", "#{s}/group/", withoutname, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "should create new item on right POST request", (done) ->
    o = _getObj()

    request "POST", "#{s}/group/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201
      res.should.be.json
      body = created = JSON.parse(body)
      should.exist body.id
      body.name.should.eql o.name
      done()

  it "must not create if already exists in DB", (done) ->
    h = _getObj()

    request "POST", "#{s}/group/", h, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "shall return the loaded list", (done) ->
    request "GET", "#{s}/group/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.length.should.eql 1
      body[0].name.should.eql _getObj().name
      done()

  it "shall return 404 on get nonexistent", (done) ->
    request "GET", "#{s}/group/22222", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()


  it "shall return object with given ID", (done) ->
    request "GET", "#{s}/group/#{created.id}/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      should.exist body.id
      body.name.should.eql created.name
      done()

  changed =
    name: "dwarves"

  it "shall update item with given ID with desired values", (done) ->
    request 'PUT', "#{s}/group/#{created.id}/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.name.should.eql changed.name
      done()

  it "shall return 404 on updating nonexistent item", (done) ->
    request 'PUT', "#{s}/group/22222/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()

  it "shall return 404 on removing nonexistent item", (done) ->
    request 'DELETE', "#{s}/group/22222/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()

  it "shall return 200 on removing the created", (done) ->
    request 'DELETE', "#{s}/group/#{created.id}/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      done()
