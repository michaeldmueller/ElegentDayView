//
//  ElegantDayView.m
//  ElegantDayView
//
//  Created by Michael Mueller on 11/20/16.
//  Copyright © 2016 Michael Mueller. All rights reserved.
//

#import "ElegantDayView.h"
#import "Tick.h"
#import "Event.h"

@implementation ElegantDayView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    if(self){
        [self setup];
    }
    
    return self;
}

-(void)setup{
    _numTicks = 96;
    _tickHeight = 35;
    self.contentSize = CGSizeMake(self.frame.size.width, 1000);
    self.layer.borderColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0].CGColor;
    self.layer.borderWidth = 1.0;
    
    _eventColors = @[
                           [UIColor colorWithRed:0.40 green:0.62 blue:0.86 alpha:1.0],
                           [UIColor colorWithRed:0.91 green:0.48 blue:0.48 alpha:1.0],
                           [UIColor colorWithRed:0.93 green:0.72 blue:0.40 alpha:1.0],
                           [UIColor colorWithRed:0.54 green:0.91 blue:0.48 alpha:1.0],
                           [UIColor colorWithRed:0.48 green:0.82 blue:0.91 alpha:1.0],
                           [UIColor colorWithRed:0.55 green:0.58 blue:0.94 alpha:1.0]
                           ];
    
    [self createTickTimes];
    [self createTicks];
    
    _events = [[NSMutableArray alloc] init];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(holdAction:)];
    [self addGestureRecognizer:longPress];
}

-(void)setFont:(UIFont *)font{
    for(Tick *tick in _ticks){
        if(tick.label){
            [tick setFont:font];
        }
    }
    for(Event *event in _events){
        [event.nameLabel setFont:font];
    }
    _font = font;
}

-(void)stopAllEditing{
    for(Event *event in _events){
        if(event.editingMode){
            [event endEditing];
        }
    }
}

