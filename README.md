# React-Native-CalendarReminders
React Native Module for IOS Calendar

The version will reviewed again and cleaned for all users

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
```javascript
//calendar id saved app db when RNCalendarManager.addEvent is success
RNCalendarManager.fetchAllEvents(calendarIDs, firstDay,lastDay, (error, events, deleted) => {
                    
                    if(deleted.length){ //database de var ama takvimden silimiş olan eventler
                       
                    }

                    if (error) {
                     
                      
                    } else {
                       
                       
                    }
                });
  ```
  
  ```javascript
         RNCalendarManager.editEvent(that.state.calendarEventID, that.state.startDate, that.state.endDate, that.state.setalarm ? that.state.alarm : -1,  (error, events) => {
                            if (error) {
                                console.log(error);
                                AlertIOS.alert(
                                    LANG[this.props.language]['Error'],
                                    error,
                                    [
                                      {text: LANG[this.props.language]['OK'], onPress: (text) => console.log('ok')},
                                    ] 
                                 );
                            } else {
                                DBActions.updateSession({sessionID: that.props.sessionID, startDate: that.state.startDate, endDate: that.state.endDate, homework : that.state.homework, note: that.state.note, price: that.state.price, alarm: that.state.setalarm ? that.state.alarm : null}, (data) => {
                                    AppActions.sessionUpdated();
                                    that._goBack();
                                }, (error) => {
                                    console.log(error);

                                }); 
                            }
                        });
   ```
