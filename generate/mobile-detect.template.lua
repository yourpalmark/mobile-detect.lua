-----
-- mobile-detect module
-- Find information on how to download and install:
-- http://yourpalmark.github.io/mobile-detect.lua
--
-- @example <pre>
--      init_by_lua_block {
--          mobile_detect = require "mobile-detect"
--      }
--
--      content_by_lua_block {
--          local user_agent = ngx.var.http_user_agent
--          ngx.say(mobile_detect.mobile(user_agent))
--          ngx.say(mobile_detect.is('iPhone', user_agent))
--          ngx.say(mobile_detect.is('bot', user_agent))
--      }
-- </pre>

local ok, json = pcall(require, "cjson")
if not ok then
    error("cjson module required")
end

local ok, rex = pcall(require, "rex_pcre")
if not ok then
    error("rex_pcre module required")
end

local mobile_detect = {}

local impl = {}

impl.mobile_detect_rules_source = [[{{token.rules}}]]
impl.mobile_detect_rules = json.decode(impl.mobile_detect_rules_source)

-- following patterns come from http://detectmobilebrowsers.com/
impl.detect_mobile_browsers_source = [[
    {
        "fullPattern": "(android|bb\\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\\.(browser|link)|vodafone|wap|windows ce|xda|xiino",
        "shortPattern": "1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\\-(n|u)|c55\/|capi|ccwa|cdm\\-|cell|chtm|cldc|cmd\\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\\-s|devi|dica|dmob|do(c|p)o|ds(12|\\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\\-|_)|g1 u|g560|gene|gf\\-5|g\\-mo|go(\\.w|od)|gr(ad|un)|haie|hcit|hd\\-(m|p|t)|hei\\-|hi(pt|ta)|hp( i|ip)|hs\\-c|ht(c(\\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\\-(20|go|ma)|i230|iac( |\\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\\-[a-w])|libw|lynx|m1\\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\\-2|po(ck|rt|se)|prox|psio|pt\\-g|qa\\-a|qc(07|12|21|32|60|\\-[2-7]|i\\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\\-|oo|p\\-)|sdk\/|se(c(\\-|0|1)|47|mc|nd|ri)|sgh\\-|shar|sie(\\-|m)|sk\\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\\-|v\\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\\-|tdg\\-|tel(i|m)|tim\\-|t\\-mo|to(pl|sh)|ts(70|m\\-|m3|m5)|tx\\-9|up(\\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\\-|your|zeto|zte\\-",
        "tabletPattern": "android|ipad|playbook|silk"
    }
]]
impl.detect_mobile_browsers = json.decode(impl.detect_mobile_browsers_source)

impl.TYPE_PHONE = 'phone'
impl.TYPE_TABLET = 'tablet'
impl.TYPE_MOBILE = 'mobile'

impl.FALLBACK_PHONE = 'UnknownPhone'
impl.FALLBACK_TABLET = 'UnknownTablet'
impl.FALLBACK_MOBILE = 'UnknownMobile'

impl.MOBILE_GRADE_A = 'A'
impl.MOBILE_GRADE_B = 'B'
impl.MOBILE_GRADE_C = 'C'

-----
-- Determine if a Lua table can be treated as an array.
-- Explicitly returns -1 for very sparse arrays.
-- @param   table
-- @return  -1   Not an array
--           0   Empty table
--          >0   Highest index in the array
local function is_array(table)
    if type(table) ~= "table" then return -1 end
    local max, count = 0, 0
    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then max = k end
            count = count + 1
        else
            return -1
        end
    end
    if max > count * 2 then
        return -1
    end
    return max
end

