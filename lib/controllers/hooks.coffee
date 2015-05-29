
path = require('path')
fs = require('fs')
crypto = require('crypto')
exec = require('child_process').exec


ISSUE_SAMBA_COMMANDS = process.env.ISSUE_SAMBA_COMMANDS || true
DELETE_HOME_ON_DELETION = process.env.DELETE_HOME_ON_DELETION || true
HOMES_PATH = process.env.HOMES_PATH || '/home'
PGINA_HACKS = process.env.PGINA_HACKS || true


module.exports = (db) ->


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
    setTimeout () ->
      # wait all is done id DB
      _createHome(user.username)
      addSmbUsr = "(echo #{user.rawpwd}; echo #{user.rawpwd})"
      addSmbUsr += " | smbpasswd -s -a #{user.username}"
      _run_command(addSmbUsr)
      console.log("user #{user.username} synced")
    , 500


  afterUpdate: (user) ->
    if user.rawpwd and ISSUE_SAMBA_COMMANDS
      _run_command "(echo #{user.rawpwd}; echo #{user.rawpwd})" +
        " | smbpasswd -s #{user.username}"

    if ISSUE_SAMBA_COMMANDS
      # change realname of da samba user
      # see: http://www.samba.org/samba/docs/man/manpages/pdbedit.8.html
      modFullname = "pdbedit --modify -u #{user.username}"
      if user.realname?
        modFullname += " --fullname \"#{user.realname}\""
      _run_command(modFullname)


  afterDestroy: (user) ->
    _delSambaUserAndHome(user.username)
