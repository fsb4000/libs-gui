/* 
   NSApplication.m

   The one and only application class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSApplication.h>
#include <gnustep/gui/NSPopUpButton.h>
#include <gnustep/gui/NSPanel.h>
#include <stdio.h>

//
// Class variables
//
// The global application instance
extern id NSApp;
NSEvent *NullEvent;
BOOL gnustep_gui_app_is_in_dealloc;

// Global strings
NSString *NSModalPanelRunLoopMode = @"ModalPanelMode";
NSString *NSEventTrackingRunLoopMode = @"EventTrackingMode";

//
// Global Exception Strings 
//
NSString *NSAbortModalException = @"AbortModalException";
NSString *NSAbortPrintingException = @"AbortPrintingException";
NSString *NSAppKitIgnoredException;
NSString *NSAppKitVirtualMemoryException;
NSString *NSBadBitmapParametersException;
NSString *NSBadComparisonException;
NSString *NSBadRTFColorTableException;
NSString *NSBadRTFDirectiveException;
NSString *NSBadRTFFontTableException;
NSString *NSBadRTFStyleSheetException;
NSString *NSBrowserIllegalDelegateException;
NSString *NSColorListIOException;
NSString *NSColorListNotEditableException;
NSString *NSDraggingException;
NSString *NSFontUnavailableException;
NSString *NSIllegalSelectorException;
NSString *NSImageCacheException;
NSString *NSNibLoadingException;
NSString *NSPPDIncludeNotFoundException;
NSString *NSPPDIncludeStackOverflowException;
NSString *NSPPDIncludeStackUnderflowException;
NSString *NSPPDParseException;
NSString *NSPasteboardCommunicationException;
NSString *NSPrintOperationExistsException;
NSString *NSPrintPackageException;
NSString *NSPrintingCommunicationException;
NSString *NSRTFPropertyStackOverflowException;
NSString *NSTIFFException;
NSString *NSTextLineTooLongException;
NSString *NSTextNoSelectionException;
NSString *NSTextReadException;
NSString *NSTextWriteException;
NSString *NSTypedStreamVersionException;
NSString *NSWindowServerCommunicationException;
NSString *NSWordTablesReadException;
NSString *NSWordTablesWriteException;

// Application notifications
NSString *NSApplicationDidBecomeActiveNotification;
NSString *NSApplicationDidFinishLaunchingNotification;
NSString *NSApplicationDidHideNotification;
NSString *NSApplicationDidResignActiveNotification;
NSString *NSApplicationDidUnhideNotification;
NSString *NSApplicationDidUpdateNotification;
NSString *NSApplicationWillBecomeActiveNotification;
NSString *NSApplicationWillFinishLaunchingNotification;
NSString *NSApplicationWillHideNotification;
NSString *NSApplicationWillResignActiveNotification;
NSString *NSApplicationWillUnhideNotification;
NSString *NSApplicationWillUpdateNotification;

@implementation NSApplication

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSApplication class])
    {
      NSLog(@"Initialize NSApplication class\n");

      // Initial version
      [self setVersion:1];

      // So the application knows its within dealloc
      // and can prevent -release loops.
      gnustep_gui_app_is_in_dealloc = NO;
    }
}

+ (NSApplication *)sharedApplication
{
  // If the global application does not exist yet then create it
  if (!NSApp)
    NSApp = [[self alloc] init];
  return NSApp;
}

//
// Instance methods
//

//
// Creating and initializing the NSApplication
//
- init
{
  [super init];

  NSLog(@"Begin of NSApplication -init\n");

  // allocate the window list
  window_list = [NSMutableArray array];
  window_count = 1;

  //
  // Event handling setup
  //
  // allocate the event queue
  event_queue = [[Queue alloc] init];
  // No current event
  current_event = nil;
  // The NULL event
  NullEvent = [[NSEvent alloc] init];

  //
  // We are the end of the responder chain
  //
  [self setNextResponder:NULL];

  return self;
}

- (void)finishLaunching
{
  // notify that we will finish the launching
  [self applicationWillFinishLaunching:self];

	// finish the launching

	// notify that the launching has finished
  [self applicationDidFinishLaunching:self];
}

- (void)dealloc
{
  int i, j;

  //NSLog(@"Freeing NSApplication\n");

  // Let ourselves know we are within dealloc
  gnustep_gui_app_is_in_dealloc = YES;

  // Release the window list
  // We retain all of the objects in our list
  //   so we need to release them

  //NSArray doesn't know -removeAllObjects yet
  [window_list removeAllObjects];
  //j = [window_list count];
  //for (i = 0;i < j; ++i)
  //  [[window_list objectAtIndex:i] release];

  // no need -array is autoreleased
  //[window_list release];

  [event_queue release];
  [current_event release];
  [super dealloc];
}

//
// Changing the active application
//
- (void)activateIgnoringOtherApps:(BOOL)flag
{
  app_is_active = YES;
}

- (void)deactivate
{
  app_is_active = NO;
}

- (BOOL)isActive
{
  return app_is_active;
}

//
// Running the event loop
//
- (void)abortModal
{
}

- (NSModalSession)beginModalSessionForWindow:(NSWindow *)theWindow
{
  return NULL;
}

- (void)endModalSession:(NSModalSession)theSession
{
}

- (BOOL)isRunning
{
  return app_is_running;
}

- (void)run
{
  NSEvent *e;

  NSLog(@"NSApplication -run\n");

  [self finishLaunching];

  app_should_quit = NO;
  app_is_running = YES;

  do
    {
      e = [self nextEventMatchingMask:NSAnyEventMask untilDate:nil 
		inMode:nil dequeue:YES];
      if (e)
	[self postEvent:e atStart:YES];
      else
	{
	  // Null event
	  // Call the back-end method to handle it
	  [self handleNullEvent];
	}
    } while (!app_should_quit);
  app_is_running = YES;

  NSLog(@"NSApplication end of run loop\n");
}

- (int)runModalForWindow:(NSWindow *)theWindow
{
  return 0;
}

- (int)runModalSession:(NSModalSession)theSession
{
  return 0;
}

- (void)sendEvent:(NSEvent *)theEvent
{
  // Don't send the null event
  if (theEvent == NullEvent)
    {
      NSLog(@"Not sending the Null Event\n");
      return;
    }

  // What is the event type
  switch ([theEvent type])
    {

      //
      // NSApplication traps the periodic events
      //
    case NSPeriodic:
      break;

    case NSKeyDown:
      {
	NSLog(@"send key down event\n");
	[[theEvent window] sendEvent:theEvent];
	break;
      }
    case NSKeyUp:
      {
	NSDebugLog(@"send key up event\n");
	[[theEvent window] sendEvent:theEvent];
	break;
      }
      //
      // All others get passed to the window
      //
    default:
      {
	if (!theEvent) NSLog(@"NSEvent is nil!\n");
	NSLog(@"NSEvent type: %d\n", [theEvent type]);
	NSLog(@"send event to window\n");
	NSLog([[theEvent window] description]);
	NSLog(@"\n");
	if (![theEvent window])
	  NSLog(@"no window\n");
	[[theEvent window] sendEvent:theEvent];
      }
    }
}

- (void)stop:sender
{
  app_is_running = NO;
}

- (void)stopModal
{
}

- (void)stopModalWithCode:(int)returnCode
{
}

//
// Getting, removing, and posting events
//
- (BOOL)event:(NSEvent *)theEvent matchMask:(unsigned int)mask
{
    NSEventType t;

    // If mask is for any event then return success
    if (mask == NSAnyEventMask)
        return YES;

    if (!theEvent) return NO;

    t = [theEvent type];

    if ((t == NSLeftMouseDown) && (mask & NSLeftMouseDownMask))
        return YES;

    if ((t == NSLeftMouseUp) && (mask & NSLeftMouseUpMask))
        return YES;

    if ((t == NSRightMouseDown) && (mask & NSRightMouseDownMask))
        return YES;

    if ((t == NSRightMouseUp) && (mask & NSRightMouseUpMask))
        return YES;

    if ((t == NSMouseMoved) && (mask & NSMouseMovedMask))
        return YES;

    if ((t == NSMouseEntered) && (mask & NSMouseEnteredMask))
        return YES;

    if ((t == NSMouseExited) && (mask & NSMouseExitedMask))
        return YES;

    if ((t == NSLeftMouseDragged) && (mask & NSLeftMouseDraggedMask))
        return YES;

    if ((t == NSRightMouseDragged) && (mask & NSRightMouseDraggedMask))
        return YES;

    if ((t == NSKeyDown) && (mask & NSKeyDownMask))
        return YES;

    if ((t == NSKeyUp) && (mask & NSKeyUpMask))
        return YES;

    if ((t == NSFlagsChanged) && (mask & NSFlagsChangedMask))
        return YES;

    if ((t == NSPeriodic) && (mask & NSPeriodicMask))
        return YES;

    if ((t == NSCursorUpdate) && (mask & NSCursorUpdateMask))
        return YES;

    return NO;
}

- (void)setCurrentEvent:(NSEvent *)theEvent;
{
    [theEvent retain];
    [current_event release];
    current_event = theEvent;
}

- (NSEvent *)currentEvent;
{
  return current_event;
}

- (void)discardEventsMatchingMask:(unsigned int)mask
		      beforeEvent:(NSEvent *)lastEvent
{
}

- (NSEvent *)nextEventMatchingMask:(unsigned int)mask
			 untilDate:(NSDate *)expiration
			    inMode:(NSString *)mode
			   dequeue:(BOOL)flag
{
  NSEvent *e;
  BOOL done;
  int i, j;

  // If the queue isn't empty then check those messages
  if (![event_queue isEmpty])
    {
      j = [event_queue count];
      for (i = j-1;i > 0; --i)
	{
	  e = [event_queue objectAtIndex: i];
	  if ([self event: e matchMask: mask])
	    {
	      [event_queue removeObjectAtIndex: i];
	      [self setCurrentEvent: e];
	      return e;
	    }
	}
    }

  // Not in queue so wait for next event
  done = NO;
  while (!done)
    {
      e = [self getNextEvent];

      // Check mask
      if ([self event: e matchMask: mask])
	{
	  if (e)
	    e = [event_queue dequeueObject];
	  done = YES;
	}
    }

  [self setCurrentEvent: e];
  return e;
}

- (void)postEvent:(NSEvent *)event atStart:(BOOL)flag
{
  [self sendEvent:event];
}

//
// Sending action messages
//
- (BOOL)sendAction:(SEL)aSelector
		to:aTarget
	      from:sender
{
  //
  // If the target responds to the selector
  // then have it perform it
  //
  if ([aTarget respondsToSelector:aSelector])
    {
      [aTarget perform:aSelector withObject:sender];
      return YES;
    }

  //
  // Otherwise traverse the responder chain
  //

  return NO;
}

- targetForAction:(SEL)aSelector
{
  return self;
}

- (BOOL)tryToPerform:(SEL)aSelector
		with:anObject
{
  return NO;
}

// Setting the application's icon
- (void)setApplicationIconImage:(NSImage *)anImage
{
    if (app_icon != nil)
    {
        [app_icon release];
    }

    app_icon = [anImage retain];
}

- (NSImage *)applicationIconImage
{
  return app_icon;
}

//
// Hiding all windows
//
- (void)hide:sender
{
  int i, j;
  NSWindow *w;

  j = [window_list count];
  for (i = 0;i < j; ++i)
    {
      w = [window_list objectAtIndex:i];
      // Do something to hide the window
    }
  app_is_hidden = YES;
}

- (BOOL)isHidden
{
  return app_is_hidden;
}

- (void)unhide:sender
{
  int i, j;
  NSWindow *w;

  app_is_hidden = NO;
  j = [window_list count];
  for (i = 0;i < j; ++i)
    {
      w = [window_list objectAtIndex:i];
      // Do something to unhide the window
    }

  [[self keyWindow] makeKeyAndOrderFront:self];
}

- (void)unhideWithoutActivation
{
  [self unhide: self];
}

//
// Managing windows
//
- (NSWindow *)keyWindow
{
  int i, j;
  id w;

  j = [window_list count];
  for (i = 0;i < j; ++i)
    {
      w = [window_list objectAtIndex:i];
      if ([w isKeyWindow]) return w;
    }
  return nil;
}

- (NSWindow *)mainWindow
{
  int i, j;
  id w;

  j = [window_list count];
  for (i = 0;i < j; ++i)
    {
      w = [window_list objectAtIndex:i];
      if ([w isMainWindow]) return w;
    }
  return nil;
}

- (NSWindow *)makeWindowsPerform:(SEL)aSelector
			 inOrder:(BOOL)flag
{
  return nil;
}

- (void)miniaturizeAll:sender
{
  id e, obj;

  e = [window_list objectEnumerator];
  obj = [e nextObject];
  while (obj)
    {
      [obj miniaturize: sender];
      obj = [e nextObject];
    }
}

- (void)preventWindowOrdering
{
}

- (void)setWindowsNeedUpdate:(BOOL)flag
{
}

- (void)updateWindows
{
  id e, obj;

  e = [window_list objectEnumerator];
  obj = [e nextObject];
  while (obj)
    {
      [obj update];
      obj = [e nextObject];
    }
}

- (NSArray *)windows
{
  return window_list;
}

- (NSWindow *)windowWithWindowNumber:(int)windowNum
{
  int i, j;
  NSWindow *w;

  j = [window_list count];
  for (i = 0;i < j; ++i)
    {
      w = [window_list objectAtIndex:i];
      if ([w windowNumber] == windowNum) return w;
    }
  return nil;
}

//
// Showing Standard Panels
//
- (void)orderFrontColorPanel:sender
{
}

- (void)orderFrontDataLinkPanel:sender
{
}

- (void)orderFrontHelpPanel:sender
{
}

- (void)runPageLayout:sender
{
}

//
// Getting the main menu
//
- (NSMenu *)mainMenu
{
  return main_menu;
}

- (void)setMainMenu:(NSMenu *)aMenu
{
  int i, j;
  NSMenuCell *mc;
  NSArray *mi;
  id w;

  // Release old and retain new
  [main_menu release];
  main_menu = aMenu;
  [main_menu retain];

  // Search for a menucell with the name Windows
  // This is the default windows menu
  mi = [main_menu itemArray];
  j = [mi count];
  windows_menu = nil;
  for (i = 0;i < j; ++i)
    {
      mc = [mi objectAtIndex:i];
      if ([[mc stringValue] compare:@"Windows"] == NSOrderedSame)
	{
	  // Found it!
	  windows_menu = mc;
	  break;
	}
    }
}

//
// Managing the Windows menu
//
- (void)addWindowsItem:aWindow
		 title:(NSString *)aString
	      filename:(BOOL)isFilename
{
  int i;

  // Not a subclass of window --forget it
  if (![aWindow isKindOfClass:[NSWindow class]])
    return;

  // Add to our window list, the array retains it
  i = [window_list count];
  [window_list addObject:aWindow];

  // set its window number
  [aWindow setWindowNumber:window_count];
  ++window_count;
	
  // If this was the first window then
  //   make it the main and key window
  if (i == 0)
    {
      [aWindow becomeMainWindow];
      [aWindow becomeKeyWindow];
    }
}

- (void)arrangeInFront:sender
{
}

- (void)changeWindowsItem:aWindow
		    title:(NSString *)aString
		 filename:(BOOL)isFilename
{
}

- (void)removeWindowsItem:aWindow
{
  int i, j;
  id w;

  // +++ This should be different
  if (aWindow == key_window)
	key_window = nil;
  if (aWindow == main_window)
	main_window = nil;

  // If we are within our dealloc then don't remove the window
  // Most likely dealloc is removing windows from our window list
  // and subsequently NSWindow is caling us to remove itself.
  if (gnustep_gui_app_is_in_dealloc)
      return;

  // Remove it from the window list
  [window_list removeObject: aWindow];

  return;
}

- (void)setWindowsMenu:aMenu
{
  if (windows_menu)
    [windows_menu setSubmenu:aMenu];
}

- (void)updateWindowsItem:aWindow
{
}

- (NSMenu *)windowsMenu
{
  return [windows_menu submenu];
}

//
// Managing the Service menu
//
- (void)registerServicesMenuSendTypes:(NSArray *)sendTypes
			  returnTypes:(NSArray *)returnTypes
{
}

- (NSMenu *)servicesMenu
{
  return nil;
}

- (void)setServicesMenu:(NSMenu *)aMenu
{
}

- validRequestorForSendType:(NSString *)sendType
		 returnType:(NSString *)returnType
{
  return nil;
}

// Getting the display postscript context
- (NSDPSContext *)context
{
    return [NSDPSContext currentContext];
}

// Reporting an exception
//- (void)reportException:(NSException *)anException

//
// Terminating the application
//
- (void)terminate:sender
{
  if ([self applicationShouldTerminate:sender])
    app_should_quit = YES;
}

// Assigning a delegate
- delegate
{
  return delegate;
}

- (void)setDelegate:anObject
{
  delegate = anObject;
}

//
// Implemented by the delegate
//
- (BOOL)application:sender openFileWithoutUI:(NSString *)filename
{
  BOOL result = NO;

  if ([delegate respondsTo:@selector(application:openFileWithoutUI:)])
    result = [delegate application:sender openFileWithoutUI:filename];

  return result;
}
	
- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename
{
  BOOL result = NO;

  if ([delegate respondsTo:@selector(application:openFile:)])
    result = [delegate application:app openFile:filename];

  return result;
}

- (BOOL)application:(NSApplication *)app openTempFile:(NSString *)filename
{
  BOOL result = NO;

  if ([delegate respondsTo:@selector(application:openTempFile:)])
    result = [delegate application:app openTempFile:filename];

  return result;
}

- (void)applicationDidBecomeActive:sender
{
  if ([delegate respondsTo:@selector(applicationDidBecomeActive:)])
    [delegate applicationDidBecomeActive:sender];
}
	
- (void)applicationDidFinishLaunching:sender
{
  if ([delegate respondsTo:@selector(applicationDidFinishLaunching:)])
    [delegate applicationDidFinishLaunching:sender];
}

- (void)applicationDidHide:sender
{
  if ([delegate respondsTo:@selector(applicationDidHide:)])
    [delegate applicationDidHide:sender];
}

- (void)applicationDidResignActive:sender
{
  if ([delegate respondsTo:@selector(applicationDidResignActive:)])
    [delegate applicationDidResignActive:sender];
}

- (void)applicationDidUnhide:sender
{
  if ([delegate respondsTo:@selector(applicationDidUnhide:)])
    [delegate applicationDidUnhide:sender];
}

- (void)applicationDidUpdate:sender
{
  if ([delegate respondsTo:@selector(applicationDidUpdate:)])
    [delegate applicationDidUpdate:sender];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)app
{
  BOOL result = NO;

  if ([delegate respondsTo:@selector(applicationOpenUntitledFile:)])
    result = [delegate applicationOpenUntitledFile:app];

  return result;
}

- (BOOL)applicationShouldTerminate:sender
{
  BOOL result = YES;

  if ([delegate respondsTo:@selector(applicationShouldTerminate:)])
    result = [delegate applicationShouldTerminate:sender];

  return result;
}

- (void)applicationWillBecomeActive:sender
{
  if ([delegate respondsTo:@selector(applicationWillBecomeActive:)])
    [delegate applicationWillBecomeActive:sender];
}

- (void)applicationWillFinishLaunching:sender
{
  if ([delegate respondsTo:@selector(applicationWillFinishLaunching:)])
    [delegate applicationWillFinishLaunching:sender];
}

- (void)applicationWillHide:sender
{
  if ([delegate respondsTo:@selector(applicationWillHide:)])
    [delegate applicationWillHide:sender];
}

- (void)applicationWillResignActive:sender
{
  if ([delegate respondsTo:@selector(applicationWillResignActive:)])
    [delegate applicationWillResignActive:sender];
}

- (void)applicationWillUnhide:sender
{
  if ([delegate respondsTo:@selector(applicationWillUnhide:)])
    [delegate applicationWillUnhide:sender];
}

- (void)applicationWillUpdate:sender
{
  if ([delegate respondsTo:@selector(applicationWillUpdate:)])
    [delegate applicationWillUpdate:sender];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: window_list];
  // We don't want to code the event queue do we?
  //[aCoder encodeObject: event_queue];
  //[aCoder encodeObject: current_event];
  [aCoder encodeObjectReference: key_window withName: @"Key window"];
  [aCoder encodeObjectReference: main_window withName: @"Main window"];
  [aCoder encodeObjectReference: delegate withName: @"Delegate"];
  [aCoder encodeObject: main_menu];
  [aCoder encodeObjectReference: windows_menu withName: @"Windows menu"];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  window_list = [aDecoder decodeObject];
  [aDecoder decodeObjectAt: &key_window withName: NULL];
  [aDecoder decodeObjectAt: &main_window withName: NULL];
  [aDecoder decodeObjectAt: &delegate withName: NULL];
  main_menu = [aDecoder decodeObject];
  [aDecoder decodeObjectAt: &windows_menu withName: NULL];

  return self;
}

@end

//
// Backend methods
// empty implementations
//
@implementation NSApplication (GNUstepBackend)

// Get next event
- (NSEvent *)getNextEvent
{
  [event_queue enqueueObject: NullEvent];
  return NullEvent;
}

// handle a non-translated event
- (void)handleNullEvent
{}

@end
