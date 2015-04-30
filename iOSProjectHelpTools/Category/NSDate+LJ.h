//
//  NSDate+LJ.h
//  Estay
//
//  Created by jerry on 14-7-20.
//  Copyright (c) 2014年 estay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (LJ)
//当前date 是周几 (从0-6  0表示周末 依次类推)
@property (nonatomic,assign,readonly) NSInteger weekDay;
//当前date 是周几 (从0-6  0表示周末 依次类推)
@property (nonatomic,copy,readonly) NSString * weekDayString;

@property (nonatomic,assign,readonly) NSInteger year;
@property (nonatomic,assign,readonly) NSInteger month;
@property (nonatomic,assign,readonly) NSInteger day;

//返回增加指定数量的月份后的date
- (NSDate *) addMonthSpecifyNum:(NSInteger)num;
//返回增加指定数量的天数后的date
- (NSDate *) addDaySpecifyNum:(NSInteger)num;
//返回增加指定数量的月份后的date (外界传入calendar 对象 主要为了效率问题 如果外界已有该对象 就不要重新创建)
- (NSDate *) addMonthSpecifyNum:(NSInteger)num calendar:(NSCalendar *)calendar;

- (NSString * ) stringWithFormat:(NSString * )format;
//返回当前日期与指定日期间的相差的天数
- (NSInteger) daysFromDate:(NSDate * )specifyDate;
@end
