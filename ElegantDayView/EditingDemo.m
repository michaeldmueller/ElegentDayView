//
//  ViewController.m
//  ElegantDayView
//
//  Created by Michael Mueller on 11/20/16.
//  Copyright © 2016 Michael Mueller. All rights reserved.
//

#import "EditingDemo.h"
#import "ElegantDayView.h"

@interface EditingDemo ()

@property (strong, nonatomic) ElegantDayView *dayView;

@end

@implementation EditingDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dayView = [[ElegantDayView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_dayView];
    _dayView.isEditable = YES;
//    [_dayView setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end