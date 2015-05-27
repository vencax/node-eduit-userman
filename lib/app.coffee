
expressJwt = require("express-jwt")
authM = require("./controllers/auth")
userM = require("./controllers/user")
groupM = require("./controllers/group")


module.exports = (app, db, sendMail) ->

  authRoutes = authM(db)
  app.post "/login", authRoutes.login
  app.post "/check", authRoutes.check

  if not process.env.DONT_PROTECT
    # the rest of API secure with JWT
    app.use expressJwt(secret: process.env.SERVER_SECRET)

  # create the routes
  app.resource "user", userM(db)
  app.resource "group", groupM(db)

  # catcher of auth excepts
  app.use (err, req, res, next) ->
    if err.name and err.name is "UnauthorizedError"
      return res.status(401).send(err.message)

    next err
