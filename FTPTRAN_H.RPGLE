**FREE
//
// BATCH FTP Project
// Author: Ramon A. Lopez
// Function: Include File with Prototypes
// Date 07/28/2022
// Platform: PUB400.COM
//
//
//
//

Dcl-Ds ErrorDS;
 BytesProv Int(10) Inz(%size(ErrorDS));
 BytesAvail Int(10);
 ExceptionIDx Char(7);
End-DS;

dcl-pr ExecuteFTP Ind;
      profile char(10) value;
end-pr;

dcl-pr CrtInput Char(20);
      profile char(10) value;
end-pr;

dcl-pr Files2Transfer;
      profile char(10) value;
end-pr;

dcl-pr qCmdExc extpgm ;
    *n char(1000) options(*varsize) const ;
    *n packed(15:5) const ;
end-pr ;

dcl-pr SendMsg extpgm('QMHSNDPM');
    MsgID char(7) const ;
    MsgF char(20) const ;
    MsgData char(30) const ;
    MsgDataLen Int(10) const ;
    MsgType char(10) const ;
    CallStackEnt char(10) const ;
    CallStackCtr Int(10) const ;
    MsgKey  char(4) const ;
    Error like(ErrorDS);
end-pr ;

dcl-pr ClrMsgQ extpgm('QMHRMVPM');
    MsgQueue char(276) const ;
    CallStack    Int(10) const ;
    MsgKey  char(4) const ;
    MsgRmv  char(10) const ;
    Error like(ErrorDS);
end-pr ;

dcl-pr WrtDtaQ extpgm('QSNDDTAQ');
   *N Char(10);
   *N Char(10);
   *N packed(5);
   *N Char(256);
   *N packed(3);
   *N Char(4);
end-pr ;


dcl-pr ReadDtaQ extpgm('QRCVDTAQ');
   *N Char(10);
   *N Char(10);
   *N Packed(5);
   *N Char(256);
   *N Packed(5);
   *N Char(2);
   *N Packed(3);
   *N Char(4);
   *N Packed(3);
   *N Char(10);
end-pr ;

dcl-pr sleep Uns(10) extproc('sleep');
   seconds Uns(10) value;
end-pr ;

dcl-pr encryptData Char(65535);
     ArgData VarChar(65535) const
     options(*varsize);
     ArgOutLen Int(10);
END-PR;

dcl-pr decryptData Char(65535);
     ArgData VarChar(65535) const
     options(*varsize);
     ArgInLen Int(10);
END-PR;

 dcl-pr chiperSetup;
   argKey Char(1024) const
   options(*varsize);
   argAlgorithm Int(10) const;
 END-PR;


