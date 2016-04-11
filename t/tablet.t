use Test::Nginx::Socket::Lua 'no_plan';

run_tests();

__DATA__

=== TEST 1: mobile_detect.tablet() - Android
--- http_config
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}
--- config
location = /t {
    content_by_lua_block {
        local user_agent = 'Mozilla/5.0 (Linux; Android 4.4.3; Nexus 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.114 Mobile Safari/537.36'
        ngx.say(mobile_detect.tablet(user_agent))
    }
}
--- request
GET /t
--- response_body
NexusTablet
--- error_code: 200


=== TEST 2: mobile_detect.tablet() - iPhone6
--- http_config
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}
--- config
location = /t {
    content_by_lua_block {
        local user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 6_0_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A523 Safari/8536.25'
        ngx.say(mobile_detect.tablet(user_agent))
    }
}
--- request
GET /t
--- response_body
nil
--- error_code: 200


=== TEST 3: mobile_detect.tablet() - BlackBerry
--- http_config
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}
--- config
location = /t {
    content_by_lua_block {
        local user_agent = 'Mozilla/5.0 (BB10; Touch) AppleWebKit/537.10+ (KHTML, like Gecko) Version/10.0.9.2372 Mobile Safari/537.10+'
        ngx.say(mobile_detect.tablet(user_agent))
    }
}
--- request
GET /t
--- response_body
nil
--- error_code: 200


=== TEST 4: mobile_detect.tablet() - MacBook
--- http_config
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}
--- config
location = /t {
    content_by_lua_block {
        local user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.110 Safari/537.36'
        ngx.say(mobile_detect.tablet(user_agent))
    }
}
--- request
GET /t
--- response_body
nil
--- error_code: 200


=== TEST 5: mobile_detect.tablet() - Bot
--- http_config
init_by_lua_block {
    mobile_detect = require "mobile-detect"
}
--- config
location = /t {
    content_by_lua_block {
        local user_agent = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
        ngx.say(mobile_detect.tablet(user_agent))
    }
}
--- request
GET /t
--- response_body
nil
--- error_code: 200
