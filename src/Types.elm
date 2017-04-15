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


type alias BudgetItem =
    { id : Int
    , description : String
    , amount : Float
    , dueDate : Date
    }


type alias Model =
    { upcomingItems : List BudgetItem
    , errorMessage : Maybe String
    , upcomingItemsLoading : Bool
    , scratchAreaItems : List ( String, Float )
    , scratchAreaNewItemDescription : Maybe String
    , scratchAreaNewItemAmount : Maybe Float
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
