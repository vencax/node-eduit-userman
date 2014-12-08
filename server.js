
require('coffee-script/register');
var express = require('express');
require('express-resource');
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

  require('./lib/app')(api, sequelize, sendMail);

  api.listen(port, function() {
    console.log('gandalf do magic on ' + port);
  });

});