-(void)holdAction:(UILongPressGestureRecognizer *)holdRecognizer{
    if(!_isEditable){
        return;
    }
    
    [self stopAllEditing];

    if(holdRecognizer.state == UIGestureRecognizerStateBegan){
        self.scrollEnabled = NO;
//        _startPoint = [holdRecognizer locationInView:self];
        CGPoint touchPoint = [holdRecognizer locationInView:self];
        
        // Prevents event from being created inside another event by long press on event
        // Pretty sure creating an event like this should be possible, so get rid of this later
//        for(Event *event in _events){
//            if(CGRectContainsPoint(event.frame, touchPoint)){
//                return;
//            }
//        }
        
        int index = touchPoint.y/_tickHeight;
        Tick *tick;
        if(index >= 0 && index < [_ticks count]){
            tick = [_ticks objectAtIndex:index];
            BOOL lookingForRightTick = YES;
            while(lookingForRightTick && index>0 && index < [_ticks count]){
                if(touchPoint.y < tick.frame.origin.y){
                    index--;
                    tick = [_ticks objectAtIndex:index];
                } else if (touchPoint.y > tick.frame.origin.y + tick.frame.origin.y){
                    index++;
                    tick = [_ticks objectAtIndex:index];
                } else {
                    lookingForRightTick = NO;
                }
            }
        }
        if(tick){
            _currentEvent = [[Event alloc] init];
            if(_randomEventColors){
                int r = arc4random_uniform((int)[_eventColors count]);
                while(r == _lastRandom){
                    r = arc4random_uniform((int)[_eventColors count]);
                }
                _lastRandom = r;
                
                [_currentEvent setColor:[_eventColors objectAtIndex:r]];
            }
            [_currentEvent setFont:_font];
            _currentEvent.startIndex = tick.index;
            _currentEvent.endIndex = tick.index + 1;
            [_currentEvent setupWithFrame:[self getEventFrameFromTick:tick]];
            _startPoint.y = tick.frame.origin.y;
            _startPoint.x = 0;
            [self addSubview:_currentEvent];
        }
    } else if (holdRecognizer.state == UIGestureRecognizerStateEnded){
        // Event created
        [_events addObject:_currentEvent];
        [self setContentOffset:CGPointMake(0,_currentEvent.frame.origin.y - 200) animated:YES];
        [self checkForCollisionsWithEvent:_currentEvent];
        self.scrollEnabled = YES;
        [_currentEvent startEditing];
    }
    
    
    _currentPoint = [holdRecognizer locationInView:self];
    
    if(_currentEvent){
        if(_currentPoint.y > _startPoint.y){
            // MOVEMENT DOWN
            if((_currentPoint.y - (_startPoint.y + _tickHeight)) >= (_tickHeight * (_currentEvent.endIndex - _currentEvent.startIndex))){
                // Making event bigger
                CGRect frame = CGRectMake(_currentEvent.frame.origin.x, _currentEvent.frame.origin.y, _currentEvent.frame.size.width, _currentEvent.frame.size.height+_tickHeight);
                _currentEvent.endIndex++;
                [_currentEvent changeFrame:frame];
                _currentPoint.y += _tickHeight;
            } else if (_currentPoint.y - (_startPoint.y + _tickHeight) <= (_tickHeight * (_currentEvent.endIndex - _currentEvent.startIndex) - _tickHeight) && _currentEvent.startIndex != _currentEvent.endIndex - 1){
                // Making event smaller
                CGRect frame = CGRectMake(_currentEvent.frame.origin.x, _currentEvent.frame.origin.y, _currentEvent.frame.size.width, _currentEvent.frame.size.height-_tickHeight);
                _currentEvent.endIndex--;
                [_currentEvent changeFrame:frame];
                _currentPoint.y -= _tickHeight;
            }
        } else if (_currentPoint.y < _startPoint.y){
            // MOVEMENT UP
            if(_startPoint.y - _currentPoint.y >= (_tickHeight * (_currentEvent.endIndex - _currentEvent.startIndex))){
                // Making event bigger
                CGRect frame = CGRectMake(_currentEvent.frame.origin.x, _currentEvent.frame.origin.y - _tickHeight, _currentEvent.frame.size.width, _currentEvent.frame.size.height+_tickHeight);
                _currentEvent.startIndex--;
                [_currentEvent changeFrame:frame];
                _currentPoint.y -= _tickHeight;
            } else if (_startPoint.y - _currentPoint.y <= (_tickHeight * (_currentEvent.endIndex - _currentEvent.startIndex) - _tickHeight) && _currentEvent.startIndex != _currentEvent.endIndex - 1){
                // Making event smaller
                CGRect frame = CGRectMake(_currentEvent.frame.origin.x, _currentEvent.frame.origin.y + _tickHeight, _currentEvent.frame.size.width, _currentEvent.frame.size.height - _tickHeight);
                _currentEvent.startIndex++;
                [_currentEvent changeFrame:frame];
                _currentPoint.y += _tickHeight;
            }
        }
    }
    
    // Manually scroll while creating an event
    CGPoint pointInView = [holdRecognizer locationInView:self.superview];
    if(_currentPoint.y - self.superview.frame.size.height/2 > 0 && _currentPoint.y + self.superview.frame.size.height/2 - 20 < self.contentSize.height){
        // Check if not out of bounds
        if(pointInView.y > self.superview.frame.size.height - 100){
            [self setContentOffset:CGPointMake(0, _currentPoint.y - self.superview.frame.size.height/2) animated:YES];
        } else if (pointInView.y < 100){
            [self setContentOffset:CGPointMake(0, _currentPoint.y - self.superview.frame.size.height/2) animated:YES];
        }
    }
}

-(void)checkForSameNames:(Event *)addedEvent{
    for(Event *event in _events){
        if([event.name isEqualToString:addedEvent.name]){
            [addedEvent setColor:event.color];
        }
    }
}

-(void)removeEvent:(Event *)event{
    [_events removeObject:event];
    [event removeFromSuperview];
}

