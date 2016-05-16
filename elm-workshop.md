# Elm Workshop with 0.17

## Opening notes

This workshop uses webpack as a host for building and deploying the Elm site. Once you have run
`npm start`, webpack should start up in its development mode on port 8080. Then, as you make
changes you should be able to see webpack hot-reload the Elm modules and see updates in your
browser. Each time this happens, your Elm program will revert back to the initial state.

Bootstrap is being used as a CSS library for this project. You can substitute whatever CSS you'd
like by updating either `web/index.html` or `web/index.js`.

If, after a reload, you see a blank page, then it is likely that the Elm compiler reported an
error. You may see an error reported in the JavaScript console, indicating that it was unable
to find the Elm module. If that is the case, jump over to the webpack console and see if Elm
reported any errors. Try and understand what the error message is indicating, and that should
help you get back on track.

Many of the steps below can be copied and pasted into the appropriate sections of the code.
Modules `Auth0`, `Authentication`, and `Api.Healthcheck` are provided at the start and will be
referenced as you move further into the workshop. These are provided to speed up some of the
workshop steps, but should be reviewed to make sure you understand what is happening.

It should be noted that although we are placing a large amount of functionality into the `Main`
module, this is for demonstration purposes. It is better overall to separate out some of the state
and functions into separate modules that you import as needed.

The finished state of this workshop can be seen in the `end-of-workshop` branch.

