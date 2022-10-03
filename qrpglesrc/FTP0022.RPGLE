**FREE
//
// BATCH FTP Project
// Author: Ramon A. Lopez
// Program Fuction: FTP Files-2-Transfer Maintenance
// Date 10/02/2022
// Platform: PUB400.COM
//
//
//  To Compile:
//  *> CRTDSPF FILE(FTP0022D) SRCFILE(QDDSSRC)
//  *> CRTBNDRPG FTP0022 SRCFILE(QRPGLESRC) DBGVIEW(*LIST)
//

ctl-opt dftactgrp(*no) actgrp(*new)
        bnddir('FTPTRAN')
        option(*srcstmt:*nodebugio:*noshowcpy);

dcl-f FTP0022D workstn infds(info) sfile(FTP022A2:rrn1)
                                   sfile(FTP022A4:rrn2);
dcl-f FTPPRF   usage(*input) keyed;
dcl-f ftpfiles usage(*input:*update:*output:*delete) keyed;

dcl-ds KeyFile likerec(FTPFilesR:*Key);
dcl-ds ProfDs likerec(FTPPRFR:*input);
dcl-ds FileDS  likerec(FTPFilesR:*input);
dcl-ds FileDS2 likerec(FTPFilesR:*output);

/INCLUDE FTPTRAN_H

dcl-ds Info;
   Key char(1) Pos(369);
end-ds;


dcl-ds Data  Inz;
  Option char(1);
  FileSeq Zoned(6);
  PRFNAM  char(10);
  LNAME   char(10);
  FNAME   char(10);
  MBRNAM  char(10);
  LNAMET  char(10);
  FNAMET  char(10);
  MBRNAMT char(10);
  filler char(179) Inz(*Blanks);
  KeyData char(4) pos(1);
end-ds;

dcl-ds Data§ Inz;
  Option§ char(1);
  PRFNAM§  char(10);
  FileSeq§ zoned(6);
  KeyData§ Zoned(3) pos(12);
  INSTRUCTZ§ char(30);
  filler§ char(209);
end-ds;

dcl-c Edition const('2');
dcl-c Delete  const('4');
dcl-c Display const('5');
dcl-c Get     const('G');
dcl-c Put     const('P');
dcl-c Etiqueta   const('F3=Exit  F12=Prior Scrn');
dcl-c Exit  const(X'33');
dcl-c Cancel const(X'3C');
dcl-c F06    const(X'36');
dcl-c F10    const(X'3A');
dcl-c Enter  const(X'F1');
dcl-c Rollup const(X'F5');
dcl-c Rolldn const(X'F4');
dcl-c SflPag const(12);
dcl-c SflPag_plus_1 const(13);
dcl-c Qlen const(256);

dcl-s fileIndicator Pointer Inz(%addr(*In));
dcl-ds indicatorname based(fileindicator);
   EditMode Ind pos(25);
   TieneHora Ind pos(27);
   NoBorrar Ind pos(28);
   SflClrWin Ind Pos(41);
   ModoAdicion Ind Pos(59);
   ProcesoError Ind Pos(60);
   AmbientError Ind Pos(61);
   SflNextChg Ind Pos(74);
   SflClr Ind Pos(90);
   SflDsp Ind Pos(91);
   SflEnd Ind Pos(94);
end-ds;

dcl-ds dspf qualified;
   F3     ind pos(3);
   F10    ind pos(10);
   F12    ind pos(12);
   sflclr ind pos(50);
   sfldsp ind pos(51);
end-ds;

dcl-s Cmd      Char(1000);
dcl-s count zoned(4);
dcl-s lstrrn zoned(4);
dcl-s lstrrn2 zoned(4);
dcl-s rrn packed(4: 0);
dcl-s recsLoaded like(rrn);
dcl-s Clave   Varchar(128);
dcl-s lib     char(10) Inz('QTEMP');
dcl-s queue   char(10) Inz('SFLDTAQDQ1');
dcl-s Len     Packed(5) Inz(256);
dcl-s Keyln   Packed(3) Inz(7);
dcl-s wait    Packed(5) Inz(0);
dcl-s sndlen  Packed(3) Inz(0);
dcl-s order   char(2) Inz('EQ');
dcl-s sndr    char(10) Inz('          ');
dcl-s Msg     char(78) Inz;
dcl-s Errores Ind Inz(*off);
dcl-s ErrWindow Ind Inz(*off);
dcl-s Idx  Int(10) Inz;
dcl-s MsgFile  char(20) Inz('QCPFMSG   *LIBL');
dcl-s MsgId    char(7)  Inz('CPF9897');
dcl-s Done01   char(1) Inz('0');
dcl-s It  Int(5);
dcl-s SavSeq zoned(3);

