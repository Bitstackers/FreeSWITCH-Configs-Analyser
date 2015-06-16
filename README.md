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
