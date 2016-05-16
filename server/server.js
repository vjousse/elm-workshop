'use strict';

const fallback    = require( 'express-history-api-fallback' );
const express     = require( 'express' );
const serveStatic = require( 'serve-static' );

// Constants
const PORT = 8080;

const root = __dirname + '/../dist'

// App
const app = express();
app.use(serveStatic(root, {
  maxAge: '1d',
  setHeaders: setCustomCacheControl
}))

app.use(fallback('index.html', { root: root }));

function setCustomCacheControl(res, path) {
  if (serveStatic.mime.lookup(path) === 'text/html') {
    // Custom Cache-Control for HTML files
    res.setHeader('Cache-Control', 'public, max-age=0')
  }
}

app.listen(PORT);
console.log('Running on http://localhost:' + PORT);
