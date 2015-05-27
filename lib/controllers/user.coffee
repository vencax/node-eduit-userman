
pwdutils = require('./pwdutils')

module.exports = (db) ->

  userHooks = require('./hooks')(db)  # user hooks


  syncGroups = (user, groups, cb) ->
    # delete all memberships
    db.UserGroup.destroy({where: {user_id: user.id}})
    .then (affectedRows) ->
      # create them all
      mships = ({user_id: user.id, group_id: g} for g in groups)
      db.UserGroup.bulkCreate(mships).then ()->
        cb null


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
    req.body.password = pwdutils.create_django_hash(req.body.password)
    db.User.create(req.body).then (created) ->
      rv = created.toJSON()

      _finish = ()->
        delete rv.password
        res.status(201).json(rv)
        rv.rawpwd = rawpwd
        userHooks.afterCreate(rv)

      if req.body.groups and req.body.groups.length > 0
        syncGroups created, req.body.groups, (err)->
          rv.groups = req.body.groups
          _finish()
      else
        rv.groups = []
        _finish()

    .catch (err) ->
      if err.name == 'SequelizeUniqueConstraintError'
        return res.status(400).send('ALREADY_EXISTS')
      res.status(400).send err


  show: (req, res) ->
    req.user.password = null
    rv = req.user.toJSON()
    db.UserGroup.findAll
      where: {user_id: req.user.id}
      attributes: ['group_id']
    .then (groups) ->
      rv.groups = (v.group_id for k, v of groups)
      # return already found (loaded) host
      res.json(rv)


  update: (req, res) ->
    if req.body.password
      req.user.rawpwd = req.body.password if req.body.password
      req.body.password = pwdutils.create_django_hash(req.body.password)
    else
      delete req.body.password

    req.user.updateAttributes(req.body).then () ->
      rv = req.user.toJSON()
      if req.body.groups and req.body.groups.length > 0
        syncGroups req.user, req.body.groups, (err)->
          rv.groups = req.body.groups
          res.json(rv)
          userHooks.afterUpdate(req.user)
      else
        db.UserGroup.findAll
          where: {user_id: req.user.id}
          attributes: ['group_id']
        .then (groups) ->
          rv.groups = (v.group_id for k, v of groups)
          res.json(rv)
          userHooks.afterUpdate(req.user)


  destroy: (req, res) ->
    req.user.destroy().then () ->
      res.json req.user
      userHooks.afterDestroy(req.user)


  # actual object loading function (loads based on req url params)
  load: (id, fn) ->
    db.User.find({where: {id: id}}).then (found) ->
      return fn null, found
