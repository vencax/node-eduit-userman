
var pbkdf2 = require('pbkdf2-sha256');

if(! ('PWD_SALT' in process.env)) {
  throw 'SET process.env.PWD_SALT!';
}
var salt = process.env.PWD_SALT;
var algorithm = "pbkdf2_sha256";
var iterations = 10000;


exports.django_pwd_match = function(key, djpwd) {
  var parts = djpwd.split('$');
  var iterations = parts[1];
  var salt = parts[2];
  return pbkdf2(key, new Buffer(salt), iterations, 32).toString('base64') === parts[3];
};

exports.create_django_hash = function(pwd) {
  var hashed = pbkdf2(pwd, new Buffer(salt), iterations, 32).toString('base64');
  return algorithm +'$' + iterations +'$' + salt +'$' + hashed;
};
