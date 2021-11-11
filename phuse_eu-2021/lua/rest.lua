--- REST service manipulation routines
--  Based on the code that came with the paper:
--    REST Easier with SAS®: Using the LUA Procedure to Simplify REST API Interactions
--    SAS Global Forum, 2019
--    https://www.sas.com/content/dam/SAS/support/en/sas-global-forum-proceedings/2019/3113-2019.pdf
--    Steven Major, SAS Institute Inc.
--
---
--    Copyright (c) 2019 by SAS Institute Inc., Cary, NC, USA.
-- 
--- REST service manipulation routines
--
--
-- EXAMPLE:
--[[
filename luapath "<location of the REST lua module>";
/* Set this if you want to store the header and body files somewhere other than work */
%let working_folder=;
proc lua restart;
submit;
  local rest = require 'rest'
   
  rest.base_url = 'http://httpbin.org/'

  local pass,code = rest.request('get','ip')
  print(pass,code)
  print(rest.utils.read('_bout_'))

endsubmit;
run;
]]--

-- The table our module will return
local rest={}

-- This is the base URL for all calls. 
rest.base_url=""

rest.headers=""
rest.timeout=""
rest.proxyhost=""
rest.proxyport=""

-- Do not show PROC HTTP statement in LOG so that password is not visible 
rest.quiet=""

rest.http_user=""
rest.http_passw=""


--- Some basic HTTP options
-- use cookies? (NO_COOKIES)
rest.cookies = true
-- clear cache after each call? (CLEAR_CACHE)
rest.clear_cache = false
-- avoid multiple headers when redirected or in other cases? (HEADEROUT_OVERWRITE)
rest.header_overwrite = false
-- Cache connections?(NO_CONN_CACHE)
rest.cache_connection = true

-- use HTTP authentication?
rest.http_authentication = true

--------------------------------------------------------------
--- Some utility functions to read to and write from files ---
--------------------------------------------------------------
rest.utils={}

--- Read a file referenced by fileref into a string.
-- @param fileref [string or a fileref from sasxx.new()] - The fileref to read from
-- @return contents [string] - The contents of the fileref, nil if nothing was found
-- @return msg [string] - Any error message
function rest.utils.read( fileref )
   if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end

   local BUFSIZE = 2^13
   local f = io.open(path,"rb")
   if not f then
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end   

   local contents = ""
   while true do
      local bufread = f:read(BUFSIZE)
      if not bufread then break end
      contents = contents..bufread
   end
   f:close()
   return contents,""
end

--- Write a file referenced by fileref from a string with carriage returns
-- @param fileref [string or a fileref from sasxx.new()] - The fileref to write to
-- @param txt  - the string being written to the file
-- @return rc [boolean] true if no error, false otherwise
function rest.utils.write( fileref, txt )
    if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end   
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return false, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for write."   
   end  
    
   local f = io.open(path,"wb")
   if not f then       
      return false, "ERROR: Couldn't open file: "..path.." for write."
   end
   f:write(txt)
   f:close()
   return true
end

--- Encode a URL string - need to do this when passing parameters that contain special characters
-- @param str String containing a URL to encode
function rest.utils.urlencode( str )
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
    end
    return str    
end

-- Assign some default filerefs that can be used for requests and responses.
--   _hin_  : the request header
--   _hout_ : the response header
--   _bin_  : the request body
--   _bout_ : the response body
if sas.symget('working_folder') and sas.symget('working_folder') ~= '' then
   rest.working_folder = sas.symget('working_folder')   
else
   rest.working_folder = sas.getoption('work')   
end

if rest.quiet then sas.set_quiet(true) end
sas.submit([[
   filename _hin_  "@working_folder@/_hin_.txt";
   filename _hout_ "@working_folder@/_hout_.txt";
   filename _bin_   "@working_folder@/_bin_.txt";
   filename _bout_  "@working_folder@/_bout_.txt";
]], {working_folder = rest.working_folder})
if rest.quiet then sas.set_quiet(false) end