-----
-- Get length of table
-- @param   table
-- @return  length of table
local function count(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

-----
-- Compare strings ignoring case
-- @param   a   string
-- @param   b   string
-- @return  boolean
local function equal_ic(a, b)
    return a ~= nil and b ~= nil and a:lower() == b:lower()
end

-----
-- String value in table
-- @param   table
-- @param   value   string
-- @return  boolean
local function contains_ic(table, value)
    local value_lc = value:lower()
    for i, v in ipairs(table) do
        if value_lc == table[i]:lower() then return true end
    end
    return false
end

-----
-- Convert properties to regex
-- @param   table
local function convert_properties_to_regex(table)
    for k, v in pairs(table) do
        if table[k] ~= nil then
            table[k] = rex.new(table[k], 'i')
        end
    end
end

-----
-- Init
local function init()
    local mobile_detect_rules = impl.mobile_detect_rules
    for key, values in pairs(mobile_detect_rules.properties) do
        if mobile_detect_rules.properties[key] ~= nil then
            if is_array(values) == -1 then
                values = { values }
            end
            for i, value in ipairs(values) do
                local ver_pos = value:find('[VER]', nil, true)
                if ver_pos >= 1 then
                    value = value:sub(1, ver_pos-1) .. '([\\w._\\+]+)' .. value:sub(ver_pos + 5)
                end
                values[i] = rex.new(value, 'i')
            end
            mobile_detect_rules.properties[key] = values
        end
    end
    convert_properties_to_regex(mobile_detect_rules.operating_systems)
    convert_properties_to_regex(mobile_detect_rules.phone_devices)
    convert_properties_to_regex(mobile_detect_rules.tablet_devices)
    convert_properties_to_regex(mobile_detect_rules.browsers)
    convert_properties_to_regex(mobile_detect_rules.utilities)

    mobile_detect_rules.operating_systems0 = {
        WindowsPhoneOS=mobile_detect_rules.operating_systems.WindowsPhoneOS,
        WindowsMobileOS=mobile_detect_rules.operating_systems.WindowsMobileOS
    }
end
init()

-----
-- Test user_agent string against a set of rules and find the first matched key.
-- @param   rules       table: k is string, v is regex
-- @param   user_agent  HTTP-Header 'User-Agent'
-- @return  key if found or nil
function impl.find_match(rules, user_agent)
    for k, v in pairs(rules) do
        if rules[k] ~= nil then
            if rules[k]:match(user_agent) then
                return k
            end
        end
    end
    return nil
end

-----
-- Test user_agent string against a set of rules and return an array of matched keys.
-- @param   rules       table: k is string, v is regex
-- @param   user_agent  HTTP-Header 'User-Agent'
-- @return  array of matched keys or empty array if no matches are found
function impl.find_matches(rules, user_agent)
    local result = {}
    for k, v in pairs(rules) do
        if rules[k] ~= nil then
            if rules[k]:match(user_agent) then
                table.insert(result, k)
            end
        end
    end
    return result
end

-----
-- Gets the version of the given property in the User-Agent.
-- @param   property_name
-- @param   user_agent
-- @return  version or nil if version not found
function impl.get_version_str(property_name, user_agent)
    local properties = impl.mobile_detect_rules.properties
    if properties[property_name] ~= nil then
        local patterns = properties[property_name]
        for k, v in pairs(patterns) do
            local match = patterns[k]:match(user_agent)
            if match ~= nil then
                return match
            end
        end
    end
    return nil
end

-----
-- Get the version of the given property in the User-Agent.
-- Will return a float number. (eg. 2_0 will return 2.0, 4.3.1 will return 4.31)
-- @param   property_name
-- @param   user_agent
-- @return  version or nil if version not found
function impl.get_version(property_name, user_agent)
    local version = impl.get_version_str(property_name, user_agent)
    return version and impl.prepare_version_num(version) or nil
end

-----
-- Prepare the version number.
-- @param   version
-- @return  version number as a floating number
function impl.prepare_version_num(version)
    local numbers = {}
    local pattern = [[(\d*)[a-z._ \/\-](\d*)]]
    for a, b, c in rex.split(version, pattern, 'i') do
        if b then table.insert(numbers, b) end
        if c then table.insert(numbers, c) end
    end
    local len = count(numbers)
    if len == 1 then
        version = numbers[1]
    end
    if len > 1 then
        version = numbers[1] .. '.'
        table.remove(numbers, 1)
        version = version .. table.concat(numbers, '')
    end
    return tonumber(version)
end

-----
-- More general mobile fallback rules.
-- @param   user_agent
-- @return  boolean
function impl.is_mobile_fallback(user_agent)
    return rex.match(user_agent, impl.detect_mobile_browsers.fullPattern, 1, 'i') ~= nil or rex.match(user_agent:sub(1, 5), impl.detect_mobile_browsers.shortPattern, 1, 'i') ~= nil
end

-----
-- More general tablet fallback rules.
-- @param   user_agent
-- @return  boolesn
function impl.is_tablet_fallback(user_agent)
    return rex.match(user_agent, impl.detect_mobile_browsers.tabletPattern, 1, 'i') ~= nil
end

-----
-- Detects mobile type.
-- @param   type
-- @param   user_agent
-- @return  detected phone or tablet type or nil if it is not a mobile device
function impl.detect(type, user_agent)
    if type == impl.TYPE_TABLET or type == impl.TYPE_MOBILE then
        local tablet = impl.find_match(impl.mobile_detect_rules.tablet_devices, user_agent)
        if tablet then return tablet end -- unambiguously identified as tablet
    end

    if type == impl.TYPE_PHONE or type == impl.TYPE_MOBILE then
        local phone = impl.find_match(impl.mobile_detect_rules.phone_devices, user_agent)
        if phone then return phone end -- unambiguously identified as phone
    end

    -- our rules haven't found a match -> try more general fallback rules
    if type == impl.TYPE_TABLET or type == impl.TYPE_MOBILE then
        if impl.is_tablet_fallback(user_agent) then
            return impl.FALLBACK_TABLET
        end
    end

    if type == impl.TYPE_PHONE or type == impl.TYPE_MOBILE then
        if impl.is_mobile_fallback(user_agent) then
            return type == impl.TYPE_PHONE and impl.FALLBACK_PHONE or impl.FALLBACK_MOBILE
        end
    end

    -- not mobile at all!
    return nil
end

-----
-- Gets mobile grade.
-- @param   user_agent
-- @return  mobile grade
function impl.mobile_grade(user_agent)
    -- impl note:
    -- To keep in sync w/ Mobile_Detect.php easily, the following code is tightly aligned to the PHP version.
    -- When changes are made in Mobile_Detect.php, copy this method and replace:
    --     // / --
    --     $this-> / mobile_detect.
    --     && / and
    --     || / or
    --     if ( / if
    --     ){ / then
    --     } / end
    --     $isMobile / is_mobile
    --     isMobile() / mobile(user_agent)
    --     self::MOBILE_GRADE_ / impl.MOBILE_GRADE_
    --     , self::VERSION_TYPE_FLOAT / ''
    --     ! / not
    --     \(mobile_detect.version('.\{-}')\) / \1 and \1
    --     (\('.\{-}'\)) / (\1, user_agent)
    local is_mobile = mobile_detect.mobile(user_agent)
        if
            -- Apple iOS 4-7.0 – Tested on the original iPad (4.3 / 5.0), iPad 2 (4.3 / 5.1 / 6.1), iPad 3 (5.1 / 6.0), iPad Mini (6.1), iPad Retina (7.0), iPhone 3GS (4.3), iPhone 4 (4.3 / 5.1), iPhone 4S (5.1 / 6.0), iPhone 5 (6.0), and iPhone 5S (7.0)
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPad', user_agent) and mobile_detect.version('iPad', user_agent) >= 4.3 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPhone', user_agent) and mobile_detect.version('iPhone', user_agent) >= 4.3 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPod', user_agent) and mobile_detect.version('iPod', user_agent) >= 4.3 or
            -- Android 2.1-2.3 - Tested on the HTC Incredible (2.2), original Droid (2.2), HTC Aria (2.1), Google Nexus S (2.3). Functional on 1.5 & 1.6 but performance may be sluggish, tested on Google G1 (1.5)
            -- Android 3.1 (Honeycomb)  - Tested on the Samsung Galaxy Tab 10.1 and Motorola XOOM
            -- Android 4.0 (ICS)  - Tested on a Galaxy Nexus. Note: transition performance can be poor on upgraded devices
            -- Android 4.1 (Jelly Bean)  - Tested on a Galaxy Nexus and Galaxy 7
            ( mobile_detect.version('Android', user_agent) and mobile_detect.version('Android', user_agent)>2.1 and mobile_detect.is('Webkit', user_agent) ) or
            -- Windows Phone 7.5-8 - Tested on the HTC Surround (7.5), HTC Trophy (7.5), LG-E900 (7.5), Nokia 800 (7.8), HTC Mazaa (7.8), Nokia Lumia 520 (8), Nokia Lumia 920 (8), HTC 8x (8)
            mobile_detect.version('Windows Phone OS', user_agent) and mobile_detect.version('Windows Phone OS', user_agent) >= 7.5 or
            -- Tested on the Torch 9800 (6) and Style 9670 (6), BlackBerry® Torch 9810 (7), BlackBerry Z10 (10)
            mobile_detect.is('BlackBerry', user_agent) and mobile_detect.version('BlackBerry', user_agent) and mobile_detect.version('BlackBerry', user_agent) >= 6.0 or
            -- Blackberry Playbook (1.0-2.0) - Tested on PlayBook
            mobile_detect.match('Playbook.*Tablet', user_agent) or
            -- Palm WebOS (1.4-3.0) - Tested on the Palm Pixi (1.4), Pre (1.4), Pre 2 (2.0), HP TouchPad (3.0)
            ( mobile_detect.version('webOS', user_agent) and mobile_detect.version('webOS', user_agent) >= 1.4 and mobile_detect.match('Palm|Pre|Pixi', user_agent) ) or
            -- Palm WebOS 3.0  - Tested on HP TouchPad
            mobile_detect.match('hp.*TouchPad', user_agent) or
            -- Firefox Mobile 18 - Tested on Android 2.3 and 4.1 devices
            ( mobile_detect.is('Firefox', user_agent) and mobile_detect.version('Firefox', user_agent) and mobile_detect.version('Firefox', user_agent) >= 18 ) or
            -- Chrome for Android - Tested on Android 4.0, 4.1 device
            ( mobile_detect.is('Chrome', user_agent) and mobile_detect.is('AndroidOS', user_agent) and mobile_detect.version('Android', user_agent) and mobile_detect.version('Android', user_agent) >= 4.0 ) or
            -- Skyfire 4.1 - Tested on Android 2.3 device
            ( mobile_detect.is('Skyfire', user_agent) and mobile_detect.version('Skyfire', user_agent) and mobile_detect.version('Skyfire', user_agent) >= 4.1 and mobile_detect.is('AndroidOS', user_agent) and mobile_detect.version('Android', user_agent) and mobile_detect.version('Android', user_agent) >= 2.3 ) or
            -- Opera Mobile 11.5-12: Tested on Android 2.3
            ( mobile_detect.is('Opera', user_agent) and mobile_detect.version('Opera Mobi', user_agent) and mobile_detect.version('Opera Mobi', user_agent) >= 11.5 and mobile_detect.is('AndroidOS', user_agent) ) or
            -- Meego 1.2 - Tested on Nokia 950 and N9
            mobile_detect.is('MeeGoOS', user_agent) or
            -- Tizen (pre-release) - Tested on early hardware
            mobile_detect.is('Tizen', user_agent) or
            -- Samsung Bada 2.0 - Tested on a Samsung Wave 3, Dolphin browser
            -- @todo: more tests here!
            mobile_detect.is('Dolfin', user_agent) and mobile_detect.version('Bada', user_agent) and mobile_detect.version('Bada', user_agent) >= 2.0 or
            -- UC Browser - Tested on Android 2.3 device
            ( (mobile_detect.is('UC Browser', user_agent) or mobile_detect.is('Dolfin', user_agent)) and mobile_detect.version('Android', user_agent) and mobile_detect.version('Android', user_agent) >= 2.3 ) or
            -- Kindle 3 and Fire  - Tested on the built-in WebKit browser for each
            ( mobile_detect.match('Kindle Fire', user_agent) or
            mobile_detect.is('Kindle', user_agent) and mobile_detect.version('Kindle', user_agent) and mobile_detect.version('Kindle', user_agent) >= 3.0 ) or
            -- Nook Color 1.4.1 - Tested on original Nook Color, not Nook Tablet
            mobile_detect.is('AndroidOS', user_agent) and mobile_detect.is('NookTablet', user_agent) or
            -- Chrome Desktop 16-24 - Tested on OS X 10.7 and Windows 7
            mobile_detect.version('Chrome', user_agent) and mobile_detect.version('Chrome', user_agent) >= 16 and not is_mobile or
            -- Safari Desktop 5-6 - Tested on OS X 10.7 and Windows 7
            mobile_detect.version('Safari', user_agent) and mobile_detect.version('Safari', user_agent) >= 5.0 and not is_mobile or
            -- Firefox Desktop 10-18 - Tested on OS X 10.7 and Windows 7
            mobile_detect.version('Firefox', user_agent) and mobile_detect.version('Firefox', user_agent) >= 10.0 and not is_mobile or
            -- Internet Explorer 7-9 - Tested on Windows XP, Vista and 7
            mobile_detect.version('IE', user_agent) and mobile_detect.version('IE', user_agent) >= 7.0 and not is_mobile or
            -- Opera Desktop 10-12 - Tested on OS X 10.7 and Windows 7
            mobile_detect.version('Opera', user_agent) and mobile_detect.version('Opera', user_agent) >= 10 and not is_mobile
        then
            return impl.MOBILE_GRADE_A;
        end
        if
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPad', user_agent) and mobile_detect.version('iPad', user_agent)<4.3 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPhone', user_agent) and mobile_detect.version('iPhone', user_agent)<4.3 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPod', user_agent) and mobile_detect.version('iPod', user_agent)<4.3 or
            -- Blackberry 5.0: Tested on the Storm 2 9550, Bold 9770
            mobile_detect.is('Blackberry', user_agent) and mobile_detect.version('BlackBerry', user_agent) and mobile_detect.version('BlackBerry', user_agent) >= 5 and mobile_detect.version('BlackBerry', user_agent) and mobile_detect.version('BlackBerry', user_agent)<6 or
            --Opera Mini (5.0-6.5) - Tested on iOS 3.2/4.3 and Android 2.3
            (mobile_detect.version('Opera Mini', user_agent) and mobile_detect.version('Opera Mini', user_agent) >= 5.0 and mobile_detect.version('Opera Mini', user_agent) and mobile_detect.version('Opera Mini', user_agent) <= 7.0 and
            (mobile_detect.version('Android', user_agent) and mobile_detect.version('Android', user_agent) >= 2.3 or mobile_detect.is('iOS', user_agent)) ) or
            -- Nokia Symbian^3 - Tested on Nokia N8 (Symbian^3), C7 (Symbian^3), also works on N97 (Symbian^1)
            mobile_detect.match('NokiaN8|NokiaC7|N97.*Series60|Symbian/3', user_agent) or
            -- @todo: report this (tested on Nokia N71)
            mobile_detect.version('Opera Mobi', user_agent) and mobile_detect.version('Opera Mobi', user_agent) >= 11 and mobile_detect.is('SymbianOS', user_agent)
        then
            return impl.MOBILE_GRADE_B;
        end
        if
            -- Blackberry 4.x - Tested on the Curve 8330
            mobile_detect.version('BlackBerry', user_agent) and mobile_detect.version('BlackBerry', user_agent) <= 5.0 or
            -- Windows Mobile - Tested on the HTC Leo (WinMo 5.2)
            mobile_detect.match('MSIEMobile|Windows CE.*Mobile', user_agent) or mobile_detect.version('Windows Mobile', user_agent) and mobile_detect.version('Windows Mobile', user_agent) <= 5.2 or
            -- Tested on original iPhone (3.1), iPhone 3 (3.2)
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPad', user_agent) and mobile_detect.version('iPad', user_agent) <= 3.2 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPhone', user_agent) and mobile_detect.version('iPhone', user_agent) <= 3.2 or
            mobile_detect.is('iOS', user_agent) and mobile_detect.version('iPod', user_agent) and mobile_detect.version('iPod', user_agent) <= 3.2 or
            -- Internet Explorer 7 and older - Tested on Windows XP
            mobile_detect.version('IE', user_agent) and mobile_detect.version('IE', user_agent) <= 7.0 and not is_mobile
        then
            return impl.MOBILE_GRADE_C;
        end
        -- All older smartphone platforms and feature phones - Any device that doesn't support media queries
        -- will receive the basic, C grade experience.
        return impl.MOBILE_GRADE_C;
