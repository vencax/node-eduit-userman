
path = require('path')
fs = require('fs')
crypto = require('crypto')
exec = require('child_process').exec


DELETE_HOME_ON_DELETION = process.env.DELETE_HOME_ON_DELETION || true
HOMES_PATH = process.env.HOMES_PATH || '/home'
PGINA_HACKS = process.env.PGINA_HACKS || true
SAMBARELOAD = process.env.SAMBA_RELOAD_CMD || 'service smbd reload'


module.exports = () ->


  _run_command = (cmd, cb) ->
    console.log cmd
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
      mkHome = "cp -a /etc/skel/. #{homedir}"
      mkHome += " && chown -R #{uname}:adm #{homedir}"
      mkHome += " && chmod 770 #{homedir}"
      _run_command(mkHome, cb)

    if not fs.existsSync(homedir)
      _run_command "mv #{homedir} /tmp", (err) ->
        _do_create_home()
    else
      _do_create_home()


  # return
  afterCreate: (user) ->
    setTimeout () ->
      # wait all is done id DB
      _createHome(user.username)
      # add samba user
      _run_command "(echo #{user.rawpwd}; echo #{user.rawpwd}) | " + \
        "smbpasswd -s -a #{user.username} && " +
        "pdbedit --modify -u #{user.username} --fullname \"#{user.realname}\""
      _run_command(SAMBARELOAD)
      console.log("user #{user.username} synced")
    , 500


  changeSmbPwd: (user, rawpwd) ->
    cmd = "(echo #{rawpwd}; echo #{rawpwd}) | smbpasswd -s #{user.username}"
    _run_command(cmd)
    _run_command(SAMBARELOAD)


  afterUpdate: (user) ->
    # change realname of da samba user
    # see: http://www.samba.org/samba/docs/man/manpages/pdbedit.8.html
    cmd = ""
    if user.realname?
      cmd = "pdbedit --modify -u #{user.username} --fullname \"#{user.realname}\""
    if user.rawpwd
      if cmd.length
        cmd += " && "
      cmd += "(echo #{user.rawpwd}; echo #{user.rawpwd}) | " + \
        "smbpasswd -s #{user.username}"

    _run_command(cmd)
    _run_command(SAMBARELOAD)


  afterDestroy: (user) ->
    if DELETE_HOME_ON_DELETION
      homedir = path.join(HOMES_PATH, user.username)
      _run_command "tar -czf /tmp/#{user.username}.tgz #{homedir} && " + \
        "rm -rf #{homedir}"
    # remove samba user
    _run_command "pdbedit --delete -u #{user.username}"
