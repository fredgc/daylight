# daylight local time

Notes and plan.

TODO:
- Do not include this file in github repo.
- publish to daylight.gchouse.org
  - may take 24 hours.
- figure out how to download apk to android phone and sideload.
  - need to upgrade to "blaze" version of firebase.
- have link from android app to main web page for info.
- Adjust clock face. (so that seconds per minute is good.)
  - just draw my own?
- run in android emulator.
- decide if we need year/month/day. (just for debugging, have jd date
- consider optimizing text with a small state full widget.
- fiddle with formatting. text hidden by hands?

Done:
- X embed in web page.
- X add timer.
- X fix date formatting.
- X add ui for debug location.
- X get location using location package.
- X use local time calcuation.
- X add debugging to be able to set location.
- X update location every N seconds.
- X view on web.
- X fiddle with it to also display location and digital time.
- X get location 
- X convert clock to using hour, min, second. (write my own?)

Classes:
- local_time.dart, LocalTime 
  keeps location stashed and updates every 5 minutes.
  computes local time.
- clock.dart, ClockWidget - 
- main.dart, main app.


widget: string and timer.
location: holds current location.
 - init.
 - valid. returns if the location has been updated.
 - transport. from string. (turns off auto update)
 - refresh. (turns back on auto update)
 - dispose.
 - to string.
time: holds current location.
 - update from DateTime, location.
 - transport from String, location.
 - getTime - in local timezone.
 - double hour(), int minute, int seconds, 
 - int seconds_per_minute
 - date (year, month, day)? 

Create new project:
flutter create -e  --org org.gchouse --project-name daylight .

- where is namespace configured these days?
  - square space. https://account.squarespace.com/domains
  - fix mail and calendar, too.
  - host web site on google, just use flame.

https://console.firebase.google.com/
https://console.cloud.google.com/projectselector2/home/dashboard?organizationId=828615825200&supportedpurview=project
https://account.squarespace.com/domains/managed/gchouse.org/dns/dns-settings

how to install firebase?


- look at
https://console.firebase.google.com/project/garage-door-opener-7c0af/hosting/sites/garage-door-opener-7c0af
or https://console.cloud.google.com/home/dashboard


Here is how to get location:
https://pub.dev/packages/location


maybe try this:
https://www.geeksforgeeks.org/analog-clock-in-flutter/
no -- that looks like it is just using a package analog_clock

This looks better:
https://medium.com/@NPKompleet/creating-an-analog-clock-in-flutter-i-68def107d9f4

But it does very fancy hands and clock face.


This talks about how to do a timer:
https://devbrite.io/flutter-timer


This worked:
https://github.com/rodydavis/flutter_web_component/tree/master/web

