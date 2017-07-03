#import "RNCalendarManager.h"
#import "RCTConvert.h"
#import <EventKit/EventKit.h>

@interface RNCalendarManager ()
// EKEventStore instance associated with the current Calendar application
@property (nonatomic, strong) EKEventStore *eventStore;

// Default calendar associated with the above event store
@property (nonatomic, strong) EKCalendar *defaultCalendar;

// Array of all events happening within the next 24 hours
@property (nonatomic, strong) NSMutableArray *eventsList;

@property (nonatomic) BOOL isAccessToEventStoreGranted;

@end

static NSString *const _id = @"id";
static NSString *const _title = @"title";
static NSString *const _location = @"location";
static NSString *const _startDate = @"startDate";
static NSString *const _endDate = @"endDate";
static NSString *const _allDay = @"allDay";
static NSString *const _notes = @"notes";
static NSString *const _url = @"url";
static NSString *const _alarms = @"alarms";
static NSString *const _recurrence = @"recurrence";
static NSString *const _occurrenceDate = @"occurrenceDate";
static NSString *const _isDetached = @"isDetached";

static inline NSString* NSStringFromBOOL(BOOL aBool) {
    return aBool? @"True" : @"False"; }

@implementation RNCalendarManager

@synthesize bridge = _bridge;
RCT_EXPORT_MODULE()


#pragma mark -
#pragma mark Event Store Initialize

- (EKEventStore *)eventStore
{
    if (!_eventStore) {
        _eventStore = [[EKEventStore alloc] init];
    }
    return _eventStore;
}



- (NSArray *)serializeCalendarEvent:(EKEvent *)event
{
    NSMutableArray *serializedCalendarEvents = [[NSMutableArray alloc] init];
    
    NSDictionary *emptyCalendarEvent = @{
                                         _title: @"",
                                         _location: @"",
                                         _startDate: @"",
                                         _endDate: @"",
                                         _allDay: @NO,
                                         _notes: @"",
                                         _url: @"",
                                         _alarms: @[],
                                         _recurrence: @""
                                         };
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z"];
    

        NSMutableDictionary *formedCalendarEvent = [NSMutableDictionary dictionaryWithDictionary:emptyCalendarEvent];
        
        if (event.calendarItemIdentifier) {
            [formedCalendarEvent setValue:event.calendarItemIdentifier forKey:_id];
        }
        
        if (event.title) {
            [formedCalendarEvent setValue:event.title forKey:_title];
        }
        
        if (event.notes) {
            [formedCalendarEvent setValue:event.notes forKey:_notes];
        }
        
        if (event.URL) {
            [formedCalendarEvent setValue:[event.URL absoluteString] forKey:_url];
        }
        
        if (event.location) {
            [formedCalendarEvent setValue:event.location forKey:_location];
        }
        
        if (event.hasAlarms) {
            NSMutableArray *alarms = [[NSMutableArray alloc] init];
            
            for (EKAlarm *alarm in event.alarms) {
                
                NSMutableDictionary *formattedAlarm = [[NSMutableDictionary alloc] init];
                NSString *alarmDate = nil;
                
                if (alarm.absoluteDate) {
                    alarmDate = [dateFormatter stringFromDate:alarm.absoluteDate];
                } else if (alarm.relativeOffset) {
                    NSDate *calendarEventStartDate = nil;
                    if (event.startDate) {
                        calendarEventStartDate = event.startDate;
                    } else {
                        calendarEventStartDate = [NSDate date];
                    }
                    alarmDate = [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:alarm.relativeOffset
                                                                                 sinceDate:calendarEventStartDate]];
                }
                [formattedAlarm setValue:alarmDate forKey:@"date"];
                
                if (alarm.structuredLocation) {
                    NSString *proximity = nil;
                    switch (alarm.proximity) {
                        case EKAlarmProximityEnter:
                            proximity = @"enter";
                            break;
                        case EKAlarmProximityLeave:
                            proximity = @"leave";
                            break;
                        default:
                            proximity = @"None";
                            break;
                    }
                    [formattedAlarm setValue:@{
                                               @"title": alarm.structuredLocation.title,
                                               @"proximity": proximity,
                                               @"radius": @(alarm.structuredLocation.radius),
                                               @"coords": @{
                                                       @"latitude": @(alarm.structuredLocation.geoLocation.coordinate.latitude),
                                                       @"longitude": @(alarm.structuredLocation.geoLocation.coordinate.longitude)
                                                       }}
                                      forKey:@"structuredLocation"];
                    
                }
                [alarms addObject:formattedAlarm];
            }
            [formedCalendarEvent setValue:alarms forKey:_alarms];
        }
        
        if (event.startDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.startDate] forKey:_startDate];
        }
        
        if (event.endDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.endDate] forKey:_endDate];
        }
        
        if (event.occurrenceDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.occurrenceDate] forKey:_occurrenceDate];
        }
        
        [formedCalendarEvent setValue:[NSNumber numberWithBool:event.isDetached] forKey:_isDetached];
        
        [formedCalendarEvent setValue:[NSNumber numberWithBool:event.allDay] forKey:_allDay];
        
        if (event.hasRecurrenceRules) {
            NSString *frequencyType = [self nameMatchingFrequency:[[event.recurrenceRules objectAtIndex:0] frequency]];
            [formedCalendarEvent setValue:frequencyType forKey:_recurrence];
        }
    return formedCalendarEvent;
}





