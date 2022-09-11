**FREE
//
// BATCH FTP Project
// Author: Ramon A. Lopez
// Program Fuction: Execute FTP Proccess
// Date 08/04/2022
// Platform: PUB400.COM
//
//
//
//  To Compile:
//  *> CRTRPGMOD MODULE(FTP003) SRCFILE(ALOPEZ151/QRPGLESRC)
//  *> CRTSRVPGM SRVPGM(FTP003) MODULE(FTP003)
//
ctl-opt nomain BNDDIR('FTPTRAN')
        option(*srcstmt:*nodebugio:*noshowcpy);

dcl-f FTPPRF   usage(*input) keyed ;
dcl-f FTPOUT   usage(*Input) UsrOpn;
dcl-f FTPLOG   usage(*output) keyed;
dcl-f FTPLOGDET usage(*output) keyed;

dcl-ds ProfDs likerec(FTPPRFR:*input);
dcl-ds OutDs  likerec(FTPOUTR:*input);
dcl-ds LogDS likerec(FTPLOGR:*output);
dcl-ds LogDetDS likerec(FTPLOGDETR:*output);
dcl-ds pgm_stat PSDS;
      User Char(10) Pos(254);
end-ds;

/INCLUDE FTPTRAN_H

dcl-s HostName Char(20);
dcl-s Cmd      Char(1000);
dcl-s Passwd  Varchar(128);
dcl-s PasLen  Int(10);


// -------------------------------------------------------------------
//  ExecuteFTP(): Execute FTP Process
//
//     profile = (input) FTP profile name
//
//    - Orchestrate Execution of FTP Proccess
//
//
//  Returns Host DNS or IP Address
// -------------------------------------------------------------------
dcl-proc ExecuteFTP Export;

   dcl-pi *N Ind;
      profile like(ProfDS.PRFNAM) value;
   end-pi;
dcl-s FirstTime Ind;
   FirstTime = *On;

   Chain profile FTPPRFR PROFDS;
   If Not %Found(FTPPRF);
        // Return back without executing FTP Proccess
      Return *Off;
      Else;
        // Generate Input FTP instructions file
        HostName = CrtInput(Profile);

        // Execute FTP
        Cmd = 'SBMJOB CMD(CALL PGM(FTP003CL) PARM(('
            + HostName + ')))';
        qCmdExc(Cmd:%len(Cmd));

        // Generate Log
        GenerateLog();

   ENDIF;

   return *on;
 end-proc;


// -------------------------------------------------------------------
//   GenerateLog(): Write log of the FTP proccess from the OUTPUT file
//
//    - Uses FTPOUT table resulting from FTP execution                 me
//    - Write into FTPLOG & FTPLOGDET
//
//
//  Returns NO value
// -------------------------------------------------------------------
 dcl-proc GenerateLog;

   dcl-pi *n;
         // Mo parameteres
   end-pi;

   Open FTPOUT;
   Read FTPOUTR OUTDS;
   LogDS.LOGSTS = 'E';
   Dou %Eof(FTPOUT);

      LogDetDS.PRFNAM  = ProfDS.PRFNAM;
      LogDetDS.LOGDATE = %Date();
      LogDetDS.LOGTIME = %Time();
      LogDetDS.LOGINST = OUTDS.FLDOUT;
      Write FTPLOGDETR LogDetDS;

      If %Scan('226':OUTDS.FLDOUT) > *Zero;
         LogDS.LOGSTS = ' ';
      Endif;
      Read FTPOUTR OUTDS;

   Enddo;
   Readp FTPOUTR OUTDS;
   LogDS.PRFNAM  = ProfDS.PRFNAM;
   LogDS.LOGDATE = %Date();
   LogDS.LOGTIME = %Time();
   LogDS.LOGUSR  = User;

   Write FTPLOGR LogDS;
   Close FTPOUT;

   return;

end-proc;
