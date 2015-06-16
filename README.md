# Freeswitch Config Analyzer

##Ivr Checks

* File must start with a single <include>.
* <Include> may only contains <menu>.
* <menu> must have a unique name.
* <menu> name should start with the reception number.
* <menu> may only contain <entry>.
* <entry> must have unique digits within a menu.
* <entry> should have unique param within a menu.
* If entry' acttion is menu-sub, then there is checked if the reference menu exists.
* <entry> action is checked from a list of known actions.
* <menu> and <entry> attributes is checked from a list of expected attributes.