If you have any questions, feel free to reach out. I am on Twitter as [@neoeinstein][] and you can
also find me in the [Elm Slack](https://elmlang.herokuapp.com).

  [@neoeinstein]: https://twitter.com/neoeinstein

## Hello World

### Initial start

Prepare a basic program.

* Create a `Main.elm` in the `src` directory
* `main` is the entrypoint
* Elm program is composed of `Model`, `view`, and `update`

```elm
module Main exposing (..)

import Html
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
```

### Add structure

Expand `view` to use a div that uses the bootstrap `container` class

```elm
import Html.Attributes exposing (..)

view model =
    div
        []
        [ div
            [ class "container" ]
            [ text ("Hello, " ++ model.name ++ "!") ]
        ]
```

## User Interaction

### Messages as user input

Accept a button click and update our internal state

* Create a `Click` message
* Add a counter into the model
* Add a button to `view` that triggers the `Click` message
 * `onClick` adds a JS event that will trigger a `Click` message to be sent to `update`
* Update the update to increment the counter on each click
 * Note the syntax for "mutating" the model

```elm
import Html.Events exposing (..)

type Msg = Click

model =
    { name = "Marcus"
    , clicks = 0
    }

view model =
    div
        []
        [ div
            [ class "container" ]
            [ text ("Hello, " ++ model.name ++ "!")
            , button
                [ onClick Click ]
                [ text ("I've been clicked " ++ (toString model.clicks) ++ " times") ]
            ]
        ]

update msg model =
    case msg of
        Click ->
            { model | clicks = model.clicks + 1 }
```

### Digression: Signatures

Type signatures allow the compiler to check your work and make sure that your functions have
the types you expect.

* The signatures for `model`, `view`, `update`, and `main` are all inferred
* Define a `type alias` for the model
* Add some actual signatures

```elm
type alias Model =
    { name : String
    , clicks : Int
    }

model : Model

view : Model -> Html Msg

update : Msg -> Model -> Model

main : Program Never
```

`Program Never` basically means that it is a program that doesn't accept any initial inputs. If you
want to accept initial inputs, then you can use `Html.programWithFlags`.

### Digression: Error messages

Elm has some great error messages, so let's intentionally cause some errors.

* Modify `view` to use `model.world` instead of `model.name` and see the error message
* Add a case to `Msg`: `type Msg = Click | Clack`; see the error message about missing cases in `update`
* Modify `view` to call `txt` instead of `text`; see the error message

### Digression: Debug logging

Sometimes you want to see what is going on inside your program. Debug logging is a side-effect, but for
our purposes it is relatively safe. Let's update `main` to show the new model every time `update` is
called.

```elm
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = \msg model -> Debug.log (toString msg) (update msg model)
        }
```

Now whenever `update` is called, we'll see what the message was as well as the new model produced after being
pumped through our `update` function.

### Getting some text input

We'll add a little update that can allow us to update the name in our example.

* Add a case to `Msg` that accepts a `String`
* Add a text input to `view` that sends a message when the text changes
* Add a case to `update` to handle the new case

```elm
type Msg
    = Click
    | UpdateHello String

view model =
    div
        []
        [ div
            [ class "container" ]
            [ text ("Hello, " ++ model.name ++ "!")
            , input
                [ type' "text"
                , placeholder "Who should I say hello to?"
                , value model.name
                , onInput UpdateHello
                ]
                []
            , button
                [ onClick Click ]
                [ text ("I've been clicked " ++ (toString model.clicks) ++ " times") ]
            ]
        ]

update msg model =
    case msg of
        Click ->
            { model | clicks = model.clicks + 1 }
        UpdateHello name ->
            { model | name = name }
```

* Modify the text box to send a message only when the input loses focus: `onBlur`

```elm
type Msg
    = Click
    | UpdateHello String
    | MakeHello

type alias Model =
    { name : String
      nameInProgress : String
      click : Int
    }

model =
    { name = "Marcus"
    , nameInProgress = "Marcus"
    , clicks = 0
    }

view model =
    div
        []
        [ div
            [ class "container" ]
            [ text ("Hello, " ++ model.name ++ "!")
            , input
                [ type' "text"
                , placeholder "Who should I say hello to?"
                , value model.name
                , onInput UpdateHello
                , onBlur MakeHello
                ]
                []
            , button
                [ onClick Click ]
                [ text ("I've been clicked " ++ (toString model.clicks) ++ " times") ]
            ]
        ]

update msg model =
    case msg of
        Click ->
            { model | clicks = model.clicks + 1 }
        UpdateHello name ->
            { model | name = name }
```


## Creating components

> From here on, I will often be omitting sections of the code that have already been provided.
> Instead, I will provide the function where the addition should be made and give the addition
> with the appropriate level of indentation. Usually you can just add the new code to the end
> of the code block at the appropriate level of indentation.

Let's build a re-usable input box that supports custom validation and will present the input box
in a common way.

### Structuring components

* Create a `ValidationBox.elm` file in `src/Components`
* Components look a lot like our program, but without `main`
* Create Validation Box component by adding some core functionality
* Note that we are explicit about what we are exposing
 * The `Model` type is exposed, but the `Model.Model` data constructor is not exposed. This means
   that only this module can actually inspect the model, and so we provide `tryGetValue` to extract
   the text. We'll pre-emptively make it return a `Maybe String` since we don't want to return a
   value if it isn't valid.

```elm
module Components.ValidationBox
    exposing
        ( Msg(..)
        , Model
        , InitialParams
        , init, update, view
        , tryGetValue
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

tryGetValue : Model -> Maybe String
tryGetValue (Model model) =
    Just model.text
```

### Hook into main view

We'll hook in two example input boxes into our main view. In `Main.elm` we need to add:

```elm
import Components.ValidationBox as ValidationBox

type Msg
    | VBox1 ValidationBox.Msg
    | VBox2 ValidationBox.Msg

type alias Model =
    , vbox1 : ValidationBox.Model
    , vbox2 : ValidationBox.Model

initialModel =
    , vbox1 =
        ValidationBox.init
            { id = "vbox1"
            , initialText = "some text"
            }
    , vbox2 =
        ValidationBox.init
            { id = "vbox2"
            , initialText = "0"
            }

update msg model =
        VBox1 vboxMsg ->
            { model | vbox1 = ValidationBox.update vboxMsg model.vbox1 }
        VBox2 vboxMsg ->
            { model | vbox2 = ValidationBox.update vboxMsg model.vbox2 }

view model =
            , Html.map VBox1 (ValidationBox.view model.vbox1)
            , Html.map VBox2 (ValidationBox.view model.vbox2)
```

### Expand responsibilities

Adding a label, some placeholder text, and some help text are common patterns for this input,
so let's make it easy for consumers to optionally specify them.

In `Components/ValidationBox.elm`:

```elm
type Model
    = Model
        , label : Maybe String
        , placeholder : Maybe String
        , helpText : Maybe String


type alias InitialParams =
    , label : Maybe String
    , placeholder : Maybe String
    , helpText : Maybe String

view (Model model) =
    let
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
            [ input (List.concat [inputAttr, placeholderAttr]) [] ]
    in
        div
            [ class "form-group" ]
            ( List.concat
                [ labelElement
                , inputElements
                , helpBlockElement
                ]
            )
```

In `Main.elm`:

```elm
    , vbox1 =
        ValidationBox.init
            { id = "vbox1"
            , initialText = "some text"
            , label = Just "First Field"
            , placeholder = Just "Type here"
            , helpText = Just "Really, just type above..."
            }
    , vbox2 =
        ValidationBox.init
            { id = "vbox2"
            , initialText = "0"
            , label = Just "Second Field"
            , placeholder = Nothing
            , helpText = Just "Must be a number that doesn't start with 0"
```

We also want to allow a consumer to reset the input boxes to their "initial" state

```elm
type Msg
    | Reset

type Model
    = Model
        , initialText : String

type alias InitialParams =
    , initialText : String


init ps =
            , initialText = ps.initialText

update msg model =
                Reset ->
                    { model
                    | text = model.initialText
                    , validationResult = model.initialText |> model.validate
                    }
```

Add to `Main.elm`:

```elm
type Msg
    | ResetTextBoxes

view model =
            , div
                []
                [ button
                    [ onClick ResetTextBoxes ]
                    [ text "Reset" ]
                ]

update msg model =
        ResetTextBoxes ->
            { model
            | vbox1 = ValidationBox.update ValidationBox.Reset model.vbox1
            , vbox2 = ValidationBox.update ValidationBox.Reset model.vbox2
            }
```

The change to `update` could also be written as:

```elm
pipeUpdate : ( Msg -> Model -> Model ) -> Msg -> Model -> Model
pipeUpdate update msg ( model, cmd ) =
    newModel = update msg model

update msg model =
        ResetTextBoxes ->
            update (VBox1 ValidationBox.Reset) model
            |> pipeUpdate update (VBox2 ValidationBox.Reset)
```

Sometimes we want to normalize the text in the input box. For example, our second text box should
only accept digits.

In `Components/ValidationBox.elm`:

```elm
type Model
    = Model
        , normalize : String -> String

type alias InitialParams =
    , normalize : String -> String

init ps =
        normalizedInitialText = ps.initialText |> ps.normalize
            , initialText = normalizedInitialText
            , normalize = ps.normalize
            , text = normalizedInitialText

update msg model =
                UpdateText newText ->
                    let
                        normalizedText = newText |> model.normalize
                    in
                        { model
                        | text = normalizedText
                        }
```

In `Main.elm`:

```elm
import Char
import String

model =
    , vbox1 =
            , normalize = identity
    , vbox2 =
            , normalize = String.filter Char.isDigit
```

Now we want to actually validate the input provided by the user. Let's add validation, and then
update `tryGetValue` to only return a value if the validation result is good.

In `Components/ValidationBox.elm`:

```elm
type Model
    = Model
        , validate : String -> Result String ()
        , validationResult : Result String ()

type alias InitialParams =
    , validate : String -> Result String ()


init ps =
            , validate = ps.validate
            , validationResult = normalizedInitialText |> ps.validate


update msg model =
                UpdateText newText ->
                        , validationResult = normalizedText |> model.validate

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
```

In `Main.elm`:

```elm
model =
    , vbox1 =
            , validate = always (Result.Ok ())
    , vbox2 =
            , validate = \s -> if String.startsWith "0" s then Result.Err "Nope" else Result.Ok ()
```

### Next steps

Perhaps validation should try to create a value rather than just return `Ok` or `Err`. We could
parameterize our `Model` type to accept a type like the following:

```elm
type Model a
    = Model
        , validate : String -> Result String a
        , validationResult : Result String a

type alias InitialParams a =
    , validate : String -> Result String a


tryGetValue : Model a -> Result String a
tryGetValue (Model model) =
    model.validationResult
```

Integrating this change is left as an exercise for you. Try using chaining the `toInt` function to
the existing validation on `vbox2` in `Main`.

## Interacting with the world

### Subscriptions and commands

First we need to get off the `beginnerProgram` paradigm and begin dealing with subscriptions `Sub`
and commands `Cmd`.

* Update `Main.elm` to use `Html.App.program` instead of `Html.App.beginnerProgram`

```elm
-- INIT
-- Add an init which pairs the initial model with Cmd.none

init : ( Model, Cmd Msg )
init = ( model, Cmd.none )

-- UPDATE
-- Most now return tuple of a model and Cmd.none
-- Repeat as necessary for each case in update
-- for example:

withoutEffect : Model -> ( Model, Cmd Msg )
withoutEffect model =
    model ! []

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Click ->
            withoutEffect { model | count = model.count + 1 }

-- VIEW
-- no change to the view

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none


main : Program Never
main =
    Html.program
        { init = init
        , update = \msg model -> Debug.log (toString msg) (update msg model)
        , view = view
        , subscriptions = subscriptions
        }
```

There is now a way to re-write the `ResetTextBoxes` case in `update`:

```elm
pipeUpdate : ( Msg -> Model -> ( Model, Cmd Msg ) ) -> Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
pipeUpdate update msg ( model, cmd ) =
    let
        ( newModel, newCmd ) = update msg model
    in
        ( newModel, Cmd.batch [ cmd, newCmd ] )

update msg model =
        ResetTextBoxes ->
            update (VBox1 ValidationBox.Reset) model
            |> pipeUpdate update (VBox2 ValidationBox.Reset)
```

### Hitting a healthcheck

Add a case to `Msg` for a healthcheck message. The `Api.Healthcheck` module allows getting the
result of a healthcheck as defined in [healthcheck.spec][], with one minor change: I use "message"
instead of "error", and can return a message in the event of a success too.

`Api.Healthcheck` has a good example of how the `Json.Decode` decoders work.

  [healthcheck.spec]: https://github.com/Cimpress-MCP/healthcheck.spec

```elm
import Api.Healthcheck as Healthcheck
import Time exposing (Time)

type Msg
    | TriggerHealthCheck
    | Healthcheck (Result () Healthcheck.TestResult)

type alias Model =
    , lastHealthcheck : Result () Healthcheck.TestResult
    , healthcheckInProgress : Bool

model =
    , lastHealthcheck = Result.Err ()
    , healthcheckInProgress = False

init =
    ( { model | healthCheckInProgress = True } , performHealthcheck )

subscriptions model =
    Time.every (30 * Time.second) (always TriggerHealthCheck)

update msg model =
    case msg of
        TriggerHealthCheck ->
            ( { model | healthCheckInProgress = True }, performHealthcheck )
        Healthcheck (Ok result) ->
            withoutEffect { model | lastHealthCheck = result, healthCheckInProgress = False }

view model =
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

performHealthcheck : Cmd Msg
performHealthcheck =
    Healthcheck.getHealthcheck "http://example.com/healthcheck"
    |> Task.perform
        (always (Result.Err () |> Healthcheck))
        (Healthcheck.rollupHealthchecks >> Result.Ok >> Healthcheck)
```

## Ports

We also want to be able to interop with JavaScript. That's where ports come in.

`Auth0` and `Authentication` modules are provided for you, but you should take a look and make
sure you understand how they work.

```elm
port module Main exposing (..)

import Auth0
import Authentication

type Msg
    | Authentication Authentication.Msg

type alias Model =
    , authModel : Authentication.Model

init =
    , authModel = Authentication.init auth0showLock

update msg model =
    case msg of
        Authentication authMsg ->
            let
                ( authModel, cmd ) = Authentication.update authMsg model.authModel
            in
                ( { model | authModel = authModel }, Cmd.map Authentication cmd )

subscriptions model =
    Sub.batch
        [ Time.every (30 * Time.second) (always TriggerHealthCheck)
        , auth0authResult (Authentication.handleAuthResult >> Authentication)
        ]

view model =
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

-- Auth0 Ports
port auth0showLock : Auth0.Options -> Cmd msg
port auth0authResult : (Auth0.RawAuthenticationResult -> msg) -> Sub msg
```

In `web/index.js` update the following. This part assumes that you already have an Auth0
application, and have a client id and auth0 domain.

```javascript
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
```

## Tools and links

* packages: http://package.elm-lang.org/
* elm-format: https://github.com/avh4/elm-format