-(void)checkForCollisionsWithEvent:(Event *)addedEvent{
    NSMutableArray *removableEvents = [[NSMutableArray alloc] init];
    NSMutableArray *addEvents = [[NSMutableArray alloc] init];

    for(Event *event in _events){
        if([addedEvent isEqual:event]){
            continue;
        }
        
        if(addedEvent.startIndex < event.startIndex && (addedEvent.endIndex > event.startIndex && addedEvent.endIndex < event.endIndex)){
            // Collision type #1: New event starts above the event but ends in the middle of it
            int difference = addedEvent.endIndex - event.startIndex;
            event.startIndex += difference;
            [event changeFrame:CGRectMake(event.frame.origin.x, event.frame.origin.y + (_tickHeight * difference), event.frame.size.width, event.frame.size.height - (_tickHeight * difference))];
        } else if ((addedEvent.startIndex > event.startIndex && addedEvent.startIndex < event.endIndex) && addedEvent.endIndex > event.endIndex){
            // Collision type #2: New event starts in middle of event but ends below it
            int difference = event.endIndex - addedEvent.startIndex;
            event.endIndex -= difference;
            [event changeFrame:CGRectMake(event.frame.origin.x, event.frame.origin.y, event.frame.size.width, event.frame.size.height - (_tickHeight * difference))];
        } else if (addedEvent.startIndex < event.startIndex && addedEvent.endIndex > event.endIndex){
            // Collision type #3: New event completely encapsulates event
            [removableEvents addObject:event];
        } else if (addedEvent.startIndex == event.startIndex){
            // Collision type #4: New event starts at same spot as old event
            if(addedEvent.endIndex >= event.endIndex){
                // If new event is longer than colliding event, just remove
                [removableEvents addObject:event];
            } else {
                int difference = addedEvent.endIndex - event.startIndex;
                event.startIndex += difference;
                [event changeFrame:CGRectMake(event.frame.origin.x, event.frame.origin.y + (_tickHeight * difference), event.frame.size.width, event.frame.size.height - (_tickHeight * difference))];
            }
        } else if (addedEvent.startIndex >= event.startIndex && addedEvent.endIndex <= event.endIndex){
            // Collision type #5: New event is created inside old event
            if(addedEvent.startIndex == event.startIndex && addedEvent.endIndex == event.endIndex){
                // Check if colliding event is completely encapsulated
                [removableEvents addObject:event];
            } else {
                int difference = event.endIndex - addedEvent.startIndex;
                Event *duplicatedEvent = [self addEventQuietlyWithStartIndex:addedEvent.endIndex-1 EndIndex:event.endIndex-1];
                [event changeFrame:CGRectMake(event.frame.origin.x, event.frame.origin.y, event.frame.size.width, event.frame.size.height - (_tickHeight * difference))];
                [duplicatedEvent setName:event.name];
                [addEvents addObject:duplicatedEvent];
                event.endIndex = addedEvent.startIndex;
                [duplicatedEvent setColor:event.color];
            }
        }
    }
    
    for(Event *event in removableEvents){
        [_events removeObject:event];
        [event removeFromSuperview];
    }
    for(Event *event in addEvents){
        [_events addObject:event];
    }
}

// When an event is tapped on
-(void)tappedEvent:(UITapGestureRecognizer *)tapRecognizer{
    Event *event = (Event *)tapRecognizer.view;
    [self stopAllEditing];
    [event startEditing];
}

-(void)createTickTimes{
    _tickTimes = @[@"12:00 am",@"12:30 am",@"1:00 am", @"1:30 am", @"2:00 am", @"2:30 am", @"3:00 am", @"3:30 am", @"4:00 am", @"4:30 am", @"5:00 am", @"5:30 am", @"6:00 am", @"6:30 am", @"7:00 am", @"7:30 am", @"8:00 am", @"8:30 am", @"9:00 am", @"9:30 am", @"10:00 am", @"10:30 am", @"11:00 am", @"11:30 am", @"12:00 pm", @"12:30 pm", @"1:00 pm", @"1:30 pm", @"2:00 pm", @"2:30 pm", @"3:00 pm", @"3:30 pm", @"4:00 pm", @"4:30 pm", @"5:00 pm", @"5:30 pm", @"6:00 pm", @"6:30 pm", @"7:00 pm", @"7:30 pm", @"8:00 pm", @"8:30 pm", @"9:00 pm", @"9:30 pm", @"10:00 pm", @"10:30 pm", @"11:00 pm", @"11:30 pm"];
}

