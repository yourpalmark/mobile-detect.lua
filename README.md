[![Build Status](https://travis-ci.org/yourpalmark/mobile-detect.lua.svg?branch=master)](https://travis-ci.org/yourpalmark/mobile-detect.lua)

# mobile-detect.lua

A loose port of [Mobile-Detect](https://github.com/serbanghita/Mobile-Detect) to Lua for NGINX HTTP servers.

The script will detect the device by comparing patterns against a given User-Agent string.  
The following device information is available:

  * mobile or not
  * if mobile, whether phone or tablet
  * operating system
  * [Mobile Grade (A, B, C)](http://jquerymobile.com/gbs/)
  * specific versions (e.g. WebKit)

Current `master` branch is using detection logic from **Mobile-Detect@2.8.20**

# Requirements

* [NGINX compiled with Lua module](https://github.com/openresty/lua-nginx-module#installation)
  * ([OpenResty](http://openresty.org/) bundle is recommended)
* [CJSON](https://github.com/mpx/lua-cjson)
  * If using OpenResty, CJSON is preinstalled
  * If not: `luarocks install lua-cjson`
* [Lrexlib - PCRE](https://github.com/rrthomas/lrexlib)
  * `luarocks install lrexlib-PCRE`

# Usage

```nginx
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}

content_by_lua_block {
    local user_agent = ngx.var.http_user_agent
    ngx.say(mobile_detect.mobile(user_agent))
    ngx.say(mobile_detect.is('iPhone', user_agent))
    ngx.say(mobile_detect.is('bot', user_agent))
}
```

# License

MIT-License (see LICENSE file)
