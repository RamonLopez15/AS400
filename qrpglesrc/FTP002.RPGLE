**FREE
//
// BATCH FTP Project
// Author: Ramon A. Lopez
// Program Fuction: FTP Instructions Maintenance
// Date 08/09/2022
// Platform: PUB400.COM
//
//
//  To Compile:
//  *> CRTDSPF FILE(FTP002D) SRCFILE(QDDSSRC)
//  *> CRTBNDRPG FTP002 SRCFILE(QRPGLESRC) DBGVIEW(*LIST)
//
//

ctl-opt dftactgrp(*no) actgrp(*new)
        bnddir('FTPTRAN')
        option(*srcstmt:*nodebugio:*noshowcpy);

dcl-f FTP002D workstn indds(dspf) sfile(SFL:RRN);
dcl-f FTPPRF   usage(*input:*update:*output) keyed;

dcl-ds ORIG likerec(MAINT:*ALL);
dcl-ds ProfDs likerec(FTPPRFR:*input);
dcl-ds ProfDs2 likerec(FTPPRFR:*output);

/INCLUDE FTPTRAN_H

dcl-c Edit    const('2');
dcl-c Display const('5');
dcl-c Instruction const('7');
dcl-c FTPFiles const('9');

dcl-pr FTPInst Extpgm('FTP0021');
  Perfil char(10);
end-pr;

dcl-pr FTPFile Extpgm('FTP0022');
  Perfil char(10);
end-pr;

dcl-ds dspf qualified;
   F3     ind pos(3);
   F10    ind pos(10);
   F12    ind pos(12);
   sflclr ind pos(50);
   sfldsp ind pos(51);
end-ds;

dcl-s §passx char(20);
dcl-s rrn packed(4: 0);
dcl-s recsLoaded like(rrn);
dcl-s Passwd  Varchar(128);
dcl-s PasLen  Int(10);
dcl-s Clave   Varchar(128);


*inlr = *on;


dow '1';

   if loadSflList() = *off;
      return;
   endif;

   if showList() = *off;
      return;
   endif;

enddo;


// -------------------------------------------------------------------
//   clearSFL():  Clears all records from the subfile that shows
//                the list of available customers
// -------------------------------------------------------------------
dcl-proc clearSfl;

   dspf.sflclr = *on;
   dspf.sfldsp = *off;
   write CTL;
   dspf.sflclr = *off;
   rrn = 0;
   recsLoaded = 0;

end-proc;


// -------------------------------------------------------------------
//   loadSflList(): Loads the subfile with the list of available
//                  customers.
//
//     - Uses HTTPAPI to retrieve the list in JSON format
//     - If HTTP server asks for a password, handles that.
//     - Uses YAJL to parse the JSON
//     - Loads result into subfile.
//
//   Returns *ON if all is well, *OFF if an error was found
// -------------------------------------------------------------------
dcl-proc loadSflList;

   dcl-pi *n ind;
   end-pi;

   dcl-s err int(10);


   // Retrieve the list of customers (get userid/password if needed)


   clearSfl();


   setll *loval FTPPRFR;
      Read FTPPRFR ProfDS;
      Dou %Eof(FTPPRF);
         opt    = *blanks;
         RRN += 1;
         PRFNAM  =  ProfDS.PRFNAM;
         DESCRIP =  ProfDS.DESCRIP;
         HOST    =  ProfDS.HOST;
         recsLoaded = RRN;
         write SFL;

         dspf.sfldsp = *on;
         Read FTPPRFR ProfDS;
      Enddo;

   return *on;

end-proc;


// -------------------------------------------------------------------
//   showList(): Display the subfile containing customer list
//
//     - Displays the (already loaded) subfile
//     - If F10 pressed, calls the newCust() routine
//     - Loops through subfile, if any record selected, calls
//         modifyCust() for that record.
//
//   Returns *ON if the list should be re-loaded
//          *OFF if the user asked for F3=Exit
// -------------------------------------------------------------------
dcl-proc showList;

   dcl-pi *n ind;
   end-pi;

   dou dspf.F3;

      write ftr;
      exfmt ctl;
      msg = *blanks;

      if dspf.F3;
         iter;
      endif;

      if dspf.F10 = *on;
         newCust();
         leave;
      endif;

      for rrn = 1 to recsLoaded;

         chain rrn SFL;
         if %found and opt <> ' ';
            Select;
//Edit FTP Profile
            When opt = Edit;
            if modifyCust(PRFNAM) = *off;
               leave;
            endif;
//Display FTP Profile fields
            When opt = Display;
//FTP Instructions Detail
            When opt = Instruction;
                FTPInst(PRFNAM);
//FTPTFiles Detail
            When opt = FTPFiles;
                FTPFile(PRFNAM);
            Endsl;
            opt = ' ';
            update SFL;
         endif;

       endfor;

    enddo;

   return not dspf.F3;
end-proc;



dcl-proc modifyCust;

   dcl-pi *n ind;
      perfil like(ORIG.PRFNAM) value;
   end-pi;


   exfmt MAINT;
   msg = *blanks;

   if dspf.F12 or dspf.F3;
      dspf.F12 = *off;
      return *off;
   endif;

   return *on;

end-proc;


// -------------------------------------------------------------------
//  newCust(): Create a new customer record
//
//   - Clears customer fields to start with a blank customer
//   - Displays screen, lets user enter customer information
//   - Calls the 'updateCust' routine to send results to provider
//
//  Returns *ON if successful, *OFF if error or user cancelled
// -------------------------------------------------------------------
dcl-proc newCust;

   dcl-pi *n ind;
   end-pi;

   clear orig;
   PRFNAM = *blanks;
   DESCRIP= *blanks;
   HOST   = *blanks;
   USER   = *blanks;
   xPASS  = *blanks;
   §PASSx = *blanks;

   exfmt MAINT;
   msg = *blanks;

   if dspf.F12 or dspf.F3;
      dspf.f12 = *off;
      return *off;
   endif;

// if xpass = §passx;
      Clave = xpass;
      Passwd = EncryptData(Clave:                      //EnEncrypt Password
                         Paslen);                      //EnEncrypt Password

      ProfDS2.Passw  = Passwd;
      ProfDS2.Plen   = Paslen;
      ProfDS2.PRFNAM = PRFNAM;
      ProfDS2.DESCRIP= DESCRIP;
      ProfDS2.HOST   = HOST;
      ProfDS2.USER   = USER;
      Write FTPPRFR ProfDS2;
// endif;

   return *on;

end-proc;



