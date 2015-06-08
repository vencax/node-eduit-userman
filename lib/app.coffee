
authM = require("./controllers/auth")
userM = require("./controllers/user")
groupM = require("./controllers/group")
sambaM = require("./controllers/samba")


module.exports = (app, db, sendMail) ->

  authRoutes = authM(db)
  app.post "/login", authRoutes.login
  app.post "/check", authRoutes.check
  sambaRoutes = sambaM(db)
  app.get "/logonscript/:uname", sambaRoutes.logonScript

  # create the routes
  app.resource "user", userM(db)
  app.resource "group", groupM(db)

  # catcher of auth excepts
  app.use (err, req, res, next) ->
    if err.name and err.name is "UnauthorizedError"
      return res.status(401).send(err.message)

    next err
