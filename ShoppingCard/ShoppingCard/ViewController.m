//
//  ViewController.m
//  ShoppingCard
//
//  Created by lzheng on 18/8/2016.
//  Copyright © 2016 lzheng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSMutableDictionary *goodsDict;//商品健值字典
@property (strong, nonatomic) NSMutableArray *buttonArray;//所有按钮
@property (strong, nonatomic) NSMutableArray *conditionArray;//当前选中按钮
@end

const NSInteger firstRowCount = 5;
const NSInteger secondRowCount = 5;
const NSInteger thirdRowCount = 2;
const NSInteger ROW_COUNT = 3;
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _buttonArray = [NSMutableArray new];
    _conditionArray = [NSMutableArray new];
    NSError *error = nil;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        NSInteger total = 0;
        _goodsDict = [NSMutableDictionary new];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSDictionary *temp = [dict objectForKey:@"goods"];
        for (NSString * key in temp.keyEnumerator) {
            NSString *value = temp[key];
            NSInteger intValue = value.intValue;
            total = total + intValue;
            if (intValue) {
                [_goodsDict setObject:value forKey:key];
            }
        }
        NSLog(@"%lu",(unsigned long)_goodsDict.count);
        _label.text = [NSString stringWithFormat:@"剩余库存:%ld",total];
    }
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

