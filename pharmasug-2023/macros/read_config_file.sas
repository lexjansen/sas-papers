/******************************************************************************
* NAME: read_config_file.sas
*
* Purpose:
* EDC: Read Configuration file
*
* Author:  Lex Jansen
*
* Parameters: (if applicable)
* 1. config_file(Required) - specify the configuration filepath
* 2. sections(Optional) - sections to use, example: %str("cdisclibrary" "box")
* 3. symboltable(Required) - macro variable symbol table (g/l/f, default:g)
*
* Dependencies/Assumptions:
*
******************************************************************************/

%macro read_config_file(config_file=, sections=, symboltable=g)/Des="Read Configuration file";

  filename _cfg "&config_file.";

  data _null_;
    length section _mac_var _mac_var_value $200;
    retain section;

    infile _cfg lrecl=1000 length=linelength;
    input cfg_line $varying1000. linelength;

    if ksubstr(left(cfg_line), 1, 1) not in ('#' '!' '*') and
      length(strip(cfg_line))>1;

    if ksubstr(left(cfg_line), 1, 1)="[" then do;
      section=scan(cfg_line, 1, "[]");
      delete;
    end;

    _mac_var = scan(cfg_line,1,"=");
    _mac_var_value = substr(cfg_line,index(cfg_line,'=')+1);

    %if %sysevalf(%superq(sections)=, boolean)=0 %then %do;
      if section in (&sections);
    %end;

    call symputx(_mac_var,strip(_mac_var_value),"&symboltable");

  run;

%mend read_config_file;
