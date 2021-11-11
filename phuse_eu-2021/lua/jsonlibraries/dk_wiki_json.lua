--  <nowiki>
--- JSON high-performance bidirectional conversion framework.
--  This module is a fork of the [[github:LuaDist/dkjson|dkjson]] library by
--  David Kolf, removing LPeg support and registration of the `_G.json` global.
--  
--  On Wikia, it serves as a polyfill for the `mw.text.jsonEncode` and
--  `mw.text.jsonDecode` PHP interfaces available in Scribunto core. Json is
--  able to perform within one order of magnitude (20%) to its PHP counterpart,
--  while also supporting multiline comments.
--  
--  [[wikipedia:JSON|JSON]] is a data serialisation format by the IETF and JS
--  developer Douglas Crockford that maps data in objects consisting of arrays
--  (key-value pairs) and lists (ordered element collections).
--  
--  The @{json.encode} function will use two spaces for indentation when
--  it is enabled, matching the behaviour of `mw.text.jsonDecode`. If you need
--  to output JSON with four spaces per indent, use @{string.gsub} and
--  parentheses - `(json.encode({json.null}):gsub('\n( +)','\n%1%1'))`.
--  
--  The @{json.decode} function accepts optional arguments to enable the
--  bidirectional processing of any JSON data. The RFC 8259 JSON specification
--  does not support JavaScript's inline and multiline comments, but these are
--  stripped gracefully in the parser anyway along with any whitespace.
--  
--  @script         json
--  @release        stable
--  @author         [[github::dhkolf|David Kolf]] ([[github:LuaDist/dkjson|Github]])
--  @author         [[User:8nml|8nml]]
--  @version        2.5.0+wikia:dev

local json, utils = {}, {}

--  Global dependencies.
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
    pairs,
    type,
    tostring,
    tonumber,
    getmetatable,
    setmetatable,
    rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, strgsub, strsub, strbyte, strchar, strfind, strlen, strformat =
    string.rep,
    string.gsub,
    string.sub,
    string.byte,
    string.char,
    string.find,
    string.len,
    string.format
local strmatch = string.match
local concat = table.concat

--  Module variables.
local escapecodes = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
}
local escapechars = {
    ['"'] = '"',
    ['\\'] = '\\',
    ['/'] = '/',
    ['b'] = '\b',
    ['f'] = '\f',
    ['n'] = '\n',
    ['r'] = '\r',
    ['t'] = '\t'
}
local decpoint, numfilter

--- Checks if a Lua table is an array.
--  @param              {table} tbl Table to test array rules on.
--  @return             {boolean} Whether the table is an array.
--  @local
function utils.isarray(tbl)
    local max, n, arraylen = 0, 0, 0

    for k, v in pairs(tbl) do
        if k == 'n' and type(v) == 'number' then
            arraylen = v
            if v > max then
                max = v
            end
        else
            if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
                return false
            end
            if k > max then
                max = k
            end
            n = n + 1
        end
    end

    -- An array implicitly does not have too many holes.
    if max > 10 and max > arraylen and max > n * 2 then
        return false
    end

    return true, max
end

--- Generator for escaped UTF-8 strings from Unicode characters.
--  @param          {number} uchar Unicode character to escape.
--  @return         {string} UTF-8 escaped string with backslashes.
--  @local
function utils.escapeutf8(uchar)
    local value = escapecodes[uchar]
    if value then
        return value
    end
    local a, b, c, d = strbyte(uchar, 1, 4)
    a, b, c, d = a or 0, b or 0, c or 0, d or 0
    if a <= 0x7f then
        value = a
    elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
        value = (a - 0xc0) * 0x40 + b - 0x80
    elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
        value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
    elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
        value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
    else
        return ''
    end
    if value <= 0xffff then
        return strformat('\\u%.4x', value)
    elseif value <= 0x10ffff then
        -- encode as UTF-16 surrogate pair
        value = value - 0x10000
        local highsur, lowsur = 0xD800 + floor(value / 0x400), 0xDC00 + (value % 0x400)
        return strformat('\\u%.4x\\u%.4x', highsur, lowsur)
    else
        return ''
    end