----- Submit a request to rest.base_url
-- ARGUMENTS:
-- action       - string - 'GET', 'POST', 'PUT', etc.
-- request      - string - the portion of the URL that follows rest.base_url
-- body_out     - string - [OPTIONAL] the fileref to write the output to. Defaults to '_bout_'
-- content_type - string - [OPTIONAL] passed to PROC HTTP's 'ct' parameter (content type)
-- header_out   - string - [OPTIONAL] the fileref to write the returned header to. Defaults to '_hout_'
-- body_in      - string - [OPTIONAL] fileref for the request body. 
-- header_in    - string - [OPTIONAL] fileref for the request header. 
--RETURNS:
-- pass        - boolean - whether or not the HTTP return code was in the 200's (200 OK, 201 CREATED, etc)
-- code        - number  - the actual http return code
function rest.request( action, request, body_out, content_type, header_out, body_in, header_in)

   -- Handle HTTP options
   local http_options = ""
   if not rest.cookies then http_options = http_options.." NO_COOKIES" end
   if rest.clear_cache then http_options = http_options.." CLEAR_CACHE" end
   if rest.header_overwrite then http_options = http_options.." HEADEROUT_OVERWRITE" end
   if not rest.cache_connection then http_options = http_options.." NO_CONN_CACHE" end
   
   -- Make sure a / separates the base url and request
   if rest.base_url:sub(-1) ~= '/' and request:sub(1,1) ~= '/' then request = '/'..request end
   local url_str = rest.base_url..request
   
   local http_authentication = ""
   if rest.http_authentication then
     local http_authentication = http_authentication.."AUTH_BASIC "
     local http_authentication = http_authentication.."WEBUSERNAME='"..rest.http_user.."' "
     local http_authentication = http_authentication.."WEBPASSWORD='"..rest.http_passw.."'"
   end
  
   local headers = ""
   if rest.headers ~= "" then headers = "headers "..rest.headers end
   local timeout = ""
   if tonumber(rest.timeout) ~= nil then timeout = "timeout = "..rest.timeout end
   local proxyhost = ""
   if rest.proxyhost ~= "" then proxyhost = "proxyhost = '"..rest.proxyhost.."'" end
   local proxyport = ""
   if tonumber(rest.proxyport) ~= nil then proxyport = "proxyport = "..rest.proxyport end
   
   local debug = ""
   if rest.debug then
     -- if #rest.debug > 0 then 
       if tonumber(rest.debug) ~= nil then
         debug = "debug level = "..rest.debug 
       else
         debug = "debug "..rest.debug 
       end
     -- end
   end  

   -- Set the content type and out arguments   
   local body_in_arg, header_in_arg, ct_arg
   if not content_type then ct_arg = " " else ct_arg = "ct = '"..content_type.."'" end
   if not body_in then body_in_arg = "" else body_in_arg = "in = "..tostring(body_in) end
   if not header_in then header_in_arg = "" else header_in_arg = "headerin = "..tostring(header_in) end
   if not body_out then body_out = "_bout_" end
   if not header_out then header_out = "_hout_" end
   
   -- Initialize the contents of the response files so that if something
   -- goes wrong, we don't accidentally get the contents from a previous request
   rest.utils.write(body_out,"_NOT_SET_BY_PROC_HTTP_")
   rest.utils.write(header_out,"_NOT_SET_BY_PROC_HTTP_")

   if rest.quiet then sas.set_quiet(true) end
   sas.submit([[
      proc http
          @http_options@ 
          method='@action@'
          url=%nrstr("@url_str@") 
          @timeout@
          @http_authentication@ @proxyhost@ @proxyport@
          @header_in_arg@
          headerout=@header_out@
          @body_in_arg@
          out=@body_out@
          @ct_arg@;
          @headers@;
          @debug@;
      run;
   ]])
   if rest.quiet then sas.set_quiet(false) end
   
       
   --Grab the response and pull out the http return code
   local header_string = rest.utils.read(header_out)
   local header_line_one = sas.scan(header_string,1,'\n\r')
   local code = tonumber(sas.scan(header_line_one,2,' '))
   local pass  = (code >= 200 and code < 300)
   return pass, code
end

return rest
