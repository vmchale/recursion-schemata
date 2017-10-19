{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Lib
    ( exec
    ) where


import           Data.FileEmbed (embedStringFile)
import qualified Data.Map       as M
import           Data.Text      (Text)
import           Miso
import           Miso.String
import           Text.Madlibs   (runText)

sourceFile :: Text
sourceFile = $(embedStringFile "mad-src/recursion-schemes.mad")

randomText :: IO Text
randomText = runText [] "noSrc" sourceFile

type Model = Text

data Action
  = Regenerate
  | Write Text
  | NoOp
  deriving (Show, Eq)

exec :: IO ()
exec = startApp App {..}
  where
    initialAction = NoOp
    model  = ""
    update = updateModel
    view   = viewModel
    events = defaultEvents
    subs   = []

backgroundStyle :: [Attribute action]
backgroundStyle = [ style_ $ M.fromList [("color", "#4d4d4d"), ("margin-left", "15%"), ("margin-top", "15%") ] ]

largeFont :: [Attribute action]
largeFont = [ style_ $ M.fromList [("font", "20px \"Comic Sans MS\", Helvetica, sans-serif")] ]

buttonFont :: [Attribute action]
buttonFont = [ style_ $ M.fromList [("font", "50px \"Comic Sans MS\", Helvetica, sans-serif")] ]

buttonTraits :: [Attribute action]
buttonTraits = class_ "button" : buttonFont

fontStyles :: [Attribute action]
fontStyles = [ style_ $ M.fromList [("font", "30px \"Comic Sans MS\", Helvetica, sans-serif")] ]

updateModel :: Action -> Model -> Effect Action Model
updateModel Regenerate m = m <# fmap Write randomText
updateModel (Write t) _  = noEff t
updateModel NoOp m       = noEff m

keypress :: Attribute Action
keypress = onKeyPress gan
    where gan (KeyCode 82) = Regenerate
          gan _            = NoOp

viewModel :: Model -> View Action
viewModel x = div_ (keypress : backgroundStyle)
    [
      p_ largeFont [ text "Press 'another' for a new recursion scheme" ]
    , p_ [] [ div_ (onClick Regenerate : buttonTraits) [ text "another" ] ]
    , p_ fontStyles [ text (toMisoString x) ]
    , p_ [] [ footer ]
    ]

footerParagraph :: [Attribute action]
footerParagraph = [ style_ $ M.fromList [("align", "bottom"), ("position", "absolute"), ("bottom", "200px")] ]

footer :: View Action
footer = footer_ [ class_ "info" ]
    [ p_ footerParagraph
        [ a_ [ href_ "https://github.com/vmchale/recursion-schemata" ] [ text "source" ] ] ]
