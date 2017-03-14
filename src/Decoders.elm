module Decoders exposing (..)

import Json.Decode as Json
import Json.Decode.Pipeline as JsonPipeline
import Date exposing (Date)
import Types exposing (..)


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
