%* update this location to your own location;
%let root=/_github/lexjansen/sas-papers/pharmasug-2022;


%include "&root/programs/config.sas";


%let _cst_rc=;

%let _cst_rcmsg=;
libname outa "..\data\adam";
libname outs "..\data\sdtm";

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(outa)), 
  _cstOutputLibrary=outa,
  _cstExtension=XPT,
  _cstOptions=
  );

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(outs)), 
  _cstOutputLibrary=outs,
  _cstExtension=XPT,
  _cstOptions=
  );

   