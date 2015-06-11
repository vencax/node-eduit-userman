
jwt = require("jsonwebtoken")
pwdutils = require("./pwdutils")


module.exports = (db) ->

  _sendError = (res) ->
    res.status(401).send("WRONG_CREDENTIALS")

  # return
  login: (req, res) ->
    return _sendError(res)  unless req.body.password

    # We are sending the profile inside the token
    db.User.find({where: {username: req.body.username}}).then (found) ->
      return _sendError(res)  unless found

      pwdutils.unixPwdMatch req.body.password, found.unixpwd, (matching) ->
        return _sendError(res) if not matching

        profile = JSON.parse(JSON.stringify(found))
        profile.token = jwt.sign(profile, process.env.SERVER_SECRET,
          expiresInMinutes: 60 * 5
        )
        delete (profile.password)

        found.getGroups().then (groups)->
          profile.groups = (g.id for g in groups)
          res.json profile

    .catch (err) ->
      res.send 401, err

  check: (req, res) ->
    db.User.find({where: {username: req.body.username}}).then (found) ->
      return res.json [] if not found
      res.json [1]
    .catch () ->
      res.json []
