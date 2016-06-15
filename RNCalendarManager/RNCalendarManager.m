#import "RNCalendarManager.h"
#import "RCTConvert.h"
#import <EventKit/EventKit.h>

@interface RNCalendarManager ()
// EKEventStore instance associated with the current Calendar application
@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong) NSString *calendarIdentifier;

// Default calendar associated with the above event store
@property (nonatomic, strong) EKCalendar *defaultCalendar;

// Array of all events happening within the next 24 hours
@property (nonatomic, strong) NSMutableArray *eventsList;

@property (nonatomic) BOOL isAccessToEventStoreGranted;

@end


static NSString *const _allDay= @"allDay";
static NSString *const _eventIdentifier = @"eventIdentifier";
static NSString *const _startDate = @"startDate";
static NSString *const _endDate = @"endDate";
static NSString *const _index = @"index";

static NSString *const calendarIdentifier = nil;



static NSString *const my_calendar_name = @"AIMCO";

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



#pragma mark -
#pragma mark RCT Exports

RCT_EXPORT_METHOD(checkCalendar:(NSString *)identifier callback:(RCTResponseSenderBlock)callback){
   
    EKEventStore *eventStore = self.eventStore;
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null],[NSNull null]]);
            });
        }
        else{
            
            EKCalendar *selectedCalendar = nil;
            if(identifier){ //if identifier used before find calendar
                NSArray *allCalendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
                for (EKCalendar *calendar in allCalendars) {
                    if ([calendar.calendarIdentifier isEqualToString:identifier]) {
                        selectedCalendar = calendar;
                        break;
                    }
                }
            }
            if(!selectedCalendar){ // if calendar not found create a calendar with name 'AIMCO'
                EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
                [calendar setTitle:my_calendar_name];
                EKSource *theSource= nil;
                
                for(EKSource *s in eventStore.sources){ //icloud calendar create
                    if(s.sourceType == EKSourceTypeCalDAV && [s.title isEqualToString: @"iCloud"]){
                        theSource= s;
                        break;
                    }
                }
                if(!theSource){
                    for(EKSource *s in eventStore.sources){
                        if(s.sourceType == EKSourceTypeLocal){
                            theSource= s;
                            break;
                        }
                    }
                }
                
                if(theSource){
                    calendar.source = theSource;
                }
                else {
                    NSLog(@"Error: Local source not available");
                    return;
                }
                
                NSString *calendarIdentifier = [calendar calendarIdentifier];
                NSError *error = nil;
                BOOL saved = [eventStore saveCalendar:calendar commit:YES error:&error];
                if(saved)
                {
                    self.calendarIdentifier = calendarIdentifier;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[[NSNull null], calendarIdentifier]);
                    });
                    return;
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(@[@"Takvim Oluşturulamadı", [NSNull null]]);
                    });
                    return;
                }
            } else {
                self.calendarIdentifier = identifier;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[[NSNull null], [NSNull null]]);
            });
        }
    }];
 }


RCT_EXPORT_METHOD(fetchAllEvents:(NSArray *)IdList callback:(RCTResponseSenderBlock)callback)
{
    /*
     
     
        NSPredicate *predicate =[self.eventStore predicateForEventsWithStartDate:[NSDate distantPast] endDate:[NSDate distantFuture] calendars:calendarsArray];
     
     */
    
    
    
    EKEventStore *eventStore = self.eventStore;
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[@"Yetki verilmedi", [NSNull null],[NSNull null]]);
            });
        }
        else{
            EKEvent *event;
            NSArray *eventsCopy;
            
            static NSString *const dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z";
            NSMutableArray* deletedItems=[[NSMutableArray alloc] init];
            NSMutableArray *serializedEvents = [[NSMutableArray alloc] init];
            
            NSDictionary *empty_event = @{
                                          _allDay: @"",
                                          _eventIdentifier: @"",
                                          _startDate: @"",
                                          _endDate: @"",
                                          _index : @""
                                          };
            
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            
            [dateFormatter setTimeZone:timeZone];
            [dateFormatter setDateFormat:dateFormat];
            
            for (NSDictionary* sessionEvent in IdList)
            {
                
                NSMutableDictionary *formedEvent = [NSMutableDictionary dictionaryWithDictionary:empty_event];
                event = [eventStore eventWithIdentifier:[sessionEvent valueForKey:@"calendarEventID"]];
                if(!event){ //event deleted from calendar
                    [deletedItems addObject:[sessionEvent valueForKey:@"calendarEventID"]];
                    continue;
                }
                [formedEvent setValue: [sessionEvent valueForKey:@"index"]  forKey: _index];
                
                if(event.eventIdentifier){
                    [formedEvent setValue: event.eventIdentifier forKey: _eventIdentifier];
                }
                if(event.allDay){
                    
                    [formedEvent setValue: NSStringFromBOOL(event.allDay) forKey: _allDay];
                    
                }
                if (event.startDate) {
                    
                    NSDate *eventStartDate = event.startDate;
                    
                    [formedEvent setValue:[dateFormatter stringFromDate:eventStartDate] forKey:_startDate];
                }
                if (event.endDate) {
                    
                    NSDate *eventEndDate = event.endDate;
                    
                    [formedEvent setValue:[dateFormatter stringFromDate:eventEndDate] forKey:_endDate];
                }
                [serializedEvents addObject:formedEvent];
            }
            eventsCopy = [serializedEvents copy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@[[NSNull null], eventsCopy, deletedItems]);
            });
            
        }
    }];
}

RCT_EXPORT_METHOD(editEvent:(NSString *)eventId sDate:(NSDate *)sDate eDate:(NSDate *)eDate aTime:(nonnull NSNumber *)aTime callback:(RCTResponseSenderBlock)callback)
{
    EKEventStore *eventStore = self.eventStore;
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
    EKEventStore *eventStore = self.eventStore;
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
            
           /* EKCalendar *selectedCalendar = nil;
            if(identifier){ //if identifier used before find calendar
                NSArray *allCalendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
                for (EKCalendar *calendar in allCalendars) {
                    if ([calendar.calendarIdentifier isEqualToString:identifier]) {
                        selectedCalendar = calendar;
                        break;
                    }
                }
            }*/
            
            EKCalendar *cal = [eventStore calendarWithIdentifier:self.calendarIdentifier];
            //set calendar
            [event setCalendar: cal];
            
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
