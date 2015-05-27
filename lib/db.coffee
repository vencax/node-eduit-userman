
Sequelize = require("sequelize")

dburl = process.env.DATABASE_URL or "sqlite://"
opts = {}

# opts.logging = false  unless process.env.NODE_ENV is "devel"
if dburl.indexOf("sqlite://") >= 0
  opts.storage = "db.sqlite"

sequelize = new Sequelize(dburl, opts)


module.exports.init = (modelModules, cb) ->

  db = {sequelize: sequelize}

  for mod in modelModules
    for modelName, model of mod(sequelize, Sequelize)
      db[modelName] = model

  db.User.hasMany(db.UserGroup)

  return cb null, db unless process.env.NODE_ENV is "devel"

  migrator = sequelize.getMigrator
    path:        __dirname + '/migrations'
    filesFilter: /\.coffee$/
  migrator.migrate({ method: 'up' }).then () ->
    cb(null, db)
  .catch (err) ->
    cb('Unable to sync database: ' + err)
