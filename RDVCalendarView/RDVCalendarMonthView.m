// RDVCalendarMonthView.m
// RDVCalendarView
//
// Copyright (c) 2013 Robert Dimitrov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RDVCalendarMonthView.h"
#import "RDVCalendarDayCell.h"

@interface RDVCalendarMonthView ()

@property (nonatomic) NSMutableArray *visibleCells;
@property (nonatomic) NSMutableArray *dayCells;

@property (nonatomic) NSInteger numberOfDays;
@property (nonatomic) NSInteger numberOfWeeks;

@property (nonatomic) NSInteger firstWeekDays;

@end

@implementation RDVCalendarMonthView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dayCells = [[NSMutableArray alloc] init];
        _visibleCells = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize viewSize = self.frame.size;
    
    NSInteger column = 7 - [self firstWeekDays];
    CGFloat dayWidth = roundf(viewSize.width / 7) - 1;
    NSInteger row = 0;
    
    for (NSInteger i = 0; i < [self numberOfDays]; i++) {
        RDVCalendarDayCell *dayCell = nil;
        
        if ([[self delegate] respondsToSelector:@selector(calendarMonthView:dayCellForIndex:)]) {
            dayCell = [[self delegate] calendarMonthView:self dayCellForIndex:i];
            if (![[self visibleCells] containsObject:dayCell]) {
                [[self visibleCells] addObject:dayCell];
                [self addSubview:dayCell];
            }
        }
        
        [dayCell setFrame:CGRectMake(column * (dayWidth + 1), row * (dayWidth + 1), dayWidth, dayWidth)];
        [dayCell setBackgroundColor:[UIColor whiteColor]];
        [dayCell setNeedsLayout];
        
        if ([dayCell superview] != self) {
            [self addSubview:dayCell];
        }
        
        if (column == 6) {
            column = 0;
            row++;
        } else {
            column++;
        }
    }
}

#pragma mark - Methods

- (void)sizeToFit {
    CGRect frame = self.frame;
    CGFloat height = CGRectGetMaxY([(UIView *)[[self visibleCells] lastObject] frame]);
    
    [self setFrame:CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), height)];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, size.height);
}

- (void)reloadData {
    for (RDVCalendarDayCell *visibleCell in [self visibleCells]) {
        [visibleCell removeFromSuperview];
        [visibleCell prepareForReuse];
        [[self dayCells] addObject:visibleCell];
    }
    
    [[self visibleCells] removeAllObjects];
    
    [self setSelectedDayCell:nil];
    
    if ([[self delegate] respondsToSelector:@selector(numberOfWeeksInCalendarMonthView:)]) {
        [self setNumberOfWeeks:[[self delegate] numberOfWeeksInCalendarMonthView:self]];
    }
    
    if ([[self delegate] respondsToSelector:@selector(numberOfDaysInCalendarMonthView:)]) {
        [self setNumberOfDays:[[self delegate] numberOfDaysInCalendarMonthView:self]];
    }
    
    if ([[self delegate] respondsToSelector:@selector(numberOfDaysInFirstWeek:)]) {
        [self setFirstWeekDays:[[self delegate] numberOfDaysInFirstWeek:self]];
    }
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    UIView *dayCell = nil;
    
    if ([[self dayCells] count]) {
        dayCell = [[self dayCells] objectAtIndex:0];
        [[self dayCells] removeObjectAtIndex:0];
    }
    
    return dayCell;
}

- (NSInteger)indexForCell:(RDVCalendarDayCell *)cell {
    return [[self visibleCells] indexOfObject:cell];
}

- (NSInteger)indexForRowAtPoint:(CGPoint)point {
    RDVCalendarDayCell *cell = [self viewAtLocation:point];
    
    if (cell) {
        return [self indexForCell:cell];
    }
    
    return 0;
}

- (RDVCalendarDayCell *)cellForRowAtIndex:(NSInteger)index {
    return [[self visibleCells] objectAtIndex:index];
}

- (NSInteger)indexForSelectedCell {
    return [self indexForCell:[self selectedDayCell]];
}

- (RDVCalendarDayCell *)viewAtLocation:(CGPoint)location {
    RDVCalendarDayCell *view = nil;
    
    for (RDVCalendarDayCell *dayView in [self visibleCells]) {
        if (CGRectContainsPoint(dayView.frame, location)) {
            view = dayView;
        }
    }
    
    return view;
}

#pragma mark - Touch handling

- (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
    RDVCalendarDayCell *selectedCell = [self viewAtLocation:[touch locationInView:self]];
    
    if (selectedCell && selectedCell != [self selectedDayCell]) {
        NSInteger cellIndex = [self indexForCell:selectedCell];
        
        if ([[self delegate] respondsToSelector:@selector(calendarMonthView:shouldSelectDayCellAtIndex:)]) {
            if (![[self delegate] calendarMonthView:self shouldSelectDayCellAtIndex:cellIndex]) {
                return;
            }
        }
        
        if ([[self delegate] respondsToSelector:@selector(calendarMonthView:willSelectDayCellAtIndex:)]) {
            [[self delegate] calendarMonthView:self willSelectDayCellAtIndex:cellIndex];
        }
        
        [[self selectedDayCell] setSelected:NO];
        [self setSelectedDayCell:selectedCell];
        [[self selectedDayCell] setSelected:YES];
        
        if ([[self delegate] respondsToSelector:@selector(calendarMonthView:didSelectDayCellAtIndex:)]) {
            [[self delegate] calendarMonthView:self didSelectDayCellAtIndex:cellIndex];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:touches withEvent:event];
}

@end
