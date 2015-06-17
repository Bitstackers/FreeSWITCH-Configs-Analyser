# Freeswitch Config Analyzer

##Ivr Checks

* File must start with a single &lt;include&gt;.
* &lt;Include&gt; may only contains &lt;menu&gt;.
* &lt;menu&gt; must have a unique name.
* &lt;menu&gt; name should start with the reception number.
* &lt;menu&gt; may only contain &lt;entry&gt;.
* &lt;entry&gt; must have unique digits within a menu.
* &lt;entry&gt; should have unique param within a menu.
* If entry' acttion is menu-sub, then there is checked if the reference menu exists.
* &lt;entry&gt; action is checked from a list of known actions.
* &lt;menu&gt; and &lt;entry&gt; attributes is checked from a list of expected attributes.

##Dialplan Checks

* File must start with a single &lt;include&gt;.
* &lt;Include&gt; may only contains &lt;extension&gt;.
* &lt;extension&gt; must have a unique name.
* &lt;extension&gt; name should start with "reception_" followed by the reception number.
* &lt;extension&gt; may only contain &lt;condition&gt;.
* &lt;condition&gt; destination_number should match filename.
* &lt;condition&gt; may only contain &lt;condition&gt; or &lt;action&gt;.
* &lt;condition&gt; time-of-day, wday gets checked.
* &lt;action&gt; IVR gets checked if it exists.
* &lt;action&gt; Playback gets checked if the audiofile exists.
* &lt;action&gt; Voicemail checks if it follows a known pattern.
