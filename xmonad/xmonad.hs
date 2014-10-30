{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE UnicodeSyntax #-}
{- |
Module       : xmonad.hs
Description  : Configuration for the XMonad window manager.
Copyright    : (c) Aaron Gable (aarongable@gmail.com)
License      : Fork me on GitHub

Maintainer   : aarongable@gmail.com
Stability    : experimental
Portability  : non-portable

My personal XMonad configuration, intended to run standalone on Ubuntu 14.04.
-}

-- | Imports
import XMonad hiding ((|||))

import System.Exit
import System.IO

import XMonad.Actions.Navigation2D
import XMonad.Actions.OnScreen

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.Place

import XMonad.Layout.LayoutCombinators
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns

import XMonad.Util.EZConfig
import XMonad.Util.Run

import qualified Data.List as L
import qualified Data.Maybe as M
import qualified XMonad.StackSet as W
import qualified XMonad.Util.ExtensibleState as XS


-- TODO(aarongable):
-- Use LayoutCombinators to add jump-to-layout shortcuts
-- Use Submap for more intuitive and sometimes vimlike keys
-- Set workspace-specific layouts
-- Set a good startupHook


-- | Main config
main = xmonad =<< myStatusBar myConfig

myConfig = withNavigation2DConfig myNavigation2DConfig $ defaultConfig
  { borderWidth         = myBorderWidth
  , focusedBorderColor  = myFocusedBorderColor
  , normalBorderColor   = myNormalBorderColor
  , focusFollowsMouse   = myFocusFollowsMouse
  , clickJustFocuses    = myClickJustFocuses
  , terminal            = myTerminal
  , modMask             = myModMask
  , keys                = myKeys
  , workspaces          = myWorkspaces
  , layoutHook          = myLayoutHook
  , manageHook          = myManageHook
  , logHook             = myLogHook
--, mouseBindings
--, startupHook
--, handleEventHook
  }


-- | Basics
myTerminal = "gnome-terminal"
myModMask = mod4Mask
myFocusFollowsMouse = False
myClickJustFocuses = False


-- | Colors
myBorderWidth = 1
myFocusedBorderColor = "red"
myNormalBorderColor = "#111111"
ubuntuBackgroundColor = "#2C001E"
ubuntuForegroundColor = "$AEA79F"


-- | Workspaces
myWorkspaces = concat $ L.transpose [nums, map ("F"++) nums]
    where nums = map show [1..10]
-- workspace switching keys
myWsKeys = concat $ L.transpose [myNumKeys, myFunKeys]
myNumKeys = map show [1..9] ++ ["0"]
myFunKeys = map (\n -> "<F"++n++">") (map show [1..10])


-- | Layouts
-- windowNavigation for M-[hjkl] movement
-- avoidStrutsOn [] to get toggleStruts, but hiding panels by default
myLayoutHook = avoidStrutsOn [] ( twocol ||| tworow  ||| threecol ||| tabbed )
    where twocol = renamed [Replace "twocol"] $ ResizableTall 1 (3/100) (1/2) []
          tworow = renamed [Replace "tworow"] $ Mirror twocol
          threecol = renamed [Replace "threecol"] $ ThreeCol 1 (3/100) (1/3)
          tabbed = renamed [Replace "tabbed"] $ simpleTabbed


-- | Management
myManageHook = composeAll $ reverse
  [ className =? "Xmessage" --> doFloat
  , appName =? "crx_nckgahadagoaajjgafhacjanaoiihapd" --> doShift "10" <+> placeHook chatPlacement <+> doFloat
  , manageDocks
  ]

chatPlacement = withGaps (1,32,1,32) (smart (1,1))


-- | Xmobar
myLogHook = dynamicLog

myStatusBar = xmobar
--myStatusBar conf = statusBar "xmonad" xmobarPP toggleStrutsKey conf

toggleStrutsKey :: XConfig t -> (KeyMask, KeySym)
toggleStrutsKey XConfig{modMask = modm} = (modm, xK_b )

myPP = defaultPP
  { ppCurrent         = xmobarColor "yellow" "" . wrap "[" "]"
  , ppVisible         = wrap "(" ")"
  , ppHidden          = id
  , ppHiddenNoWindows = const ""
  , ppUrgent          = xmobarColor "red" "yellow"
  , ppSep             = " ❯ "
  , ppWsSep           = " "
  , ppTitle           = xmobarColor "green"  "" . shorten 128
  , ppLayout          = id
  , ppOrder           = id
  , ppOutput          = putStrLn
--, ppSort            = getSortByIndex
  , ppExtras          = []
  }

myToggleStrutsKey XConfig{modMask = modm} = (modm, xK_b)


-- | Keyboard shortcuts
myNavKeys = ["h", "j", "k", "l"]
myNavKeys2 = ["y", "i", "o", "p"]
myNavDirs = [L, D, U, R]

myNavigation2DConfig = defaultNavigation2DConfig
  { layoutNavigation = [("tabbed", centerNavigation)]
  }

myKeys = \conf -> mkKeymap conf $
  [ -- Directional window navigation (Navigation2D)
    ("M-h",             windowGo L False)
  , ("M-j",             windowGo D False)
  , ("M-k",             windowGo U False)
  , ("M-l",             windowGo R False)
  , ("M-S-h",           windowSwap L False)
  , ("M-S-j",           windowSwap D False)
  , ("M-S-k",           windowSwap U False)
  , ("M-S-l",           windowSwap R False)
  , ("M-S-y",           windowToScreen L False)
  , ("M-S-u",           windowToScreen D False)
  , ("M-S-i",           windowToScreen U False)
  , ("M-S-o",           windowToScreen R False)
  , ("M-y",             screenGo L False)
  , ("M-u",             screenGo D False)
  , ("M-i",             screenGo U False)
  , ("M-o",             screenGo R False)
  , ("M1-S-y",          screenSwap L True)
  , ("M1-S-u",          screenSwap D True)
  , ("M1-S-i",          screenSwap U True)
  , ("M1-S-o",          screenSwap R True)
  ]
  ++
  [ -- Navigation utilities
    ("M-<Tab>",         windows W.focusDown)
  , ("M-S-<Tab>",       windows W.focusUp  )
  , ("M-m",             windows W.focusMaster)
  , ("M-S-m",           windows W.swapMaster)
  , ("M-t",             withFocused $ windows . W.sink)
  , ("M-q",             kill)
  ]
  ++
  [ -- Layout Management
    ("M-<Space>",       sendMessage NextLayout)
  , ("M-S-<Space>",     sendMessage FirstLayout)
  , ("M--",             sendMessage (IncMasterN (-1)))
  , ("M-=",             sendMessage (IncMasterN 1))
  , ("M-S--",           sendMessage Shrink)
  , ("M-S-=",           sendMessage Expand)
  , ("M-b",             sendMessage ToggleStruts)
  , ("M-<Scroll_lock>", XS.modify wsTogglePairState)
  ]
  ++
  [ -- Applications
    ("M-<Return>",      spawn $ XMonad.terminal conf)
  , ("M-S-<Return>",    spawn $ "dmenu_run -l 4 -nb '#2C001E' -nf '#AEA79F'"
                                           ++ " -sb '#AEA79F' -sf '#2C001E'")
  , ("<F12>",           spawn $ "gnome-screensaver-command --lock")
  , ("<Print>",         spawn $ "gnome-screenshot --interactive")
  ]
  ++
  [ -- XMonad system
    ("M-C-<Esc>",       spawn $ "xkill")
  , ("M-S-q",           io (exitWith ExitSuccess))
  , ("M-S-r",           spawn "xmonad --recompile; xmonad --restart")
  ]
  ++
  [ -- Unified workspace shifting
    (m ++ k,            f k)
    | k <- myWsKeys
    , (m, f) <- [("M-", myViewer), ("M-S-", myShifter)]
  ]


-- | Helper functions
-- let bools be stored in persistent storage
data WsPairState = WsPairState Bool deriving (Typeable, Read, Show)
instance ExtensionClass WsPairState where
  initialValue  = WsPairState True
  extensionType = PersistentExtension

-- toggle the state of the stored bool
wsTogglePairState (WsPairState s) = WsPairState $ not s

-- The core of the workspace switching
-- * if the pair state is false, just do normal views
-- * if the pair state is true, do paired workspace switching
myViewer k = do
  WsPairState s <- XS.get
  case s of
    False -> windows $ W.view (keyWs k)
    True  -> windows (onlyOnScreen 0 (numKeyWs k)) >> windows (onlyOnScreen 1 (funKeyWs k))

myShifter k = windows $ W.shift (keyWs k)

-- Maps input keys to corresponding workspaces
keyWs k = snd . head $ filter ((==k) . fst) myWsMap
  where
    myWsMap = zip myWsKeys myWorkspaces
-- Maps input keys to corresponding number or function workspaces
numKeyWs k = keyWs $ myNumKeys !! modIndex k
funKeyWs k = keyWs $ myFunKeys !! modIndex k
modIndex k = M.fromJust (L.elemIndex k myWsKeys) `div` 2
