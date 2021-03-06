module View exposing (..)

import Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, type_, value, property, style, disabled, href)
import Html.Events exposing (onClick, onInput, onSubmit)
import Date.Extra
import NumberFormat as NumFormat
import Date exposing (Date)
import Json.Encode as Json


{-| Create arbitrary floating-point *properties*.
-}
floatProperty : String -> Float -> Attribute msg
floatProperty name float =
    property name (Json.float float)


{-| Uses `valueAsNumber` to update an input with a floating-point value.
This should only be used on <input> of type `number`, `range`, or `date`.
It differs from `value` in that a floating point value will not necessarily overwrite the contents on an input element.
    valueAsFloat 2.5 -- e.g. will not change the displayed value for input showing "2.5000"
    valueAsFloat 0.4 -- e.g. will not change the displayed value for input showing ".4"
-}
valueAsFloat : Float -> Attribute msg
valueAsFloat value =
    floatProperty "valueAsNumber" value


formatFriendlyDate : Date -> String
formatFriendlyDate =
    Date.Extra.toFormattedString "MMMM dd YYYY"


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


scratchArea : Model -> Html Msg
scratchArea model =
    let
        snd ( a, b ) =
            b

        totalUpcoming =
            List.foldr ((+) << .amount) 0 model.upcomingItems

        viewScratchAreaItem (( t, a ) as scratchItem) =
            form [ class "row", onSubmit <| RemoveScratchItem scratchItem ]
                [ div [ class "col-sm-5" ] [ text t ]
                , div [ class "col-sm-5" ]
                    [ div [ class "input-group" ]
                        [ span [ class "input-group-addon" ] [ text "$" ]
                        , input
                            [ type_ "number"
                            , class "form-control text-right"
                            , style [ ( "padding-right", "0px" ) ]
                            , valueAsFloat a
                            , onInput (ScratchItemChanged scratchItem << Result.withDefault 0 << String.toFloat)
                            ]
                            []
                        ]
                    ]
                , div [] [ button [ type_ "submit", class "btn btn-link remove-scratch-item" ] [ i [ class "glyphicon glyphicon-minus-sign" ] [] ] ]
                ]

        totalScratchItems =
            List.foldr ((+) << snd) 0 model.scratchAreaItems

        totalRemaining =
            totalUpcoming - totalScratchItems

        isScratchButtonDisabled =
            case model.scratchAreaNewItemDescription of
                Just desc ->
                    case model.scratchAreaNewItemAmount of
                        Just amt ->
                            False

                        Nothing ->
                            True

                Nothing ->
                    True
    in
        div [] <|
            [ div [ class "row" ]
                [ div [ class "col-sm-5" ] [ text "Total Upcoming" ]
                , div [ class "col-sm-5 text-right" ] [ text <| "$" ++ formatCurrency totalUpcoming ]
                ]
            ]
                ++ (List.map viewScratchAreaItem model.scratchAreaItems)
                ++ [ form [ class "row", onSubmit AddNewScratchItem ]
                        [ div [ class "col-sm-5" ] [ input [ class "form-control", type_ "text", value (Maybe.withDefault "" model.scratchAreaNewItemDescription), onInput ScratchItemNewDescription ] [] ]
                        , div [ class "col-sm-5" ]
                            [ div [ class "input-group" ]
                                [ span [ class "input-group-addon" ] [ text "$" ]
                                , input
                                    [ type_ "number"
                                    , class "form-control text-right"
                                    , style [ ( "padding-right", "0px" ) ]
                                    , valueAsFloat (Maybe.withDefault 0 model.scratchAreaNewItemAmount)
                                    , onInput (ScratchItemNewAmount << Result.withDefault 0 << String.toFloat)
                                    ]
                                    []
                                ]
                            ]
                        , div [] [ button [ type_ "submit", class "btn btn-link add-scratch-item", disabled isScratchButtonDisabled ] [ i [ class "glyphicon glyphicon-plus-sign" ] [] ] ]
                        ]
                   , div [ class "row" ]
                        [ div [ class "col-sm-5" ] [ text "Total Remaining" ]
                        , div [ class "col-sm-5 text-right" ] [ text <| "$" ++ formatCurrency totalRemaining ]
                        ]
                   ]


