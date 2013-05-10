//
//  AppDelegate.m
//  csv2plist
//
//  Created by Daniel Payne on 10/05/2013.
//  Copyright (c) 2013 o2. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
    BOOL readingTopLine;
}
@property (nonatomic, strong) NSMutableArray *fields;
@property (nonatomic, strong) NSMutableArray *currentRow;
@property (nonatomic, strong) NSMutableArray *outputArray;
@property (nonatomic, strong) NSURL *savedFileLocation;

@property (nonatomic, strong) NSDataDetector *detector;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
}

- (IBAction)chooseFilePressed:(id)sender {
    [self showOpenPanel];
}

- (void)showOpenPanel
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton)
    {
        for (NSURL *url in [panel URLs])
        {
            [self parseFileWithLocation:url];
        }
    }
}

- (void)parseFileWithLocation:(NSURL*)location
{
    if (![location.pathExtension isEqualToString:@"csv"])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This is not a .csv file"];
        [alert runModal];
        return;
    }
    NSLog(@"location = %@", location);
    
    
    NSURL *parentDir = [location URLByDeletingPathExtension];
    self.savedFileLocation = [parentDir URLByAppendingPathExtension:@"plist"];
    NSLog(@"saved Path Extension = %@", self.savedFileLocation);
    
    
    CHCSVParser *parser = [[CHCSVParser alloc]initWithContentsOfCSVFile:[location path]];
    parser.delegate = self;
    [parser parse];    
}

#pragma mark - CHCSVParser delegate methods

- (void)parserDidBeginDocument:(CHCSVParser *)parser
{
}

- (void)parserDidEndDocument:(CHCSVParser *)parser
{
    [self.outputArray writeToURL:self.savedFileLocation atomically:YES];
    NSAlert *alert = [NSAlert alertWithMessageText:@"Finished" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The plist has been saved into the same directory as your csv file"];
    [alert runModal];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber
{
    if (recordNumber == 1)
    {
        self.fields = [[NSMutableArray alloc]init];
        readingTopLine = YES;
    }
    else
    {
        self.currentRow = [[NSMutableArray alloc]init];
        readingTopLine = NO;
    }
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber
{
    if (!readingTopLine)
    {
        if (!self.outputArray)
            self.outputArray = [NSMutableArray array];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *str in self.fields)
        {
            [dict setObject:[self.currentRow objectAtIndex:[self.fields indexOfObject:str]] forKey:str];
        }
        [self.outputArray addObject:dict];
        
        self.currentRow = nil;
    }
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
    if (readingTopLine)
        [self.fields insertObject:field atIndex:fieldIndex];
    else
    {
        // First check if object is a date
        
        if (!self.detector)
            self.detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:nil];
        NSUInteger numMatches = [self.detector numberOfMatchesInString:field options:0 range:NSMakeRange(0, [field length])];
        if (numMatches > 0)
        {
            NSArray *matches = [self.detector matchesInString:field
                                                 options:0
                                                   range:NSMakeRange(0, [field length])];
            for (NSTextCheckingResult *match in matches)
            {
                [self.currentRow insertObject:match.date atIndex:fieldIndex];
                return;
            }
        }
        
        // Then check object is a number
        
        if (!self.numberFormatter)
            self.numberFormatter = [[NSNumberFormatter alloc]init];
        
        NSNumber *num = [self.numberFormatter numberFromString:field];
        if (num)
        {
            [self.currentRow insertObject:num atIndex:fieldIndex];
            return;
        }
        
        // Then check for a bool
        
        if ([[field uppercaseString] isEqualToString:@"YES"] || [[field uppercaseString] isEqualToString:@"TRUE"])
        {
            [self.currentRow insertObject:@YES atIndex:fieldIndex];
            return;
        }
        if ([[field uppercaseString] isEqualToString:@"NO"] || [[field uppercaseString] isEqualToString:@"FALSE"])
        {
            [self.currentRow insertObject:@NO atIndex:fieldIndex];
            return;
        }
        
        // If none of the above, save as a string

        [self.currentRow insertObject:field atIndex:fieldIndex];
    }
}

- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment
{
//    NSLog(@"did Read Comment: %@", comment);
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error
{
    NSLog(@"did fail with error: %@", [error localizedDescription]);
}


@end
