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


```javascript

 RNCalendarManager.addEvent(title, notes, location, that.state.startDate, that.state.endDate, that.state.setalarm ? that.state.alarm : -1,(error, savedID) => 
                            {   
                                if(error) {
                                     
                                } else {
                                }
                            });
```