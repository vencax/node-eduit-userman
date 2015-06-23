
authM = require("./controllers/auth")
userM = require("./controllers/user")
groupM = require("./controllers/group")
sambaM = require("./controllers/samba")


module.exports = (app, db, sendMail) ->

  authRoutes = authM(db.models.User, db.models.Group)
  app.post "/login", authRoutes.login
  app.post "/ginalogin", authRoutes.ginalogin
  app.post "/check", authRoutes.check
  sambaRoutes = sambaM(db.models.User, db.models.Group)
  app.get "/logonscript/:uname", sambaRoutes.logonScript

  # create the routes
  app.resource "user", userM(db.models.User, db.models.Group)
  app.resource "group", groupM(db.models.User, db.models.Group)

  # catcher of auth excepts
  app.use (err, req, res, next) ->
    if err.name and err.name is "UnauthorizedError"
      return res.status(401).send(err.message)

    next err
