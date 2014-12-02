
expressJwt = require("express-jwt")


module.exports = (app, db, sendMail) ->

  app.post "/login", require("./auth")(db)

  if not process.env.DONT_PROTECT
    # the rest of API secure with JWT
    app.use expressJwt(secret: process.env.SERVER_SECRET)

  # create the routes
  app.resource "user", require("./controllers/user")(db)
  app.resource "group", require("./controllers/group")(db)

  # catcher of auth excepts
  app.use (err, req, res, next) ->
    if err.name and err.name is "UnauthorizedError"
      return res.status(401).send(err.message)

    next err
