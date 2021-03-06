
jwt = require("jsonwebtoken")
pwdutils = require("./pwdutils")
Hooks = require('./hooks')
TOKENVALIDITYDURATION = process.env.TOKEN_VALIDITY_IN_MINS || 60 * 24


module.exports = (User, Group) ->

  _sendError = (res) ->
    res.status(401).send("WRONG_CREDENTIALS")

  # return
  login: (req, res) ->
    return _sendError(res)  unless req.body.password

    pwdutils.do_login User, req.body.username, req.body.password, (err, found) ->
      return res.status(401).send(err) if err

      found.getGroups().then (groups)->
        profile = JSON.parse(JSON.stringify(found))
        profile.groups = (g.id for g in groups)

        # We are sending the profile inside the token
        profile.token = jwt.sign(profile, process.env.SERVER_SECRET,
          expiresInMinutes: TOKENVALIDITYDURATION
        )
        res.json profile


  ginalogin: (req, res) ->
    return _sendError(res)  unless req.body.password

    if req.body.old
      return pwdutils.handle_pwd_change User, req.body.username, req.body.password, req.body.old, (err, found) ->
        return res.status(401).send(err) if err
        res.status(200).send('password changed')

    pwdutils.do_login User, req.body.username, req.body.password, (err, user) ->
      return res.status(401).send(err) if err

      if process.env.EI_FORCE_SMB_PASS || false
        Hooks.changeSmbPwd(user, req.body.password)

      user.getGroups().then (groups)->
        grps = (g.name for g in groups)
        # GID as well
        Group.find({where: {id: user.gid}}).then (GID) ->
          grps.push(GID.name)
          profile = JSON.parse(JSON.stringify(user))

          res.status(200).send """\n#{profile.username}
#{profile.realname}
#{profile.email}
#{grps.join(';')}"""


  check: (req, res) ->
    User.find({where: {username: req.body.username}}).then (found) ->
      return res.json [] if not found
      res.json [1]
    .catch () ->
      res.json []