- (NSArray *)serializeCalendarEvents:(NSArray *)calendarEvents
{
    NSMutableArray *serializedCalendarEvents = [[NSMutableArray alloc] init];
    
    NSDictionary *emptyCalendarEvent = @{
                                         _title: @"",
                                         _location: @"",
                                         _startDate: @"",
                                         _endDate: @"",
                                         _allDay: @NO,
                                         _notes: @"",
                                         _url: @"",
                                         _alarms: @[],
                                         _recurrence: @""
                                         };
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z"];
    
    for (EKEvent *event in calendarEvents) {
        
        NSMutableDictionary *formedCalendarEvent = [NSMutableDictionary dictionaryWithDictionary:emptyCalendarEvent];
        
        if (event.calendarItemIdentifier) {
            [formedCalendarEvent setValue:event.calendarItemIdentifier forKey:_id];
        }
        
        if (event.title) {
            [formedCalendarEvent setValue:event.title forKey:_title];
        }
        
        if (event.notes) {
            [formedCalendarEvent setValue:event.notes forKey:_notes];
        }
        
        if (event.URL) {
            [formedCalendarEvent setValue:[event.URL absoluteString] forKey:_url];
        }
        
        if (event.location) {
            [formedCalendarEvent setValue:event.location forKey:_location];
        }
        
        if (event.hasAlarms) {
            NSMutableArray *alarms = [[NSMutableArray alloc] init];
            
            for (EKAlarm *alarm in event.alarms) {
                
                NSMutableDictionary *formattedAlarm = [[NSMutableDictionary alloc] init];
                NSString *alarmDate = nil;
                
                if (alarm.absoluteDate) {
                    alarmDate = [dateFormatter stringFromDate:alarm.absoluteDate];
                } else if (alarm.relativeOffset) {
                    NSDate *calendarEventStartDate = nil;
                    if (event.startDate) {
                        calendarEventStartDate = event.startDate;
                    } else {
                        calendarEventStartDate = [NSDate date];
                    }
                    alarmDate = [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:alarm.relativeOffset
                                                                                 sinceDate:calendarEventStartDate]];
                }
                [formattedAlarm setValue:alarmDate forKey:@"date"];
                
                if (alarm.structuredLocation) {
                    NSString *proximity = nil;
                    switch (alarm.proximity) {
                        case EKAlarmProximityEnter:
                            proximity = @"enter";
                            break;
                        case EKAlarmProximityLeave:
                            proximity = @"leave";
                            break;
                        default:
                            proximity = @"None";
                            break;
                    }
                    [formattedAlarm setValue:@{
                                               @"title": alarm.structuredLocation.title,
                                               @"proximity": proximity,
                                               @"radius": @(alarm.structuredLocation.radius),
                                               @"coords": @{
                                                       @"latitude": @(alarm.structuredLocation.geoLocation.coordinate.latitude),
                                                       @"longitude": @(alarm.structuredLocation.geoLocation.coordinate.longitude)
                                                       }}
                                      forKey:@"structuredLocation"];
                    
                }
                [alarms addObject:formattedAlarm];
            }
            [formedCalendarEvent setValue:alarms forKey:_alarms];
        }
        
        if (event.startDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.startDate] forKey:_startDate];
        }
        
        if (event.endDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.endDate] forKey:_endDate];
        }
        
        if (event.occurrenceDate) {
            [formedCalendarEvent setValue:[dateFormatter stringFromDate:event.occurrenceDate] forKey:_occurrenceDate];
        }
        
        [formedCalendarEvent setValue:[NSNumber numberWithBool:event.isDetached] forKey:_isDetached];
        
        [formedCalendarEvent setValue:[NSNumber numberWithBool:event.allDay] forKey:_allDay];
        
        if (event.hasRecurrenceRules) {
            NSString *frequencyType = [self nameMatchingFrequency:[[event.recurrenceRules objectAtIndex:0] frequency]];
            [formedCalendarEvent setValue:frequencyType forKey:_recurrence];
        }
        
        [serializedCalendarEvents addObject:formedCalendarEvent];
    }
    
    return [serializedCalendarEvents copy];
}

