
     H* BATCH FTP Project
     H* Author: Ramon A. Lopez
     H* Program Fuction: FTP Encryption/Decryption Functions
     H* Date 08/09/2022
     H* Platform: PUB400.COM

     HNOMAIN
     D* The QUSEC Source Contains the Common Error Code Data Structure.

     D/COPY QSYSINC/QRPGLESRC,QUSEC

     D stdError        DS                  qualified

     D  QUSEC                              likeDs(QUSEC)

     D  outError                   1024A
     D*
     D* The QC3CCI Source Contains Encryption Data Structures.
      *
      *
     D/COPY QSYSINC/QRPGLESRC,QC3CCI
     D/COPY QRPGLESRC,FTPTRAN_H

     D keyDesc         DS                  qualified

     D  QC3D020000                         likeDs(QC3D020000)

     D  QC3Key                     1024A
     D*
     D encryptDataAPI...
     D                 PR                  extPgm('QC3ENCDT')

     D  argIn                     65535    const options(*varsize)

     D  argInLen                     10I 0 const

     D  argInFmt                      8    const

     D  argAlg                    65535    const options(*varsize)

     D  argAlgFmt                     8    const

     D  argKey                    65535    const options(*varsize)

     D  argKeyFmt                     8    const

     D  argCryptoPro                  1    const

     D  argCryptoDev                 10    const

     D  argOut                    65535

     D  argOutBuffLen                10I 0 const

     D  argOutLen                    10I 0

     D  argError                           likeDs(QUSEC)
     D*
     D*encryptData...
     D*                PR         65535A
     D*
     D* argData                   65535A   const varying
     D*
     D*                                    options(*varsize)
     D*
     D* argOutLen                    10I 0
     D*
     D*decryptData...
     D*                PR         65535A
     D*
     D* argData                   65535A   const varying
     D*
     D*                                    options(*varsize)
     D*
     D* argInLen                     10I 0
     D*
     D decryptDataAPI...
     D                 PR                  extPgm('QC3DECDT')

     D  argIn                     65535    const options(*varsize)

     D  argInLen                     10I 0 const

     D  argAlg                    65535    const options(*varsize)

     D  argAlgFmt                     8    const

     D  argKey                    65535    const options(*varsize)

     D  argKeyFmt                     8    const

     D  argCryptoPro                  1    const

     D  argCryptoDev                 10    const

     D  argOut                    65535

     D  argOutBuffLen                10I 0 const

     D  argOutLen                    10I 0

     D  argError                           likeDs(QUSEC)
     D*
     D
     D cipherSetup...
     D                 PR

     D  argKey                     1024A   const varying

     D                                     options(*varsize)

     D  argAlgorithm                 10I 0 const
     D*

     D ssn             S            128A

     D results         S          65535A

     D secretKey       S             32A

     D cryptoPro       S              1A

     D cryptoDev       S             10A

     D encryptLen      S             10I 0

     D displayBytes    S             52A

     D************************* Constants *******************************

     D* Block Cipher Algorithms

     D DES             C                   20

     D TRIPLE_DES      C                   21

     D AES             C                   22

     D**************************** Main *********************************

     D**********************************************************************

     D*  cipherSetup() using Block Cipher Algorithms

     D**********************************************************************

     P cipherSetup...
     P                 B                   EXPORT
     D cipherSetup...
     D                 PI

     D  argKey                     1024A   const varying

     D                                     options(*varsize)

     D  argAlgorithm                 10I 0 const

     D*

     D svBytes         S             52A

      /free

        // Initialize the Algorithm Data Structure QC3D0200

        QC3D0200 = *AllX'00';

        QC3BCA = argAlgorithm;

        select;

          when argAlgorithm = DES;

            QC3BL = 8;

          when argAlgorithm = TRIPLE_DES;

            QC3BL = 8;

          when argAlgorithm = AES;

            // For AES, could be 16, 24 or 32

            QC3BL = 16;

          other;

            QC3BL = 0;

        endsl;

        QC3MODE = '1';

        QC3PO = '1';

        QC3EKS = 0;

        // Initialize the Key Data Structure QC3D020000

        keyDesc.QC3D020000 = *AllX'00';

        keyDesc.QC3D020000.QC3KT = argAlgorithm;

        keyDesc.QC3D020000.QC3KF = '0';

        keyDesc.QC3D020000.QC3KSL = %len(%trim(argKey));

        keyDesc.QC3Key = %trim(argKey);

        // Initialize the Rest of the Parameters

        stdError.QUSEC = *AllX'00';

        stdError.QUSEC.QUSBPRV = 1040;

        cryptoPro = '0';

        cryptoDev = *BLANKS;

      /end-free

     P                 E
     D**********************************************************************

     D*  encryptData() using Block Cipher Algorithms

     D**********************************************************************

     P encryptData...
     P                 B                   EXPORT
     D encryptData...
     D                 PI         65535A

     D  argData                   65535A   const varying

     D                                     options(*varsize)

     D  argOutLen                    10I 0

     D*

     D svOutData       S          65535A

     D svBytes         S             52A
      /free

      *  secretKey = 'MC_pr3$$';
       secretKey = 'MC_pr3$$!0nL1N3_';
       // Configure Encryption Cipher

       cipherSetup(secretKey: AES);

        svOutData = *BLANKS;

        // API

        encryptDataAPI(argData: %len(argData): 'DATA0100':

                    QC3D0200: 'ALGD0200':

                    keyDesc: 'KEYD0200':

                    cryptoPro: cryptoDev:

                    svOutData: %size(svOutData): argOutLen:

                    stdError);

        if stdError.QUSEC.QUSBAVL > 0;

          // Error

          svBytes = 'Error: ' + stdError.QUSEC.QUSEI;

          DSPLY svBytes;

          svOutData = *BLANKS;

        else;

        endif;

        return svOutData;

      /end-free

     P                 E
     D**********************************************************************

     D*  decryptData() using Block Cipher Algorithms

     D**********************************************************************

     P decryptData...
     P                 B                   EXPORT
     D decryptData...
     D                 PI         65535A

     D  argData                   65535A   const varying

     D                                     options(*varsize)

     D  argInLen                     10I 0

     D*

     D svOutData       S          65535A

     D svOutDataLen    S             10I 0

     D svBytes         S             52A

      /free

        svOutData = *BLANKS;

      *secretKey = 'MC_pr3$$';
       secretKey = 'MC_pr3$$!0nL1N3_';
       // Configure Encryption Cipher
       cipherSetup(secretKey: AES);
        // API

        decryptDataAPI(argData: argInLen:

                    QC3D0200: 'ALGD0200':

                    keyDesc: 'KEYD0200':

                    cryptoPro: cryptoDev:

                    svOutData: %size(svOutData): svOutDataLen:

                    stdError);

        if stdError.QUSEC.QUSBAVL > 0;

          // Error

          svBytes = 'Error: ' + stdError.QUSEC.QUSEI;

          DSPLY svBytes;

          svOutData = *BLANKS;

        else;

        endif;

        return svOutData;

      /end-free

     P                 E
