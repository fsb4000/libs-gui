/** <title>GSTitleView</title>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Serg Stoyan <stoyan@on.com.ua>
   Date: Mar 2003
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSApplication.h>

#include <GNUstepGUI/GSTitleView.h>

#include <Foundation/NSDebug.h>
#include <Foundation/NSRunLoop.h>

@implementation GSTitleView

+ (float) height
{
  static float height = 0.0;

  if (height == 0.0)
    {
      NSFont *font = [NSFont menuFontOfSize: 0.0];

      /* Should make up 23 for the default font */
      height = ([font boundingRectForFont].size.height) + 8;
    }

  return height;
}

- (id) init
{
  self = [super init];

  _owner = nil;
  _ownedByMenu = NO;
  _hasCloseButton = NO;
  _hasMiniaturizeButton = NO;

  [self setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];

  textAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
  [NSColor blackColor], NSForegroundColorAttributeName, nil];

  titleColor = RETAIN ([NSColor lightGrayColor]);

  /*  [self setAutoresizingMask: 
      NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin];*/

  return self;
}

- (void) dealloc
{
  RELEASE (closeButton);
  RELEASE (miniaturizeButton);

  [super dealloc];
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
} 
 
- (NSSize) titleSize
{
  return [[_owner title] sizeWithAttributes: textAttributes];
}

