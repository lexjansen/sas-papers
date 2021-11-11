proc lua ;
  submit;
  
  -- Lua statements in SAS
  print('Hello world')

  endsubmit;   
run;


%let foo=conference;

proc lua;
  submit;
  local foo = sas.symget("foo")
  print("foo is ", foo) -- prints 'conference'
  sas.symput('foo','PHUSE')
  endsubmit;
run;

%put &foo; /* prints 'PHUSE' */
