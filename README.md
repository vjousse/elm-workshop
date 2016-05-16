# Elm 0.17 Example

This project is an example package for an Elm UI using Elm 0.17 using webpack.
Work through the workshop by checking out `elm-workshop.md`

## Prerequisites

* A working installation of [node.js][] with `npm`
* A working installation of [Elm][] version 0.17

## Development

Run the following commands from the repository root to start the development server:

    npm install
    npm start

The cached Elm modules can be cleaned by running the `clean:elm` script:

    npm run clean:elm

## Production Build

Run the following commands from the repository root to build the static site in `dist/`.

    npm run build

You can start the included `express` server by switching to the `server/` directory and running:

    npm start

  [node.js]: https://nodejs.org/en/
  [Elm]: https://elm-lang.org/