homeView : Model -> Html Msg
homeView model =
    let
        sortedUpcomingItems =
            List.sortWith
                (\budgetItem1 budgetItem2 ->
                    case Date.Extra.compare budgetItem1.dueDate budgetItem2.dueDate of
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
        div []
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
            , div [ class "col-sm-4" ]
                [ h3 [] [ text "Scratch Area" ]
                , scratchArea model
                ]
            , div [ class "col-sm-4" ] []
            ]


formattedFrequency : Frequency -> String
formattedFrequency frequency =
    case frequency of
        OneTime ->
            "One Time"

        Weekly ->
            "Weekly"

        BiWeekly ->
            "Bi-Weekly"

        Monthly ->
            "Monthly"


budgetItemAdminView : Model -> Html Msg
budgetItemAdminView model =
    let
        budgetItemRow ({ id, description, amount, startDate, frequency } as def) =
            let
                isEditing =
                    case model.editingBudgetItemDefinition of
                        Nothing ->
                            False

                        Just editingDef ->
                            id == editingDef.id
            in
                if isEditing then
                    tr []
                        [ td [] [ input [ type_ "text", class "form-control", value description ] [] ]
                        , td []
                            [ text <| formattedFrequency frequency ]
                        , td []
                            [ text <| formatFriendlyDate startDate ]
                        , td []
                            [ text <| "$" ++ formatCurrency amount ]
                        , td [ class "tools" ]
                            [ div [ class "btn-group" ]
                                [ button [ type_ "button", class "btn btn-default" ] [ span [ class "glyphicon glyphicon-ok" ] [] ]
                                , button [ type_ "button", class "btn btn-default", onClick CancelEditingBudgetItemDefinition ] [ span [ class "glyphicon glyphicon-remove" ] [] ]
                                ]
                            ]
                        ]
                else
                    tr []
                        [ td []
                            [ text description ]
                        , td []
                            [ text <| formattedFrequency frequency ]
                        , td []
                            [ text <| formatFriendlyDate startDate ]
                        , td []
                            [ text <| "$" ++ formatCurrency amount ]
                        , td [ class "tools" ]
                            [ div [ class "btn-group" ]
                                [ button [ type_ "button", class "btn btn-default", onClick <| EditBudgetItemDefinition def ] [ span [ class "glyphicon glyphicon-edit" ] [] ]
                                , button [ type_ "button", class "btn btn-default" ] [ span [ class "glyphicon glyphicon-trash" ] [] ]
                                ]
                            ]
                        ]
    in
        div []
            [ h2 [] [ text "Budget Item Admin" ]
            , table [ class "budget-item-table table table-striped" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Description" ]
                        , th [] [ text "Frequency" ]
                        , th [] [ text "Start Date" ]
                        , th [] [ text "Amount" ]
                        , th [] []
                        ]
                    ]
                , tbody [] <|
                    List.map
                        budgetItemRow
                        model.budgetItemDefinitions
                ]
            ]


view : Model -> Html Msg
view model =
    let
        pageView =
            case model.currentPage of
                Home ->
                    homeView model

                BudgetItemAdmin ->
                    budgetItemAdminView model
    in
        div [ class "container" ]
            [ ul [ class "nav nav-tabs" ]
                [ li
                    ([ onClick <| ChangePage Home ]
                        ++ if model.currentPage == Home then
                            [ class "active" ]
                           else
                            []
                    )
                    [ a [ href "#" ] [ text "Home" ] ]
                , li
                    ([ onClick <| ChangePage BudgetItemAdmin ]
                        ++ if model.currentPage == BudgetItemAdmin then
                            [ class "active" ]
                           else
                            []
                    )
                    [ a [ href "#" ] [ text "Budget Admin" ] ]
                ]
            , pageView
            ]
