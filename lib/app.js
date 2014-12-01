
var expressJwt = require('express-jwt');


module.exports = function(app, db, sendMail) {

  app.post('/login', require('./auth.js')(db));

  // the rest of API secure with JWT
  if(!process.env.DONT_PROTECT) {
    app.use(expressJwt({secret: process.env.SERVER_SECRET}));
  }

  // create the routes
  app.resource('user', require('./controllers/user')(db));

  app.use(function(err, req, res, next) {
    if(err.name && err.name === 'UnauthorizedError') {
      return res.status(401).send(err.message);
    }
    next(err);
  });

};