end

-----
-- Gets OS
-- @param   user_agent
-- @return  OS
function impl.detect_os(user_agent)
    return impl.find_match(impl.mobile_detect_rules.operating_systems0, user_agent) or impl.find_match(impl.mobile_detect_rules.operating_systems, user_agent)
end

-----
-- Returns the detected phone or tablet type or nil if it is not a mobile device.
-- For a list of possible return values see mobile_detect.phone and mobile_detect.tablet.
-- If the device is not detected by the regular expressions from Mobile-Detect, a test is made against
-- the patterns from http://detectmobilebrowsers.com/. If this test
-- is negative, a value of UnknownPhone, UnknownTablet or UnknownMobile is returned.
-- Be aware that in this special case you will get UnknownMobile only for:
-- mobile_detect.mobile, not for mobile_detect.phone and mobile_detect.tablet.
-- In most cases you will use the return value just as a boolean.
-- @param   user_agent  http_header['User-Agent']
-- @return  the key of the phone family or tablet family, e.g. "Nexus".
function mobile_detect.mobile(user_agent)
    return impl.detect(impl.TYPE_MOBILE, user_agent)
end

-----
-- Returns the detected phone type/family string or nil.
-- The returned phone is one of the following keys:
-- {{token.phone_devices}}
-- If the device is not detected by the regular expressions from Mobile-Detect, a test is made against
-- the patterns from http://detectmobilebrowsers.com/. If this test
-- is negative, a value of UnknownPhone or UnknownMobile is returned.
-- Be aware that in this special case you will get UnknownMobile only for:
-- mobile_detect.mobile, not for mobile_detect.phone and mobile_detect.tablet.
-- In most cases you will use the return value just as a boolean.
-- @param   user_agent  http_header['User-Agent']
-- @return  the key of the phone family, e.g. "iPhone".
function mobile_detect.phone(user_agent)
    return impl.detect(impl.TYPE_PHONE, user_agent)
