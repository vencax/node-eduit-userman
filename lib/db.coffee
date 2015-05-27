
Sequelize = require("sequelize")

if process.env.DATABASE_URL
  opts = {}
  # opts.logging = false  unless process.env.NODE_ENV is "devel"
  if dburl.indexOf("sqlite://") >= 0
    opts.storage = "db.sqlite"

  sequelize = new Sequelize(dburl, opts)
else
  # in MEMORY sqlite
  sequelize = new Sequelize('database', 'username', 'password',
    dialect: 'sqlite'
  )

module.exports.init = (modelModules, cb) ->

  db = {sequelize: sequelize}

  for mod in modelModules
    for modelName, model of mod(sequelize, Sequelize)
      db[modelName] = model

  db.User.hasMany(db.UserGroup)

  db.sequelize.sync().then () ->
    return cb(null, db)

  # migrator = sequelize.getMigrator
  #   path:        __dirname + '/migrations'
  #   filesFilter: /\.coffee$/
  # migrator.migrate({ method: 'up' }).then () ->
  #   cb(null, db)
  # .catch (err) ->
  #   cb('Unable to sync database: ' + err)
