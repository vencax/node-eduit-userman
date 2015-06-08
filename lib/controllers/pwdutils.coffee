
pbkdf2 = require("pbkdf2-sha256")
bcrypt = require "bcrypt"
crypto = require('crypto')
exec = require('child_process').exec


throw new Error("SET process.env.PWD_SALT!") unless "PWD_SALT" of process.env
salt = process.env.PWD_SALT
algorithm = "pbkdf2_sha256"
iterations = 10000


exports.createMD5Hash = (pwd) ->
  return crypto.createHash('md5').update(pwd).digest('hex')


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
    return cb(stdout)


exports.unixPwdMatch = (rawpwd, hash, cb) ->
  c = "python -c 'import crypt; print crypt.crypt(\"#{rawpwd}\", \"#{hash}\")'"
  child = exec c, (err, stdout, stderr) ->
    return cb(stdout.indexOf(hash) == 0)
