
pbkdf2 = require("pbkdf2-sha256")
bcrypt = require "bcrypt"
crypto = require('crypto')
exec = require('child_process').exec


throw new Error("SET process.env.PWD_SALT!") unless "PWD_SALT" of process.env
salt = process.env.PWD_SALT
algorithm = "pbkdf2_sha256"
iterations = 10000


exports.django_pwd_match = (key, djpwd) ->
  parts = djpwd.split("$")
  iterations = parts[1]
  salt = parts[2]
  pbkdf2(key, new Buffer(salt), iterations, 32).toString("base64") is parts[3]


exports.create_django_hash = (pwd) ->
  hashed = pbkdf2(pwd, new Buffer(salt), iterations, 32).toString("base64")
  algorithm + "$" + iterations + "$" + salt + "$" + hashed


exports.getUnixPwd = (rawPwd, cb) ->
  cmd = "python -c 'import crypt; print crypt.crypt(\"#{rawPwd}\", \"ds\")'"
  child = exec cmd, (err, stdout, stderr) ->
    return cb(stdout.replace('\n', ''))


exports.unixPwdMatch = _unixPwdMatch = (rawpwd, hash, cb) ->
  hash = hash.replace('\n', '')
  c = "python -c 'import crypt; print crypt.crypt(\"#{rawpwd}\", \"#{hash}\")'"
  child = exec c, (err, stdout, stderr) ->
    return cb(stdout.indexOf(hash) == 0) if cb?


exports.do_login = (usermodel, uname, pass, cb) ->
  usermodel.find({where: {username: uname}}).then (found) ->
    return cb("WRONG_CREDENTIALS") unless found

    _unixPwdMatch pass, found.unixpwd, (matching) ->
      return cb("WRONG_CREDENTIALS") if not matching

      delete (found.password)
      cb(null, found)
  .catch (err) ->
    cb(err)
