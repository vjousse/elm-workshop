var path              = require( 'path' );
var webpack           = require( 'webpack' );
var merge             = require( 'webpack-merge' );
var HtmlWebpackPlugin = require( 'html-webpack-plugin' );
var autoprefixer      = require( 'autoprefixer' );
var ExtractTextPlugin = require( 'extract-text-webpack-plugin' );

// detemine build env
var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';

var commonConfig = {

  entry: {
    app: path.join( __dirname, 'web/index.js' ),
  },

  externals : {
    "jquery": "jQuery",
    "auth0-lock": "Auth0Lock"
  },

  output: {
    path: path.join(__dirname, 'dist/'),
    filename: "/js/[name].[hash].js",
    chunkFilename: "/js/chunk-[chunkhash].js"
  },

  resolve: {
    modulesDirectories: ['node_modules'],
    extensions:         ['', '.js', '.elm']
  },

  module: {
    loaders: [
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader:  'elm-webpack'
      },
      // required for bootstrap icons
      {
        test: /\.woff2?$/,
        loader: "url?name=/font/[name].[ext]?[sha512:hash:base64:7]&limit=5000&mimetype=application/font-woff"
      },
      {
        test: /\.ttf$/,
        loader: "file?name=/font/[name].[ext]?[sha512:hash:base64:7]"
      },
      {
        test: /\.eot$/,
        loader: "file?name=/font/[name].[ext]?[sha512:hash:base64:7]"
      },
      {
        test: /\.(jpe?g|gif|png|svg)$/i,
        loaders: [
          'file?name=/img/[name].[ext]?[sha512:hash:base64:7]',
          'image-webpack'
        ]
      }
    ],
    noParse: /\.elm$/
  },



  plugins: [
    new HtmlWebpackPlugin({
      template: './web/index.html',
      inject:   'body',
      filename: 'index.html',
      showErrors: TARGET_ENV === 'development'
    })
  ],

  postcss: [ autoprefixer( { browsers: ['last 2 versions'] } ) ],

  imageWebpackLoader: {
      progressive: true,
      interlaced: false,
      optimizationLevel: 7,
      //bypassOnDebug: true,
      pngquant: {
        quality: "65-90",
        speed: 4
      },
      svgo: {
        plugins: [
          {
            removeViewBox: false
          },
          {
            removeEmptyAttrs: false
          }
        ]
      }
    }
}

// additional webpack settings for local env (when invoked by 'npm start')
if ( TARGET_ENV === 'development' ) {
  console.log( 'Serving locally...');

  module.exports = merge( commonConfig, {

    entry: {
      vendor: [
        'webpack-dev-server/client?http://localhost:8080',
      ]
    },

    devServer: {
      inline:   true,
      progress: true,
      historyApiFallback: true
    },

    module: {
      loaders: [
        {
          test: /\.(css|scss)$/,
          loaders: [
            'style',
            'css',
            'postcss',
            'sass'
          ]
        }
      ]
    }
  });
}

// additional webpack settings for prod env (when invoked via 'npm run build')
if ( TARGET_ENV === 'production' ) {
  console.log( 'Building for prod...');

  module.exports = merge( commonConfig, {

    module: {
      loaders: [
        {
          test: /\.(css|scss)$/,
          loader: ExtractTextPlugin.extract( 'style', [
            'css',
            'postcss',
            'sass'
          ])
        }
      ]
    },

    plugins: [
      new webpack.optimize.OccurenceOrderPlugin(),

      // extract CSS into a separate file
      new ExtractTextPlugin( '/css/[name].[hash].css', { allChunks: true } ),

      new webpack.DefinePlugin({
        "process.env": {
          // This has effect on the react lib size
          "NODE_ENV": JSON.stringify("production")
        }
      }),

      new webpack.optimize.DedupePlugin(),

      // minify & mangle JS/CSS
      new webpack.optimize.UglifyJsPlugin({
          minimize:   true,
          compressor: { warnings: false },
          mangle:     true
      })
    ]

  });
}
