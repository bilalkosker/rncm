# React-Native-CalendarReminders
React Native Module for IOS Calendar


## Install
```
npm install react-native-calendar-manager
```
Then add RNCalendarManager to project libraries.


## Usage

Require Native Module:
```javascript
var RNCalendarManager = require('react-native-calendar-manager');
```
The **EventKit.framework** will also need to be added to the project

## Events
When adding, removing, or editing reminders, an app event will be dispatched with the name `EventReminder` along with the collection of reminders on the body.

```javascript
componentWillMount () {
  this.eventEmitter = NativeAppEventEmitter.addListener('EventReminder', (reminders) => {...});
}

componentWillUnmount () {
  this.eventEmitter.remove();
}
```

## Request authorization to IOS EventStore
Authorization must be granted before accessing reminders.

```javascript
RNCalendarReminders.authorizeEventStore((error, auth) => {...});
```


## Fetch all reminders from EventStore

```javascript
RNCalendarReminders.fetchAllReminders(reminders => {...});
```
## Create reminder

```
RNCalendarReminders.saveReminder(title, settings);
```
Example:
```javascript
RNCalendarReminders.saveReminder('title', {
  location: 'location',
  notes: 'notes',
  startDate: '2016-10-01T09:45:00.000UTC'
});
```

## Create reminder with alarms

### Alarm options:

| Property        | Value            | Description |
| :--------------- | :------------------| :----------- |
| date           | Date or Number    | If a Date is given, an alarm will be set with an absolute date. If a Number is given, an alarm will be set with a relative offset (in minutes) from the start date. |
| structuredLocation | Object             | The location to trigger an alarm. |

### Alarm structuredLocation properties:

| Property        | Value            | Description |
| :--------------- | :------------------| :----------- |
| title           | String  | The title of the location.|
| proximity | String             | A value indicating how a location-based alarm is triggered. Possible values: `enter`, `leave`, `none`. |
| radius | Number             | A minimum distance from the core location that would trigger the reminder's alarm. |
| coords | Object             | The geolocation coordinates, as an object with latitude and longitude properties |

Example with date:

```javascript
RNCalendarReminders.saveReminder('title', {
  location: 'location',
  notes: 'notes',
  startDate: '2016-10-01T09:45:00.000UTC',
  alarms: [{
    date: -1 // or absolute date
  }]
});
```
Example with structuredLocation:

```javascript
RNCalendarReminders.saveReminder('title', {
  location: 'location',
  notes: 'notes',
  startDate: '2016-10-01T09:45:00.000UTC',
  alarms: [{
    structuredLocation: {
      title: 'title',
      proximity: 'enter',
      radius: 500,
      coords: {
        latitude: 30.0000,
        longitude: 97.0000
      }
    }
  }]
});
```

Example with recurrence:

```javascript
## add event
 RNCalendarManager.addEvent(title, notes, location, that.state.startDate, that.state.endDate, that.state.setalarm ? that.state.alarm : -1,(error, savedID) => 
                            {   
                                if(error) {
                                     
                                } else {
                                }
                            });
```