-(NSString *)nameMatchingFrequency:(EKRecurrenceFrequency)frequency
{
    switch (frequency) {
        case EKRecurrenceFrequencyWeekly:
            return @"weekly";
        case EKRecurrenceFrequencyMonthly:
            return @"monthly";
        case EKRecurrenceFrequencyYearly:
            return @"yearly";
        default:
            return @"daily";
    }
}

#pragma mark -
#pragma mark RCT Exports



RCT_EXPORT_METHOD(fetchAllEvents:(NSArray *)IdList  callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
               callback(@[@"Yetki verilmedi", [NSNull null],[NSNull null]]);
            });
        }
        else{
            EKEvent *event;
            NSArray *eventsCopy;

            NSMutableArray* deletedItems=[[NSMutableArray alloc] init];
            NSMutableArray *serializedEvents = [[NSMutableArray alloc] init];
            
            for (NSDictionary* sessionEvent in IdList)
            {
                event = [eventStore eventWithIdentifier:[sessionEvent valueForKey:@"calendarEventID"]];
                if(!event){ //event deleted from calendar
                    [deletedItems addObject:[sessionEvent valueForKey:@"calendarEventID"]];
                    continue;
                }
                [serializedEvents addObject:event];
            }
            
            eventsCopy = [self serializeCalendarEvents:serializedEvents];
         
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[[NSNull null], eventsCopy, deletedItems]);
            });
        }
    }];
}


RCT_EXPORT_METHOD(deleteAllEvents:(NSArray *)IdList  callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null]]);
            });
        }
        else{
            EKEvent *event;
            NSError *err = nil;
            
            for (NSDictionary* sessionEvent in IdList)
            {
                event = [eventStore eventWithIdentifier:[sessionEvent valueForKey:@"calendarEventID"]];
                if(event){ //event
                    [eventStore removeEvent:event span:EKSpanThisEvent error:&err];
                }
            }

             dispatch_async(dispatch_get_main_queue(), ^{
              callback(@[[NSNull null]]);
            });
        }
    }];
}


