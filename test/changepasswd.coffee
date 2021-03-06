
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    user =
      username: 'gimly'
      email: 'gimly@nda.lf'
      password: 'secretwhisper'
      gid: 2
      groups: [3, 4]

  created = null

  it "should create new user gimly", (done) ->
    o = _getObj()
    this.timeout(0)
    execenv.stdout = o.password

    request 'POST', "#{s}/user/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201
      res.should.be.json
      body = created = JSON.parse(body)
      should.exist body.id
      should.not.exist body.password
      body.username.should.eql o.username
      body.email.should.eql o.email
      setTimeout () ->
        done()
      , 800

  it "shall update gimly's password", (done) ->
    this.timeout(0)

    changed =
      password: "topsecret"
    execenv.stdout = changed.password

    request 'PUT', "#{s}/user/#{created.id}/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      setTimeout () ->
        execenv.res[1][0].should.eql "(echo #{changed.password};" +
          " echo #{changed.password}) | smbpasswd -s gimly"

        # lets try to login with da new pwd ...
        request "POST", "#{s}/login/",
          username: 'gimly'
          password: changed.password
        , (err, res, body) ->
          return done err if err
          res.statusCode.should.eql 200
          body = JSON.parse(body)
          body.username.should.eql 'gimly'
          should.exist body.token
          done()
      , 4000