end

--- String substitution predicated on pattern lookup.
--  This function offers significant optimisation over @{string.gsub},
--  which always builds a new string in a buffer even when there is no
--  match. The original string is returned when the string doesn't
--  contain the pattern (which is often the case).
--  @function           utils.fsub
--  @param              {string} str Target string for replacement.
--  @param              {string} pattern Pattern to replace.
--  @param              {function|table|string} Replacement value or
--                      generator.
--  @local
function utils.fsub(str, pattern, repl)
    if strfind(str, pattern) then
        return strgsub(str, pattern, repl)
    else
        return str
    end
end

--- Computes the document coordinates of a character position.
--  @param              {string} str String to index character position
--                      in.
--  @param              {number} where Character position including
--                      newlines.
--  @return             {string} Line and column coordinates for
--                      `where`.
--  @local
function utils.location(str, where)
    local line, pos, linepos = 1, 1, 0
    while true do
        pos = strfind(str, '\n', pos, true)
        if pos and pos < where then
            line = line + 1
            linepos = pos
            pos = pos + 1
        else
            break
        end
    end
    return 'line ' .. line .. ', column ' .. (where - linepos)
end

--- Generates an exception for unterminated JSON values.
--  @param              {string} str Invalid JSON string.
--  @param              {string} what Type of unterminated value.
--  @param              {string} where Character 1-index position.
--  @local
function utils.unterminated(str, what, where)
    return nil, strlen (str) + 1, 'unterminated ' .. what .. ' at ' .. utils.location(str, where)
end

--- Whitespace scanner for JSON string at a specified position.
--  @param              {string} str JSON string input.
--  @param              {string} where Start character 1-index position.
--  @local
function utils.scanwhite(str, pos)
    while true do
        pos = strfind(str, '%S', pos)
        if not pos then
            return nil
        end
        local sub2 = strsub(str, pos, pos + 1)
        if sub2 == '\239\187' and strsub(str, pos + 2, pos + 2) == '\191' then
            -- UTF-8 Byte Order Mark
            pos = pos + 3
        elseif sub2 == '//' then
            pos = strfind(str, '[\n\r]', pos + 2)
            if not pos then
                return nil
            end
        elseif sub2 == '/*' then
            pos = strfind(str, '*/', pos + 2)
            if not pos then
                return nil
            end
            pos = pos + 2
        else
            return pos
        end
    end
end

--- Unicode character conversion to UTF-8 string.
--  @param              {number} value Unicode character.
--  @return             {string|nil} UTF-8 string representation.
--  @local
function utils.unichar(value)
    if value < 0 then
        return nil
    elseif value <= 0x007f then
        return strchar(value)
    elseif value <= 0x07ff then
        return strchar(0xc0 + floor(value / 0x40), 0x80 + (floor(value) % 0x40))
    elseif value <= 0xffff then
        return strchar(0xe0 + floor(value / 0x1000), 0x80 + (floor(value / 0x40) % 0x40), 0x80 + (floor(value) % 0x40))
    elseif value <= 0x10ffff then
        return strchar(
            0xf0 + floor(value / 0x40000),
            0x80 + (floor(value / 0x1000) % 0x40),
            0x80 + (floor(value / 0x40) % 0x40),
            0x80 + (floor(value) % 0x40)
        )
    else
        return nil
    end
end

