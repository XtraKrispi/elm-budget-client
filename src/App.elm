module App exposing (..)

import Html exposing (..)
import Date exposing (Date)


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias BudgetItem =
    { id : Int
    , description : String
    , amount : Float
    , dueDate : Date
    }


type alias Model =
    { upcomingItems : List BudgetItem
    }


type Msg
    = NoOp


init : ( Model, Cmd Msg )
init =
    ( { upcomingItems = [] }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [] [ text "Hello! World!" ]
