

module.exports = (db) ->

  _writeCommon = (res) ->
    res.write """
    rem delete all existing connections
    net use * /delete /y

    rem wait 3 secs
    ping 1.1.1.0 -w 1 -n 2 > NUL

    net use H: \\\\#{process.env.LOGONSERVER}\\%USERNAME%

    """

  _writeGroupScript = (res, groupname) ->
    LOGONSHARE = process.env.LOGONSHARE || 'nlogon'

    res.write """
    \\\\#{process.env.LOGONSERVER}\\#{LOGONSHARE}\\#{groupname}.bat

    """

  logonScript: (req, res) ->
    _writeCommon(res)
    db.User.find({where: {username: req.params.uname}}).then (found) ->
      return res.status(404) if not found

      db.Group.find({where: {id: found.gid}}).then (gid) ->
        _writeGroupScript(res, gid.name)

        found.getGroups().then (groups)->
          for g in groups
            _writeGroupScript(res, g.name)
          res.end()
    # db.User.find({where: {username: req.params.uname}}).then (found) ->
    #   db.UserGroup.findAll
    #     where: {user_id: req.user.id}
    #     attributes: ['group_id']
    #   .then (mships) ->
    #     for f in found
    #       delete f.password
    #     res.json found
