
require('coffee-script/register');
var express = require('express');
require('express-resource');
expressJwt = require("express-jwt")
var bodyParser = require('body-parser');
var cors = require('cors');

var port = process.env.PORT || 8080;

var sendMail = {};

var modelModules = [
  require('./lib/models')
];

require('./lib/db').init(modelModules, function(err, sequelize) {
  if(err) { return console.log(err); }

  // create API
  var api = express();
  // enable CORS
  api.use(cors({maxAge: 86400}));
  api.use(bodyParser.json());

  if(! process.env.DONT_PROTECT) {
    var unprotected = [
      '/login', '/check', '/logonscript/:uname'
    ]
    // the rest of API secure with JWT

    app.use(
      expressJwt(secret: process.env.SERVER_SECRET).unless({path: unprotected})
    );
  }

  require('./lib/app')(api, sequelize, sendMail);

  api.listen(port, function() {
    console.log('gandalf do magic on ' + port);
  });

});
