![CroppedMK](https://user-images.githubusercontent.com/16869300/191701451-5550afce-b19f-4f8c-9e28-90777dd441e1.png)

# Microsoft Store App Install Powershell Script - RMM Friendly!!

![Build](https://img.shields.io/badge/Build-Passing-Success)

Hello and welcome!
This script allows the user to install a Microsoft Store App. As the title suggests, its RMM friendly, tested with [Datto RMM](https://www.datto.com/products/rmm/) and [Tactical RMM](https://github.com/amidaware/tacticalrmm). 

The Script Uses the ["RunAsUser"](https://github.com/KelvinTegelaar/RunAsUser) module created by [Kelvin Tegelaar](https://www.cyberdrain.com/). A user has to be logged in for the script to work. The script, as of 22/09/2022, will now feed the output of the installation into the RMM.

As of the 29/09/2022, you can use the script with an enviroment variable using the App ID.

As of 06/02/2023, Better error handling has been written into the script.

If this script helped you, please give it a star to show your appreciation. 

=======================================================================

List of well known apps which can be installed along with their IDs:

App Name | ID
--- | ---
Microsoft Photos | `9WZDNCRFJBH4`
Company Portal | `9WZDNCRFJ3PZ`
Microsoft 365 (Office) | `9WZDNCRD29V9`
Adobe Acrobat Reader DC | `XPDP273C0XHQH2`
Adobe Creative Cloud | `XPDLPKWG9SW2WD`
WhatsApp | `9NKSQGP7F2NH`
Zoom | `XP99J3KP4XZ4VV`

========================================================================

If you would like to learn more on how this script works or how to implement it into your RMM, please don't hesitate to contact me via [email](mailto:david@mearkats.co.uk) and I'll get back to you as soon as I can!

If this script helped you, please give it a star to show your appreciation. 