--- Quoted string scanner for JSON string at a specified position.
--  @param              {string} str JSON string input.
--  @param              {string} where Start character 1-index position.
--  @local
function utils.scanstring(str, pos)
    local lastpos = pos + 1
    local buffer, n = {}, 0
    
    while true do
        local nextpos = strfind(str, '["\\]', lastpos)
        if not nextpos then
            utils.unterminated(str, 'string', pos)
        end
        if nextpos > lastpos then
            n = n + 1
            buffer[n] = strsub(str, lastpos, nextpos - 1)
        end
        if strsub(str, nextpos, nextpos) == '"' then
            lastpos = nextpos + 1
            break
        else
            local escchar = strsub(str, nextpos + 1, nextpos + 1)
            local value
            if escchar == 'u' then
                value = tonumber(strsub(str, nextpos + 2, nextpos + 5), 16)
                if value then
                    local value2
                    if 0xD800 <= value and value <= 0xDBff then
                        -- we have the high surrogate of UTF-16. Check if there is a
                        -- low surrogate escaped nearby to combine them.
                        if strsub(str, nextpos + 6, nextpos + 7) == '\\u' then
                            value2 = tonumber(strsub(str, nextpos + 8, nextpos + 11), 16)
                            if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                                value = (value - 0xD800) * 0x400 + (value2 - 0xDC00) + 0x10000
                            else
                                value2 = nil -- in case it was out of range for a low surrogate
                            end
                        end
                    end
                    value = value and utils.unichar(value)
                    if value then
                        if value2 then
                            lastpos = nextpos + 12
                        else
                            lastpos = nextpos + 6
                        end
                    end
                end
            end
            if not value then
                value = escapechars[escchar] or escchar
                lastpos = nextpos + 2
            end
            n = n + 1
            buffer[n] = value
        end
    end
    if n == 1 then
        return buffer[1], lastpos
    elseif n > 1 then
        return concat(buffer), lastpos
    else
        return '', lastpos
    end
end

--- Object scanner for JSON string at a specified position.
--  @local
function utils.scantable(what, closechar, str, startpos, nullval, objectmeta, arraymeta)
    local len = strlen(str)
    local tbl, n = {}, 0
    local pos = startpos + 1
    if what == 'object' then
        setmetatable(tbl, objectmeta)
    else
        setmetatable(tbl, arraymeta)
    end
    while true do
        pos = utils.scanwhite(str, pos)
        if not pos then
            return utils.unterminated(str, what, startpos)
        end
        local char = strsub(str, pos, pos)
        if char == closechar then
            return tbl, pos + 1
        end
        local val1, err
        val1, pos, err = utils.scanvalue(str, pos, nullval, objectmeta, arraymeta)
        if err then
            return nil, pos, err
        end
        pos = utils.scanwhite(str, pos)
        if not pos then
            return utils.unterminated(str, what, startpos)
        end
        char = strsub(str, pos, pos)
        if char == ':' then
            if val1 == nil then
                return nil, pos, 'cannot use nil as table index (at ' .. utils.location(str, pos) .. ')'
            end
            pos = utils.scanwhite(str, pos + 1)
            if not pos then
                return utils.unterminated(str, what, startpos)
            end
            local val2
            val2, pos, err = utils.scanvalue(str, pos, nullval, objectmeta, arraymeta)
            if err then
                return nil, pos, err
            end
            tbl[val1] = val2
            pos = utils.scanwhite(str, pos)
            if not pos then
                return utils.unterminated(str, what, startpos)
            end
            char = strsub(str, pos, pos)
        else
            n = n + 1
            tbl[n] = val1
        end
        if char == ',' then
            pos = pos + 1
        end
    end
end

