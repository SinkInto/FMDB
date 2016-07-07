//
//  ViewController.m
//  FMDB
//
//  Created by 王向召 on 16/7/6.
//  Copyright © 2016年 王向召. All rights reserved.
//

#import "ViewController.h"
#import "MYBCustomer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [MYBCustomer clearTable];
        
        MYBCustomer *customer = [[MYBCustomer alloc] init];
        customer.customerName = @"小h";
        customer.code = @"code_3";
        customer.birthday = [NSDate date];
//        [customer saveInTransaction:YES db:nil];
//        [customer deleteObjectInTransaction:YES db:nil];
//        [customer saveOrUpdate];
//        [customer saveOrUpdateInTransaction:YES db:nil];
        MYBCustomer *customer1 = [[MYBCustomer alloc] init];
        customer1.customerName = @"小张";
        customer1.code = @"code_2";
        customer1.birthday = [NSDate date];
        
        NSArray *customers = @[customer,customer1];
//        [MYBCustomer saveOrUpdateObjects:customers];
        
        [MYBCustomer deleteObjects:customers];
    
//        [MYBCustomer updateObjects:customers];
//
        
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//           [MYBCustomer deleteObjects:customers];
//        });

        
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"全部:%@",[MYBCustomer findAll]);
        });
    });
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
