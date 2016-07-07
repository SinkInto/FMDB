//
//  MYBCustomer.h
//  FMDB
//
//  Created by 王向召 on 16/7/6.
//  Copyright © 2016年 王向召. All rights reserved.
//

#import "MYBFMDBModel.h"

@interface MYBCustomer : MYBFMDBModel


@property (nonatomic, strong) NSDate *birthday;

@property (nonatomic, copy) NSString *customerName;
@property (nonatomic, copy) NSString *customerName1;
@property (nonatomic, copy) NSString *customerName2;
@property (nonatomic, copy) NSString *customerName3;
@property (nonatomic, copy) NSString *customerName4;
@property (nonatomic, copy) NSString *customerName5;

@end
