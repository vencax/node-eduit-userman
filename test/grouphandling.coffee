
should = require('should')


module.exports = (s, request, execenv) ->

  _getObj = ->
    user =
      username: 'legolas'
      email: 'legolas@nda.lf'
      password: 'secretwhisper'
      gid: 2
      groups: [3, 4]

  created = null

  it "should create new user legolas", (done) ->
    o = _getObj()
    this.timeout(0)

    request 'POST', "#{s}/user/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201
      res.should.be.json
      body = created = JSON.parse(body)

      setTimeout () ->
        request 'GET', "#{s}/user/#{body.id}/", (err, res, body) ->
          return done err if err
          res.statusCode.should.eql 200
          body = JSON.parse(body)
          should.exist body.id
          should.not.exist body.password
          body.username.should.eql o.username
          body.gid.should.eql o.gid
          body.groups.should.eql o.groups
          done()
      , 800

  it "shall update legolas's groups", (done) ->
    changed =
      gid: 3
      groups: [2]

    request 'PUT', "#{s}/user/#{created.id}/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.gid.should.eql changed.gid
      body.groups.should.eql changed.groups

      setTimeout () ->
        # console.log execenv.res
        # execenv.res.length.should.eql 0
        # lets try to login with da new pwd ...
        request 'GET', "#{s}/user/#{created.id}/", (err, res, body) ->
          return done err if err
          res.statusCode.should.eql 200
          body = JSON.parse(body)
          body.gid.should.eql changed.gid
          body.groups.should.eql changed.groups
          done()
      , 400

  # it "shall return all users with their groups", (done) ->
  #   request 'GET', "#{s}/user/", (err, res, body) ->
  #     return done err if err
  #     res.statusCode.should.eql 200
  #     body = JSON.parse(body)
  #     console.log body
  #     for u in body
  #       should.not.exist u.password
  #     done()