end

-----
-- Returns the detected tablet type/family string or nil.
-- The returned tablet is one of the following keys:
-- {{token.tablet_devices}}
-- If the device is not detected by the regular expressions from Mobile-Detect, a test is made against
-- the patterns of http://detectmobilebrowsers.com/. If this test
-- is negative, a value of UnknownTablet or UnknownMobile is returned.
-- Be aware that in this special case you will get UnknownMobile only for:
-- mobile_detect.mobile, not for mobile_detect.phone and mobile_detect.tablet.
-- In most cases you will use the return value just as a boolean.
-- @param   user_agent  http_header['User-Agent']
-- @return  the key of the tablet family, e.g. "SamsungTablet"
function mobile_detect.tablet(user_agent)
    return impl.detect(impl.TYPE_TABLET, user_agent)
end

-----
-- Returns the (first) detected browser string or nil.
-- The returned browser is one of the following keys:
-- {{token.browsers}}
-- In most cases calling mobile_detect.browser will be sufficient. But there are rare
-- cases where a mobile device pretends to be more than one particular browser. You can get the
-- list of all matches with mobile_detect.browsers or check for a particular value by
-- providing one of the defined keys as first argument to mobile_detect.is.
-- @param   user_agent  http_header['User-Agent']
-- @return  the key for the detected browser or nil
function mobile_detect.browser(user_agent)
    return impl.find_match(impl.mobile_detect_rules.browsers, user_agent)
