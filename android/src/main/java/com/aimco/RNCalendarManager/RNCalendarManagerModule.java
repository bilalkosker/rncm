package com.aimco.RNCalendarManager;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Arguments;

import java.text.ParseException; 
import java.text.SimpleDateFormat; 
import java.util.ArrayList; 
import java.util.Calendar; 
import java.util.Date; 
import java.util.GregorianCalendar; 
import java.util.HashMap; 
import java.util.List; 
import java.util.Locale;
import java.util.TimeZone;
import java.text.SimpleDateFormat;
import java.text.DateFormat;

import android.net.Uri;

 
import java.util.HashSet;
import java.util.regex.Pattern;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor; 
import android.text.format.DateUtils;
import android.provider.CalendarContract.Calendars;
import android.provider.CalendarContract;
 
import android.provider.CalendarContract.Events;
import android.content.ContentValues;
 
import java.util.Collections;    

import android.telephony.SmsManager;
import android.widget.Toast;
import android.util.Log;
import org.json.JSONObject;



/**
 * NativeModule that allows JS to open emails sending apps chooser.
 */

public class RNCalendarManagerModule extends ReactContextBaseJavaModule {

  ReactApplicationContext reactContext;

  public RNCalendarManagerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }
  private Calendar _calendar;
  private int month, year;
  public static final Uri CALENDAR_URI = Uri.parse("content://com.android.calendar/calendars");

  
  // Projection array. Creating indices for this array instead of doing
// dynamic lookups improves performance.
public static final String[] EVENT_PROJECTION = new String[] {
    Calendars._ID,                           // 0
    Calendars.ACCOUNT_NAME,                  // 1
    Calendars.CALENDAR_DISPLAY_NAME,         // 2
    Calendars.OWNER_ACCOUNT                  // 3
};
  
// The indices for the projection array above.
private static final int PROJECTION_ID_INDEX = 0;
private static final int PROJECTION_ACCOUNT_NAME_INDEX = 1;
private static final int PROJECTION_DISPLAY_NAME_INDEX = 2;
private static final int PROJECTION_OWNER_ACCOUNT_INDEX = 3;
  
  
  
  
   @Override
   public String getName() {
        return "RNCalendarManager";
   }

    // Default constructor
    public static HashMap<String, List<CalendarEvent>> readCalendar(Context context) {
        return readCalendar(context, 1, 0);
    }

    // Use to specify specific the time span
    public static HashMap<String, List<CalendarEvent>> readCalendar(Context context, int days, int hours) {

        ContentResolver contentResolver = context.getContentResolver(); 
        Cursor cursor = contentResolver.query(
                Uri.parse("content://com.android.calendar/events"),
                new String[] { "calendar_id", "title", "description",
                        "dtstart", "dtend", "eventLocation" }, null,
                null, null);

        HashSet<String> calendarIds = getCalenderIds(cursor);

        HashMap<String, List<CalendarEvent>> eventMap = new HashMap<String, List<CalendarEvent>>();
        
        
        for (String id : calendarIds) {
            // Create a builder to define the time span
            Uri.Builder builder = Uri.parse("content://com.android.calendar/instances/when").buildUpon();
            long now = new Date().getTime();

            // create the time span based on the inputs
            ContentUris.appendId(builder, now - (DateUtils.DAY_IN_MILLIS * days) - (DateUtils.HOUR_IN_MILLIS * hours));
            ContentUris.appendId(builder, now + (DateUtils.DAY_IN_MILLIS * days) + (DateUtils.HOUR_IN_MILLIS * hours));

           Cursor eventCursor = contentResolver.query(builder.build(),
            new String[] { "_id" ,"calendar_id", "title", "description", "dtstart", "dtend", "allDay", "eventLocation"}, "calendar_id=" + id,
            null, "startDay ASC, startMinute ASC");

            System.out.println("eventCursor count="+eventCursor.getCount());

            // If there are actual events in the current calendar, the count will exceed zero
            if(eventCursor.getCount()>0)
            {

                    // Create a list of calendar events for the specific calendar
                List<CalendarEvent> eventList = new ArrayList<CalendarEvent>();

                    // Move to the first object
                eventCursor.moveToFirst();

                // Create an object of CalendarEvent which contains the title, when the event begins and ends, 
                // and if it is a full day event or not 
                CalendarEvent ce = loadEvent(eventCursor);

                // Adds the first object to the list of events
                eventList.add(ce);

                System.out.println(ce.toString());

                // While there are more events in the current calendar, move to the next instance
                while (eventCursor.moveToNext())
                {
                    // Adds the object to the list of events
                    ce = loadEvent(eventCursor);
                    eventList.add(ce);

                    System.out.println(ce.toString());
                }

                Collections.sort(eventList);
                eventMap.put(id, eventList);
            } 
        }
        return eventMap;            
    }
	
    // Returns a new instance of the calendar object
    private static CalendarEvent loadEvent(Cursor csr) {
        return new CalendarEvent(csr.getInt(0),
                                 csr.getString(2), 
                                 new Date(csr.getLong(4)),
                                 new Date(csr.getLong(5)), 
                                 !csr.getString(6).equals("0"));
    }
        
    //tested
    // Creates the list of calendar ids and returns it in a set
    private static HashSet<String> getCalenderIds(Cursor cursor) {
		
		HashSet<String> calendarIds = new HashSet<String>();
		
		try
	    { 
			// If there are more than 0 calendars, continue
	        if(cursor.getCount() > 0)
	        { 
	        	// Loop to set the id for all of the calendars
		    while (cursor.moveToNext()) {
	
                        String _id = cursor.getString(0);
                        String displayName = cursor.getString(1);
                        Boolean selected = !cursor.getString(2).equals("0");

                        //System.out.println("Id: " + _id + " Display Name: " + displayName + " Selected: " + selected);
                        calendarIds.add(_id);
		            
		    }
	        } 
	    }
		
	    catch(AssertionError ex)
	    {
	        ex.printStackTrace();
	    }
	    catch(Exception e)
	    {
	        e.printStackTrace();
	    }
		
		return calendarIds;
		
	}
  
  