#pragma datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ROW_COUNT;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.row) {
        case 0: {
            [self initButtons:cell withCount:firstRowCount forRowIndex:indexPath];
        }
            
            break;
        case 1: {
            [self initButtons:cell withCount:secondRowCount forRowIndex:indexPath];
        }
            
            break;
        case 2: {
            [self initButtons:cell withCount:thirdRowCount forRowIndex:indexPath];
            [self buttonSelected:nil];
        }
            
            break;
        default:
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)initButtons:(UITableViewCell *)tableViewCell withCount:(NSInteger) count forRowIndex:(NSIndexPath *)indexPath{
    for(int i = 0; i < count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        NSString *temp = [NSString stringWithFormat:@"%ld%ld",(long)indexPath.row,(long)i];
        button.frame = CGRectMake(i * 70 + 5, 40.0, 50.0, 50.0);
        button.tag = (indexPath.row + 1) * 10 + i + 1;
//        [button setBackgroundColor:[UIColor greenColor]];
        [button setTitle:temp forState:UIControlStateNormal];
        [tableViewCell.contentView addSubview:button];
        [_buttonArray addObject:button];
        [button addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buttonSelected:(UIButton *)button{
    if (button) {
        button.selected = !button.selected;
        [self conditionWhenButtonSelectedWithButton:button];
        if (button.selected) {
            for (UIButton *btn in _buttonArray) {
                if([self button:btn isInSameRowWithButton:button] && btn != button)
                    btn.selected = NO;
            }
        }
    }
    
    //重刷所有按钮是否置灰
    for (UIButton *btn in _buttonArray) {
        [self reviewButton:btn withConditions:_conditionArray fromDict:_goodsDict];
    }
    
}
//构造被点击按钮条件数组
- (void)conditionWhenButtonSelectedWithButton:(UIButton *)button {
    if (button.selected) {
        if (!_conditionArray.count) {
            [_conditionArray addObject:button];
            NSLog(@"%@按钮被点击，添加到条件组",[button titleForState:UIControlStateNormal]);
        } else {
            NSMutableArray *temp = [NSMutableArray new];
            [temp addObject:button];
            for (UIButton *btn in _conditionArray) {
                if (![self button:btn isInSameRowWithButton:button]) {
                    [temp addObject:btn];
                }
            }
            _conditionArray = temp;
        }
    } else {
        NSMutableArray *temp = [NSMutableArray new];
        for (UIButton *btn in _conditionArray) {
            if (btn != button) {
                [temp addObject:btn];
            }
        }
        _conditionArray = temp;
    }
    
    NSLog(@"条件组内条件数量%ld",_conditionArray.count);
    NSLog(@"%@",_conditionArray);
    if (_conditionArray.count == ROW_COUNT) {//当三项都选择的时候，给出具体库存
        [self calculateReminderWithConditionArray];
    } else _label.text = @"";
}


- (void)reviewButton:(UIButton *)button withConditions:(NSMutableArray *)conditions fromDict:(NSMutableDictionary *)dict {
    NSMutableArray *filteredConditions = [self filterConditions:conditions forButton:button];
    button.enabled = YES;
    if (!filteredConditions.count) {
        [self noConditionWhenReviewButton:button withGooldsDict:_goodsDict];
    } else {
        NSMutableDictionary *targetDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        for (int i = 0; i < filteredConditions.count; i++) {
            UIButton *btn = (UIButton *)filteredConditions[i];
            NSMutableDictionary *remainderDict = [self resultWhenSelectOneButton:btn fromDict:targetDict];
            targetDict = remainderDict;
            if (i == filteredConditions.count - 1) {
                if (targetDict.count) {
                    [self noConditionWhenReviewButton:button withGooldsDict:targetDict];
                } else button.enabled = NO;
            }
        }
    }
}

- (NSMutableArray *)filterConditions:(NSMutableArray *)conditions forButton:(UIButton *)button {
    if (!button) {
        return conditions;
    }
    NSMutableArray *result = [NSMutableArray new];
    for (UIButton *btn in conditions) {
        if (![self button:btn isInSameRowWithButton:button]) {
            [result addObject:btn];
        }
    }
    return result;
}

- (void)noConditionWhenReviewButton:(UIButton *)button withGooldsDict:(NSMutableDictionary *)goodsDict{
    NSInteger row = button.tag / 10 * 2 - 1;
    NSInteger line = button.tag % 10 - 1;
    button.enabled = NO;
    for (NSString *key in goodsDict.keyEnumerator) {
        NSString *targetString = [key substringWithRange:NSMakeRange(row - 1,1)];
        if ([targetString isEqualToString:[NSString stringWithFormat:@"%ld",line]]) {
            button.enabled = YES;
            break;
        }
    }
}

#pragma utility

- (BOOL)button:(UIButton *)button isInSameRowWithButton:(UIButton *)toButton {
    if(toButton.tag / 10 == button.tag / 10)
        return YES;
    else
        return NO;
}

- (NSMutableDictionary *)resultWhenSelectOneButton:(UIButton *)button fromDict:(NSMutableDictionary *)fromDict {
    NSMutableDictionary *resultDict = [NSMutableDictionary new];
    for (NSString *key in fromDict.keyEnumerator) {
        NSString *value = [fromDict objectForKey:key];
        NSInteger row = button.tag / 10 * 2 - 1;
        NSInteger line = button.tag % 10 - 1;
        NSString *targetString = [key substringWithRange:NSMakeRange(row - 1,1)];
        if ([targetString isEqualToString:[NSString stringWithFormat:@"%ld",line]]) {
            [resultDict setObject:value forKey:key];
        }
    }
    return resultDict;
}

- (void)calculateReminderWithConditionArray {
    NSMutableDictionary *remainderDict = [self resultWhenSelectOneButton:_conditionArray.firstObject fromDict:_goodsDict];
    if (remainderDict.count) {
        NSMutableDictionary *remainderDict2 = [self resultWhenSelectOneButton:_conditionArray.lastObject fromDict:remainderDict];
        if (remainderDict2.count) {
            UIButton *button = _conditionArray[1];
            NSInteger row = button.tag / 10 * 2 - 1;
            NSInteger line = button.tag % 10 - 1;
            for (NSString *key in remainderDict2.keyEnumerator) {
                NSString *targetString = [key substringWithRange:NSMakeRange(row - 1,1)];
                if ([targetString isEqualToString:[NSString stringWithFormat:@"%ld",line]]) {
                    NSString *result = _goodsDict[key];
                    _label.text = [NSString stringWithFormat:@"剩余库存:%@",result];
                }
            }
        }
    }
}

@end
