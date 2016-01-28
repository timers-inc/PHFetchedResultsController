//
//  Header.m
//  PHFetchedResultsController
//
//  Created by 1amageek on 2016/01/28.
//  Copyright © 2016年 Stamp inc. All rights reserved.
//

#import "Header.h"

@interface Header ()

@property (nonatomic) UILabel *label;

@end

@implementation Header

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = @"TITLE";
        _label.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_label sizeToFit];
    _label.frame = CGRectMake(16, 12, _label.bounds.size.width, _label.bounds.size.height);
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    _label.text = _title;
    [self setNeedsLayout];
}

@end
