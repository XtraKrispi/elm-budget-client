module View exposing (..)

import Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Date.Format as DateFormat
import NumberFormat as NumFormat
import Date exposing (Date)


formatFriendlyDate : Date -> String
formatFriendlyDate =
    DateFormat.format "%B %e %Y"


formatCurrency : Float -> String
formatCurrency =
    NumFormat.pretty 2 ',' '.'


viewBudgetItem : BudgetItem -> Html Msg
viewBudgetItem ({ id, description, amount, dueDate } as budgetItem) =
    div [ class "panel panel-default budget-item" ]
        [ div [ class "panel-body" ]
            [ div [ class "row" ]
                [ div [ class "col-sm-6" ]
                    [ div [ class "description" ] [ text description ]
                    ]
                , div [ class "col-sm-6" ]
                    [ div [ class "amount" ] [ text <| "$" ++ formatCurrency amount ]
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-sm-8" ]
                    [ div [ class "due-date" ] [ text <| formatFriendlyDate dueDate ]
                    ]
                , div [ class "col-sm-4" ]
                    [ div [ class "budget-item-actions" ]
                        [ a [ class "mark-paid", onClick (MarkItemPaid budgetItem) ] [ i [ class "glyphicon glyphicon-ok" ] [] ]
                        , a [ class "remove-item", onClick (RemoveItem budgetItem) ] [ i [ class "glyphicon glyphicon-trash" ] [] ]
                        ]
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        sortedUpcomingItems =
            List.sortWith
                (\budgetItem1 budgetItem2 ->
                    case compare (Date.toTime budgetItem1.dueDate) (Date.toTime budgetItem2.dueDate) of
                        LT ->
                            LT

                        GT ->
                            GT

                        EQ ->
                            case compare budgetItem1.id budgetItem2.id of
                                LT ->
                                    LT

                                GT ->
                                    GT

                                EQ ->
                                    EQ
                )
    in
        div [ class "container" ]
            [ div [ class "col-sm-4" ]
                [ h3 [] [ text "Upcoming Items" ]
                , if model.upcomingItemsLoading == True then
                    div [] [ text "Loading..." ]
                  else
                    case model.upcomingItems of
                        [] ->
                            div [] [ text "No items" ]

                        _ ->
                            div [] <|
                                List.map viewBudgetItem <|
                                    sortedUpcomingItems model.upcomingItems
                ]
            , div [ class "col-sm-4" ] []
            , div [ class "col-sm-4" ] []
            ]
