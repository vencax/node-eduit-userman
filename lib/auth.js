
var jwt = require('jsonwebtoken');
var pwdutils = require('./pwdutils');


module.exports = function(db) {

  function _sendError(res) {
    return res.send(401, 'Wrong user or password');
  }

  return function (req, res) {

    if(! req.body.password) { return _sendError(res); }

    db.User.find({where: {username: req.body.username}})
     .on('success', function(found) {

        if(! found) { return _sendError(res); }

        if(! pwdutils.django_pwd_match(req.body.password, found.password)) {
          return _sendError(res);
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