--- JSON value scanner in JSON string at a specified position.
--  @local
function utils.scanvalue(str, pos, nullval, objectmeta, arraymeta)
    pos = pos or 1
    pos = utils.scanwhite(str, pos)
    if not pos then
        return nil, strlen (str) + 1, 'no valid JSON value (reached the end)'
    end
    local char = strsub(str, pos, pos)
    if char == '{' then
        return utils.scantable('object', '}', str, pos, nullval, objectmeta, arraymeta)
    elseif char == '[' then
        return utils.scantable('array', ']', str, pos, nullval, objectmeta, arraymeta)
    elseif char == '"' then
        return utils.scanstring(str, pos)
    else
        local pstart, pend = strfind(str, '^%-?[%d%.]+[eE]?[%+%-]?%d*', pos)
        if pstart then
            local number = utils.str2num(strsub(str, pstart, pend))
            if number then
                return number, pend + 1
            end
        end
        pstart, pend = strfind(str, '^%a%w*', pos)
        if pstart then
            local name = strsub(str, pstart, pend)
            if name == 'true' then
                return true, pend + 1
            elseif name == 'false' then
                return false, pend + 1
            elseif name == 'null' then
                return nullval, pend + 1
            end
        end
        return nil, pos, 'no valid JSON value at ' .. utils.location(str, pos)
    end
end

--- Character replacement utility.
--  @param              {string} str Character sequence.
--  @param              {string} o Character to replace.
--  @param              {string} n Replacement character.
--  @return             {string} Sequence with first instance of `o` character
--                      replaced by `n` character.
--  @local
function utils.replace(str, o, n)
    local i, j = strfind(str, o, 1, true)
    if i then
        return strsub(str, 1, i - 1) .. n .. strsub(str, j + 1, -1)
    else
        return str
    end
end

-- locale independent num2str and str2num functions

--- Updates decimal point and number filter pattern.
--  @todo               Refactor out (as `os.setlocale` is not defined).
--  @local
function utils.updatedecpoint()
    decpoint = strmatch(tostring(0.5), '([^05+])')
    -- build a filter that can be used to remove group separators
    numfilter = '[^0-9%-%+eE' .. strgsub(decpoint, '[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0') .. ']+'
end

utils.updatedecpoint()

--- Localised string conversion.
--  @local
function utils.num2str(num)
    return utils.replace(utils.fsub(tostring(num), numfilter, ''), decpoint, '.')
end

--- Localised numerical conversion.
--  @local
function utils.str2num(str)
    local num = tonumber(utils.replace(str, '.', decpoint))
    if not num then
        utils.updatedecpoint()
        num = tonumber(utils.replace(str, '.', decpoint))
    end
    return num
end

--- Inserts newlines into the encoding buffer of the encoder state.
--  @param              {number} level Indentation level.
--  @param              {table} buffer Serialisation stack buffer as an array.
--  @param              {number} buflen Length of encoding buffer.
--  @return             {number} New buffer length after buffer insertion.
--  @local
function utils._addnewline(level, buffer, buflen)
    buffer[buflen + 1] = '\n'
    buffer[buflen + 2] = strrep('  ', level)
    buflen = buflen + 2
    return buflen
end

