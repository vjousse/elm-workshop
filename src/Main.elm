module Main exposing (..)

import Html exposing (..)
import Html.App as Html

model = { name = "Marcus" }

view model = text ("Hello, " ++ model.name ++ "!")

update msg model = model

main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }
