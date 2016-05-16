module Components.ValidationBox
    exposing
        ( Msg(..)
        , Model
        , InitialParams
        , init
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type Msg
    = UpdateText String

type Model
    = Model
        { id : String
        , text : String
        }


type alias InitialParams =
    { id : String
    , initialText : String
    }


init : InitialParams -> Model
init ps =
    Model
        { id = ps.id
        , text = ps.initialText
        }

update : Msg -> Model -> Model
update msg (Model model) =
    Model
        ( case msg of
            UpdateText newText ->
                { model
                | text = newText
                }
        )

view : Model -> Html Msg
view (Model model) =
        div
            [ class "form-group" ]
            [ input
                [ id model.id
                , type' "text"
                , value model.text
                , onInput UpdateText
                , class "form-control"
                ]
                []
            ]
