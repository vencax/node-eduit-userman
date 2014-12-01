var Sequelize = require('sequelize');
var extend = require('util')._extend

var opts = {}
if (process.env.NODE_ENV != 'devel') { opts.logging = false; }
if (process.env.DATABASE_URL &&
  process.env.DATABASE_URL.indexOf('sqlite://') >= 0) {
  opts.storage = 'db.sqlite';
}

var sequelize = new Sequelize(process.env.DATABASE_URL || 'sqlite://', opts);

module.exports.init = function(modelModules, cb) {

  var db = {sequelize: sequelize};

  modelModules.forEach(function(mod) {
    extend(db, mod(sequelize, Sequelize));
  });

  // var migrator = sequelize.getMigrator({
  //   path:        __dirname + '/migrations',
  //   filesFilter: /\.coffee$/
  // });
  // migrator.migrate({ method: 'up' }).then(function() {
  cb(null, db);
  // }).catch(function(err) {
  //   cb('Unable to sync database: ' + err);
  // });

};