@ReactMethod
public void getCalendarEvents(Callback success, Callback err) {  
      
    /* Toast.makeText(reactContext, "Başarılı",
    Toast.LENGTH_LONG).show();*/
    //success.invoke(new JSONObject(readCalendar(reactContext,50,0).values()));
    
    System.out.println(readCalendar(reactContext,50,0).values()); 
   
};

  
@ReactMethod
public void addEvent(ReadableMap startDate, ReadableMap endDate, int startYear, int startMonth, int startDay, int startHour, int startMinute, String title,
                      Callback success, // Callback for success 
                      Callback err) { 
    
    
    //find default calendar id!!!
    //send date as date object anyway
    /*long calId = getCalendarId();
    if (calId == -1) {
       // no calendar account; react meaningfully
       return;
    }  */
    
   /*Calendar beginTime = Calendar.getInstance();
beginTime.set(2013, 3, 23, 7, 30);
startMillis = beginTime.getTimeInMillis();
Calendar endTime = Calendar.getInstance();
endTime.set(2013, 3, 24, 8, 45);
endMillis = endTime.getTimeInMillis();*/ 
     
    Calendar beginTime = Calendar.getInstance();
    beginTime.set(startYear, startMonth, startDay, startHour, startMinute);
    long startMillis = beginTime.getTimeInMillis();

    // String to access default google calendar of device for Event setting.
    String eventUriString = "content://com.android.calendar/events";

    ContentValues eventValues = new ContentValues();
    eventValues.put(Events.CALENDAR_ID, 1);
    eventValues.put(Events.TITLE, title);
    eventValues.put(Events.DESCRIPTION, "Discription");
    eventValues.put(Events.EVENT_TIMEZONE, "UTC/GMT +2:00");
    eventValues.put(Events.DTSTART, startMillis);
    eventValues.put(Events.DTEND, startMillis);
    //eventValues.put("eventStatus", 1);
    //eventValues.put("visibility", 3);
    //eventValues.put("transparency", 0);
    //eventValues.put(Events.HAS_ALARM, 1);    

    // Set Event in calendar.
    Uri eventUri = reactContext.getContentResolver().insert(Uri.parse(eventUriString), eventValues);
    // Getting ID of event in Long. 
    
    int id = Integer.parseInt(eventUri.getLastPathSegment());
    Toast.makeText(reactContext, "Created Calendar Event " + id,
        Toast.LENGTH_LONG).show();
    success.invoke(id);
     /* 
      Calendar cal = Calendar.getInstance();              
Intent i = new Intent(Intent.ACTION_EDIT);
i.setType("vnd.android.cursor.item/event");
i.putExtra("beginTime", cal.getTimeInMillis());
i.putExtra("allDay", true);
i.putExtra("rrule", "FREQ=YEARLY");
i.putExtra("endTime", cal.getTimeInMillis()+60*60*1000);
i.putExtra("title", "A Test Event from android app");


PackageManager manager = reactContext.getPackageManager();
    List<ResolveInfo> list = manager.queryIntentActivities(i, 0);

    if (list == null || list.size() == 0) {
      err.invoke("not_available");
      return;
}
    
    Intent chooser = Intent.createChooser(i, "Enter Calendar");
    chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
 
    try {
      reactContext.startActivity(chooser);
    } catch (Exception ex) {
      err.invoke("error");
    }*/

 
/*    if (options.hasKey("subject") && !options.isNull("subject")) {
      i.putExtra(Intent.EXTRA_SUBJECT, options.getString("subject"));
    }*/
/*
    if (options.hasKey("body") && !options.isNull("body")) {
      i.putExtra(Intent.EXTRA_TEXT, options.getString("body"));
    }*/

   /* if (options.hasKey("recipients") && !options.isNull("recipients")) {
      ReadableArray r = options.getArray("recipients");
      int length = r.size();
      String[] recipients = new String[length];
      for (int keyIndex = 0; keyIndex < length; keyIndex++) {
        recipients[keyIndex] = r.getString(keyIndex);
      }
      i.putExtra(Intent.EXTRA_EMAIL, recipients);
    }*/

   /* PackageManager manager = reactContext.getPackageManager();
    List<ResolveInfo> list = manager.queryIntentActivities(i, 0);

    if (list == null || list.size() == 0) {
      callback.invoke("not_available");
      return;
    }*/

    /*Intent chooser = Intent.createChooser(i, "Send Mail");
    chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
*/
    /*try {
      reactContext.startActivity(chooser);
    } catch (Exception ex) {
      callback.invoke("error");
    }*/











      
      
			 /*			  
			try {
            SmsManager m = SmsManager.getDefault();
            m.sendTextMessage(phoneNo, null, sms, null, null); 	
				success.invoke(); // Call success callback
			} catch (Exception e) {
				 
				err.invoke(e.getMessage());
			}  */
	  
	   //  WritableNativeMap data = new WritableNativeMap(); 
    /*DisplayMetrics metrics = this.reactContext.getResources().getDisplayMetrics(); 
    String orientation = ""; 
    if(metrics.widthPixels < metrics.heightPixels){ 
      orientation = "PORTRAIT"; 
    }else { 
      orientation = "LANDSCAPE"; 
    } 
    data.putString("orientation", orientation); 
    data.putString("device", getDeviceName()); */
    //success.invoke(data); 
	  
	  
	  
	  /*
	  LocationManager locationManager =
          (LocationManager) getReactApplicationContext().getSystemService(Context.LOCATION_SERVICE);*/
		  
		  
		  
		  
	  //this.readCalendar(this.reactContext);
        /*Calendar cal = Calendar.getInstance(); 
        cal.set(2012, 9, 14, 7, 30); 
        Intent intent = new Intent(Intent.ACTION_EDIT);
        intent.setType("vnd.android.cursor.item/event");
        intent.putExtra("beginTime", cal.getTimeInMillis());
        intent.putExtra("allDay", false);
        intent.putExtra("rrule", "FREQ=YEARLY");
        intent.putExtra("endTime",cal.getTimeInMillis() + 60 * 60 * 1000);
        intent.putExtra("title", " Test Title");*/
        //startActivity(intent);
       // callback.invoke(""+5,"","","","","");

/*
    Intent i = new Intent(Intent.ACTION_SEND);
    i.setType("message/rfc822");

    if (options.hasKey("subject") && !options.isNull("subject")) {
      i.putExtra(Intent.EXTRA_SUBJECT, options.getString("subject"));
    }

    if (options.hasKey("body") && !options.isNull("body")) {
      i.putExtra(Intent.EXTRA_TEXT, options.getString("body"));
    }

    if (options.hasKey("recipients") && !options.isNull("recipients")) {
      ReadableArray r = options.getArray("recipients");
      int length = r.size();
      String[] recipients = new String[length];
      for (int keyIndex = 0; keyIndex < length; keyIndex++) {
        recipients[keyIndex] = r.getString(keyIndex);
      }
      i.putExtra(Intent.EXTRA_EMAIL, recipients);
    }

    PackageManager manager = reactContext.getPackageManager();
    List<ResolveInfo> list = manager.queryIntentActivities(i, 0);

    if (list == null || list.size() == 0) {
      callback.invoke("not_available");
      return;
    }

    Intent chooser = Intent.createChooser(i, "Send Mail");
    chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

    try {
      reactContext.startActivity(chooser);
    } catch (Exception ex) {
      callback.invoke("error");
    }
*/	   
  }
}