--- Encoding buffer insertion in iterator form.
--  @local
function utils.addpair(key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
    local kt = type(key)
    if kt ~= 'string' and kt ~= 'number' then
        return nil, 'type "' .. kt .. '" is not supported as a key by JSON'
    end
    if prev then
        buflen = buflen + 1
        buffer[buflen] = ','
    end
    if indent then
        buflen = utils._addnewline(level, buffer, buflen)
    end
    buffer[buflen + 1] = json.quote(key)
    buffer[buflen + 2] = ':'
    return utils._encode(value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

--- Custom append function for encoding buffer.
--  @param              {string} res Item to append to buffer.
--  @param              {table} buffer Serialisation stack buffer as an array.
--  @param[opt]         {table} state Serialiser state/option configuration.
--  @local
function utils.appendcustom(res, buffer, state)
    local buflen = state.bufferlen
    if type(res) == 'string' then
        buflen = buflen + 1
        buffer[buflen] = res
    end
    return buflen
end

--- Generates exceptions with custom exception handler support.
--  @local
function utils.exception(reason, value, state, buffer, buflen, defaultmessage)
    defaultmessage = defaultmessage or reason
    local handler = state.exception
    if not handler then
        return nil, defaultmessage
    else
        state.bufferlen = buflen
        local ret, msg = handler(reason, value, state, defaultmessage)
        if not ret then
            return nil, msg or defaultmessage
        end
        return utils.appendcustom(ret, buffer, state)
    end
end

--- Private JSON encoding utility.
--  @local
function utils._encode(value, indent, level, buffer, buflen, tables, globalorder, state)
    local valtype = type(value)
    local valmeta = getmetatable(value)
    valmeta = type(valmeta) == 'table' and valmeta -- only tables
    local valtojson = valmeta and valmeta.__tojson

    if valtojson then
        if tables[value] then
            return utils.exception('reference cycle', value, state, buffer, buflen)
        end
        tables[value] = true
        state.bufferlen = buflen
        local ret, msg = valtojson(value, state)

        if not ret then
            return utils.exception('custom encoder failed', value, state, buffer, buflen, msg)
        end

        tables[value] = nil
        buflen = utils.appendcustom(ret, buffer, state)

    elseif value == nil then
        buflen = buflen + 1
        buffer[buflen] = 'null'

    elseif valtype == 'number' then
        local s

        -- The value is NaN (n ~= n) or Inf (+/-math.huge), so return null.
        -- This is the behaviour of the original JSON implementation.
        if value ~= value or value >= huge or -value >= huge then
            
            s = 'null'

        else
            s = utils.num2str(value)
        end

        buflen = buflen + 1
        buffer[buflen] = s

    elseif valtype == 'boolean' then
        buflen = buflen + 1
        buffer[buflen] = value and 'true' or 'false'

    elseif valtype == 'string' then
        buflen = buflen + 1
        buffer[buflen] = json.quote(value)

    elseif valtype == 'table' then
        if tables[value] then
            return utils.exception('reference cycle', value, state, buffer, buflen)
        end

        tables[value] = true
        level = level + 1
        local isa, n = utils.isarray(value)

        if n == 0 and valmeta and valmeta.__jsontype == 'object' then
            isa = false
        end
        local msg

        -- The value is a JSON array.
        if isa then
            buflen = buflen + 1
            buffer[buflen] = '['
            for i = 1, n do
                buflen, msg = utils._encode(value[i], indent, level, buffer, buflen, tables, globalorder, state)

                if not buflen then
                    return nil, msg
                end

                if i < n then
                    buflen = buflen + 1
                    buffer[buflen] = ','
                end
            end
            buflen = buflen + 1
            buffer[buflen] = ']'

        -- The value is a JSON object.
        else
            local prev = false
            buflen = buflen + 1
            buffer[buflen] = '{'
            local order = valmeta and valmeta.__jsonorder or globalorder

            -- The JSON object is ordered in the encoder call.
            if order then
                local used = {}
                n = #order

                for i = 1, n do
                    local k = order[i]
                    local v = value[k]

                    if v ~= nil then
                        used[k] = true
                        buflen, msg = utils.addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                        prev = true -- add a seperator before the next element
                    end
                end

                for k, v in pairs(value) do
                    if not used[k] then
                        buflen, msg =
                            utils.addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)

                        if not buflen then
                            return nil, msg
                        end
                        prev = true -- add a seperator before the next element
                    end
                end

            -- Otherwise, the JSON object is unordered in the encoder call.
            else
                for k, v in pairs(value) do
                    buflen, msg = utils.addpair(k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
                    if not buflen then
                        return nil, msg
                    end
                    prev = true -- add a seperator before the next element
                end
            end

            if indent then
                buflen = utils._addnewline(level - 1, buffer, buflen)
            end

            buflen = buflen + 1
            buffer[buflen] = '}'
        end

        tables[value] = nil

    else
        return utils.exception('unsupported type', value, state, buffer, buflen, 'type "' .. valtype .. '" is not supported by JSON')
    end

    return buflen
end

--- Optional metatable setter in the decoder.
--  @param              {boolean} Whether to attach metatables for `'object'` and `'array'`.
--  @local
function utils.optionalmetatables(mt)
    if mt then
        return {__jsontype = 'object'}, {__jsontype = 'array'}
    end
end

--- Version of the JSON library.
json.version = 'dkjson 2.5.0+wikia:dev'

--- JSON serialiser in pure Lua for data objects.
--  @param              {table|string|number|boolean|nil} value
--                      Lua upvalue to serialise into JSON. A table can only use
--                      strings and numbers as keys and its values have to be
--                      valid objects as well.
--  @param[opt]         {table} state Serialiser state/option configuration.
--  @param[opt]         {boolean} state.indent
--                      Whether the serialised string will be formatted with
--                      newlines and indentations. If not, the encoded JSON
--                      will be compressed to one line.
--  @param[opt]         {table} state.keyorder
--                      Array that specifies the ordering of keys in the encoded
--                      output. If an object has keys which are not in this
--                      array they are written after the sorted keys.
--  @param[opt]         {number} state.level
--                      Initial level of indentation used when `state.indent` is
--                      enabled. For each level, four spaces are added. Default:
--                      `0`.
--  @param[opt]         {number} state.bufferlen
--                      The target length of the buffer array, to validate
--                      against the true buffer length.
--  @param[opt]         {number} state.tables
--                      Internal set for reference cycles. It is written to by
--                      the table scanning utilities and has every table that is
--                      currently processed attached as a key. The set key
--                      becomes temporary when the table value is absent.
--  @param[opt]         {function} state.exception
--                      Custom exception handler, called when the encoder cannot
--                      encode a given value. See @{json.encode_exception} for a
--                      example function and the handler parameter description.
--  @error[729]         {string} Exceptions for invalid data types, reference
--                      cycles in tables or custom encoding failures thrown by
--                      any @{__tojson} metafields.
--  @return             {string|number} JSON string representation of the data
--                      object, or boolean for `state.bufferlen` validity. The
--                      Lua values for ECMAScript's `Inf` and `NaN` are encoded
--                      as `null` per the JSON specification. The tables within
--                      the object are only serialised as arrays if the
--                      following rules apply:
--                       * All table keys are numerical non-zero integers.
--                       * More than half of the array elements are non-nil
--                      values **IF** the array size is greater than 10.
function json.encode(value, state)
    state = state or {}
    local oldbuffer = state.buffer
    local buffer = oldbuffer or {}
    state.buffer = buffer

    utils.updatedecpoint()
    local ret, msg = utils._encode(
        value,
        state.indent,
        state.level or 0,
        buffer,
        state.bufferlen or 0,
        state.tables or {},
        state.keyorder,
        state
    )

    if not ret then
        error(msg, 2)

    elseif oldbuffer == buffer then
        state.bufferlen = ret
        return true

    else
        state.bufferlen = nil
        state.buffer = nil
        return concat(buffer)
    end
end

--- JSON parser in pure Lua for valid JSON strings.
--  Converts a JSON string representation of Lua data into the corresponding Lua
--  table or primitive.
--  @param              {string} str JSON string representation of value.
--  @param[opt]         {string} position Internal argument for start character
--                      position. Default: `1` - start of string.
--  @param[opt]         {string|table} null Value to use for JSON's `null` value.
--                      Accepts @{json.null} for internal bidirectionality.
--                      Default: `nil`.
--  @param[opt]         {boolean} mt Assign metatables to objects for internal
--                      bidirectionality.
--  @error[opt,760]     {string} Exception with character position upon parsing
--                      failure.
--  @return             Deserialised Lua data from JSON string.
function json.decode(str, position, null, mt)
    local objectmeta, arraymeta = utils.optionalmetatables(mt)
    local val, pos, msg = utils.scanvalue(str, position, null, objectmeta, arraymeta)

    if msg then
        error(msg)

    else
        return val
    end
end

--- JSON double quote escape generator from UTF-8 strings.
--  @param              {string} value Unquoted string representation of key.
--  @return             Double quote with Unicode backslash escapes.
--  @see                [[github:douglascrockford/JSON-js/blob/2a76286/json2.js#L168]]
function json.quote(value)
    -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
    value = utils.fsub(value, '[%z\1-\31"\\\127]', utils.escapeutf8)
    if strfind(value, '[\194\216\220\225\226\239]') then
        value = utils.fsub(value, '\194[\128-\159\173]', utils.escapeutf8)
        value = utils.fsub(value, '\216[\128-\132]', utils.escapeutf8)
        value = utils.fsub(value, '\220\143', utils.escapeutf8)
        value = utils.fsub(value, '\225\158[\180\181]', utils.escapeutf8)
        value = utils.fsub(value, '\226\128[\140-\143\168-\175]', utils.escapeutf8)
        value = utils.fsub(value, '\226\129[\160-\175]', utils.escapeutf8)
        value = utils.fsub(value, '\239\187\191', utils.escapeutf8)
        value = utils.fsub(value, '\239\191[\176-\191]', utils.escapeutf8)
    end
    return '"' .. value .. '"'
end

--- Newline insertion utility for @{__tojson} metafields.
--  When `state.indent` is set, this function add a newline to `state.buffer`
--  and adds spaces according to `state.level`.
--  @param              {table} state State tracking from @{json.encode}.
function json.add_newline(state)
    if state.indent then
        state.bufferlen = utils._addnewline(state.level or 0, state.buffer, state.bufferlen or #(state.buffer))
    end
end

--- Exception encoder for debugging malformed input data.
--  This function is passed to `state.exception` in @{json.encode}. Instead of
--  raising an error, this function encodes the error message as a string.
--  @param              {string} reason Error message normally raised.
--  @param              {string} value Original value that caused exception.
--  @param              {string} state Serialiser state/option configuration.
--  @param              {string} defaultmessage Error message normally raised.
function json.encode_exception(reason, value, state, defaultmessage)
    return json.quote('<' .. defaultmessage .. '>')
end

--- Lua representation of JSON null object.
--  This function is useful for bidirectionality in @{json.decode}.
--  @field              {function} __tojson Returns `'null'` when encoding.
json.null = setmetatable({}, {
    __tojson = function()
        return 'null'
    end
})

--- JSON serialisation metafields.
--  The @{json.encode} method supports a series of metafields used in the
--  configuration of serialisation behaviour when encoding Lua.
--  @section            value

--- Serialisation order configuration.
--  Overwrites the @{json.encode} `keyorder` option for any specific table or
--  subtable it is attached to. If a key is not present in the order array, it
--  is serialised after the listed keys.
--  @member             {string} value.__jsonorder

--- Serialisation object class name.
--  Defines which  a Lua table should be rendered as a JSON object or a JSON
--  array. Accepts a value of `"object"` or `"array"`. This value is only tested
--  for empty tables. Default: `"array"`.
--  @member             {string} value.__jsontype

--- Serialisation handler function.
--  This function can either add directly to the buffer and return true, or you
--  can return a string. On errors nil and a message should be returned.
--  @function           value.__tojson
--  @param              {table} state State tracking for JSON serialisation.
--  @param              {table} state.buffer Buffer array containing the string
--                      nodes generated by @{json.encode}.
--  @param              {table} state.bufferlen Buffer length, used for tracking.
--  @return             {string|boolean|nil} JSON representation of the Lua item
--                      as a string, or `true` when the handler inserts data
--                      directly into the buffer. If the handler is throwing an
--                      exception message, this return value is set to `nil`.
--  @return[opt]        {string} Error message describing serialisation
--                      failure, to be thrown in @{json.encode}.

return json
