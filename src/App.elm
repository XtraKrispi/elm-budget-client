port module App exposing (..)

import Html exposing (..)
import Date exposing (Date)
import Http
import Json.Decode as Json
import Json.Decode.Pipeline as JsonPipeline
import Json.Encode


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type ToastMessageType
    = Success
    | Warning
    | Info
    | Error


type ToastMessage
    = ToastMessage ToastMessageType String


port sendToast : Json.Encode.Value -> Cmd msg


type alias BudgetItem =
    { id : Int
    , description : String
    , amount : Float
    , dueDate : Date
    }


type alias Model =
    { upcomingItems : List BudgetItem
    , errorMessage : Maybe String
    }


type alias NumberOfWeeks =
    Int


type Msg
    = GetUpcomingItemsSuccess (List BudgetItem)
    | GetUpcomingItemsFailed Http.Error



-- HTTP Calls


baseUrl : String
baseUrl =
    "http://localhost:8080/"


customDecoder : Json.Decoder b -> (b -> Result String a) -> Json.Decoder a
customDecoder decoder toResult =
    Json.andThen
        (\a ->
            case toResult a of
                Ok b ->
                    Json.succeed b

                Err err ->
                    Json.fail err
        )
        decoder


dateDecoder : Json.Decoder Date
dateDecoder =
    customDecoder Json.string Date.fromString


budgetItemDecoder : Json.Decoder BudgetItem
budgetItemDecoder =
    JsonPipeline.decode BudgetItem
        |> JsonPipeline.required "id" Json.int
        |> JsonPipeline.required "description" Json.string
        |> JsonPipeline.required "amount" Json.float
        |> JsonPipeline.required "dueDate" dateDecoder


budgetItemsDecoder : Json.Decoder (List BudgetItem)
budgetItemsDecoder =
    Json.list budgetItemDecoder


encodeToastMessage : ToastMessage -> Json.Encode.Value
encodeToastMessage (ToastMessage msgType message) =
    let
        messageTypeString =
            case msgType of
                Success ->
                    "success"

                Warning ->
                    "warning"

                Info ->
                    "info"

                Error ->
                    "error"
    in
        Json.Encode.object
            [ ( "type", Json.Encode.string messageTypeString )
            , ( "message", Json.Encode.string message )
            ]


getUpcomingItems : NumberOfWeeks -> Cmd Msg
getUpcomingItems n =
    let
        request =
            Http.get (baseUrl ++ "upcomingItems?weeks=" ++ (toString n)) budgetItemsDecoder

        parseFn result =
            case result of
                Ok r ->
                    GetUpcomingItemsSuccess r

                Err err ->
                    GetUpcomingItemsFailed err
    in
        Http.send parseFn request


init : ( Model, Cmd Msg )
init =
    ( { upcomingItems = [], errorMessage = Nothing }, getUpcomingItems 2 )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetUpcomingItemsSuccess items ->
            { model | upcomingItems = items } ! [ Cmd.none ]

        GetUpcomingItemsFailed err ->
            { model | upcomingItems = [] }
                ! [ ToastMessage Error "There was a problem loading upcoming items"
                        |> encodeToastMessage
                        |> sendToast
                  ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [] [ text "Hello! World!" ]