dcl-pr Main Extpgm('FTP0022');
  Perfil char(10);
end-pr;
//
dcl-pi *N;
  Perfil char(10);
end-pi;

        // Execute FTP
        Cmd = 'CALL PGM(FTP0022CL)';
        qCmdExc(Cmd:%len(Cmd));

        KeyFile.PRFNAM = Perfil;
        Setll %kds(KeyFile:1) FTPFilesR;
        LoadSflList();

        Dou Key   = Exit;

             lstrrn   =  rrn1;
             rrn1     =  1;
             Write FTP022D1;
             DEMSG_TMSG  =  Etiqueta;
             PRFNAM  =  FileDS.PRFNAM;
             GETPUT  =  FileDS.GETPUT;
             FileSeq =  FileDS.FileSeq;
             LNAME   =  FileDS.LNAME;
             FNAME   =  FileDS.FNAME;
             MBRNAM  =  FileDS.MBRNAM;
             Write FTP022D4;

            If NoBorrar;
                      PgmQ  =  '*';
                      PrnMsg();   // Display Error Msg
                      NoBorrar = *Off;
            Endif;

             Exfmt FTP022A3;

            // PgmQ  =  '*';
             ClrMsg();    // Clear Subfile Message Error

             Select;
                            // When Enter is pressed Locate in subfile
                            // by search field

             When Key = enter and Situar <> *Zeros;
                  Addque();
                  KeyFile.PRFNAM  = Perfil;
                  KeyFile.FileSeq = Situar;
                  Setll %Kds(KeyFile) FTPFilesR;
                  LoadSflList();

                            // When Enter is pressed proccess subfile
                            // & ask for selected options if search
                            // field is blank

             When Key = enter and Situar = *Zeros;
                  Addque();
                  Prcsfl();
                  Setll %Kds(KeyFile:1) FTPFilesR;
                  LoadSflList();

             When Key = F06;
                  ModoAdicion = *On;
                  Addque();
                  ChgDtl();
                  Setll %Kds(KeyFile:1) FTPFilesR;
                  LoadSflList();

                            // Page Dwn - Load options to Dtaq before
                            // adding data to subfile.
             When Key = rollup and (not SflEnd);
                  Addque();
                  LoadSflList();

                             // Page Up - Load options to Dtaq before
                             // reverse data to subfile.
           //When Key = rolldn and (not %Eof(MAE_CLI));
             When Key = rolldn;
                  Addque();
                  Goback();
                  LoadSflList();

             When Key = Cancel;
                 Leave;
             Endsl;

        Enddo;
 *Inlr = *On;

//-----------------------------------------------------------
// GOBACK - Go one page back in subfile.
//-----------------------------------------------------------
dcl-proc Goback;

              KeyFile.PRFNAM  = perfil;
              KeyFile.FileSeq = savseq;
              Setll %Kds(KeyFile) FTPFilesR;
              Clear      it;

              Dou It = Sflpag_plus_1;

                   Readpe %Kds(KeyFile:1) FTPFilesR FileDS;
                   If %Eof(FTPFiles);
                        Setll *Loval FTPFilesR;
                        Leave;
                   Endif;


                   It   +=  1;

              Enddo;

end-proc;

//-----------------------------------------------------------
// CLRMSG - Clear Subfile Message Error.
//-----------------------------------------------------------
dcl-proc ClrMsg;

             //  Msg  = *Blanks;
                 ClrMsgQ('*':*Zero:*Blanks:'*ALL':ErrorDs);
             //  Write FTP022D4;       // Write Windows
             //  Write MsgCtl;         // Write to Subfile Msg Record

end-proc;

//-----------------------------------------------------------
// PRNMSG - Display Subfile Message Error.
//-----------------------------------------------------------
dcl-proc PrnMsg;

                 SendMsg(MsgId     :
                         MsgFile   :
                         Msg       :
                         %Size(Msg):
                         '*STATUS' :
                         '*EXT'    :
                         0         :
                         *Blanks   :
                         ErrorDs   );

                 Write FTP022D4;       // Write Windows
                 Write MsgCtl;         // Write to Subfile Msg Record
            //   sleep(5);

