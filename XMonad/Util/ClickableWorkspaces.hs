-------------------------------------------------------------------------------
-- |
-- Module      :  XMonad.Util.ClickableWorkspaces
-- Copyright   :  (c) Geoff deRosenroll <geoffderosenroll@gmail.com>
-- License     :  BSD3-style (see LICENSE)
--
-- Maintainer  :  Geoff deRosenroll <geoffderosenroll@gmail.com>
-- Stability   :  unstable
-- Portability :  unportable
--
-- Provides @clickablePP@, which when applied to the 'PP' pretty-printer used
-- by "XMonad.Hooks.StatusBar" will make the workspace tags clickable in
-- XMobar (for switching focus).
--
-----------------------------------------------------------------------------

module XMonad.Util.ClickableWorkspaces (
  -- * Usage
  -- $usage
  clickablePP,
  clickableWrap,
  ) where

import Control.Monad ((>=>))
import Data.Functor ((<&>))

import XMonad
import XMonad.Hooks.StatusBar.PP (xmobarAction, PP(..))
import XMonad.Util.WorkspaceCompare (getSortByIndex)
import qualified XMonad.StackSet as W
import Data.List (elemIndex)

-- $usage
-- If you're using the "XMonad.Hooks.StatusBar" interface, apply 'clickablePP'
-- to the 'PP' passed to 'XMonad.Hooks.StatusBar.statusBarProp':
--
-- > mySB <- statusBarProp "xmobar" (clickablePP xmobarPP)
--
-- Or if you're using the old "XMonad.Hooks.DynamicLog" interface:
--
-- > logHook = clickablePP xmobarPP { ... } >>= dynamicLogWithPP
--
-- Requirements:
--
--   * @xdotool@ on system (in path)
--   * "XMonad.Hooks.EwmhDesktops" for @xdotool@ support (see Hackage docs for setup)
--   * use of UnsafeStdinReader/UnsafeXMonadLog in xmobarrc (rather than StdinReader/XMonadLog)
--
-- Note that UnsafeStdinReader is potentially dangerous if your workspace
-- names are dynamically generated from untrusted input (like window titles).
-- You may need to add @xmobarRaw@ to 'ppRename' before applying
-- 'clickablePP' in such case.

-- | Wrap string with an xmobar action that uses @xdotool@ to switch to
-- workspace @i@.
clickableWrap :: Int -> String -> String
clickableWrap i ws = xmobarAction ("xdotool set_desktop " ++ show i) "1" ws

-- Note that 'getWsIndex' from "XMonad.Util.WorkspaceCompare" only works for
-- predefined workspaces. When used together with "XMonad.Action.DynamicWorkspaces",
-- 'getWsIndex' needs to be rewritten to get the correct index of a workspace.
-- The workspace order perceived by @xdotool@ is the same as that by 'getSortByIndex'.
-- So 'getSortByIndex' is used in such case.

-- | Return the index of a workspace if it exists.
getWsIndex :: X (WorkspaceId -> Maybe Int)
getWsIndex = do
    wSort <- getSortByIndex
    spaces <- gets (map W.tag . wSort . W.workspaces . windowset)
    return $ flip elemIndex spaces

-- | Return a function that wraps workspace names in an xmobar action that
-- switches to that workspace.
--
-- This assumes that 'XMonad.Hooks.EwmhDesktops.ewmhDesktopsEventHook'
-- isn't configured to change the workspace order. We might need to add an
-- additional parameter if anyone needs that.
getClickable :: X (String -> WindowSpace -> String)
getClickable = getWsIndex <&> \idx s w -> maybe id clickableWrap (idx (W.tag w)) s

-- | Apply clickable wrapping to the given PP.
clickablePP :: PP -> X PP
clickablePP pp = getClickable <&> \ren -> pp{ ppRename = ppRename pp >=> ren }
