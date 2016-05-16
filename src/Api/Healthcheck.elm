module Api.Healthcheck
    exposing
        ( TestResult(..)
        , Tests
        , Healthcheck
        , getHealthcheck
        , rollupHealthchecks
        )

import Dict exposing (Dict)
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (Task)
import Time exposing (Time)


type TestResult
    = Failed
    | Passed


type alias Tests =
    { duration : Time
    , message : Maybe String
    , result : TestResult
    , testedAt : String
    }


type alias Healthcheck =
    { duration : Time
    , generatedAt : String
    , tests : Dict String Tests
    }


testResultDecoder : Json.Decoder TestResult
testResultDecoder =
    Json.string `Json.andThen` \s ->
        case s of
            "passed" -> Json.succeed Passed
            "failed" -> Json.succeed Failed
            _ -> Json.fail <| "Invalid test result: " ++ s


-- Elm has a nice alternate constructor for the type aliases, so `Tests` in the
-- function below can be read as:
-- (\d m r t -> { duration = d, message = m, result = r, testedAt = t })
testsDecoder : Json.Decoder Tests
testsDecoder =
    Json.object4 Tests
        ("duration_millis" := Json.float)
        (Json.maybe ("message" := Json.string))
        ("result" := testResultDecoder)
        ("tested_at" :=  Json.string)


healthcheckDecoder : Json.Decoder Healthcheck
healthcheckDecoder =
    Json.object3 Healthcheck
        ("duration_millis" := Json.float)
        ("generated_at" :=  Json.string)
        ("tests" := Json.dict testsDecoder)


getHealthcheck : String -> Task Http.Error Healthcheck
getHealthcheck url =
    Http.get healthcheckDecoder url
    |> Task.map (Debug.log "Result (success)")
    |> Task.mapError (Debug.log "Result (failure)")

rollupHealthchecks : Healthcheck -> TestResult
rollupHealthchecks hc =
    List.foldr
        (\t s ->
            case s of
                Failed -> Failed
                Passed -> t.result
        )
        Passed
        (Dict.values hc.tests)
