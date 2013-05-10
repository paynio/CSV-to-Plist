//
//  AppDelegate.h
//  csv2plist
//
//  Created by Daniel Payne on 10/05/2013.
//  Copyright (c) 2013 o2. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHCSVParser.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, CHCSVParserDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)chooseFilePressed:(id)sender;

@end
