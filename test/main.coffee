
should = require('should')
horaa = require('horaa')
http = require('http')
request = require('request').defaults({timeout: 5000})
fs = require('fs')
bodyParser = require('body-parser')
express = require('express')
Resource = require('express-resource')


port = process.env.PORT || 3333
process.env.SERVER_SECRET='jfdlksjflaf'
process.env.PWD_SALT='p9Tkr6uqxKtf'
process.env.DONT_PROTECT=true
process.env.LOGONSERVER='mordor'
process.env.DEFAULT_EMAIL_DOMAIN = 'mordor.cz'
# process.env.DATABASE_URL='mysql://pgina:heslo77@localhost:5000/pgina'
# process.env.DATABASE_URL='sqlite://db.sqlite'

execenv =
  res: []
  stdout: 'ahoj'

child_process_moc = horaa('child_process')
child_process_moc.hijack 'exec', (prog, pars, cb) ->
  rpars = if cb then pars else {}
  cb ?= pars
  execenv.res.push([prog, rpars])
  err = execenv.err || null
  stdout = execenv.stdout || null
  stderr = execenv.stderr || null
  setTimeout () ->
    cb(err, stdout, stderr) if cb
  , 10
  ret =
    stdout: {pipe: (r) ->}
    stderr: {pipe: (r) ->}

_makeReq = (method, url, body, cb) ->
  if method in ["GET", "DELETE"]
    return request {url: url, method: method}, body

  sBody = JSON.stringify(body)
  headers =
    'Content-Type': 'application/json',
    'Content-Length': sBody.length
  options =
    url: url
    method: method,
    headers: headers
  req = request options, cb
  req.write sBody
  req.end


# entry ...
describe "app", ->

  apiMod = require(__dirname + '/../lib/app')
  dbM = require(__dirname + '/../lib/db')
  g = {}

  modelModules = [
    require(__dirname + '/../lib/models')
  ]

  before (done) ->

    dbM.init(modelModules, (err, sequelize) ->

      # init server
      app = express()
      app.use(bodyParser.urlencoded({ extended: false }))
      app.use(bodyParser.json())

      apiMod(app, sequelize)  # inject api routes

      app.use (req, res, next) ->
        req.user =
          id: 11
        next()

      g.server = app.listen port, (err) ->
        return done(err) if err
        done()

      g.app = app

    , true)  # do sync

  after (done) ->
    g.server.close()
    done()

  it "should exist", (done) ->
    should.exist g.app
    done()

  # run the rest of tests
  baseurl = "http://localhost:#{port}"

  require('./group')(baseurl, _makeReq, execenv)
  require('./prereqs')(baseurl, _makeReq, execenv)
  require('./crud')(baseurl, _makeReq, execenv)
  require('./login')(baseurl, _makeReq, execenv)
  require('./changepasswd')(baseurl, _makeReq, execenv)
  require('./grouphandling')(baseurl, _makeReq, execenv)
