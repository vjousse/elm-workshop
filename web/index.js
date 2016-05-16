var jQuery = require('jquery');
var Auth0Lock = require('auth0-lock');

// Example requires for pulling in static content via WebPack
// require("file?name=/favicon.ico!./favicon.ico");
// require("./assets/stylesheets/styles.css");
// require("./assets/images/logo.png")

var Elm = require("../src/Main.elm");

var main = Elm.Main.fullscreen();