-(void)createTicks{
    // if i = even, create tick with label
    // if i = odd, just create tick
    int i = 0;
    int labelNum = 0; // index num (if even, create large text. if odd, create small text)
    
    if(!_ticks){
        _ticks = [[NSMutableArray alloc] init];
    }
    
    Tick *lastTick;
    
    CGFloat nextY = 0.0;
    
    while(i < _numTicks){
        Tick *tick;
        
        if(!lastTick){
            nextY = 100;
        } else {
            nextY = lastTick.frame.origin.y + lastTick.frame.size.height;
        }
        
        if(i % 4 == 0){
            tick = [[Tick alloc] initWithFrame:CGRectMake(45, nextY, self.frame.size.width - 90, _tickHeight) lineType:LineTypeStraight];
        } else {
            tick = [[Tick alloc] initWithFrame:CGRectMake(45, nextY, self.frame.size.width - 90,_tickHeight) lineType:LineTypeDashed];
        }
        
        [self addSubview:tick];
        [_ticks addObject:tick];
        
        lastTick = tick;
        
        if(i % 2 == 0){
            // create tick with label
            if(labelNum % 2 == 0){
                [tick createLabelWithTime:[_tickTimes objectAtIndex:labelNum] size:LabelSizeLarge];
            } else {
                [tick createLabelWithTime:[_tickTimes objectAtIndex:labelNum] size:LabelSizeSmall];
            }
            labelNum++;
        }
        
        i++;
        
        tick.index = i;
        
        
    }
    Tick *tick = [[Tick alloc] initWithFrame:CGRectMake(45, nextY, self.frame.size.width - 90, _tickHeight) lineType:LineTypeDashed];
    [self addSubview:tick];
    [_ticks addObject:tick];
    nextY = tick.frame.origin.y + tick.frame.size.height;
    // Add 12:00 am to the bottom
    Tick *finalTick = [[Tick alloc] initWithFrame:CGRectMake(45, nextY, self.frame.size.width - 90, _tickHeight) lineType:LineTypeStraight];
    [self addSubview:finalTick];
    [_ticks addObject:finalTick];
    [finalTick createLabelWithTime:@"12:00 am" size:LabelSizeLarge];
    self.contentSize = CGSizeMake(self.frame.size.width, finalTick.frame.origin.y + finalTick.frame.size.height + 20);
}

-(CGFloat)getHeightFromStartIndex:(int)start EndIndex:(int)end{
    return (end-start)*_tickHeight;
}

-(CGRect)getEventFrameFromTick:(Tick*)tick{
    return CGRectMake((tick.lineStart.x+45) + 25, tick.frame.origin.y, (tick.lineEnd.x - tick.lineStart.x) - 50, _tickHeight);
}

-(void)goToTime:(NSString *)time{
    for(Tick *tick in _ticks){
        if([tick.timeLabel isEqualToString:time]){
            CGFloat y = tick.frame.origin.y - self.frame.size.height;
            if(y < 0){
                y = 0;
            }
            self.contentOffset = CGPointMake(0, y);
        }
    }
}

-(Event *)addEventWithStartIndex:(int)startIndex EndIndex:(int)endIndex Name:(NSString *)name{
    if(startIndex < 0 || endIndex >= [_ticks count] || startIndex >= endIndex){
        return nil;
    }
    
    Event *event = [[Event alloc] init];
    if(_randomEventColors){
        int r = arc4random_uniform((int)[_eventColors count]);
        while(r == _lastRandom){
            r = arc4random_uniform((int)[_eventColors count]);
        }
        _lastRandom = r;
        
        [event setColor:[_eventColors objectAtIndex:r]];
    }
    [event setFont:_font];
    event.startIndex = startIndex;
    event.endIndex = endIndex;
    Tick *tick = [_ticks objectAtIndex:startIndex];
    CGRect eventFrame = [self getEventFrameFromTick:tick];
    eventFrame.size.height = _tickHeight * (endIndex - startIndex);
    [event setupWithFrame:eventFrame];
    [event setName:name];
    [_events addObject:_currentEvent];
    
    [self checkForCollisionsWithEvent:event];
    [self checkForSameNames:event];
    
    [self addSubview:event];
    
    return event;
}

-(Event *)addEventQuietlyWithStartIndex:(int)startIndex EndIndex:(int)endIndex{    
    Event *event = [[Event alloc] init];
    if(_randomEventColors){
        int r = arc4random_uniform((int)[_eventColors count]);
        while(r == _lastRandom){
            r = arc4random_uniform((int)[_eventColors count]);
        }
        _lastRandom = r;
        
        [event setColor:[_eventColors objectAtIndex:r]];
    }
    [event setFont:_font];
    event.startIndex = startIndex;
    event.endIndex = endIndex;
    Tick *tick = [_ticks objectAtIndex:startIndex];
    CGRect eventFrame = [self getEventFrameFromTick:tick];
    eventFrame.size.height = _tickHeight * (endIndex - startIndex);
    [event setupWithFrame:eventFrame];
    
    [self addSubview:event];
    
    return event;
}

@end
