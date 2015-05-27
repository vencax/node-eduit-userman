
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
process.env.DATABASE_URL='mysql://pgina:heslo77@localhost:5000/pgina'

execenv =
  res: []

child_process_moc = horaa('child_process')
child_process_moc.hijack 'exec', (prog, pars, cb) ->
  rpars = if cb then pars else {}
  cb ?= pars
  execenv.res.push([prog, rpars])
  setTimeout(() ->
    if cb
      cb(execenv.err || null, execenv.stdout || null, execenv.stderr || null)
  , 50)
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
  g = {}
  Sequelize = require('sequelize')
  db = {}

  before (done) ->
    # init server
    app = express()
    app.use(bodyParser.urlencoded({ extended: false }))
    app.use(bodyParser.json())

    db.sequelize = new Sequelize('database', 'username', 'password',
      # sqlite! now!
      dialect: 'sqlite'
    )

    # register models
    mdls = require(__dirname + '/../lib/models')(db.sequelize, Sequelize)
    for k, mdl of mdls
      db[k] = mdl

    db.sequelize.sync().then () ->

      apiMod app, db

      app.use (req, res, next) ->
        req.user =
          id: 11
        next()

      g.server = app.listen port, (err) ->
        return done(err) if err
        done()

      g.app = app

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
