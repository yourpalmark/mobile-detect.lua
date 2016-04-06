# mobile-detect.lua

A loose port of [Mobile-Detect](https://github.com/serbanghita/Mobile-Detect) to Lua.

The script will detect the device by comparing patterns against a given User-Agent string.  
The following device information is available:

  * mobile or not
  * if mobile, whether phone or tablet
  * operating system
  * [Mobile Grade (A, B, C)](http://jquerymobile.com/gbs/)
  * specific versions (e.g. WebKit)

Current `master` branch is using detection logic from **Mobile-Detect@2.8.20**
