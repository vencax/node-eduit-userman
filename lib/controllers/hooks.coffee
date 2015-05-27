
path = require('path')
fs = require('fs')
crypto = require('crypto')
bcrypt = require('bcrypt')
exec = require('child_process').exec


ISSUE_SAMBA_COMMANDS = process.env.ISSUE_SAMBA_COMMANDS || true
DELETE_HOME_ON_DELETION = process.env.DELETE_HOME_ON_DELETION || true
HOMES_PATH = process.env.HOMES_PATH || '/home'
PGINA_HACKS = process.env.PGINA_HACKS || true


module.exports = (db) ->

  _getUnixPwd = (rawPwd) ->
    salt = bcrypt.genSaltSync(10)
    return bcrypt.hashSync(rawPwd, salt)


  # Make appropriate SysUser instance according user
  _syncSysUser = (user, sysUser) ->
    return false if sysUser is null  # this is weird

    if PGINA_HACKS
      sysUser.user = user.username
      sysUser.hash_method = 'MD5'

    if user.rawpwd
      sysUser.unixpwd = _getUnixPwd(user.rawpwd)
      if PGINA_HACKS
        h = crypto.createHash('md5').update(user.rawpwd).digest('hex')
        sysUser.password = h

    sysUser.user_name = user.username
    sysUser.realname = "#{user.first_name} #{user.last_name}"
    sysUser.status = 'A'

    _getOrCreateSysGroup user.gid, (err, sysGID) ->
      sysUser.gid_id = sysGID.group_id
      sysUser.save().then (saved) ->
        _syncGroups(user.groups, sysUser)


  _syncGroups = (otherGrs, sysUser) ->

    return unless otherGrs

    # delete all memberships
    db.SysMembership.destroy({where: {user: sysUser.user_id}})
    .then (affectedRows) ->
      # create them all
      mships = []

      _solveGroup = () ->
        return db.SysMembership.bulkCreate(mships) if otherGrs.length == 0

        g = otherGrs.pop()
        _getOrCreateSysGroup g, (err, sysG) ->
          mships.push({user: sysUser.user_id, group: sysG.group_id})
          _solveGroup()

      _solveGroup(otherGrs)


  _getOrCreateSysGroup = (groupid, cb) ->
    db.Group.find({where: {id: groupid}}).then (group) ->
      throw new Error("Group with ID #{groupid} not found!") if not group
      db.SysGroup.find({where: {group_name: group.name}}).then (g) ->
        if not g
          g = db.SysGroup.build({group_name: group.name})
          g.save().then (saved)->
            cb(null, saved)
        else
          cb(null, g)


  _run_command = (cmd, cb) ->
    child = exec cmd, (err, stdout, stderr) ->
      return cb(err) if err and cb
      return cb(null, stdout) if cb
    child.stdout.pipe(process.stdout)
    child.stderr.pipe(process.stderr)


  _createHome = (uname, cb) ->
    ###
    Create home dir and samba user on create
    or change samba pwd on change.
    ###
    homedir = path.join(HOMES_PATH, uname)
    _do_create_home = () ->
      mkHome = "cp -R /etc/skel #{homedir}"
      mkHome += " && chown -R #{uname}:adm #{homedir}"
      mkHome += " && chmod 770 #{homedir}"
      _run_command(mkHome, cb)

    if not fs.existsSync(homedir)
      _run_command "mv #{homedir} /tmp", (err) ->
        _do_create_home()
    else
      _do_create_home()

  _delSambaUserAndHome = (uname) ->
    ###
    Delete samba user and tar home dir to /tmp.
    ###
    if DELETE_HOME_ON_DELETION
      homedir = path.join(HOMES_PATH, uname)
      c = "tar -czf /tmp/#{uname}.tgz #{homedir} && rm -rf #{homedir}"
      _run_command(c)
    if ISSUE_SAMBA_COMMANDS
      _run_command "smbpasswd -x #{uname}"

  # return
  afterCreate: (user) ->
    sysuser = db.SysUser.build({user_name: user.username})

    _syncSysUser(user, sysuser)

    setTimeout () ->
      # wait all is done id DB
      _createHome(user.username)
      addSmbUsr = "(echo #{user.rawpwd}; echo #{user.rawpwd})"
      addSmbUsr += " | smbpasswd -s -a #{user.username}"
      _run_command(addSmbUsr)
      console.log("user #{user.username} synced")
    , 500


  afterUpdate: (user) ->
    db.SysUser.find({where: {user_name: user.username}}).then (sysuser) ->
      if not sysuser
        console.log "WEIRD: sysuser #{user.username} not found!"
        return

      if not user.gid
        user.gid = sysuser.gid_id
      _syncSysUser(user, sysuser)

      if user.rawpwd and ISSUE_SAMBA_COMMANDS
        _run_command "(echo #{user.rawpwd}; echo #{user.rawpwd})" +
          " | smbpasswd -s #{user.username}"

      if ISSUE_SAMBA_COMMANDS
        # change realname of da samba user
        # see: http://www.samba.org/samba/docs/man/manpages/pdbedit.8.html
        modFullname = "pdbedit --modify -u #{user.username}"
        if sysuser.realname?
          modFullname += " --fullname \"#{sysuser.realname}\""
        _run_command(modFullname)

    .catch (err) ->
      console.log(err.stack)

  afterDestroy: (user) ->
    _delSambaUserAndHome(user.username)
    db.SysUser.find({where: {user_name: user.username}}).then (sysuser) ->
      if not sysuser
        console.log "WEIRD: sysuser #{user.username} not found!"
        return

      sysuser.destroy()
    .catch (err) ->
      console.log(err.stack)
