
should = require('should')


module.exports = (s, request, execenv) ->

  beforeEach (done) ->
    # console.log("\n... Resetting execenv")
    # for i in execenv.res
    #   console.log i[0]
    execenv.res = []
    done()

  _getObj = ->
    user =
      username: 'gandalf'
      first_name: 'gandalf'
      last_name: 'the gray'
      email: 'g@nda.lf'
      password: 'secretwhisper'
      gid: 2
      groups: [3, 4]

  created = undefined

  it "must not create if requred param (username) is missing", (done) ->
    withoutname = _getObj()
    delete withoutname['username']

    request 'POST', "#{s}/user/", withoutname, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "must not create if requred param passwd is missing", (done) ->
    without = _getObj()
    delete without['password']

    request 'POST', "#{s}/user/", without, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      done()

  it "should create new user on right POST request", (done) ->
    o = _getObj()
    this.timeout(0)

    request 'POST', "#{s}/user/", o, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 201
      res.should.be.json
      body = created = JSON.parse(body)
      console.log "created user: #{JSON.stringify(created)}"
      should.exist body.id
      should.not.exist body.password
      body.username.should.eql o.username
      body.email.should.eql o.email
      setTimeout () ->
        console.log "verifying background commands ..."
        execenv.res.length.should.eql 3
        execenv.res[0][0].should.eql "mv /home/gandalf /tmp"
        execenv.res[1][0].should.eql "(echo #{o.password};" +
          " echo #{o.password}) | smbpasswd -s -a #{o.username}"
        execenv.res[2][0].should.eql "cp -R /etc/skel /home/gandalf" +
          " && chown -R gandalf:adm /home/gandalf && chmod 770 /home/gandalf"
        done()
      , 800

  it "must not create if already exists in DB", (done) ->
    h = _getObj()

    request 'POST', "#{s}/user/", h, (err, res) ->
      return done err if err
      res.statusCode.should.eql 400
      execenv.res.should.eql []
      done()

  it "shall return the loaded list", (done) ->
    request 'GET', "#{s}/user/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.length.should.eql 1
      body[0].username.should.eql _getObj().username
      done()

  it "shall return 404 on get nonexistent", (done) ->
    request 'GET', "#{s}/user/22222", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      done()


  it "shall return object with given ID", (done) ->
    request 'GET', "#{s}/user/#{created.id}/", (err, res, body) ->
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
    request 'PUT', "#{s}/user/#{created.id}/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      body = JSON.parse(body)
      body.last_name.should.eql changed.last_name
      setTimeout () ->
        execenv.res[0][0].should.eql 'pdbedit --modify -u gandalf' +
          ' --fullname "gandalf The white!!"'
        done()
      , 400

  it "shall return 404 on updating nonexistent item", (done) ->
    request 'PUT', "#{s}/user/22222/", changed, (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      execenv.res.should.eql []
      done()

  it "shall return 404 on removing nonexistent item", (done) ->
    request 'DELETE', "#{s}/user/22222/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 404
      execenv.res.should.eql []
      done()

  it "shall return 200 on removing the created", (done) ->
    request 'DELETE', "#{s}/user/#{created.id}/", (err, res, body) ->
      return done err if err
      res.statusCode.should.eql 200
      execenv.res[0][0].should.eql "tar -czf /tmp/gandalf.tgz /home/gandalf " +
        "&& rm -rf /home/gandalf"
      execenv.res[1][0].should.eql "smbpasswd -x gandalf"
      setTimeout () ->
        done()
      , 1800
