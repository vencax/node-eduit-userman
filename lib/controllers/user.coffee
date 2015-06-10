
pwdutils = require('./pwdutils')

module.exports = (db) ->

  userHooks = require('./hooks')(db)  # user hooks

  index: (req, res) ->
    db.User.findAll()
      # include: [{ model: db.UserGroup, as: 'groups' }]
    .then (found) ->
      for f in found
        delete f.password
      res.json found


  create: (req, res, next) ->
    if not req.body.username or not req.body.password or not req.body.gid
      return res.status(400).send("REQUIRED_PARAM_MISSING")
    rawpwd = req.body.password
    pwdutils.getUnixPwd req.body.password, (unixPwd) ->
      req.body.password = pwdutils.createMD5Hash(req.body.password)
      req.body.unixpwd = unixPwd
      req.body.hash_method = 'MD5'
      req.body.user = req.body.username
      req.body.status = 'A'
      db.User.create(req.body).then (created) ->
        rv = created.toJSON()
        _syncGroups created, req.body.groups, (err, groups)->
          rv.groups = groups
          delete rv.password
          res.status(201).json(rv)
          rv.rawpwd = rawpwd
          userHooks.afterCreate(rv)

      .catch (err) ->
        if err.name == 'SequelizeUniqueConstraintError'
          return res.status(400).send('ALREADY_EXISTS')
        res.status(400).send err


  show: (req, res) ->
    req.user.password = null
    rv = req.user.toJSON()

    req.user.getGroups().then (groups)->
      rv.groups = (g.id for g in groups)
      # return already found (loaded) host
      res.json(rv)


  update: (req, res) ->
    _save = () ->
      req.user.updateAttributes(req.body).then () ->
        rv = req.user.toJSON()
        if req.body.groups and req.body.groups.length > 0
          _syncGroups req.user, req.body.groups, (err, groups)->
            rv.groups = groups
            res.json(rv)
            userHooks.afterUpdate(req.user)
        else
          req.user.getGroups().then (groups)->
            rv.groups = (g.id for g in groups)
            res.json(rv)
            userHooks.afterUpdate(req.user)

    if req.body.password
      req.user.rawpwd = req.body.password if req.body.password
      pwdutils.getUnixPwd req.body.password, (unixPwd) ->
        req.body.password = pwdutils.createMD5Hash(req.body.password)
        req.body.unixpwd = unixPwd
        _save()
    else
      delete req.body.password
      _save()


  destroy: (req, res) ->
    req.user.destroy().then () ->
      res.json req.user
      userHooks.afterDestroy(req.user)


  # actual object loading function (loads based on req url params)
  load: (id, fn) ->
    db.User.find({where: {id: id}}).then (found) ->
      return fn null, found

# ----------------

_syncGroups = (user, groups, cb) ->
  if groups == undefined or groups.length == 0
    return cb(null, [])
  # delete all memberships
  user.getGroups().then (oldG)->
    user.removeGroups(oldG).then ()->
      # create all new
      user.addGroups(groups).then ()->
        cb null, groups
