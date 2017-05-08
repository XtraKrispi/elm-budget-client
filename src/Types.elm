module Types exposing (..)

import Date exposing (Date)
import Http exposing (Error)


type ToastMessageType
    = Success
    | Warning
    | Info
    | Error


type ToastMessage
    = ToastMessage ToastMessageType String


type Page
    = Home
    | BudgetItemAdmin


type Frequency
    = OneTime
    | Weekly
    | Monthly
    | BiWeekly


type alias BudgetItem =
    { id : Int
    , description : String
    , amount : Float
    , dueDate : Date
    }


type alias BudgetItemDefinition =
    { id : Int
    , description : String
    , amount : Float
    , startDate : Date
    , frequency : Frequency
    }


type alias Model =
    { currentPage : Page
    , upcomingItems : List BudgetItem
    , errorMessage : Maybe String
    , upcomingItemsLoading : Bool
    , scratchAreaItems : List ( String, Float )
    , scratchAreaNewItemDescription : Maybe String
    , scratchAreaNewItemAmount : Maybe Float
    , budgetItemDefinitions : List BudgetItemDefinition
    , editingBudgetItemDefinition : Maybe BudgetItemDefinition
    }


type alias NumberOfWeeks =
    Int


type Msg
    = GetUpcomingItemsSuccess (List BudgetItem)
    | GetUpcomingItemsFailed Error
    | MarkItemPaid BudgetItem
    | MarkItemPaidSuccess BudgetItem
    | MarkItemPaidFailed BudgetItem Error
    | RemoveItem BudgetItem
    | RemoveItemSuccess BudgetItem
    | RemoveItemFailed BudgetItem Error
    | ConfirmItemRemoval Int Bool
    | ScratchItemChanged ( String, Float ) Float
    | ScratchItemNewDescription String
    | ScratchItemNewAmount Float
    | AddNewScratchItem
    | RemoveScratchItem ( String, Float )
    | ChangePage Page
    | GetBudgetItemDefinitionsSuccess (List BudgetItemDefinition)
    | GetBudgetItemDefinitionsFailed Error
    | EditBudgetItemDefinition BudgetItemDefinition
    | CancelEditingBudgetItemDefinition
