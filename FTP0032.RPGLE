**FREE
//
// BATCH FTP Project
// Author: Ramon A. Lopez
// Program Fuction: Create FTP Input based on Instructions & Files
// Date 08/01/2022
// Platform: PUB400.COM
//
//
//  To Compile:
//  *> CRTRPGMOD MODULE(FTP0032) SRCFILE(ALOPEZ151/QRPGLESRC)
//  *> CRTSRVPGM SRVPGM(FTP0032) MODULE(FTP0032)
//
ctl-opt nomain BNDDIR('FTPTRAN')
        option(*srcstmt:*nodebugio:*noshowcpy);

dcl-f FTPPRF   usage(*input) keyed ;
dcl-f FTPINST  usage(*input) keyed ;
dcl-f FTPFILES usage(*input) keyed ;
dcl-f FTPINP   usage(*output) ;

dcl-ds ProfDs likerec(FTPPRFR:*input);
dcl-ds InstDs likerec(FTPINSTR:*input);
dcl-ds FileDs likerec(FTPFILESR:*input);
dcl-ds InpDs likerec(FTPINPR:*output);



/INCLUDE FTPTRAN_H

dcl-s HostName Char(20);
dcl-s Passwd  Varchar(128);
dcl-s PasLen  Int(10);


// -------------------------------------------------------------------
//  CrtInput(): Create Ftp Input File for Automatic Transfer
//
//     profile = (input) FTP profile name
//
//    - Orchestrate creation of FTP script
//
//
//  Returns Host DNS or IP Address
// -------------------------------------------------------------------
dcl-proc CrtInput Export;

   dcl-pi *N Char(20);
      profile like(ProfDS.PRFNAM) value;
   end-pi;
dcl-c OpenHost 'Open ';
dcl-c ClosHost 'REI ';
dcl-c UserId   'User ';
dcl-s FirstTime Ind;
dcl-s OnlyB     Ind;
   FirstTime = *On;

   Chain profile FTPPRFR PROFDS;
   If %Found(FTPPRF);
//    INPDS.FLDINP = ClosHost;
//    Write FTPINPR INPDS;
//    INPDS.FLDINP = OpenHost + PROFDS.HOST;
//    Write FTPINPR INPDS;
      Paslen = %Int(PROFDS.PLEN);
      Passwd = DecryptData(PROFDS.PASSW:               //DeEncrypt Password
                         Paslen);                      //DeEncrypt Password
      INPDS.FLDINP =  %Trim(PROFDS.USER)
                   + ' ' + %Trim(Passwd);
      Write FTPINPR INPDS;
   ENDIF;

   Chain profile FTPINSTR INSTDS;
   If %Found(FTPINST);
      Dou %Eof(FTPINST);
          IF INSTDS.SPOT = 'B';
             INPDS.FLDINP = INSTDS.INSTRUCT;
             Write FTPINPR INPDS;
             OnlyB     = *On;
             Else;
                If FirstTime;
                   Files2Transfer(profile);
                   FirstTime = *Off;
                   INPDS.FLDINP = INSTDS.INSTRUCT;
                   Write FTPINPR INPDS;
                   Else;
                   INPDS.FLDINP = INSTDS.INSTRUCT;
                   Write FTPINPR INPDS;
                Endif;
             OnlyB     = *Off;
          ENDIF;
          Reade Profile FTPINSTR INSTDS;
      ENDDO;
      If FirstTime and OnlyB;
          Files2Transfer(profile);  //Look for files to transfer
      Endif;
      Else;    //No FTP Special Instructions
          Files2Transfer(profile);  //Look for files to transfer
   ENDIF;

   // After File Transfer Instructions, proceed to quit
   INPDS.FLDINP = 'Quit';
   Write FTPINPR INPDS;

   return PROFDS.HOST;
 end-proc;


// -------------------------------------------------------------------
//   Files2Transfer(): Look for all files to be transfer and write the
//                  proper Get or Put instruction in the FTP script
//
//    - Uses FTPFILES table where library & file name, folder & file name
//        with corresponding transfer type (Get or Put) is defined.
//    - Write FTP instructions in FTP Script table FTPINP
//
//
//  Returns NO value
// -------------------------------------------------------------------
 dcl-proc Files2Transfer;

   dcl-pi *n;
      Profile like(PROFDS.PRFNAM) value;
   end-pi;

   dcl-c Qsys '/QSYS.LIB/';
   dcl-c Lib  '.LIB/';
   dcl-c File '.FILE/';
   dcl-c Mbr  '.MBR';
   dcl-c Put 'Put ';
   dcl-c Get 'Get ';
   dcl-c Replace ' (Replace ';


   Chain profile FTPFILESR FILEDS;
   If %Found(FTPFILES);
      Dou %Eof(FTPFILES);
      Select;
      When FILEDS.GETPUT = 'G';
        If FILEDS.MBRNAM <> *Blanks And FILEDS.MBRNAMT <> *Blanks;
          INPDS.FLDINP = Get + %Trim(FILEDS.LNAMET) + '/' + %Trim(FILEDS.FNAMET) +
                       '.'   + %Trim(FILEDS.MBRNAMT) +
                       ' '   + %Trim(FILEDS.LNAME) + '/' + %Trim(FILEDS.FNAME)   +
                       '.'   + %Trim(FILEDS.MBRNAM) +
                       Replace;
        Else;
          INPDS.FLDINP = Get + %Trim(FILEDS.LNAMET) + '/' + %Trim(FILEDS.FNAMET) +
                       ' '   + %Trim(FILEDS.LNAME) + '/' + %Trim(FILEDS.FNAME)   +
                       Replace;
        Endif;
      When FILEDS.GETPUT = 'P';
        If FILEDS.MBRNAM <> *Blanks And FILEDS.MBRNAMT <> *Blanks;
          INPDS.FLDINP = Put + QSYS + %Trim(FILEDS.LNAME) + LIB
                       + %Trim(FILEDS.FNAME) + FILE  + %Trim(FILEDS.MBRNAM)
                       + MBR  + ' '
// Target
                       + QSYS + %Trim(FILEDS.LNAMET) + LIB
                       + %Trim(FILEDS.FNAMET) + FILE
                       + %Trim(FILEDS.MBRNAMT) + MBR;
        Else;
          INPDS.FLDINP = Put + %Trim(FILEDS.LNAME) + '/' + %Trim(FILEDS.FNAME) +
                       ' '   + %Trim(FILEDS.LNAMET) + '/' + %Trim(FILEDS.FNAMET);
        Endif;
      ENDSL;
      Write FTPINPR INPDS;
      Reade profile FTPFILESR FILEDS;
      Enddo;
   ENDIF;

   return;

end-proc;