end-proc;


// -------------------------------------------------------------------
// RCVQUE() - Check in Dtaq before writing into subfile.
// -------------------------------------------------------------------
dcl-proc Rcvque;


              order = 'EQ';

              ReadDtaq( queue   :
                        lib     :
                        len     :
                        data    :
                        wait    :
                        order   :
                        Keyln   :
                        keydata :
                        sndlen  :
                        sndr    );


              If len > *Zero;
                     SflNextChg =  *On;
              Endif;

end-proc;

// -------------------------------------------------------------------
// ADDQUE - Load data from subfile to a Data Queue
// -------------------------------------------------------------------
dcl-proc Addque;

              Readc FTP022A2;

              Dow not %Eof;

                   len = qlen;
                   WrtDtaq(  queue   :
                             lib     :
                             len     :
                             data    :
                             keyln   :
                             keydata );

                   Readc FTP022A2;

              Enddo;


end-proc;

//-----------------------------------------------------------
// VLDPAN - Validate Data Entry Screen
//-----------------------------------------------------------
dcl-proc VldPan;

                Clear Msg;
                For Idx = 60 To 70;
                    *In(Idx) = *Off;
                Endfor;

                Errores = *Off;

                If GETPUT <> Get And GETPUT <> Put;
                        Msg     = 'GETPUT should be G or P';
                        *In68   = *On;
                        Errores = *On;
                Endif;

                If LNAME    = *Blanks;
                        Msg     = 'Library From should not be blank';
                        *In69   = *On;
                        Errores = *On;
                Endif;

                If FNAME    = *Blanks;
                        Msg     = 'File From should not be blank';
                        *In69   = *On;
                        Errores = *On;
                Endif;

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


   dcl-s err int(10);
   rrn1    =  *Zeros;
   SflClr  =  *On;
   SflDsp  =  *Off;
   Write FTP022A3;              // Clear Subfile
   SflClr  =  *Off;
   SflDsp  =  *On;
   Clear      it;

   Dou It  = Sflpag;
       Reade %Kds(KeyFile:1) FTPFilesR FileDS;
       If %Eof(FTPFiles) and rrn1 = *Zero;
           Clear Situar;
           Setgt %Kds(KeyFile:1) FTPFilesR;
           Readpe %kds(KeyFile:1) FTPFilesR FileDS;
       Endif;

       If %Eof(FTPFiles) and rrn1 > *Zero;
               Leave;
       Endif;


       Option  =  *Blanks;

       PRFNAM  =  FileDS.PRFNAM;
       GETPUT  =  FileDS.GETPUT;
       FileSeq =  FileDS.FileSeq;
       LNAME   =  FileDS.LNAME;
       FNAME   =  FileDS.FNAME;
       MBRNAM  =  FileDS.MBRNAM;

   // Verify Data Queue for any option executed
       Rcvque();
       rrn1   +=  1;

       Write FTP022A2;
       SflNextChg =  *Off;

       If rrn1 = 1;
          savseq = FileSeq;
       Endif;

       It      +=  1;
   Enddo;

   // Retrieve the list of customers (get userid/password if needed)


end-proc;

