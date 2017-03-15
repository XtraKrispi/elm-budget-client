module App exposing (..)

import Html exposing (program)
import Types exposing (Model, Msg)
import View exposing (..)
import Update exposing (..)


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
