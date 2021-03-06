defmodule WxConst do
  require Record

  # Generated by running
  # grep '^-record' wx.hrl |sed -e 's/-record(//' -e 's/,.*//'|while read r; do echo "  Record.defrecord :$r, Record.extract(:$r, from_lib: \"wx/include/wx.hrl\")"; done >/tmp/x
  # and including the result here.
  Record.defrecord :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxActivate, Record.extract(:wxActivate, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxAuiManager, Record.extract(:wxAuiManager, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxAuiNotebook, Record.extract(:wxAuiNotebook, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxCalendar, Record.extract(:wxCalendar, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxChildFocus, Record.extract(:wxChildFocus, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxClipboardText, Record.extract(:wxClipboardText, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxClose, Record.extract(:wxClose, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxColourPicker, Record.extract(:wxColourPicker, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxCommand, Record.extract(:wxCommand, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxContextMenu, Record.extract(:wxContextMenu, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxDate, Record.extract(:wxDate, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxDisplayChanged, Record.extract(:wxDisplayChanged, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxDropFiles, Record.extract(:wxDropFiles, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxErase, Record.extract(:wxErase, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxFileDirPicker, Record.extract(:wxFileDirPicker, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxFocus, Record.extract(:wxFocus, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxFontPicker, Record.extract(:wxFontPicker, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxGrid, Record.extract(:wxGrid, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxHelp, Record.extract(:wxHelp, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxHtmlLink, Record.extract(:wxHtmlLink, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxIconize, Record.extract(:wxIconize, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxIdle, Record.extract(:wxIdle, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxInitDialog, Record.extract(:wxInitDialog, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxJoystick, Record.extract(:wxJoystick, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxKey, Record.extract(:wxKey, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxList, Record.extract(:wxList, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMaximize, Record.extract(:wxMaximize, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMenu, Record.extract(:wxMenu, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMouseCaptureChanged, Record.extract(:wxMouseCaptureChanged, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMouseCaptureLost, Record.extract(:wxMouseCaptureLost, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMouse, Record.extract(:wxMouse, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMove, Record.extract(:wxMove, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxNavigationKey, Record.extract(:wxNavigationKey, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxNotebook, Record.extract(:wxNotebook, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxPaint, Record.extract(:wxPaint, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxPaletteChanged, Record.extract(:wxPaletteChanged, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxQueryNewPalette, Record.extract(:wxQueryNewPalette, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSash, Record.extract(:wxSash, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxScroll, Record.extract(:wxScroll, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxScrollWin, Record.extract(:wxScrollWin, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSetCursor, Record.extract(:wxSetCursor, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxShow, Record.extract(:wxShow, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSize, Record.extract(:wxSize, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSpin, Record.extract(:wxSpin, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSplitter, Record.extract(:wxSplitter, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxStyledText, Record.extract(:wxStyledText, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxSysColourChanged, Record.extract(:wxSysColourChanged, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxTaskBarIcon, Record.extract(:wxTaskBarIcon, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxTree, Record.extract(:wxTree, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxUpdateUI, Record.extract(:wxUpdateUI, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxWindowCreate, Record.extract(:wxWindowCreate, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxWindowDestroy, Record.extract(:wxWindowDestroy, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxMouseState, Record.extract(:wxMouseState, from_lib: "wx/include/wx.hrl")
  Record.defrecord :wxHtmlLinkInfo, Record.extract(:wxHtmlLinkInfo, from_lib: "wx/include/wx.hrl")
end