- (void) drawRect: (NSRect)rect
{
  NSRect     workRect = [self bounds];
  NSSize     titleSize;
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
  float      blacks[] = {NSBlack, NSBlack};
  float      grays[] = {NSDarkGray, NSDarkGray};

  // Draw the dark gray upper left lines.
  if (_ownedByMenu)
    workRect = NSDrawTiledRects(workRect, workRect, sides, grays, 2);
  else
    workRect = NSDrawTiledRects(workRect, workRect, sides, blacks, 2);
  
  // Draw the title box's button.
  NSDrawButton(workRect, workRect);
  
  // Paint it Black!
  workRect.origin.x += 1;
  workRect.origin.y += 2;
  workRect.size.height -= 3;
  workRect.size.width -= 3;

  [titleColor set];
  NSRectFill(workRect);
  
  // Draw the title
  titleSize = [self titleSize];
  if (_ownedByMenu)
    {
      workRect.origin.x += 4;
    }
  else
    {
      workRect.origin.x += NSMidX (workRect) - titleSize.width / 2;
    }
  workRect.origin.y = NSMidY (workRect) - titleSize.height / 2;
  workRect.size.height = titleSize.height;
  [[_owner title] drawInRect: workRect  withAttributes: textAttributes];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint  lastLocation;
  NSPoint  location;
  unsigned eventMask = NSLeftMouseUpMask | NSPeriodicMask;
  BOOL     done = NO;
  NSDate   *theDistantFuture = [NSDate distantFuture];

  NSDebugLLog (@"NSMenu", @"Mouse down in title!");

  lastLocation = [theEvent locationInWindow];

  if (_ownedByMenu && ![_owner isTornOff] && [_owner supermenu])
    {
      [_owner setTornOff: YES];
    }

  [_window _captureMouse: nil];
  
  [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

  while (!done)
    {
      theEvent = [NSApp nextEventMatchingMask: eventMask
                                    untilDate: theDistantFuture
                                       inMode: NSEventTrackingRunLoopMode
                                      dequeue: YES];

      switch ([theEvent type])
        {
        case NSRightMouseUp:
        case NSLeftMouseUp: 
          done = YES; 
          [_window _releaseMouse: nil];
          break;
        case NSPeriodic:
          location = [_window mouseLocationOutsideOfEventStream];
          if (NSEqualPoints(location, lastLocation) == NO)
            {
              NSPoint origin = [_window frame].origin;

              origin.x += (location.x - lastLocation.x);
              origin.y += (location.y - lastLocation.y);
              if ([_owner class] == [NSMenu class])
                {
                  [_owner nestedSetFrameOrigin: origin];
                }
              else
                {
                  [_owner setFrameOrigin: origin];
                }
            }
          break;

        default: 
          break;
        }
    }
  [NSEvent stopPeriodicEvents];
}

// We do not need app menu over menu
- (void) rightMouseDown: (NSEvent*)theEvent
{
}

// We do not want to popup menus in this menu.
- (id) menuForEvent: (NSEvent*) theEvent
{
  return nil;
}

- (void) windowBecomeKey: (NSNotification *)notification
{
  RELEASE (titleColor);
  titleColor = RETAIN ([NSColor blackColor]);
  [textAttributes setObject: [NSColor whiteColor] 
                     forKey: NSForegroundColorAttributeName];

  [self setNeedsDisplay: YES];
}

- (void) windowResignKey: (NSNotification *)notification
{
  RELEASE (titleColor);
  if ([NSApp isActive] && [_owner isMainWindow])
    {
      titleColor = RETAIN ([NSColor darkGrayColor]);
      [textAttributes setObject: [NSColor whiteColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  else
    {
      titleColor = RETAIN ([NSColor lightGrayColor]);
      [textAttributes setObject: [NSColor blackColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  [self setNeedsDisplay: YES];
}

/*- (void) windowBecomeMain
{
}

- (void) windowResignMain
{
}*/

/*
 *  Buttons
 */
- (NSButton *) _createButtonWithImage: (NSImage *)image
                       highlightImage: (NSImage *)imageH
                               action: (SEL)action
{
  NSButton *button;
  NSSize   imageSize = [image size]; 
	NSRect   rect = NSMakeRect (0, 0, imageSize.width+3, imageSize.height+3);
  
  button = [[NSButton alloc] initWithFrame: rect];
  [button setRefusesFirstResponder: YES];
  [button setButtonType: NSMomentaryChangeButton];
  [button setImagePosition: NSImageOnly];
  [button setBordered: YES];
  [button setAutoresizingMask: NSViewMaxXMargin | NSViewMaxYMargin];
  [button setImage: image];
  [button setAlternateImage: imageH];
  [button setTarget: _owner];
  [button setAction: action];

  return button;
}
            
- (void) addCloseButtonWithAction: (SEL)closeAction
{
  if (closeButton == nil)
    {
      NSImage *closeImage = [NSImage imageNamed: @"common_Close"];
      NSImage *closeHImage = [NSImage imageNamed: @"common_CloseH"];
      
      closeButton = [self _createButtonWithImage: closeImage 
                                  highlightImage: closeHImage
                                          action: closeAction];

      NSSize viewSize = [self frame].size;
      NSSize buttonSize = [closeButton frame].size;

      // Update location
      [closeButton setFrameOrigin:
        NSMakePoint (viewSize.width - buttonSize.width - 4,
                     (viewSize.height - buttonSize.height) / 2)];

      [closeButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
    }

  if ([closeButton superview] == nil)
    {
      [self addSubview: closeButton];
      RELEASE (closeButton);
      [self setNeedsDisplay: YES];
    }
}

- (void) removeCloseButton
{
  if ([closeButton superview] != nil)
    {
      RETAIN (closeButton);
      [closeButton removeFromSuperview];
    }
}

- (void) addMiniaturizeButtonWithAction: (SEL)miniaturizeAction
{
  if (miniaturizeButton == nil)
    {
      NSImage *miniImage = [NSImage imageNamed: @"common_Miniaturize"];
      NSImage *miniHImage = [NSImage imageNamed: @"common_MiniaturizeH"];
      
      miniaturizeButton = [self _createButtonWithImage: miniImage
                                        highlightImage: miniHImage
                                                action: miniaturizeAction];
      NSSize viewSize = [self frame].size;
      NSSize buttonSize = [miniaturizeButton frame].size;

      // Update location
      [miniaturizeButton setFrameOrigin:
        NSMakePoint (4, (viewSize.height - buttonSize.height) / 2)];

      [miniaturizeButton setAutoresizingMask: 
        NSViewMaxXMargin | NSViewMaxYMargin];
    }
    
  if ([miniaturizeButton superview] == nil)
    {
      [self addSubview: miniaturizeButton];
      RELEASE (miniaturizeButton);
      [self setNeedsDisplay: YES];
    }
}

- (void) removeMiniaturizeButton
{
  if ([miniaturizeButton superview] != nil)
    {
      RETAIN (miniaturizeButton);
      [miniaturizeButton removeFromSuperview];
    }
}

/*
 * Owner setting
 */
- (void) setOwner: (id)owner
{
  NSNotificationCenter  *theCenter = [NSNotificationCenter defaultCenter];

  if ([owner class] == [NSMenu class])
    {
      _owner = owner;
      _ownedByMenu = YES;
      RELEASE (titleColor);
      titleColor = RETAIN ([NSColor blackColor]);
      [textAttributes setObject: [NSColor whiteColor] 
                         forKey: NSForegroundColorAttributeName];
    }
  else if ([owner class] == [NSWindow class])
    {
      _owner = owner;
      _ownedByMenu = NO;

      [self setFrame: 
        NSMakeRect (0, [_owner frame].size.height - [GSTitleView height],
                    [_owner frame].size.width, [GSTitleView height])];

      [self addCloseButtonWithAction: @selector (performClose:)];

      [self addMiniaturizeButtonWithAction: @selector (performMiniaturize:)];

      // Observers
      [theCenter addObserver: self
                    selector: @selector(windowBecomeKey:)
                        name: NSWindowDidBecomeKeyNotification
                      object: _owner];
      [theCenter addObserver: self
                    selector: @selector(windowResignKey:)
                        name: NSWindowDidResignKeyNotification
                      object: _owner];
    }
  else
    {
      return;
    }
}

- (id) owner
{
  return _owner;
}

@end 

