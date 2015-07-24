# EventsApp/Resources/Sounds

Custom sounds used by the app

## Files

Brief description of files. Add a bried description when adding a new file.
Keep list in alphabetical order.

#### [notification.caf](http://www.freesound.org/people/FoolBoyMedia/sounds/234564/)
General remote notfication alert sound

#### [muted.caf](http://sharkfood.com/content/Developers/content/Sound%20Switch/)
Sound used for detecting the device's silent switch state


## Creating `.caf` files

* Convert the `.ogg` file to a `.wav` file using [media.io](http://media.io)
* Convert the `.wav` file to a `.caf` file using the command line command:
  `afconvert -d LEI16 -f 'caff' notification.xxx notification.caf`
* If necessary, trim the file with QuickTime. 
  * 1 second duration seems reasonable.