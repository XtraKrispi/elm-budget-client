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
    }


type alias NumberOfWeeks =
    Int


type Msg
    = GetUpcomingItemsSuccess (List BudgetItem)
    | GetUpcomingItemsFailed Error
    | MarkItemPaid BudgetItem
