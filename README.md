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
  * [OpenResty](http://openresty.org/) bundle is recommended
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

# Contributing

Your contribution is welcome.  
If you want new devices to be supported, please contribute to [Mobile-Detect](https://github.com/serbanghita/Mobile-Detect).  
Changes there will cascade to this project.

If you have bug-fixes, new features, etc for this project, please follow the below steps:  
*Note: To generate source from template, it requires [Mobile-Detect](https://github.com/serbanghita/Mobile-Detect) as a sibling directory to [mobile-detect.lua](https://github.com/yourpalmark/mobile-detect.lua)*

 * Clone [Mobile-Detect](https://github.com/serbanghita/Mobile-Detect)
 * Fork [mobile-detect.lua](https://github.com/yourpalmark/mobile-detect.lua)
 * Create branch
 * Make changes
 * Generate source: `php generate/generate.php` (requires PHP >= 5.4 in your PATH)
 * Run tests (see below)
 * Commit, push to your branch
 * Create pull request

# Testing

 * Install Perl (add to PATH)
 * Install [Test::Nginx](https://github.com/openresty/test-nginx): `cpan Test::Nginx`
 * Run: `prove -r t`

# License

MIT-License (see LICENSE file)
