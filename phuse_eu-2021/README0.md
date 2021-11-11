Code from the paper Parsing JSON Files in SAS© Using PROC LUA
PHUSE EU Connect 2021, November 15 - 18

Lex Jansen, SAS Institute Inc., Cary, NC, USA


Run the programs in the programs folder in the following order:

- example1.sas
- example2.sas
- proc_lua.sas
- lua_json_cdisc_library_example.sas
- test_lua_json_libraries.sas

You may need to Change the global macro variable project_folder to point to your project folder.

The last 2 programs will extract a json file from the CDISC Library: json/sdtmct_20210625.json
This will onloy work after you replace the CDISC Library API token with your own personal token in the line:
  local token = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
 


Disclaimer

THIS CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF
ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT. SAS Institute shall not be liable whatsoever for any damages
arising out of the use of this documentation or code, including any direct,
indirect, or consequential damages. The Institute reserves the right to alter or
abandon use of this documentation at any time. In addition, the Institute will
provide no support for the materials contained herein.