RCT_EXPORT_METHOD(deleteEvent:(NSString *)eventId callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null]]);
            });
        }
        else{
            
    
            EKEvent *event = [eventStore eventWithIdentifier:eventId];
            // Uncomment below if you want to create a new event if savedEventId no longer exists
            // if (event == nil)
            //   event = [EKEvent eventWithEventStore:store];
            if (event) {
                NSError *err = nil;
                
                BOOL result = [eventStore removeEvent:event span:EKSpanThisEvent error:&err];
                
                 // sil  ---
                if(result){
                    NSString *savedEventId = event.eventIdentifier;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[NSNull null]]);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[err localizedDescription]]);
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(@[@"Event Not Found in Calendar"]);
                });
            }
        }
    }];
}


RCT_EXPORT_METHOD(getEvent:(NSString *)eventId  callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null],[NSNull null]]);
            });
        }
        else{
            NSArray *eventsCopy;
            NSMutableArray* deletedItems=[[NSMutableArray alloc] init];
            NSMutableArray *serializedEvents = [[NSMutableArray alloc] init];
            
            EKEvent *event = [eventStore eventWithIdentifier:eventId];
            if(event){
                eventsCopy = [self serializeCalendarEvent:event];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(@[[NSNull null], eventsCopy]);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(@[@"Event Not Found in Calendar", [NSNull null]]);
                });
            }
        }
    }];
}




RCT_EXPORT_METHOD(editEvent:(NSString *)eventId sDate:(NSDate *)sDate eDate:(NSDate *)eDate aTime:(nonnull NSNumber *)aTime callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null]]);
            });
        }
        else{
            EKEvent *event = [eventStore eventWithIdentifier:eventId];
            // Uncomment below if you want to create a new event if savedEventId no longer exists
            // if (event == nil)
            //   event = [EKEvent eventWithEventStore:store];
            if (event) {
                NSError *err = nil;
                if(sDate){
                    event.startDate = sDate;
                }
                if(eDate){
                    event.endDate = eDate;
                }
                if (aTime && [aTime intValue] != -1) {
                    EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:[aTime intValue] * -60]; // Half Hour Before
                    event.alarms = [NSArray arrayWithObject:alarm];
                }
                else {
                    [event setAlarms:[NSArray array]];
                }
                
                BOOL result = [eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
                if(result){
                    NSString *savedEventId = event.eventIdentifier;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[NSNull null], savedEventId]);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[err localizedDescription], [NSNull null]]);
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(@[@"Event Not Found in Calendar", [NSNull null]]);
                });
            }
        }
    }];
}

RCT_EXPORT_METHOD(addEvent:(NSString *)name notes:(NSString *)notes location:(NSString *)location sDate:(NSDate *)sDate eDate:(NSDate *)eDate aTime:(nonnull NSNumber *)aTime callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null]]);
            });
        }
        else{
        // create an instance of event with the help of event-store object.
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.notes = notes;
        // set the title of the event.
        event.title = name;
        
        // set the start date of event - based on current time, tomorrow's date
        event.startDate = sDate; // 24 hours * 60 mins * 60 seconds = 86400
        
        // set the end date - meeting duration 1 hour
        event.endDate = eDate; // 25 hours * 60 mins * 60 seconds = 86400
        
        /* optional now
         event.allDay    = NO;    // set the calendar of the event. - here default calendar
         event.location  = @"Location of";
         event.notes     = @"Notes";*/
       if (aTime && [aTime intValue] != -1) {
            EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:[aTime intValue] * -60]; // Half Hour Before
            event.alarms = [NSArray arrayWithObject:alarm];
        }
        //set calendar
        [event setCalendar: eventStore.defaultCalendarForNewEvents];

                NSError *err;
                BOOL result  = [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                
                if(result){
                    NSString *savedEventId = event.eventIdentifier;
                    //NSString *calendarEventId = event.calendarItemIdentifier;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[NSNull null], savedEventId]);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[err localizedDescription], [NSNull null]]);
                    });
                }

        }
        
    }];

}

@end
