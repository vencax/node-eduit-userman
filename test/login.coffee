
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    user =
      username: 'gandalf'
      first_name: 'gandalf'
      last_name: 'the gray'
      email: 'g@nda.lf'
      password: 'secretwhisper'

  it "must not login without username", (done) ->
    request.post "#{s}/user/", {form: _getObj()}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201

      withoutname = _getObj()
      delete withoutname['username']

      request.post "#{s}/login/", {form: withoutname}, (err, res) ->
        return done err if err
        res.statusCode.should.eql 401
        done()

  it "must not login without passwd", (done) ->
    without = _getObj()
    delete without['password']

    request.post "#{s}/login/", {form: without}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must not login with wrong username", (done) ->
    o = _getObj()
    o.username = 'NOTexists'

    request.post "#{s}/login/", {form: o}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must not login with wrong password", (done) ->
    o = _getObj()
    o.username = 'NOTexists'

    request.post "#{s}/login/", {form: o}, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must login with right credentials", (done) ->
    o = _getObj()

    request.post "#{s}/login/", {form: o}, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.username.should.eql o.username
      should.exist body.token
      done()