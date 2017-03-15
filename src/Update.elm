port module Update exposing (..)

import Http
import Json.Encode
import Types exposing (..)
import Decoders exposing (..)


port sendToast : Json.Encode.Value -> Cmd msg



-- HTTP Calls


patch : String -> Http.Body -> Http.Request ()
patch url body =
    Http.request
        { method = "PATCH"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectStringResponse (\_ -> Ok ())
        , timeout = Nothing
        , withCredentials = False
        }


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


markItemPaid : BudgetItem -> Cmd Msg
markItemPaid budgetItem =
    let
        request =
            patch
                (baseUrl ++ "upcomingItems/" ++ (toString budgetItem.id))
                (Http.jsonBody <| Json.Encode.object [ ( "paid", Json.Encode.bool True ) ])

        parseFn result =
            case result of
                Ok _ ->
                    MarkItemPaidSuccess budgetItem

                Err err ->
                    MarkItemPaidFailed budgetItem err
    in
        Http.send parseFn request


init : ( Model, Cmd Msg )
init =
    ( { upcomingItems = [], errorMessage = Nothing, upcomingItemsLoading = True }
    , getUpcomingItems 2
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetUpcomingItemsSuccess items ->
            { model | upcomingItems = items, upcomingItemsLoading = False } ! [ Cmd.none ]

        GetUpcomingItemsFailed err ->
            { model | upcomingItems = [], upcomingItemsLoading = False }
                ! [ ToastMessage Error "There was a problem loading upcoming items"
                        |> encodeToastMessage
                        |> sendToast
                  ]

        MarkItemPaid budgetItem ->
            ( { model | upcomingItems = List.filter ((/=) budgetItem) model.upcomingItems }
            , Cmd.batch
                [ markItemPaid budgetItem
                , ToastMessage Info ("Item marked as paid: " ++ budgetItem.description)
                    |> encodeToastMessage
                    |> sendToast
                ]
            )

        MarkItemPaidSuccess budgetItem ->
            ( model
            , ToastMessage Success ("Item successfully marked as paid: " ++ budgetItem.description)
                |> encodeToastMessage
                |> sendToast
            )

        MarkItemPaidFailed budgetItem err ->
            ( { model | upcomingItems = model.upcomingItems ++ [ budgetItem ] }
            , ToastMessage Error ("Item was not marked as paid: " ++ budgetItem.description)
                |> encodeToastMessage
                |> sendToast
            )

        RemoveItem budgetItem ->
            ( { model | upcomingItems = List.filter ((/=) budgetItem) model.upcomingItems }
            , Cmd.batch
                [ ToastMessage Info ("Item removed: " ++ budgetItem.description)
                    |> encodeToastMessage
                    |> sendToast
                ]
            )