end

-----
-- Returns all detected browser strings.
-- The returned table is empty or contains one or more of the following keys:
-- {{token.browsers}}
-- In most cases calling mobile_detect.browser will be sufficient. But there are rare
-- cases where a mobile device pretends to be more than one particular browser. You can get the
-- list of all matches with mobile_detect.browsers or check for a particular value by
-- providing one of the defined keys as first argument to mobile_detect.is.
-- @param   user_agent  http_header['User-Agent']
-- @return  the array of detected browser keys or {}
function mobile_detect.browsers(user_agent)
    return impl.find_matches(impl.mobile_detect_rules.browsers, user_agent)
end

-----
-- Returns the detected operating system string or nil.
-- The returned operating system is one of the following keys:
-- {{token.operating_systems}}
-- @param   user_agent  http_header['User-Agent']
-- @return  the key for the detected operating system.
function mobile_detect.os(user_agent)
    return impl.detect_os(user_agent)
end

-----
-- Get the version (as number) of the given property in the User-Agent.
-- Will return a float number. (eg. 2_0 will return 2.0, 4.3.1 will return 4.31)
-- @param   key     a key defining a thing which has a version.
-- You can use one of following keys:
-- {{token.properties}}
-- @param   user_agent  http_header['User-Agent']
-- @return  the version as float or nil if User-Agent doesn't contain this version.
-- Be careful when comparing this value with '==' operator!
function mobile_detect.version(key, user_agent)
    return impl.get_version(key, user_agent)
