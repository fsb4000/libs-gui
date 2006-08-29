/* 
   NSDocument.h

   The abstract document class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSDocument
#define _GNUstep_H_NSDocument

#include <Foundation/NSObject.h>
#include <AppKit/NSNibDeclarations.h>
#include <AppKit/NSUserInterfaceValidation.h>


/* Foundation classes */
@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSData;
@class NSFileManager;
@class NSURL;
@class NSUndoManager;

/* AppKit classes */
@class NSWindow;
@class NSView;
@class NSSavePanel;
@class NSMenuItem;
@class NSPrintInfo;
@class NSPopUpButton;
@class NSFileWrapper;
@class NSDocumentController;
@class NSWindowController;


typedef enum _NSDocumentChangeType {
    NSChangeDone 	= 0,
    NSChangeUndone 	= 1,
    NSChangeCleared 	= 2
} NSDocumentChangeType;

typedef enum _NSSaveOperationType {
    NSSaveOperation		= 0,
    NSSaveAsOperation		= 1,
    NSSaveToOperation		= 2
} NSSaveOperationType;

@interface NSDocument : NSObject
{
  @private
    NSWindow		*_window;		// Outlet for the single window case
    NSMutableArray 	*_windowControllers;	// WindowControllers for this document
    NSString		*_fileName;		// Save location
    NSString 		*_fileType;		// file/document type
    NSPrintInfo 	*_printInfo;		// print info record
    long		_changeCount;		// number of time the document has been changed
    NSView 		*savePanelAccessory;	// outlet for the accessory save-panel view
    NSPopUpButton	*spaButton;     	// outlet for "the File Format:" button in the save panel.
    int			_documentIndex;		// Untitled index
    NSUndoManager 	*_undoManager;		// Undo manager for this document
    NSString            *_saveType;             // the currently selected extension.
    struct __docFlags {
        unsigned int inClose:1;
        unsigned int hasUndoManager:1;
        unsigned int RESERVED:30;
    } _docFlags;
    void 		*_reserved1;
}

/*" Initialization "*/
- (id)init;
- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType;
- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)fileType;

/*" Window management "*/
- (NSArray *)windowControllers;
- (void)addWindowController:(NSWindowController *)windowController;
- (BOOL)shouldCloseWindowController:(NSWindowController *)windowController;
- (void)showWindows;
- (void)removeWindowController:(NSWindowController *)windowController;
- (void)setWindow:(NSWindow *)aWindow;

/*" Window controller creation "*/
- (void)makeWindowControllers;  // Manual creation
- (NSString *)windowNibName;    // Automatic creation (Document will be the nib owner)

/*" Window loading notifications "*/
// Only called if the document is the owner of the nib
- (void)windowControllerWillLoadNib:(NSWindowController *)windowController;
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController;

/*" Edited flag "*/
- (BOOL)isDocumentEdited;
- (void)updateChangeCount:(NSDocumentChangeType)change;

/*" Display Name (window title) "*/
- (NSString *)displayName;

/*" Backup file "*/
- (BOOL)keepBackupFile;

/*" Closing "*/
- (void)close;
- (BOOL)canCloseDocument;

/*" Type and location "*/
- (NSString *)fileName;
- (void)setFileName:(NSString *)fileName;
- (NSString *)fileType;
- (void)setFileType:(NSString *)type;
+ (NSArray *)readableTypes;
+ (NSArray *)writableTypes;
+ (BOOL)isNativeType:(NSString *)type;

/*" Read/Write/Revert "*/

- (NSData *)dataRepresentationOfType:(NSString *)type;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type;

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type;
- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper 
			       ofType:(NSString *)type;

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type;
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type;
- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type;

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type;
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type;
- (BOOL)revertToSavedFromURL:(NSURL *)url ofType:(NSString *)type;

/*" Save panel "*/
- (BOOL)shouldRunSavePanelWithAccessoryView;
- (NSString *)fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType)saveOperation;
- (int)runModalSavePanel:(NSSavePanel *)savePanel withAccessoryView:(NSView *)accessoryView;
- (NSString *)fileTypeFromLastRunSavePanel;
- (NSDictionary *)fileAttributesToWriteToFile: (NSString *)fullDocumentPath 
				       ofType: (NSString *)docType 
				saveOperation: (NSSaveOperationType)saveOperationType;
- (BOOL)writeToFile:(NSString *)fileName 
	     ofType:(NSString *)type 
       originalFile:(NSString *)origFileName
      saveOperation:(NSSaveOperationType)saveOp;
- (BOOL)writeWithBackupToFile:(NSString *)fileName 
		       ofType:(NSString *)fileType 
		saveOperation:(NSSaveOperationType)saveOp;

/*" Printing "*/
- (NSPrintInfo *)printInfo;
- (void)setPrintInfo:(NSPrintInfo *)printInfo;
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo;
- (IBAction)runPageLayout:(id)sender;
- (int)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo;
- (IBAction)printDocument:(id)sender;
- (void)printShowingPrintPanel:(BOOL)flag;

/*" IB Actions "*/
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (IBAction)saveDocumentTo:(id)sender;
- (IBAction)revertDocumentToSaved:(id)sender;

/*" Menus "*/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

/*" Undo "*/
- (NSUndoManager *)undoManager;
- (void)setUndoManager:(NSUndoManager *)undoManager;
- (BOOL)hasUndoManager;
- (void)setHasUndoManager:(BOOL)flag;

/* NEW delegate operations*/
- (void)shouldCloseWindowController:(NSWindowController *)windowController 
			   delegate:(id)delegate 
		shouldCloseSelector:(SEL)callback
			contextInfo:(void *)contextInfo;
- (void)canCloseDocumentWithDelegate:(id)delegate 
		 shouldCloseSelector:(SEL)shouldCloseSelector 
			 contextInfo:(void *)contextInfo;
- (void)saveToFile:(NSString *)fileName 
     saveOperation:(NSSaveOperationType)saveOperation 
	  delegate:(id)delegate
   didSaveSelector:(SEL)didSaveSelector 
       contextInfo:(void *)contextInfo;
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;
- (void)saveDocumentWithDelegate:(id)delegate 
		 didSaveSelector:(SEL)didSaveSelector 
		     contextInfo:(void *)contextInfo;
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation 
				 delegate:(id)delegate
			  didSaveSelector:(SEL)didSaveSelector 
			      contextInfo:(void *)contextInfo;

@end

#endif // _GNUstep_H_NSDocument
