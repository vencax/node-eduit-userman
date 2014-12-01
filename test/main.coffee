
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

execenv =
  res: []

child_process_moc = horaa('child_process')
child_process_moc.hijack 'exec', (prog, pars, cb) ->
  rpars = if cb then pars else {}
  cb ?= pars
  execenv.res.push([prog, rpars])
  if cb
    cb(execenv.err || null, execenv.stdout || null, execenv.stderr || null)

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

    db.sequelize.sync().on 'success', () ->

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

  require('./crud')(baseurl, request, execenv)
  require('./login')(baseurl, request, execenv)
