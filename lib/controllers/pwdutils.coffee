
pbkdf2 = require("pbkdf2-sha256")
bcrypt = require "bcrypt"


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


getUnixPwd = (rawPwd) ->
  salt = bcrypt.genSaltSync(10)
  return bcrypt.hashSync(rawPwd, salt)
exports.getUnixPwd = getUnixPwd


exports.unixPwdMatch = (rawpwd, hash) ->
  return bcrypt.compareSync(rawpwd, hash)
