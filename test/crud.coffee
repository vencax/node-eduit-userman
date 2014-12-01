
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    user =
      username: 'gandalf'
      first_name: 'gandalf'
      last_name: 'the gray'
      email: 'g@nda.lf'
      password: 'secretwhisper'

  created = undefined

  it "must not create if requred param (username) is missing", (done) ->
    withoutname = _getObj()
    delete withoutname['username']

    request.post "#{s}/user/", {form: withoutname}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "must not create if requred param passwd is missing", (done) ->
    without = _getObj()
    delete without['password']

    request.post "#{s}/user/", {form: without}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "should create new item on right POST request", (done) ->
    o = _getObj()
    
    request.post "#{s}/user/", {form: o}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201
      res.should.be.json
      body = created = JSON.parse(body)
      should.exist body.id
      should.not.exist body.password
      body.username.should.eql o.username
      body.email.should.eql o.email
      done()

  it "must not create if already exists in DB", (done) ->
    h = _getObj()

    request.post "#{s}/user/", {form: h}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "shall return the loaded list", (done) ->
    request "#{s}/user/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.length.should.eql 1
      body[0].username.should.eql _getObj().username
      done()

  it "shall return 404 on get nonexistent", (done) ->
    request "#{s}/user/22222", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()


  it "shall return object with given ID", (done) ->
    request "#{s}/user/#{created.id}/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      should.exist body.id
      should.not.exist body.password
      body.username.should.eql created.username
      body.email.should.eql created.email
      done()

  changed =
    last_name: "The white!!"

  it "shall update item with given ID with desired values", (done) ->
    request.put "#{s}/user/#{created.id}/", {form: changed}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.last_name.should.eql changed.last_name
      done()

  it "shall return 404 on updating nonexistent item", (done) ->
    request.put "#{s}/user/22222/", {form: changed}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()

  it "shall return 404 on removing nonexistent item", (done) ->
    request.del "#{s}/user/22222/", {form: changed}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()

  it "shall return 200 on removing the created", (done) ->
    request.del "#{s}/user/#{created.id}/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      done()
