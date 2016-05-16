module Components.ValidationBox
    exposing
        ( Msg(..)
        , Model
        , InitialParams
        , init
        , update
        , view
        , tryGetValue
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type Msg
    = UpdateText String
    | Reset

type Model
    = Model
        { id : String
        , text : String
        , label : Maybe String
        , placeholder : Maybe String
        , helpText : Maybe String
        , initialText : String
        , normalize : String -> String
        , validate : String -> Result String ()
        , validationResult : Result String ()
        }


type alias InitialParams =
    { id : String
    , initialText : String
    , label : Maybe String
    , placeholder : Maybe String
    , helpText : Maybe String
    , normalize : String -> String
    , validate : String -> Result String ()
    }


init : InitialParams -> Model
init ps =
    let
        normalizedText = ps.normalize ps.initialText
    in
        Model
            { id = ps.id
            , text = normalizedText
            , label = ps.label
            , placeholder = ps.placeholder
            , helpText = ps.helpText
            , initialText = normalizedText
            , normalize = ps.normalize
            , validate = ps.validate
            , validationResult = ps.validate normalizedText
            }

update : Msg -> Model -> Model
update msg (Model model) =
    Model
        ( case msg of
            UpdateText newText ->
                let
                    normalizedText = model.normalize newText
                in
                    { model
                    | text = normalizedText
                    , validationResult = model.validate normalizedText
                    }
            Reset ->
                { model
                | text = model.initialText
                , validationResult = model.validate model.initialText
                }
        )

view : Model -> Html Msg
view (Model model) =
    let
        isSuccess = model.validationResult |> Result.map (\() -> True) |> Result.toMaybe |> Maybe.withDefault False
        placeholderAttr =
            case model.placeholder of
                Just p -> [ placeholder p ]
                Nothing -> []
        inputAttr =
            [ id model.id
            , type' "text"
            , value model.text
            , onInput UpdateText
            , class "form-control"
            ]
        labelElement =
            case model.label of
                Just l -> [ label [ for model.id ] [ text l ] ]
                Nothing -> []
        helpBlockElement =
            case model.helpText of
                Just ht -> [ p [ class "help-block" ] [ text ht ] ]
                Nothing -> []
        inputElements =
            [ input (List.concat [inputAttr, placeholderAttr]) []
            , span [ classList [ ( "glyphicon", True ), ( "glyphicon-ok", isSuccess ), ( "glyphicon-remove", not isSuccess ), ("form-control-feedback", True ) ] ] []
            ]
    in
        div
            [ classList [ ( "form-group", True ), ( "has-success", isSuccess ), ( "has-error", not isSuccess ), ( "has-feedback", True ) ] ]
            ( List.concat
                [ labelElement
                , inputElements
                , helpBlockElement
                ]
            )

tryGetValue : Model -> Maybe String
tryGetValue (Model model) =
    case model.validationResult of
        Ok () -> Just model.text
        Err _ -> Nothing