//-----------------------------------------------------------
// PRCSFL - Proccess options from subfile.
//-----------------------------------------------------------
dcl-proc Prcsfl;

           SflClrWin = *On;

           Write FTP022A5;
           SflClrWin = *Off;
           rrn2      = *Zero;
                                    // Read records from Dtaq until
                                    // it is empty
           order = 'GE';

           Dou len = *Zero;

              ReadDtaq( queue   :
                        lib     :
                        len     :
                        data    :
                        wait    :
                        order   :
                        Keyln   :
                        keydata :
                        sndlen  :
                        sndr    );


              If len > *Zero;         // If true record was read

                     Select;
                                            // Edit Routine
                     When option = Edition;
                           KeyFile.PRFNAM  = Perfil;
                           KeyFile.FileSeq = FileSeq;

                           Chain %Kds(KeyFile) FTPFilesR FileDS;
                           If %Found(FTPFiles);

                               mode  = 'Change';
                               modoAdicion = *Off;
                               Chgdtl();
                               If Key = Exit or Key = Cancel;
                                    Leave;
                               Endif;
                           Endif;

         // Option 4 write record to confirmation screen and turn on
         // SFLNXTCHG indicator for marking the record as changed and
         // update the subfile.  If F12 is pressed those records
         // remain in original state.

                     When option = Delete;


                           rrn2 += 1;
                           data§     = data;
                           Write FTP022A4;

         // Display Data

                     When option = Display;
                           mode  = *Blanks;
                           KeyFile.PRFNAM  = Perfil;
                           KeyFile.FileSeq = FileSeq;
                           Chain %Kds(KeyFile) FTPFilesR FileDS;
                           GETPUT  =  FileDS.GETPUT;
                           LNAME   =  FileDS.LNAME;
                           FNAME   =  FileDS.FNAME;
                           MBRNAM  =  FileDS.MBRNAM;
                           LNAMET  =  FileDS.LNAMET;
                           FNAMET  =  FileDS.FNAMET;
                           MBRNAMT =  FileDS.MBRNAMT;
                           Exfmt FTP022D5;
                           If Key = Exit or Key = Cancel;
                                Leave;
                           Endif;


                     EndSl;

              Endif;

           Enddo;

         // If there are records for deleting, Display them in a
         // Windows.  Enter confirm & F12 rollback.

           If rrn2 > *Zero;

                     lstrrn2  =  rrn2;
                     rrn2     =  1;
                     Exfmt FTP022A5;
                     If Key <> Exit and Key <> Cancel;
                           DltRcd();
                           KeyFile.PRFNAM  = Perfil;
                           KeyFile.FileSeq = 1;
                           Chain %Kds(KeyFile) FTPFilesR;
                     Endif;
           Endif;

end-proc;

//-----------------------------------------------------------
// CHGDTL  - Confirma si Excluye Prestamo del Castigo
//-----------------------------------------------------------
dcl-proc Chgdtl;

          If ModoAdicion;
             KeyFile.PRFNAM  = Perfil;
             Setgt %Kds(KeyFile:1) FTPFilesR;
             Readpe %Kds(KeyFile:1) FTPFilesR FileDS;
             If %Eof(FTPFiles);
                 FileSeq     = 1;
             Else;
                 FileSeq    += 1;
             Endif;
             Clear  LNAME;
             Clear  GETPUT;
          Else;
             Done01   =   '0';
             KeyFile.PRFNAM  = Perfil;
             KeyFile.FileSeq = FileSeq;
             Chain %Kds(KeyFile) FTPFilesR FileDS;
             If %Found(FTPFiles);       //If found bring Edit Screen
                           GETPUT  =  FileDS.GETPUT;
                           LNAME   =  FileDS.LNAME;
                           FNAME   =  FileDS.FNAME;
                           MBRNAM  =  FileDS.MBRNAM;
                           LNAMET  =  FileDS.LNAMET;
                           FNAMET  =  FileDS.FNAMET;
                           MBRNAMT =  FileDS.MBRNAMT;
             Endif;
          Endif;

                  Dow Done01  =  '0';
                       DEMSG_TMSG  =  Etiqueta;
                       Exfmt FTP022D6;
                       ClrMsg();        //Clear Subfile Message
                       If Key <> Exit And Key <> Cancel;
                            VldPan();
                            If Not Errores;
                                 FileDS2 = FileDS;
                                 FileDS2.GETPUT   = GETPUT;
                                 FileDS2.LNAME     = LNAME;
                                 FileDS2.FNAME     = FNAME;
                                 FileDS2.MBRNAM    = MBRNAM;
                                 FileDS2.LNAMET    = LNAMET;
                                 FileDS2.FNAMET    = FNAMET;
                                 FileDS2.MBRNAMT   = MBRNAMT;
                                 Update FTPFilesR FileDS2;
                                 Done01   =   '1';
                            Else;
                                 PrnMsg();   // Display Error Msg
                            Endif;
                       Else;
                            Done01   =   '1';
                       Endif;
                  Enddo;
end-proc;

//-----------------------------------------------------------
// DLTRCD - Delete Record after Confirmation
//-----------------------------------------------------------
dcl-proc DltRcd;


           // Read All records from Windows Confirmation

              NoBorrar  =  *Off;

              For Count = 1 to lstrrn2;
                   Chain Count FTP022A4;
                   If %Found;

                         KeyFile.PRFNAM  = PRFNAM;
                         KeyFile.FileSeq = FileSeq;

                         Chain %Kds(KeyFile) FTPFilesR;
                         Delete FTPFilesR;


                   Endif;
              Endfor;

end-proc;




