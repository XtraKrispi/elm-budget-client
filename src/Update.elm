port module Update exposing (..)

import Http
import Json.Encode
import Types exposing (..)
import Decoders exposing (..)


port sendToast : Json.Encode.Value -> Cmd msg



-- HTTP Calls


baseUrl : String
baseUrl =
    "http://localhost:8080/"


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

        MarkItemPaid budgetItem ->
            ( model
            , ToastMessage Info ("Item marked as paid: " ++ budgetItem.description)
                |> encodeToastMessage
                |> sendToast
            )
