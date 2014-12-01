var pbkdf2 = require('pbkdf2-sha256');
var jwt = require('jsonwebtoken');


var _django_pwd_match = function(key, djpwd) {
  var parts = djpwd.split('$');
  var iterations = parts[1];
  var salt = parts[2];
  return pbkdf2(key, new Buffer(salt), iterations, 32).toString('base64') === parts[3];
};

module.exports = function(db) {

  return function (req, res) {

    db.User.find({where: {username: req.body.username}})
     .on('success', function(found) {

        if(! found) {
          return res.send(401, 'Wrong user or password');
        }

        if(! _django_pwd_match(req.body.password, found.password)) {
          return res.send(401, 'Wrong user or password');
        };

        var profile = JSON.parse(JSON.stringify(found));

        // We are sending the profile inside the token
        profile.token = jwt.sign(profile, process.env.SERVER_SECRET, {
          expiresInMinutes: 60*5
        });

        delete(profile.password);

        res.json(profile);
      })
      .on('error', function(err){
        res.send(401, err);
      });
  };

}
