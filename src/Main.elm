port module Main exposing (..)

import Api.Healthcheck as Healthcheck
import Auth0
import Authentication
import Char
import Components.ValidationBox as ValidationBox
import Dict
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task
import Time exposing (Time)
import String

type Msg
    = Click
    | UpdateHello String
    | MakeHello
    | VBox1 ValidationBox.Msg
    | VBox2 ValidationBox.Msg
    | ResetTextBoxes
    | TriggerHealthCheck
    | Healthcheck (Result () Healthcheck.TestResult)
    | Authentication Authentication.Msg

type alias Model =
    { name : String
    , nameInProgress : String
    , clicks : Int
    , vbox1 : ValidationBox.Model
    , vbox2 : ValidationBox.Model
    , lastHealthcheck : Result () Healthcheck.TestResult
    , healthcheckInProgress : Bool
    , authModel : Authentication.Model
    }

model : Model
model =
    { name = "Marcus"
    , nameInProgress = "Marcus"
    , clicks = 0
    , vbox1 =
        ValidationBox.init
            { id = "vbox1"
            , initialText = "some text"
            , label = Just "First Field"
            , placeholder = Just "Type here"
            , helpText = Just "Really, just type above..."
            , normalize = identity
            , validate = always (Result.Ok ())
            }
    , vbox2 =
        ValidationBox.init
            { id = "vbox2"
            , initialText = "0"
            , label = Just "Second Field"
            , placeholder = Nothing
            , helpText = Just "Must be a number that doesn't start with 0"
            , normalize = String.filter Char.isDigit
            , validate = \s -> if String.startsWith "0" s then Result.Err "Nope" else Result.Ok ()
            }
    , lastHealthcheck = Result.Err ()
    , healthcheckInProgress = False
    , authModel = Authentication.init auth0showLock
    }

init : ( Model, Cmd Msg )
init = ( { model | healthcheckInProgress = True } , performHealthcheck )

view : Model -> Html Msg
view model =
    div
        []
        [ div
            [ class "container" ]
            [ text ("Hello, " ++ model.name ++ "!")
            , input
                [ type' "text"
                , placeholder "Who should I say hello to?"
                , value model.nameInProgress
                , onInput UpdateHello
                , onBlur MakeHello
                ]
                []
            , button
                [ onClick Click ]
                [ text ("I've been clicked " ++ (toString model.clicks) ++ " times") ]
            , Html.map VBox1 (ValidationBox.view model.vbox1)
            , Html.map VBox2 (ValidationBox.view model.vbox2)
            , div
                []
                [ button
                    [ onClick ResetTextBoxes ]
                    [ text "Reset" ]
                ]
            , div
                []
                [ text
                    ( case ( model.healthcheckInProgress, model.lastHealthcheck ) of
                        ( True, _ ) -> "Checking health..."
                        ( False, Result.Ok Healthcheck.Passed ) -> "Service is healthy"
                        ( False, Result.Ok Healthcheck.Failed ) -> "Service is not healthy"
                        ( False, Result.Err () ) -> "Could not reach service..."
                    )
                ]
            , div
                []
                [ div
                    []
                    ( case Authentication.tryGetUserProfile model.authModel of
                        Nothing -> [ text "Please log in" ]
                        Just user ->
                            [ img [ height 50, width 50, src user.picture ] []
                            , text ("Welcome, " ++ user.given_name ++ ".")
                            ]
                    )
                , button
                    [ onClick (Authentication (if Authentication.isLoggedIn model.authModel then Authentication.LogOut else Authentication.ShowLogIn)) ]
                    [ text (if Authentication.isLoggedIn model.authModel then "Logout" else "Login")]
                ]
            ]
        ]

withoutEffect msg =
    ( msg, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Click ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )
        UpdateHello newName ->
            { model | nameInProgress = newName }
            |> withoutEffect
        MakeHello ->
            { model | name = model.nameInProgress }
            |> withoutEffect
        VBox1 vboxMsg ->
            { model | vbox1 = ValidationBox.update vboxMsg model.vbox1 }
            |> withoutEffect
        VBox2 vboxMsg ->
            { model | vbox2 = ValidationBox.update vboxMsg model.vbox2 }
            |> withoutEffect
        ResetTextBoxes ->
            { model
            | vbox1 = ValidationBox.update ValidationBox.Reset model.vbox1
            , vbox2 = ValidationBox.update ValidationBox.Reset model.vbox2
            }
            |> withoutEffect
        Healthcheck result ->
            { model | lastHealthcheck = result, healthcheckInProgress = False }
            |> withoutEffect
        TriggerHealthCheck ->
            ( { model | healthcheckInProgress = True } , performHealthcheck )
        Authentication authMsg ->
            let
                ( authModel, cmd ) = Authentication.update authMsg model.authModel
            in
                ( { model | authModel = authModel }, Cmd.map Authentication cmd )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ auth0authResult (Authentication.handleAuthResult >> Authentication)
        , Time.every (5 * Time.second) (always TriggerHealthCheck)
        ]


main : Program Never
main =
    Html.program
        { init = init
        , view = view
        , update = \msg model -> Debug.log (toString msg) (update msg model)
        , subscriptions = subscriptions
        }


performHealthcheck : Cmd Msg
performHealthcheck =
    Healthcheck.getHealthcheck "https://example.com/healthcheck"
    |> Task.perform
        (always (Result.Err () |> Healthcheck))
        (Healthcheck.rollupHealthchecks >> Result.Ok >> Healthcheck)

-- Auth0 Ports
port auth0showLock : Auth0.Options -> Cmd msg
port auth0authResult : (Auth0.RawAuthenticationResult -> msg) -> Sub msg