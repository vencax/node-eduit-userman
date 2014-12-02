
jwt = require("jsonwebtoken")
pwdutils = require("./pwdutils")


module.exports = (db) ->

  _sendError = (res) ->
    res.status(401).send("WRONG_CREDENTIALS")

  return (req, res) ->
    return _sendError(res)  unless req.body.password

    # We are sending the profile inside the token
    db.User.find({where: {username: req.body.username}})
    .on "success", (found) ->
      return _sendError(res)  unless found

      if not pwdutils.django_pwd_match(req.body.password, found.password)
        return _sendError(res)

      profile = JSON.parse(JSON.stringify(found))
      profile.token = jwt.sign(profile, process.env.SERVER_SECRET,
        expiresInMinutes: 60 * 5
      )
      delete (profile.password)

      res.json profile

    .on "error", (err) ->
      res.send 401, err
