//
//  ViewController.m
//  nim-ios-demo
//
//  Created by Thomas Denney on 27/01/2015.
//  Copyright (c) 2015 Programming Thomas. All rights reserved.
//

#import "ViewController.h"
#import "backend.h"

@interface ViewController ()
- (IBAction)textChanged:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (IBAction)textChanged:(UITextField *)sender {
    char * helloName = hello((char*)sender.text.UTF8String);
    self.label.text = [NSString stringWithUTF8String:helloName];
}

@end
