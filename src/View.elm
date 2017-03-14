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
                        , a [ class "remove-item" ] [ i [ class "glyphicon glyphicon-trash" ] [] ]
                        ]
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "col-sm-4" ]
            [ h3 [] [ text "Upcoming Items" ]
            , div [] <| List.map viewBudgetItem model.upcomingItems
            ]
        , div [ class "col-sm-4" ] []
        , div [ class "col-sm-4" ] []
        ]
