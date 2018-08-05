{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Main
    ( main
    ) where


import qualified Data.Map     as M
import qualified Data.Set     as S
import           Data.Text    (Text)
import           Miso         hiding (Key)
import           Miso.String
import           Numeric      (showHex)
import           Text.Madlibs (madFile, run)

randomText :: IO Text
randomText = run $(madFile "mad-src/recursion-schemes.mad")

type Key = Int

type PreAttribute = (MisoString, MisoString)

type Model = Text

data Action
  = Regenerate
  | Write Text
  | NoOp

main :: IO ()
main = startApp App {..}
  where
    mountPoint = Nothing
    initialAction = NoOp
    model  = ""
    update = updateModel
    view   = viewModel
    events = defaultEvents
    subs   = [ keyboardSub keypress ]

backgroundStyle :: [Attribute action]
backgroundStyle = [ style_ $ M.fromList [ color 0x4d4d4d, leftMargin 15, topMargin 15 ] ]
    where leftMargin :: Int -> PreAttribute
          leftMargin i = ("margin-left", showMiso i <> "%")
          topMargin :: Int -> PreAttribute
          topMargin i = ("margin-top", showMiso i <> "%")
          color :: Int -> PreAttribute
          color c = ("color", "#" <> toMisoString (showHex c mempty))

defaultFonts :: MisoString
defaultFonts = "\"Comic Sans MS\", Helvetica, sans-serif"

showMiso :: Show a => a -> MisoString
showMiso = toMisoString . show

sizedFont :: Int -> [Attribute action]
sizedFont i = [ style_ $ M.singleton "font" (showMiso i <> "px " <> defaultFonts) ]

buttonTraits :: [Attribute action]
buttonTraits = class_ "button" : sizedFont 50

updateModel :: Action -> Model -> Effect Action Model
updateModel Regenerate m = m <# fmap Write randomText
updateModel (Write t) _  = noEff t
updateModel NoOp m       = noEff m

keypress :: S.Set Key -> Action
keypress keys = if keyR `elem` S.toList keys then Regenerate else NoOp
    where keyR = 82

viewModel :: Model -> View Action
viewModel x = div_ backgroundStyle
    [
      p_ largeFont [ text "Press 'another' or push 'r' for a new recursion scheme" ]
    , p_ [] [ div_ (onClick Regenerate : buttonTraits) [ text "another" ] ]
    , p_ fontStyles [ text (toMisoString x) ]
    , p_ [] [ footer ]
    ]

    where largeFont = sizedFont 20
          fontStyles = sizedFont 30

footerParagraph :: [Attribute action]
footerParagraph = [ style_ $ M.fromList [("align", "bottom"), ("position", "absolute"), ("bottom", "200px")] ]

footer :: View Action
footer = footer_ [ class_ "info" ]
    [ p_ footerParagraph
        [ a_ [ href_ "https://github.com/vmchale/recursion-schemata" ] [ text "source" ] ] ]
