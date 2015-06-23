
Sequelize = require("sequelize")

if process.env.DATABASE_URL
  opts = {}
  # opts.logging = false  unless process.env.NODE_ENV is "devel"
  if process.env.DATABASE_URL.indexOf("sqlite://") >= 0
    opts.storage = "db.sqlite"

  sequelize = new Sequelize(process.env.DATABASE_URL, opts)
else
  # in MEMORY sqlite
  console.log('## using in memory sqlite')
  sequelize = new Sequelize('database', 'username', 'password',
    dialect: 'sqlite'
  )

module.exports.init = (modelModules, cb, doSync) ->

  for mod in modelModules
    mod(sequelize, Sequelize)

  return cb(null, sequelize) if not doSync

  sequelize.sync().then () ->
    return cb(null, sequelize)
