port module Update exposing (..)

import Http
import Json.Encode
import Types exposing (..)
import Decoders exposing (..)
import Date.Extra


port sendToast : Json.Encode.Value -> Cmd msg


port confirmItemRemoval : Json.Encode.Value -> Cmd msg


port confirmItemRemovalResponse : ({ budgetItemId : Int, confirmed : Bool } -> msg) -> Sub msg



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


encodeBudgetItem : BudgetItem -> Json.Encode.Value
encodeBudgetItem { id, description, amount, dueDate } =
    Json.Encode.object
        [ ( "id", Json.Encode.int id )
        , ( "description", Json.Encode.string description )
        , ( "amount", Json.Encode.float amount )
        , ( "dueDate", Json.Encode.string <| Date.Extra.toIsoString dueDate )
        ]


getUpcomingItems : NumberOfWeeks -> Cmd Msg
getUpcomingItems n =
    let
        request =
            Http.get (baseUrl ++ "upcomingItems?paid=false&deleted=false&weeks=" ++ (toString n)) budgetItemsDecoder

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


removeItem : BudgetItem -> Cmd Msg
removeItem budgetItem =
    let
        request =
            patch
                (baseUrl ++ "upcomingItems/" ++ (toString budgetItem.id))
                (Http.jsonBody <| Json.Encode.object [ ( "deleted", Json.Encode.bool True ) ])

        parseFn result =
            case result of
                Ok _ ->
                    RemoveItemSuccess budgetItem

                Err err ->
                    RemoveItemFailed budgetItem err
    in
        Http.send parseFn request


init : ( Model, Cmd Msg )
init =
    ( { upcomingItems = [], errorMessage = Nothing, upcomingItemsLoading = True, scratchAreaItems = [], scratchAreaNewItemDescription = Nothing, scratchAreaNewItemAmount = Nothing }
    , getUpcomingItems 2
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    confirmItemRemovalResponse (\{ budgetItemId, confirmed } -> ConfirmItemRemoval budgetItemId confirmed)


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
            ( model
            , confirmItemRemoval (encodeBudgetItem budgetItem)
            )

        RemoveItemSuccess budgetItem ->
            ( model
            , ToastMessage Success ("Item successfully removed: " ++ budgetItem.description)
                |> encodeToastMessage
                |> sendToast
            )

        RemoveItemFailed budgetItem err ->
            ( { model | upcomingItems = model.upcomingItems ++ [ budgetItem ] }
            , ToastMessage Error ("Item was not removed: " ++ budgetItem.description)
                |> encodeToastMessage
                |> sendToast
            )

        ConfirmItemRemoval budgetItemId confirmed ->
            let
                budgetItem =
                    (List.head << List.filter (\{ id } -> id == budgetItemId)) model.upcomingItems
            in
                case budgetItem of
                    Just item ->
                        if confirmed then
                            { model | upcomingItems = List.filter ((/=) item) model.upcomingItems }
                                ! [ removeItem item
                                  , ToastMessage Info ("Item removed: " ++ item.description)
                                        |> encodeToastMessage
                                        |> sendToast
                                  ]
                        else
                            ( model, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )

        ScratchItemChanged sItem amt ->
            { model
                | scratchAreaItems =
                    List.map
                        (\(( s, a ) as sI) ->
                            if sI == sItem then
                                ( s, amt )
                            else
                                sI
                        )
                        model.scratchAreaItems
            }
                ! [ Cmd.none ]

        ScratchItemNewDescription desc ->
            { model
                | scratchAreaNewItemDescription =
                    if desc == "" then
                        Nothing
                    else
                        Just desc
            }
                ! [ Cmd.none ]

        ScratchItemNewAmount amt ->
            { model
                | scratchAreaNewItemAmount =
                    if amt == 0 then
                        Nothing
                    else
                        Just amt
            }
                ! [ Cmd.none ]

        AddNewScratchItem ->
            let
                newItem =
                    case model.scratchAreaNewItemDescription of
                        Just desc ->
                            case model.scratchAreaNewItemAmount of
                                Just amt ->
                                    [ ( desc, amt ) ]

                                Nothing ->
                                    []

                        Nothing ->
                            []
            in
                { model | scratchAreaItems = model.scratchAreaItems ++ newItem, scratchAreaNewItemAmount = Nothing, scratchAreaNewItemDescription = Nothing } ! [ Cmd.none ]

        RemoveScratchItem item ->
            { model | scratchAreaItems = List.filter ((/=) item) model.scratchAreaItems } ! [ Cmd.none ]