end

-----
-- Get the version (as String) of the given property in the User-Agent.
-- @param   key     a key defining a thing which has a version.
-- You can use one of following keys:
-- {{token.properties}}
-- @param   user_agent  http_header['User-Agent']
-- @return  the "raw" version as String or nil if User-Agent doesn't contain this version.
function mobile_detect.version_str(key, user_agent)
    return impl.get_version_str(key, user_agent)
end

-----
-- Global test key against userAgent, os, phone, tablet and some other properties of userAgent string.
-- @param   key     the key (case-insensitive) of a user_agent, an operating system, phone or
-- tablet family.
-- Additionally you have following keys:
-- {{token.utilities}}
-- @param   user_agent  http_header['User-Agent']
-- @return  boolean     true when the given key is one of the defined keys of user_agent, os, phone,
-- tablet or one of the listed additional keys, otherwise false
function mobile_detect.is(key, user_agent)
    return contains_ic(mobile_detect.browsers(user_agent), key) or
        equal_ic(key, mobile_detect.os(user_agent)) or
        equal_ic(key, mobile_detect.phone(user_agent)) or
        equal_ic(key, mobile_detect.tablet(user_agent)) or
        contains_ic(impl.find_matches(impl.mobile_detect_rules.utilities, user_agent), key)
end

-----
-- Do a quick test against navigator::user_agent.
-- @param   pattern
-- @param   user_agent  http_header['User-Agent']
-- @return  boolean     true when the pattern matches, otherwise false
function mobile_detect.match(pattern, user_agent)
    return rex.match(user_agent, pattern, 1, 'i')
end

-----
-- Returns the mobile grade ('A', 'B', 'C').
-- @param   user_agent  http_header['User-Agent']
-- @return  one of the mobile grades ('A', 'B', 'C').
function mobile_detect.mobile_grade(user_agent)
    return impl.mobile_grade(user_agent)
end

return mobile_detect
