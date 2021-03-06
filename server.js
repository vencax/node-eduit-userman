
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
  // secure API
  var unprotected = [
    '/login', '/ginalogin', '/check', /\/logonscript\/.*$/
  ];
  // the rest of API secure with JWT
  api.use(
    expressJwt({secret: process.env.SERVER_SECRET}).unless({path: unprotected})
  );
  // enable JSON bodies
  api.use(bodyParser.json());

  require('./lib/app')(api, sequelize, sendMail);

  api.listen(port, function() {
    console.log('gandalf do magic on ' + port);
  });

});
