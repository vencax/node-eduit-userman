
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    user =
      username: 'gandalf2'
      realname: 'gandalf the gray'
      email: 'g@nda.lf'
      password: 'secretwhisper'
      gid: 2
      groups: [3, 4]

  it "must not login without username", (done) ->
    o = _getObj()
    execenv.stdout = o.password
    request "POST", "#{s}/user/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201

      withoutname = _getObj()
      delete withoutname['username']

      request "POST", "#{s}/login/", withoutname, (err, res) ->
        return done err if err
        res.statusCode.should.eql 401
        done()

  it "must not login without passwd", (done) ->
    without = _getObj()
    delete without['password']

    request "POST", "#{s}/login/", without, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must not login with wrong username", (done) ->
    o = _getObj()
    o.username = 'NOTexists'
    execenv.stdout = 'TotalyDifferentHash'

    request "POST", "#{s}/login/", o, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must not login with wrong password", (done) ->
    o = _getObj()
    o.password = 'NOTexists'

    request "POST", "#{s}/login/", o, (err, res) ->
      return done err if err
      res.statusCode.should.eql 401
      done()

  it "must login with right credentials", (done) ->
    o = _getObj()
    execenv.stdout = o.password

    request "POST", "#{s}/login/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.username.should.eql o.username
      should.exist body.token
      should.exist body.groups
      body.groups.length.should.eql 2
      done()

  # check
  it "must return no errors on valid user", (done) ->
    o = _getObj()
    o.username = 'NOTexists'

    request "POST", "#{s}/check", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.should.eql []
      done()

  it "must indicate that username already exists", (done) ->
    o = _getObj()

    request "POST", "#{s}/check", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.should.eql [1]
      done()

  it "must return logon script according group m-ship", (done) ->
    o = _getObj()

    request "GET", "#{s}/logonscript/#{o.username}", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      console.log body
      body.indexOf("group 0").should.be.above 0
      body.indexOf("group 1").should.be.above 0
      body.indexOf("group 2").should.be.above 0
      done()

  it "must return logon information for gina login", (done) ->
    o = _getObj()

    request "POST", "#{s}/ginalogin/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      parts = body.split('\n')
      console.log parts
      parts[0].should.eql ""
      parts[1].should.eql o.username
      parts[2].should.eql o.realname
      parts[3].should.eql o.email
      parts[4].indexOf("group 0").should.be.above -1
      parts[4].indexOf("group 1").should.be.above -1
      parts[4].indexOf("group 2").should.be.above -1
      done()
