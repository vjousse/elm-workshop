var jQuery = require('jquery');
var Auth0Lock = require('auth0-lock');

// Example requires for pulling in static content via WebPack
// require("file?name=/favicon.ico!./favicon.ico");
// require("./assets/stylesheets/styles.css");
// require("./assets/images/logo.png")

var Elm = require("../src/Main.elm");

var auth0lock = Auth0Lock("YOUR-CLIENT-ID", "YOUR-AUTH0-DOMAIN");

var main = Elm.Main.fullscreen();

main.ports.auth0showLock.subscribe(function(opts) {
    auth0lock.showSignin(opts,function(err,profile,token) {
        var result = {err:null, ok:null};
        if (!err) {
        result.ok = {profile:profile,token:token};
        } else {
        result.err = err.details;
        }
        main.ports.auth0authResult.send(result);
    });
});
