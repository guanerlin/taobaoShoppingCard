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
const NSInteger rowCount = 3;
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
    return rowCount;
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
        [self calculateForButton:btn];
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
    if (_conditionArray.count == 3) {//当三项都选择的时候，给出具体库存
        [self calculateReminderWithConditionArray];
    } else _label.text = @"";
}

- (void)calculateForButton:(UIButton *)button {
    //无条件
    switch (_conditionArray.count) {
        case 0:
            [self noConditionWhenReviewButton:button];
            break;
        case 1:
            [self oneConditionWhenReviewButton:button];
            break;
        case 2:
            [self twoConditionWhenReviewButton:button withConditionArray:_conditionArray];
            break;
        case 3:
            [self threeConditionWhenReviewButton:button];
            break;
        default:
            break;
    }

}

- (void)noConditionWhenReviewButton:(UIButton *)button {
    [self noConditionWhenReviewButton:button withGooldsDict:_goodsDict];
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

- (void)oneConditionWhenReviewButton:(UIButton *)button {
    UIButton *conditionButton = [_conditionArray firstObject];
    if (button == conditionButton) {//自己已经是被选中状态，在条件组中，所以不必考虑置灰，因为已经可选
        return;
    } else {
        if ([self button:button isInSameRowWithButton:conditionButton]) {
            //相同行，此唯一条件互斥，相当于无条件状态下是否可选
            [self noConditionWhenReviewButton:button withGooldsDict:_goodsDict];
        } else {
            //非同行，需要将条件组内此唯一条件作为前提，查找库存
            NSMutableDictionary *remainderDict = [self resultWhenSelectOneButton:conditionButton fromDict:_goodsDict];
            if (remainderDict.count) {
                [self noConditionWhenReviewButton:button withGooldsDict:remainderDict];
            } else button.enabled = NO;
        }
    }
}

- (void)oneConditionWhenReviewButton:(UIButton *)button withConditionArray:(NSMutableArray *)conditionArray{
    UIButton *conditionButton = [conditionArray firstObject];
    if (button == conditionButton) {//自己已经是被选中状态，在条件组中，所以不必考虑置灰，因为已经可选
        return;
    } else {
        if ([self button:button isInSameRowWithButton:conditionButton]) {
            //相同行，此唯一条件互斥，相当于无条件状态下是否可选
            [self noConditionWhenReviewButton:button withGooldsDict:_goodsDict];
        } else {
            //非同行，需要将条件组内此唯一条件作为前提，查找库存
            NSMutableDictionary *remainderDict = [self resultWhenSelectOneButton:conditionButton fromDict:_goodsDict];
            if (remainderDict.count) {
                [self noConditionWhenReviewButton:button withGooldsDict:remainderDict];
            } else button.enabled = NO;
        }
    }
}

- (void)twoConditionWhenReviewButton:(UIButton *)button withConditionArray:(NSMutableArray *)conditionArray{
    UIButton *btn1 = conditionArray[0];
    UIButton *btn2 = conditionArray[1];
    //与两条条件之一的button同行的时候，就只剩一个条件
    if ([self button:btn1 isInSameRowWithButton:button]) {
        [self oneConditionWhenReviewButton:button withConditionArray:[NSMutableArray arrayWithObject:btn2]];
    } else if ([self button:btn2 isInSameRowWithButton:button]) {
        [self oneConditionWhenReviewButton:button withConditionArray:[NSMutableArray arrayWithObject:btn1]];
//        [self oneConditionWhenReviewButton:btn1];
    } else {
        //都是非同行
        NSMutableDictionary *remainderDict = [self resultWhenSelectOneButton:btn1 fromDict:_goodsDict];
        if (remainderDict.count) {
            NSMutableDictionary *remainderDict2 = [self resultWhenSelectOneButton:btn2 fromDict:remainderDict];
            if (remainderDict2.count) {
                [self noConditionWhenReviewButton:button withGooldsDict:remainderDict2];
            } else button.enabled = NO;
        } else button.enabled = NO;
    }
}

- (void)threeConditionWhenReviewButton:(UIButton *)button {
    NSMutableArray *newConditionArray = [NSMutableArray arrayWithArray:_conditionArray];
    for (UIButton *btn in _conditionArray) {
        if ([self button:btn isInSameRowWithButton:button]) {
            [newConditionArray removeObject:btn];
            [self twoConditionWhenReviewButton:button withConditionArray:newConditionArray];
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
