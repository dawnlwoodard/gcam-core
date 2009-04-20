! MAGTAR.FOR
!
!   THE OUTPUTS PASSED TO THE Tcl CODE ARE:
!    (1) THE FIVE DISPLAY FILES, *.dis, FOR GLOBAL-MEAN TEMP AND MSL,
!        AND EMISSIONS, CONCENTRATIONS, AND RADIATIVE FORCING; AND
!    (2) THE FOUR SCENGEN DRIVER FILES lo/mid/hi/usrdrive.out.
!
! Revision history:
! 022409  *  Added read-in and calc of BC+OC forcing directly from emissions
!            Enable by setting MAGICC input parameter IFOC = 3
! 013009  *  Updated output arrays for ObjECTS MiniCAM
! 091708  *  Changed file paths for use as stand-alone model in own directory sjs

! 012605  *  Added output of total Kyoto forcing to MiniCAM sjs
! 030526  *  Revised to work with MiniCAM 5/2003 mrj
! changes based on those by sjs and hmp in prior MAGICC version

! 030518  * sjs added extra halocarbon outputs to mag.csv
! 030321  * sjs changed mag.out to mag.csv output
! 03032?  * sjs added SAVE to DELTAQ to correct error

! 080625  * FOR NOUT=1, MSL TOTAL LESS TAR "OTHER" ADDED TO OUTPUT.
! 080619  * ADDED OUTPUT FILE FOR CCSM INPUT, OUTPUT ONLY IF ICCSM=1
! 080619  * FOR FORCINGS FROM 1765, CFC12 AND EFFECTIVE CFC11 CONCS
!            ADDED AS OUTPUT. THIS REQUIRED ADDING CFC12 CONCS AS AN
!            INPUT IN QHALOS.IN
! 080617  * MAG.OUT OUTPUT REDUCED EVEN MORE FOR FULL VERSION. THIS
!            REDUCES COLLATION TIME MORE. (SEE LINE 1542.) THIS HAS THE
!            DESIRED EFFECT ON RUN  TIME, BUT IT REMOVES CRUCIAL OUTPUT
!            FROM THE REPORTS FILES. HENCE, BACK TO PREVIOUS VERSION.
!           ERROR IDENTIFIED IN ***drive OUTPUTS THAT DEFINE THE WEIGHTS
!            FOR THE AEROSOL PATTERNS IN SCENGEN. BECAUSE OF SMOOTHING,
!            THESE WERE NOT BEING PRODUCED FOR THE LAST THREE YEARS.
!            CORRECTED USING LINEAR EXTRAPOLATION.
!           THIS IS THE VERSION HANDED OVER TO SETH.
! 080612  * VZERO IN GSIC MODEL CHANGED TO 18, 29, 44 CM. THESE ARE 1.2
!            TIMES THE AR4 NUMBERS (AS IN AR4) TO ACCOUNT FOR GREENLAND
!            AND ANTARCTICA GSICs. NOTE THAT THE CENTRAL NUMBER MUST BE
!            SPECIFIED IN MAGICE.CFG.
!           THE METHOD FOR CALCULATING SLT SEEMS TO BE WRONG. IT ATTEMPTS
!            TO USE QUADRATURE FOR THE ERRORS IN INDIVIDUAL COMPONENTS,
!            BUT DOES NOT DO THIS CONSISTENTLY. SO IT IS BETTER TO SUM
!            THE INDIVIDUAL COMPONENT VALUES. THIS GIVES EXTREMES THAT
!            ARE TOO HIGH OR TOO LOW. TO GET THE 5th AND 95th %ILES,
!            A GOOD ESTIMATE IS TO HALVE THE DEPARTURES OF THESE EXTREME
!            FROM THE BEST ESTIMATE.
! 080611  * FOR FULL VERSION (ISCENGEN=1) REDUCE MAG.OUT OUTPUT TO GIVE
!            RESULTS ONLY FOR FULL SO2 EMISSIONS CASE (NESO2=1). THIS
!            IS TO REDUCE COLLATION TIME IN RUNNING MAGICC.
! 080611  * HANDED OVER TO SETH
! 080608  * FOR NOUT=1, SUM OF GREENLAND+ANTARCTICA NOW OUTPUTTED.
!           CO2 UNCERTAINTY VALUES FOR DN80S UPDATED TO USE NEW BEST
!            ESTIMATE OF 1.5 (BUT STILL +/- 0.7).
! 080605  * NUMEROUS CORRECTIONS TO HANDLE QMN CORRECTLY AND KEYED TO 
!            MAGINV.FOR
!           CH4 AND N2O BALANCE METHOD GENERALIZED SO THAT YEAR 2000 DOES 
!            NOT HAVE TO BE D*(2).
! 080531  * NO3 PLUS MINERAL AEROSOL FORCING (QMN) OUTPUT SEPARATELY
! 080528  * BEST GUESS SENSITIVITY BACK TO 3.0
!           IDIS NOW BACK TO BEING SET IN MAGRUN.CFG
! 080527  * NEW GSIC MODEL ADDED FROM MAGMSL.FOR, SING WIGLEY AND RAPER
!            (2005). NEW GSIC PARAMETERS PUT INTO A NEW CFG FILE
!            'MAGICE.CFG'.
! 080520  * INTERIM VERSION WITH BEST GUESS DT2x = 2.6C TO ACCORD
!            WITH OLD MAG4.1 CFG FILES FOR DEFAULT.
! 080517  * THREE NEW FORCINGS ADDED: DIRECT NITRATE AEROSOL FORCING
!            QNO3 (-0.1 IN 1990), MINERAL DUST QMIN (-0.1 IN 1990),
!            AND LAND ALBEDO QLAND (-0.2 IN 1990). THESE RAMP UP
!            LINEARLY TO 1990 AND ARE KEPT CONSTANT AFTER THIS.
!           QNO3 AND QMIN ARE SET IN SUBROUTINE SUPHATE AND ADDED TO
!            INDIRECT SO4 AEROSOL FORCING
!           QLAND IS SET IN SUBROUTINE DELTAQ AND PASSED TO MAIN
!           DEFAULT VALUES OF S90DIR, S90IND, S90BIO AND FOC90 RESET
!           BASE TROP OZONE FORCING CORRECTED TO GIVE 0.35 IN 2005 AS
!            IN AR4
!           CLIMATE SENSITIVITY 90% RANGE AND BEST ESTIMATE CHANGED
!            FROM 1.5(2.6)4.5 TO 1.5(3.0)6.0, IN ACCORD WITH AR4.
! 080517  * LAST 4.1 VERSION BEFORE UPDATING TO VERSION 5.3. SEE THIS
!            VERSION FOR EARLIER HISTORY.
!
!-------------------------------------------------------------------------------
! Written by Tom Wigley, Sarah Raper & Mike Salmon, Climatic Research Unit, UEA.
!-------------------------------------------------------------------------------
!
!      SUBROUTINE CLIMAT (IWrite, MAGICCCResults,MagEM)	
! MiniCAM Header with inputs and outputs passed directly

      SUBROUTINE CLIMAT	
! Expose subroutine climat to users of this DLL
!
!DEC$ ATTRIBUTES DLLEXPORT::climat
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)

!
!   THIS IS THE CLIMATE MODEL MODULE.
!
      parameter (iTp=740)
!
  	  REAL*4 MAGICCCResults(0:30,75) ! sjs pass data to ObjECTS
	  REAL*4 getForcing, getSLR
  	  
      INTEGER IY1(100),OVRWRITE
!
! sjs removed TEMUSER(iTp), QSO2SAVE(0:iTp+1),QDIRSAVE(0:iTp+1) from dimension statement since now in common block
      DIMENSION FOS(100),DEF(100),DCH4(100),DN2O(100), &
      DNOX(100),DVOC(100),DCO(100),DSO2(100), &
      DSO21(100),DSO22(100),DSO23(100),DCF4(100),DC2F6(100), &
      D125(100),D134A(100),D143A(100),D227(100),D245(100),DSF6(100), &
      DBC(100),DOC(100), &
      TEMLO(iTp),TEMMID(iTp),TEMHI(iTp),TEMNOSO2(iTp), &
      SLUSER(iTp),SLLO(iTp),SLMID(iTp),SLHI(iTp), &
      TALL(4,iTp-225),TGHG(4,iTp-225),TSO21(4,iTp-225), &
      TSO22(4,iTp-225),TSO23(4,iTp-225),TREF(4),XSO21(4,iTp-225), &
      XSO22(4,iTp-225),XSO23(4,iTp-225),XGHG(4,iTp-225), &
      SCALER(197:iTp),SCALAR(197:iTp)
!
      REAL*4 FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing !sjs
      COMMON/BCOC/FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing

      DIMENSION EESS1(iTp),EESS2(iTp),EESS3(iTp),EESST(iTp),QTROZ(iTp), &
     QSTROZ(iTp),C11EFF(iTp)
!
      common /Limits/KEND
!
      COMMON/OZ/OZ00CH4,OZCH4,OZNOX,OZCO,OZVOC
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
!  NOTE THAT EMISSIONS START WITH J=226, =1990.
!
      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/NEWCONCS/CF4(iTp),C2F6(iTp),C125(iTp),C134A(iTp), &
     C143A(iTp),C227(iTp),C245(iTp),CSF6(iTp), &
     ECF4(226:iTp+1),EC2F6(226:iTp+1),E125(226:iTp+1),E134A(226:iTp+1), &
     E143A(226:iTp+1),E227(226:iTp+1),E245(226:iTp+1),ESF6(226:iTp+1)
!
      COMMON/COBS/COBS(0:236)
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
!
      COMMON /METH1/emeth(226:iTp),imeth,ch4l(225:iTp),ch4b(225:iTp), &
     ch4h(225:iTp),ef4(226:iTp),StratH2O,TCH4(iTp),iO3feed, &
     ednet(226:iTp+1),DUSER,FUSER,CORRUSER,CORRMHI,CORRMMID,CORRMLO
!
      COMMON /FORCE/qco2(0:iTp),qm(0:iTp),qn(0:iTp),QCFC(0:iTp), &
     QMONT(0:iTp),QOTHER(0:iTp),QSTRATOZ(0:iTp),QCH4O3(0:iTp), &
     CFC12(0:iTp), QCH4H2O(0:iTp),QBC(0:iTp),QOC(0:iTp)
!
      COMMON /METH2/LEVCH4,ch4bar90,QQQN2O
!
      COMMON /METH3/TCH4CON,TAUINIT,SCH4,DELSS,DELTAU, &
     ANOX,ACO,AVOC,DELANOX,DELACO,DELAVOC,ICH4FEED
!
      COMMON /METH4/GAM,TAUOTHER,BBCH4,CM00
      common /TauNitr/TN2000,BBN2O,SN2O,CN00,NOFFSET
      common /Sulph/S90DIR,S90IND,S90BIO,enat,ES1990,ECO90,FOC90,IFOC
      COMMON /CO2READ/ICO2READ,XC(226:iTp),CO2SCALE,qtot86,LEVCO2
      COMMON /DSENS/IXLAM,XLAML,XLAMO,ADJUST
      COMMON /VARW/Z(40),W(2),DW(2),TO0(2),TP0(2),WNH(iTp),WSH(iTp), &
     TW0NH,TW0SH,IVARW,KEYDW
      COMMON /QSPLIT/QNHO,QNHL,QSHO,QSHL,QGLOBE(0:iTp), &
     QQNHO(0:iTp),QQNHL(0:iTp),QQSHO(0:iTp),QQSHL(0:iTp), &
     QQQNHO(0:iTp),QQQNHL(0:iTp),QQQSHO(0:iTp),QQQSHL(0:iTp), &
      EHistBC(iTp),EHistOC(iTp) ! Vars to store read-in BC-OC history.
!
      COMMON /ICE/T1990,G1990,SEN,SENG,SENA,ERRG,ERRA, &
     DMG,DMA,SENI,SENP,SENS,DSENI,DSENP,DSENS,ICE,MODEL, &
     NEWGSIC,IXG,VZERO,XG
!
      COMMON /AREAS/FNO,FNL,FSO,FSL
!
      COMMON /QADD/IQREAD,OrgIQREAD,JQFIRST,JQLAST,QEX(0:iTp),QEXNH(0:iTp), &
     QEXSH(0:iTp),QEXNHO(0:iTp),QEXNHL(0:iTp),QEXSHO(0:iTp), &
     QEXSHL(0:iTp),IOLDTZ
!
      COMMON /NSIM/NSIM,NCLIM,ISCENGEN,TEMEXP(2,40),IWNHOFF,IWSHOFF, &
     WTHRESH
!
      COMMON /JSTART/JSTART,FOSSHIST(0:236),QKYMAG(0:iTp),IGHG, &
     QCH4OZ,QFOC(0:iTp),ICO2CORR,TROZSENS
!
      COMMON /CORREN/CORREN1,CORREN2,CORREN3,CORREN4,CORREN
!
! sjs -- add storage for halocarbon variables
      COMMON /HALOF/QCF4_ar(0:iTp),QC2F6_ar(0:iTp),qSF6_ar(0:iTp), &
      Q125_ar(0:iTp),Q134A_ar(0:iTp), &
      Q143A_ar(0:iTp),Q227_ar(0:iTp),Q245_ar(0:iTp)

!sjs -- parameters that can be modified directly from ObjECTS
! Note need to add the appropriate model variables to a common block if they are not in one
! already so that they can be set via subroutine
	  REAL*4 aNewClimSens, aNewBTsoil, aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, aNewSO2dir1990, aNewSO2ind1990
      COMMON/NEWPARAMS/aNewClimSens, aNewBTsoil, DT2XUSER,aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, &
     					aNewSO2dir1990, aNewSO2ind1990
      DATA aNewClimSens/-1.0/,aNewBTsoil/-1.0/,aNewBTHumus/-1.0/
      DATA aNewDUSER/-1.0/,aNewFUSER/-1.0/,aNewBTGPP/-1.0/

!Store temperature values
      COMMON/STOREDVALS/ TEMUSER(iTp),QSO2SAVE(0:iTp+1),QDIRSAVE(0:iTp+1)

!  ********************************************************************
!
      CHARACTER*4 LEVEL(4)
!
      CHARACTER*7 MODNAME(0:10)
!
      character*20 mnem
      character*3  month(12)
!
      DATA (LEVEL(I),I=1,4) /' LOW',' MID','HIGH','USER'/
!
      DATA (MODNAME(I),I=0,10) /' MAGICC','   GFDL','  CSIRO', &
     ' HadCM3',' HadCM2',' ECHAM4','    CSM','    PCM', &
     'OAGCM 8','OAGCM 9','OAGCM 0'/
!
      data (month(i),i=1,12) /'Jan','Feb','Mar','Apr','May','Jun', &
                             'Jul','Aug','Sep','Oct','Nov','Dec'/
!
      JSTART=236
!
!  READ CO2 CONCENTRATION AND FOSSIL EMISSIONS HISTORIES
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/CO2HIST.IN',status='OLD')
      DO ICO2=0,JSTART
      READ(LUN,4445)IIII,COBS(ICO2),FOSSHIST(ICO2)
      END DO
      CLOSE(lun)
!
!  READ PARAMETERS FROM MAGUSER.CFG.
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGUSER.CFG',status='OLD')
!
        READ(LUN,4240) LEVCO2
        READ(LUN,4240) IFEED
        READ(LUN,4240) LEVSO4
        READ(LUN,4241) DT2XUSER
        READ(LUN,4241) YK
        READ(LUN,4240) IVARW
        READ(LUN,4240) MODEL
        READ(LUN,4240) KYRREF
        READ(LUN,4240) IY0
        READ(LUN,4240) LASTYEAR
        READ(LUN,4240) ITEMPRT
        READ(LUN,4240) ICE
        NONOFF=0
!
      close(lun)
!
      LASTMAX=1764+iTp
      IF(LASTYEAR.GT.LASTMAX)LASTYEAR=LASTMAX
!
!  ********************************************************************
!
!  READ PARAMETERS FROM MAGICE.CFG.
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGICE.CFG',status='OLD')
!
        READ(LUN,4240) NEWGSIC  ! SET = 1 TO USE NEW ALGORITHM
        READ(LUN,4241) VZERO
        READ(LUN,4241) XG
        READ(LUN,4240) IXG
        READ(LUN,4241) ASEN
!
      CLOSE(lun)
!
!  ********************************************************************
!
!  READ PARAMETERS FROM MAGGAS.CFG. ORDER OF PARAMETERS CHANGED
!   AND OTHER ITEMS ADDED IN SEPT 2000.
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGGAS.CFG',status='OLD')
!
        READ(LUN,4240) OVRWRITE
        READ(LUN,4241) DUSER
        READ(LUN,4241) FUSER
        READ(LUN,4241) BTGPP
        READ(LUN,4241) BTRESP
        READ(LUN,4241) BTHUM
        READ(LUN,4241) BTSOIL
        READ(LUN,4240) IMETH
        READ(LUN,4240) LEVCH4
        READ(LUN,4241) TCH4CON
        READ(LUN,4241) TAUINIT
        READ(LUN,4241) DELTAU
        READ(LUN,4241) TAUSOIL
        READ(LUN,4241) TAUSTRAT
        READ(LUN,4241) CMBAL
        READ(LUN,4241) DCMBAL
        READ(LUN,4241) TN2000
        READ(LUN,4241) CNBAL
        READ(LUN,4241) DCNBAL
        READ(LUN,4241) QQQN2O
        READ(LUN,4241) S90Duser
        READ(LUN,4241) S90Iuser
        READ(LUN,4241) S90Buser
        READ(LUN,4241) FOC90usr
        READ(LUN,4240) IFOC
        READ(LUN,4241) TROZSENS
        READ(LUN,4240) IO3FEED
        READ(LUN,4240) IHALOETC
        READ(LUN,4241) OZ00CH4
        READ(LUN,4241) OZCH4
        READ(LUN,4241) OZNOX
        READ(LUN,4241) OZCO
        READ(LUN,4241) OZVOC
        READ(LUN,4240) ICH4FEED
        IOLDOZ=0
!
      close(lun)

! Initiailize internal BC-OC vars
       aBCUnitForcing = 0
       aOCUnitForcing = 0
       aNewSO2dir1990 = 0
       aNewSO2ind1990 = 0
	
!
!   Call overrite subroutine after each file that may have parameters to overwrite
      call overrideParameters( )	! sjs

       IF ( FSO2_dir1990 .LT. 0) THEN
          S90Duser = FSO2_dir1990
	      S90Iuser = FSO2_ind1990
	   END IF

       IF ( FBC1990 .NE. 0) THEN
          FOC90usr = 0
	      S90Buser = 0
	   END IF

!
      IF(OVRWRITE.EQ.1)THEN
        LEVCO2=4
        LEVSO4=4
      ENDIF
!
!  NEW METHOD FOR CALCULATING CO2 OUTPUT PDF FROM INVERSE VERSION
!   OF MAGICC. XB=0.074 gives DUSER=1.1, BTGPP=0.015
!
      XB=BTSOIL
!      DUSER=1.8*EXP(-6.6551*XB)
!      BTGPP=0.03*EXP(-9.3669*XB)
!
      IF(IOLDOZ.EQ.1)THEN
         OZ00CH4 = 0.168
         OZCH4   = 6.2048
         OZNOX   = 0.17
         OZCO    = 0.0014
         OZVOC   = 0.0042
      ENDIF
!
      TAUOTHER=1.0/(1.0/TAUSOIL+1.0/TAUSTRAT)
!
      IF(IFEED.EQ.0)THEN
        BTGPP  = 0.0
        BTRESP = 0.0
        BTHUM  = 0.0
        BTSOIL = 0.0
      ENDIF
!
!  TRAP IN CASE LEV* MIS-SPECIFIED OUTSIDE PERMISSIBLE RANGE. IF SO, 
!   RE-SET TO BEST GUESS CASE.
!
      IF((LEVCO2.GT.4).OR.(LEVCH4.GT.4).OR.(LEVSO4.GT.4))THEN
        WRITE(8,115)
      ENDIF
!
      IF(LEVCO2.GT.4)LEVCO2=2
      IF(LEVCH4.GT.4)LEVCH4=2
      IF(LEVSO4.GT.4)LEVSO4=2
!
!  READ PARAMETERS FROM MAGMOD.CFG
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGMOD.CFG',status='OLD')
!
        READ(LUN,4241) ADJUST
        READ(LUN,4241) CO2DELQ
        READ(LUN,4241) RLO
        READ(LUN,4241) HM
        READ(LUN,4241) W0
        READ(LUN,4241) PI
        READ(LUN,4241) TW0NH
        READ(LUN,4241) TW0SH
        READ(LUN,4241) XKLO
        READ(LUN,4241) XKNS
        READ(LUN,4240) ICO2READ
        READ(LUN,4241) CO2SCALE
        READ(LUN,4240) IQREAD
        READ(LUN,4241) QOFFSET
        READ(LUN,4241) QFACTOR
!
      IF(NONOFF.EQ.1)ICO2READ=5
      IF(RLO.GT.2.0)THEN
        RLO=1.05+0.6228*EXP(-0.339*DT2XUSER)
      ENDIF
!
      close(lun)
!
!   Call overrite subroutine after each file that may have parameters to overwrite
      call overrideParameters( )	! sjs
!
      IF(IVARW.EQ.2)THEN
        TW0SH=TW0NH
        TW0=TW0NH
      ENDIF
!
!  'DEFAULT' (= AOGCM MEAN) ICE MELT PARAMETERS FOR MAGICC. NOTE
!    THAT T1990 IS NOT USED FOR THIS CASE.
!
      T1990    =  0.607
      G1990    =  2.14     ! CM
      SEN      =  0.0625   ! CM/YR-degC (GSIC)
      SENG     =  0.0110   ! CM/YR-degC (GREENLAND)
      SENA     = -0.0341   ! CM/YR-degC (ANTARCTICA)
      ERRG     =  1.896    ! GREENLAND
      ERRA     =  1.242    ! GREENLAND
!
!  ICE PARAMETERS COMMON TO ALL CASES
!
      DMG      =  0.005    ! CM/YR-degC
      DMA      =  0.008    ! CM/YR-degC
      SENI     =  0.025    ! CM/YR
      DSENI    =  0.025    ! CM/YR
      SENP     =  0.01136  ! CM/YR
      DSENP    =  0.01136  ! CM/YR
      SENS     =  0.0025   ! CM/YR
      DSENS    =  0.0025   ! CM/YR
!
!  IF MODEL.NE.0, THEN SELECT MODEL FROM 'LIBRARY' GIVEN BELOW.
!
      IF(MODEL.EQ.1)THEN
        CO2DELQ  =  5.352
        DT2XUSER =  4.20
        TW0NH    =  8.00
        YK       =  2.30
        RLO      =  1.20
        XKLO     =  1.00
        T1990    =  0.635
        G1990    =  1.5      ! CM
        SEN      =  0.0576   ! CM/YR-degC (GSIC)
        SENG     =  0.0121   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0177   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  1.879    ! GREENLAND
        ERRA     =  0.799    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.2)THEN
        CO2DELQ  =  4.977
        DT2XUSER =  3.70
        TW0NH    =  5.00
        YK       =  1.60
        RLO      =  1.20
        XKLO     =  1.00
        T1990    =  0.593
        G1990    =  2.2      ! CM
        SEN      =  0.0733   ! CM/YR-degC (GSIC)
        SENG     =  0.0157   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0373   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  2.042    ! GREENLAND
        ERRA     =  1.120    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.3)THEN
        CO2DELQ  =  5.396
        DT2XUSER =  3.00
        TW0NH    = 25.00
        YK       =  1.90
        RLO      =  1.40
        XKLO     =  0.50
        T1990    =  0.562
        G1990    =  2.1      ! CM
        SEN      =  0.0622   ! CM/YR-degC (GSIC)
        SENG     =  0.0085   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0354   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  1.443    ! GREENLAND
        ERRA     =  1.288    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.4)THEN
        CO2DELQ  =  5.006
        DT2XUSER =  2.50
        TW0NH    = 12.00
        YK       =  1.70
        RLO      =  1.40
        XKLO     =  0.50
        T1990    =  0.603
        G1990    =  2.7      ! CM
        SEN      =  0.0613   ! CM/YR-degC (GSIC)
        SENG     =  0.0096   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0214   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  1.441    ! GREENLAND
        ERRA     =  1.239    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.5)THEN
        CO2DELQ  =  5.482
        DT2XUSER =  2.60
        TW0NH    = 20.00
        YK       =  9.00
        RLO      =  1.40
        XKLO     =  0.50
        T1990    =  0.780
        G1990    =  2.7      ! CM
        SEN      =  0.0637   ! CM/YR-degC (GSIC)
        SENG     =  0.0029   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0478   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  1.153    ! GREENLAND
        ERRA     =  1.484    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.6)THEN
        CO2DELQ  =  5.194
        DT2XUSER =  1.90
        TW0NH    = 1000.00
        YK       =  2.30
        RLO      =  1.40
        XKLO     =  0.50
        T1990    =  0.567
        G1990    =  2.1      ! CM
        SEN      =  0.0608   ! CM/YR-degC (GSIC)
        SENG     =  0.0146   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0305   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  3.147    ! GREENLAND
        ERRA     =  1.143    ! GREENLAND
      ENDIF
!
      IF(MODEL.EQ.7)THEN
        CO2DELQ  =  5.194
        DT2XUSER =  1.70
        TW0NH    = 14.00
        YK       =  2.30
        RLO      =  1.40
        XKLO     =  0.50
        T1990    =  0.510
        G1990    =  1.7      ! CM
        SEN      =  0.0587   ! CM/YR-degC (GSIC)
        SENG     =  0.0136   ! CM/YR-degC (GREENLAND)
        SENA     = -0.0484   ! CM/YR-degC (ANTARCTICA)
        ERRG     =  2.165    ! GREENLAND
        ERRA     =  1.618    ! GREENLAND
      ENDIF
!
!  OVERWRITE GSIC SENSITIVITY
!
      SEN=ASEN*SEN
!
      IF(MODEL.NE.0)THEN
        TW0SH=TW0NH
        XKNS=XKLO
      ENDIF
!
!  ********************************************************************
!
!  READ PARAMETERS FROM MAGRUN.CFG
!  NOTE (051308): IDIS NOW DEFINED IN MAGUSER.CFG TO BE THE SAME
!   AS ITEMPRT. IDIS BELOW RELABELLED AS JDIS TO AVOID OVERWRITING.
!  052808: IDIS BACK TO BEING SPECIFIED HERE
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGRUN.CFG',status='OLD')
!
        READ(LUN,4240) ISCENGEN
        READ(LUN,4240) IDIS
!        READ(LUN,4240) JDIS
        READ(LUN,4240) KSTART
        READ(LUN,4240) ICO2CORR
        READ(LUN,4240) KEYDW
        READ(LUN,4240) IMAGTAR
        READ(LUN,4240) IPEAK
        READ(LUN,4241) DPEAK
        READ(LUN,4241) D2400
!
      close(lun)
!
!  ********************************************************************
!
!  READ PARAMETERS FROM MAGXTRA.CFG
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/MAGXTRA.CFG',status='OLD')
!
        READ(LUN,4240) IOLDTZ
        READ(LUN,4241) DT
        READ(LUN,4240) NOUT
        READ(LUN,4240) IEMPRT
        READ(LUN,4240) ICO2PRT
        READ(LUN,4240) ICONCPRT
        READ(LUN,4240) IQGASPRT
        READ(LUN,4241) TOFFSET
        READ(LUN,4241) STRATH2O
        READ(LUN,4241) ENAT
        READ(LUN,4240) IGHG
        READ(LUN,4241) BBCH4
        READ(LUN,4241) SCH4
        READ(LUN,4241) DELSS
        READ(LUN,4241) GAM
        READ(LUN,4241) ANOX
        READ(LUN,4241) DELANOX
        READ(LUN,4241) ACO
        READ(LUN,4241) DELACO
        READ(LUN,4241) AVOC
        READ(LUN,4241) DELAVOC
        READ(LUN,4240) NOOTHER
        READ(LUN,4241) BBN2O
        READ(LUN,4241) SN2O
        READ(LUN,4240) NOFFSET
        READ(LUN,4241) WTHRESH
        READ(LUN,4241) ES1990
        READ(LUN,4240) ICCSM
        IYRQALL=1990
!
      close(lun)
!
!   Call overrite subroutine after each file that may have parameters to overwrite
      call overrideParameters( ) !sjs

      IF(NOOTHER.EQ.1)THEN
        ANOX=0.0
        ACO=0.0
        AVOC=0.0
      ENDIF
!
!  ************************************************************
!
!  OPEN MAIN OUTPUT FILE (MAG.OUT).
!
   OPEN(UNIT=8,file='../cvs/objects/magicc/outputs/MAG.CSV',STATUS='UNKNOWN')
! sjs changed to .csv
      OPEN(UNIT=88,FILE='../cvs/objects/magicc/outputs/CCSM.TXT', STATUS='UNKNOWN')
!
!  INTERIM CORRECTION TO AVOID CRASH IF S90IND SET TO ZERO IN
!   MAGUSER.CFG
!
      IF(S90IND.EQ.0.0)S90IND=-0.0001
!
      XK=YK*3155.76
!
!  CO2 AND CH4 GAS CYCLE PARAMETERS ARE SELECTED IN DELTAQ.
!   SO4 AEROSOL LEVEL IS SET HERE.
!
      IF(LEVSO4.EQ.1)THEN      ! LOW
        S90DIR   = -0.2
        S90IND   = -0.3
        S90BIO   = -0.095
        FOC90    =  0.094
      ENDIF
      IF(LEVSO4.EQ.2)THEN      ! MID
        S90DIR   = -0.4
        S90IND   = -0.7
        S90BIO   =  0.025
        FOC90    =  0.244
      ENDIF
      IF(LEVSO4.EQ.3)THEN      ! HIGH
        S90DIR   = -0.6
        S90IND   = -1.1
        S90BIO   =  0.145
        FOC90    =  0.394
      ENDIF
      IF(LEVSO4.EQ.4)THEN      ! user
        S90DIR   = S90Duser
        S90IND   = S90Iuser
        S90BIO   = S90Buser
        FOC90    = FOC90usr
      ENDIF
!
!  READ IN HALOCARBON FORCINGS. FORCINGS ARE ZERO TO AND INCLUDING
!   1930 (1930-1940 FORCINGS ARE LINEARLY INTERPOLATED FROM ZERO IN
!   193O TO THE 1940 VALUE CALCULATED OFF LINE IN HALOSRES.FOR).
!  INPUT FILE ENDS IN IHALO1.
!  FORCING AFTER 2100 DETERMINED BY IHALOETC (EMS TO ZERO BY 2200 IF
!   IHALOETC=1, CONST AFTER 2100 IF IHALOETC=2).
!  CONST FORCING ASSUMED AFTER IHALO1.
!  FORCINGS ARE END OF YEAR VALUES.
!  QHALOS.IN FORCINGS ARE BROKEN DOWN INTO MONTREAL GASES, STRAT
!   OZONE, MAGICC KYOTO GASES (I.E., THE 8 MAJOR CONTRIBUTORS),
!   AND OTHER GASES (TWO CASES FOR LAST TWO DEPENDING ON IHALOETC).
!  FOR 1991+, QHALOS.IN ONLY GIVES FORCINGS FOR MONTREAL
!   GASES, OTHER GASES AND STRAT OZONE BECAUSE THE CODE
!   CALCULATES THE MAGICC-KYOTO COMPONENT.
!
!  FIRST INITIALIZE QCFC, QMONT, ETC. ARRAYS WITH ZEROES.
!
      DO JCFC=0,LASTYEAR-1764
        QCFC(JCFC)=0.0
        QMONT(JCFC)=0.0
        QOTHER(JCFC)=0.0
        QSTRATOZ(JCFC)=0.0
        QKYMAG(JCFC)=0.0
        CFC12(JCFC)=0.0
      END DO
!
      lun = 42   ! spare logical unit no.
      open(unit=lun,file='../cvs/objects/magicc/inputs/QHALOS.IN',status='OLD')
!
      READ(LUN,4446)IHALO1
      IF(IHALO1.GT.LASTYEAR)IHALO1=LASTYEAR
!
      READ(LUN,*)
      READ(LUN,*)
      READ(LUN,*)
!
      L0=1930-1765
      LAST=IHALO1-1764
!
!  READ QCFC INPUT ARRAY
!
      DO JCFC=L0+1,LAST
      IF(IHALOETC.EQ.2)THEN
        READ(LUN,4448)IYCFC,QMONT(JCFC),QSTRATOZ(JCFC),QKYMAG(JCFC), &
       QOTHER(JCFC),CFC12(JCFC)
      ELSE
        READ(LUN,4447)IYCFC,QMONT(JCFC),QSTRATOZ(JCFC),QKYMAG(JCFC), &
       QOTHER(JCFC),CFC12(JCFC)
      ENDIF
      END DO
!
      CLOSE(lun)
!
!  TAU FOR CH4 SOIL SINK CHANGED TO ACCORD WITH IPCC94 (160 yr).
!  SPECIFICATION OF TauSoil MOVED TO MAGEXTRA.CFG ON 1/10/97.
!
      IF(ISCENGEN.EQ.1)THEN
        NUMSIMS=20
      ELSE
        NUMSIMS=4
      ENDIF
!
!  SWITCH TO PRODUCE ONLY 1 SIMULATIONS.
!
      IF(ISCENGEN.EQ.9)NUMSIMS=1
!
      IXLAM=1
      IF(RLO.EQ.1.0) IXLAM=0
!
      IF(ICO2READ.GE.1)IMETH=0
!
      IF(DT.GT.1.0)DT=1.0
!
      QXX=CO2DELQ
      Q2X=QXX*ALOG(2.)
!
!   FO(I) AND FL(I) ARE N.H. AND S.H. OCEAN AND LAND FRACTIONS.
!
      FO(1)=1.0-FL(1)
      FO(2)=1.0-FL(2)
!
      FK=RHO*SPECHT*HTCONS/31.5576
!
!  TRAP TO CATCH AND OVERWRITE UNREALISTIC D80SIN
!
      IF(DUSER.LT.-0.5)THEN
        DOLD=DUSER
        DUSER=-0.5
        WRITE(8,808)DOLD,DUSER
      ENDIF
      IF(DUSER.GT.3.0)THEN
        DOLD=DUSER
        DUSER=3.0
        WRITE(8,809)DOLD,DUSER
      ENDIF
!
!  READ CO2 CONCS DIRECTLY FROM CO2INPUT.DAT IF ICO2READ=1,2,3,4
!
      IF(ICO2READ.GE.1.AND.ICO2READ.LE.4)THEN
        lun = 42   ! spare logical unit no.
        open(unit=lun,file='../cvs/objects/magicc/inputs/co2input.dat',status='OLD')
!
!  CO2INPUT.DAT MUST HAVE FIRST YEAR = 1990 AND MUST HAVE ANNUAL END
!   OF YEAR VALUES. FIRST LINE OF FILE GIVES LAST YEAR OF ARRAY.
!
        READ(lun,900)LCO2
        ILCO2=LCO2-1764
        DO JCO2=226,ILCO2
        READ(lun,902)JYEAR,XC(JCO2)
        END DO
!
!  IF LAST YEAR OF INPUT CO2 DATA LESS THAN LASTYEAR FILL OUT
!   ARRAY WITH CONSTANT CO2
!
        IF(LASTYEAR.GT.LCO2)THEN
          DO JCO2=ILCO2+1,LASTYEAR-1764
          XC(JCO2)=XC(ILCO2)
          END DO
        ENDIF
        close(lun)
      ENDIF
!
!  ************************************************************
!
!  READ EXTRA FORCING IF IQREAD=1 OR 2. IF IQREAD=1, FORCING
!   IN QEXTRA.IN IS ADDED TO ANTHROPOGENIC FORCING. IF IQREAD=2,
!   QEXTRA.IN FORCING IS USED ALONE. QEXTRA.IN HAS A FLAG (NCOLS)
!   TO TELL WHETHER THE DATA ARE GLOBAL (ONE Q COLUMN), HEMISPHERIC
!   (TWO Q COLUMNS, NH THEN SH) OR FOR ALL BOXES (FOUR Q COLUMNS,
!   IN ORDER NHO, NHL, SHO, SHL)
!
      IF(IQREAD.GE.1)THEN
        lun = 42   ! spare logical unit no.
        open(unit=lun,file='../cvs/objects/magicc/inputs/qextra.in',status='OLD')
!
        READ(LUN,900)NCOLS
        READ(lun,901)IQFIRST,IQLAST
        JQFIRST=IQFIRST-1764
!
!  TRAP IN CASE FIRST YEAR IS BEFORE 1765
!
        IF(JQFIRST.LT.1)THEN
          DO JQ=JQFIRST,0
          IF(NCOLS.EQ.1)READ(lun,902)JYEAR,QQQGL
          IF(NCOLS.EQ.2)READ(lun,903)JYEAR,QQQNH,QQQSH
          IF(NCOLS.EQ.4)READ(lun,904)JYEAR,QQQNHO,QQQNHL,QQQSHO,QQQSHL
          END DO
          JQFIRST=1
          IQFIRST=1765
        ENDIF
!
        JQLAST=IQLAST-1764
        DO JQ=JQFIRST,JQLAST
          IF(NCOLS.EQ.1)THEN
            READ(lun,902)JYEAR,QEX(JQ)
            QEXNHO(JQ)=(QEX(JQ)-QOFFSET)*QFACTOR
            QEXNHL(JQ)=(QEX(JQ)-QOFFSET)*QFACTOR
            QEXSHO(JQ)=(QEX(JQ)-QOFFSET)*QFACTOR
            QEXSHL(JQ)=(QEX(JQ)-QOFFSET)*QFACTOR
          ENDIF
          IF(NCOLS.EQ.2)THEN
            READ(lun,903)JYEAR,QEXNH(JQ),QEXSH(JQ)
            QEXNHO(JQ)=(QEXNH(JQ)-QOFFSET)*QFACTOR
            QEXNHL(JQ)=(QEXNH(JQ)-QOFFSET)*QFACTOR
            QEXSHO(JQ)=(QEXSH(JQ)-QOFFSET)*QFACTOR
            QEXSHL(JQ)=(QEXSH(JQ)-QOFFSET)*QFACTOR
          ENDIF
          IF(NCOLS.EQ.4)THEN
            READ(lun,904)JYEAR,QEXNHO(JQ),QEXNHL(JQ),QEXSHO(JQ), &
           QEXSHL(JQ)
            QEXNHO(JQ)=(QEXNHO(JQ)-QOFFSET)*QFACTOR
            QEXNHL(JQ)=(QEXNHL(JQ)-QOFFSET)*QFACTOR
            QEXSHO(JQ)=(QEXSHO(JQ)-QOFFSET)*QFACTOR
            QEXSHL(JQ)=(QEXSHL(JQ)-QOFFSET)*QFACTOR
          ENDIF
        END DO
        IF(NCOLS.EQ.1.OR.NCOLS.EQ.2)THEN
          QEXNH(JQFIRST-1)=QEXNH(JQFIRST)
          QEXSH(JQFIRST-1)=QEXSH(JQFIRST)
        ENDIF
        IF(NCOLS.EQ.4)THEN
          QEXNHO(JQFIRST-1)=QEXNHO(JQFIRST)
          QEXNHL(JQFIRST-1)=QEXNHL(JQFIRST)
          QEXSHO(JQFIRST-1)=QEXSHO(JQFIRST)
          QEXSHL(JQFIRST-1)=QEXSHL(JQFIRST)
        ENDIF
        close(lun)
      ELSE
        JQLAST=2100-1764
        DO JQ=1,JQLAST ! sjs
            QEXNHO(JQ)=0.0
            QEXNHL(JQ)=0.0
            QEXSHO(JQ)=0.0
            QEXSHL(JQ)=0.0
          END DO
      ! If QEXTRA was not read-in initialize arrays with zeros in case used for BCOC forcing
      ENDIF


!
!  ************************************************************
!
!  Read in historical BC and OC emissions and translate into
!  radiative forcing. Add to QXTRA forcing and set QEXTRA to be
!  true if not already. 
!
!  Emissions are read in as global values. sjs

! Store original value
      OrgIQREAD = IQREAD

! Read in BC emissions if IFOC is set to 3  
! and if IQREAD is NE 2 (which means only qextra should be used)
     IF( IFOC.GE.3 .AND. IQREAD.NE.2 )THEN

        lun = 42   ! spare logical unit no.
        open(unit=lun,file='../cvs/objects/magicc/inputs/BCOCHist.csv',status='OLD')
!
        READ(LUN,*)QtempBCUnitForcing
        READ(LUN,*)QtempOCUnitForcing

! Convert to W/m^2 per Gg
        QtempBCUnitForcing = QtempBCUnitForcing / 1000.
        QtempOCUnitForcing = QtempOCUnitForcing / 1000.
        
! Use default read-in values if have not been otherwise set.
        IF(aBCUnitForcing.EQ.0)THEN
           aBCUnitForcing   = QtempBCUnitForcing
        ENDIF
        
        IF(aOCUnitForcing.EQ.0)THEN
           aOCUnitForcing   = QtempOCUnitForcing
        ENDIF

        READ(lun,*)IQFIRST,IQLAST
        JQFIRST=IQFIRST-1764
!
!  TRAP IN CASE FIRST YEAR IS BEFORE 1765 with dummy read
!
        IF(JQFIRST.LT.1)THEN
          DO JQ=JQFIRST,0
             READ(lun,902)JYEAR,QQQGL
          END DO
          JQFIRST=1
          IQFIRST=1765
        ENDIF
!
        JQLAST=IQLAST-1764
        DO JQ=JQFIRST,JQLAST
            READ(lun,*)JYEAR,EHistBC(JQ),EHistOC(JQ)
        END DO
        
        close(lun)
        
        ! Flag to use QExtra forcing
        IQREAD = 1
        
        !Remove forcing from MAGICC internal calc if BCOC is read in
        S90BIO   = 0
        FOC90    = 0

      ENDIF
!
!  ******************************************************************
!
!  Read in gas emissions from GAS.EMK
!
      lun = 42   ! spare logical unit no.
!
      open(unit=lun,file='GAS.EMK',status='OLD')
!
!  READ HEADER AND NUMBER OR ROWS OF EMISIONS DATA FROM GAS.EMK
!
      read(lun,4243)  NVAL
      read(lun,'(a)') mnem
      read(lun,*) !   skip description
      read(lun,*) !   skip column headings
      read(lun,*) !   skip units
!
!  READ INPUT EMISSIONS DATA FROM GAS.EMK
!  SO2 EMISSIONS (BY REGION) MUST BE INPUT AS CHANGES FROM 1990.
!
	iReadNative = 0

	! Maintain code to read in original magicc input file format
    do i=1,NVAL
	  if ( iReadNative .EQ. 1 )THEN
        read(lun,4242) IY1(I),FOS(I),DEF(I),DCH4(I),DN2O(I), &
       DNOX(I),DVOC(I),DCO(I), &
       DSO21(I),DSO22(I),DSO23(I),DCF4(I),DC2F6(I),D125(I), &
        D134A(I),D143A(I),D227(I),D245(I),DSF6(I)
  	 END IF

! For objects, read in our csv format.
	 IF ( iReadNative .EQ. 0 )THEN
        read(lun,*) IY1(I),FOS(I),DEF(I),DCH4(I),DN2O(I), &
      DSO21(I),DSO22(I),DSO23(I),DCF4(I),DC2F6(I),D125(I), &
      D134A(I),D143A(I),D227(I),D245(I),DSF6(I), &
      DNOX(I),DVOC(I),DCO(I), DBC(I), DOC(I)  ! Change to match order of writeout -- this is different than magicc default - sjs
  	 END IF
 
	IF(i.eq.1) THEN !collect our 1990 values since MAGICC wants differences from 1990
	  ES1990 = DSO21(1) + DSO22(1) + DSO23(1) !global 1990 emissions
	  DSO211990 = DSO21(1) !regional 1990 emissions
	  DSO221990 = DSO22(1)
	  DSO231990 = DSO23(1)
	END IF

!
        DERROR=DPEAK
        FOS(I)=FOS(I)-DERROR
        IF(IY1(I).EQ.2000)ICORR=I
!
!  ADJUST SO2 EMISSIONS INPUT
!
    IF ( iReadNative .EQ. 1 )THEN ! Original MAGICC code
        DSO21(I)= DSO21(I)+ES1990
        DSO22(I)= DSO22(I)+ES1990
        DSO23(I)= DSO23(I)+ES1990
        DSO2(I) = DSO21(I)+DSO22(I)+DSO23(I)-2.0*ES1990
    END IF
!
    IF ( iReadNative .EQ. 0 )THEN 
		DSO21(I) = DSO21(I) - DSO211990 + ES1990 !where ES1990 is the MAGICC global 1990 emissions
		DSO22(I) = DSO22(I) - DSO221990 + ES1990 !note it is added in to all three regions...
		DSO23(I) = DSO23(I) - DSO231990 + ES1990
	
		DSO2(I) = DSO21(I)+DSO22(I)+DSO23(I)-2.0*ES1990 !but here correct for it in the global number
     END IF
     
     END DO
     close(lun)
!
!  TRAP TO CATCH INCONSISTENCY BETWEEN LASTYEAR FROM CFG FILE
!   AND LAST YEAR OF EMISSIONS INPUT OR MAX ARRAY SIZE
!
      IF(ICO2READ.EQ.0)THEN
        IF((LASTYEAR-1764).GT.iTp)LASTYEAR=iTp+1764
        IF(LASTYEAR.GT.IY1(NVAL)) LASTYEAR=IY1(NVAL)
      ENDIF
      IYEND = LASTYEAR
      KEND  = IYEND-1764
      KREF  = KYRREF-1764
      TEND  = FLOAT(KEND-1)
!
!  Offset IY1 entries from 1990 : i.e., make IY1(1)=0,
!   IY1(2)=IY1(2)-1990, etc.
!
      do i=1,NVAL
        IY1(i) = IY1(i) - 1990
      end do
!
! INITIAL (1990) METHANE VALUES: EMISS (LO, MID, HI OR CON) IS THE
!  'CORRECT' 1990 VALUE CALCULATED TO BE CONSISTENT WITH THE
!  CORRESPONDING VALUE OF THE 1990 CH4 TAU. IN GENERAL, EMISS
!  WILL BE INCONSISTENT WITH THE 1990 INPUT VALUE. THIS IS CORRECTED
!  BY OFFSETTING ALL INPUT VALUES BY THE 1990 'ERROR'. SINCE
!  THIS ERROR DEPENDS ON TAU, DIFFERENT OFFSETS MUST BE CALCULATED FOR
!  EACH 1990 TAU VALUE.
! Note that C and dC/dt must be for mid 1990. VALUES CORRECTED TO
!  AGREE WITH IPCC SAR ON 1/10/98. HISTORY CORRECTED TOO.
!
! CHANGED TO BALANCE BUDGET IN 2000 FOR TAR (SEPT 2000). BALANCE
!  NUMBERS NOW SPECIFIED IN MAGXTRA.CFG
!
      TTLO    = TAUINIT-DELTAU
      TTMID   = TAUINIT
      TTHI    = TAUINIT+DELTAU
      TTCON   = TCH4CON
!
      CBAL=CMBAL
      DCDT=DCMBAL
!
      EMISSLO  = BBCH4*(DCDT +CBAL/TTLO  +CBAL/TAUOTHER)
      EMISSMID = BBCH4*(DCDT +CBAL/TTMID +CBAL/TAUOTHER)
      EMISSHI  = BBCH4*(DCDT +CBAL/TTHI  +CBAL/TAUOTHER)
      EMISSCON = BBCH4*(DCDT +CBAL/TTCON +CBAL/TAUOTHER)
!
! INITIAL (2000) N2O VALUE: FOLLOWS CH4 CASE, BUT THERE IS ONLY ONE
!  CORRECTION FACTOR (emissN). THIS IS CALCULATED to be consistent
!  with TN2000. Note that C and dC/dt must be for mid 2000.
!
      CBAL=CNBAL
      DCDT=DCNBAL
!
      EMISSN   = BBN2O*(DCDT +CBAL/TN2000)
!
!  ADD (OR SUBTRACT) CONSTANT TO ALL CH4 AND N2O EMISSIONS TO GIVE
!   1990 VALUE CONSISTENT WITH LIFETIME, CONC AND DC/DT.
!  FOR CH4, ONLY THE CORRECTION FOR THE USER-SPECIFIED 1990 LIFETIME
!   IS APPLIED (GIVEN BY THE CHOICE OF LEVCH4).
!
!  SPECIFY USER LIFETIME. NOTE, THIS IS RESPECIFIED IN DELTAQ.
!
      IF(LEVCH4.EQ.1) TTUSER = TTLO
      IF(LEVCH4.EQ.2) TTUSER = TTMID
      IF(LEVCH4.EQ.3) TTUSER = TTHI
      IF(LEVCH4.EQ.4) TTUSER = TTCON
!
!  NOTE : D*(2) MUST BE 2000 VALUE
!  THIS IS I=ICORR
!

      CORRMLO  = EMISSLO  - DCH4(ICORR)
      CORRMMID = EMISSMID - DCH4(ICORR)
      CORRMHI  = EMISSHI  - DCH4(ICORR)
      CORRMCON = EMISSCON - DCH4(ICORR)
!
      CORRN2O  = EMISSN   - DN2O(ICORR)
!
      IF(LEVCH4.EQ.1) CORRUSER = CORRMLO
      IF(LEVCH4.EQ.2) CORRUSER = CORRMMID
      IF(LEVCH4.EQ.3) CORRUSER = CORRMHI
      IF(LEVCH4.EQ.4) CORRUSER = CORRMCON
!
      do i=1,NVAL
        DCH4(I)=DCH4(I)+CORRUSER
        DN2O(I)=DN2O(I)+CORRN2O
      end do
!
!  ***************************************************************
!
      call interp(NVAL,226,IY1,fos,ef)
      call interp(NVAL,226,IY1,def,ednet)
      call interp(NVAL,226,IY1,DCH4,ECH4)
      call interp(NVAL,226,IY1,DN2O,EN2O)
      call interp(NVAL,226,IY1,DNOX,ENOX)
      call interp(NVAL,226,IY1,DVOC,EVOC)
      call interp(NVAL,226,IY1,DCO,ECO)
      ECO90=ECO(226)
!
!  NOTE, IF ESO2 WERE BEING INTERPOLATED, WOULD HAVE TO HAVE ESO2(226)
!   AS LAST ARGUMENT BECAUSE OF MISMATCH OF ESO2 AND Y ARRAYS IN MAIN
!   AND SUBROUTINE INTERP. THIS IS AVOIDED BY USING ESO2SUM.
!
      call interp(NVAL,226,IY1,dSO2,ESO2SUM)
      call interp(NVAL,226,IY1,dSO21,ESO21)
      call interp(NVAL,226,IY1,dSO22,ESO22)
      call interp(NVAL,226,IY1,dSO23,ESO23)
      call interp(NVAL,226,IY1,DCF4 ,ECF4 )
      call interp(NVAL,226,IY1,DC2F6,EC2F6)
      call interp(NVAL,226,IY1,D125 ,E125 )
      call interp(NVAL,226,IY1,D134A,E134A)
      call interp(NVAL,226,IY1,D143A,E143A)
      call interp(NVAL,226,IY1,D227 ,E227 )
      call interp(NVAL,226,IY1,D245 ,E245 )
      call interp(NVAL,226,IY1,DSF6 ,ESF6 )
      call interp(NVAL,226,IY1,DBC  ,EBC  )
      call interp(NVAL,226,IY1,DOC  ,EOC  )
!
!  SET ESO2 ARRAY
!
      DO KE=226,KEND
        ESO2(KE)=ESO2SUM(KE)
      END DO
!
!  FIRST PRINT OUTS TO MAG.OUT
!  PRINT OUT DATE HEADER
!
!      call getdat(myr,imon,iday)  ! sjs - comment out since not available on all platforms
	myr = 0
	imon = 0
	iday = 0

      write(8,87) mnem,iday,month(imon),myr
      write(88,87) mnem,iday,month(imon),myr
  87  format(' Emissions profile: ',a20,20x,' Date: ',i2,1x,a3,1x,i4,/)
!
!  PRINT OUT CO2, CH4 AND SO4 AEROSOL CHOICES (IN WORDS)
!
        WRITE(8,110) LEVEL(LEVCO2)
        IF(IFEED.EQ.0)WRITE(8,1100)
        IF(IFEED.EQ.1)WRITE(8,1101)
        IF(LEVCO2.EQ.4)WRITE(8,111) DUSER,FUSER
        IF(LEVCH4.LE.3) WRITE (8,112) LEVEL(LEVCH4)
        IF(LEVCH4.EQ.4) WRITE (8,113) TCH4CON
        WRITE(8,114) LEVEL(LEVSO4)
!
        WRITE(88,110) LEVEL(LEVCO2)
        IF(IFEED.EQ.0)WRITE(88,1100)
        IF(IFEED.EQ.1)WRITE(88,1101)
        IF(LEVCO2.EQ.4)WRITE(88,111) DUSER,FUSER
        IF(LEVCH4.LE.3) WRITE (88,112) LEVEL(LEVCH4)
        IF(LEVCH4.EQ.4) WRITE (88,113) TCH4CON
!
!  PRINT OUT HALOCARBON CHOICES
!
        IF(IO3FEED.EQ.0) WRITE(8,117)
        IF(IO3FEED.NE.0) WRITE(8,1171)
        IF(IHALOETC.EQ.2) WRITE(8,1181)
        IF(IHALOETC.NE.2) WRITE(8,118)
!
!  PRINT OUT CLIMATE MODEL SELECTED
!
        WRITE(8,116) MODNAME(MODEL)
!
!  PRINT OUT ICE MELT SELECTED (LOW, MID OR HIGH)
!
        IF(ICE.EQ.1)WRITE(8,1161)
        IF(ICE.EQ.2)WRITE(8,1162)
        IF(ICE.EQ.3)WRITE(8,1163)
!
      NCLIM=1
      CALL INIT
!
!  LINEARLY EXTRAPOLATE LAST ESO2 VALUES FOR ONE YEAR
!
      ESO2SUM(KEND+1) = 2.*ESO2SUM(KEND)-ESO2SUM(KEND-1)
      ESO21(KEND+1)   = 2.*ESO21(KEND)-ESO21(KEND-1)
      ESO22(KEND+1)   = 2.*ESO22(KEND)-ESO22(KEND-1)
      ESO23(KEND+1)   = 2.*ESO23(KEND)-ESO23(KEND-1)
      ESO2(KEND+1)    = ESO2SUM(KEND+1)
!
!  DEFINE ECO FOR J=1,225
!
      DO KC=1,225
        COE(KC)=ECO90*KC/226
      END DO
      DO KC=226,KEND
        COE(KC)=ECO(KC)
      END DO
!
!  WRITE OUT HEADER INFORMATION FOR MAG.OUT
!
!  SCALING FACTOR FOR CO2 FORCING :
!   (QTOT-Q1990)=(QCO2-QCO2.1990)*CO2SCALE
!
      SCAL=100.*(CO2SCALE-1.)
      IF(ICO2READ.EQ.1)WRITE(8,871)SCAL
      IF(ICO2READ.EQ.2)WRITE(8,872)
      IF(ICO2READ.EQ.3)WRITE(8,873)
!
      IF(IQREAD.EQ.0)WRITE(8,756)
      IF(OrgIQREAD.GE.1)THEN
        IF(NCOLS.EQ.1)WRITE(8,757)IQFIRST,IQLAST
        IF(NCOLS.EQ.2)WRITE(8,758)IQFIRST,IQLAST
        IF(NCOLS.EQ.4)WRITE(8,759)IQFIRST,IQLAST
        IF(QOFFSET.NE.0.0)WRITE(8,760)QOFFSET
        IF(QFACTOR.NE.1.0)WRITE(8,761)QFACTOR
      ENDIF
      IF(IQREAD.EQ.2)WRITE(8,762)
      
      IF ( IFOC.GE.3 ) THEN	! sjs
         WRITE(8,*) "ObjECTS Custom BC-OC forcing Used."
      ELSE
         WRITE(8,*) "MAGICC Internal BC-OC forcing Used."
      ENDIF
      
!
      WRITE (8,10) Q2X
!      WRITE (8,11) FO(1),FO(2),FL(1),FL(2)
!
      IF(S90DIR.EQ.0.0) write(8,*) 'DIRECT AEROSOL FORCING IGNORED'
      IF(ABS(S90DIR).GT.0.0) write(8,60)S90DIR
      IF(S90IND.EQ.0.0) write(8,*) 'INDIRECT AEROSOL FORCING IGNORED'
      IF(ABS(S90IND).GT.0.0) write(8,61)S90IND
      IF(S90BIO.EQ.0.0) write(8,*) 'BIOMASS AEROSOL FORCING IGNORED'
      IF(ABS(S90BIO).GT.0.0) write(8,62)S90BIO
      IF(FOC90.EQ.0.0) write(8,*) 'FOSSIL OB+BC AEROSOL FORCING', &
     ' IGNORED'
      IF(ABS(FOC90).GT.0.0) write(8,63)FOC90
      write(8,53)STRATH2O
!
!  ****************************************************************
!
!  Run model NUMSIMS times for different values of DT2X.
!    The input parameter ICEOPT determines what ice melt parameter
!    values are used in each case.
!
!  THE KEY FOR NSIM IS AS FOLLOWS (CASES 17-20 ADDED FEB 7, 1998) ...
!   NOTE : IF ISCENGEN=9, ONLY NSIM=1 IS RUN, BUT NCLIM IS SET TO 4.
!
!  NSIM  CLIM MODEL  EMISSIONS                     NESO2  NCLIM
!     1     LOW         ALL                          1      1
!     2     MID         ALL                          1      2
!     3    HIGH         ALL                          1      3
!     4    USER         ALL                          1      4
!     5     LOW         ESO2 = CONST AFTER 1990      2      1
!     6     MID         ESO2 = CONST AFTER 1990      2      2
!     7    HIGH         ESO2 = CONST AFTER 1990      2      3
!     8    USER         ESO2 = CONST AFTER 1990      2      4
!     9     LOW         ESO2 = ESO2(REGION 1)        3      1
!    10     MID         ESO2 = ESO2(REGION 1)        3      2
!    11    HIGH         ESO2 = ESO2(REGION 1)        3      3
!    12    USER         ESO2 = ESO2(REGION 1)        3      4
!    13     LOW         ESO2 = ESO2(REGION 2)        4      1
!    14     MID         ESO2 = ESO2(REGION 2)        4      2
!    15    HIGH         ESO2 = ESO2(REGION 2)        4      3
!    16    USER         ESO2 = ESO2(REGION 2)        4      4
!    17     LOW         ESO2 = ESO2(REGION 3)        5      1
!    18     MID         ESO2 = ESO2(REGION 3)        5      2
!    19    HIGH         ESO2 = ESO2(REGION 3)        5      3
!    20    USER         ESO2 = ESO2(REGION 3)        5      4
!
!  ALTERNATIVE WAY TO DO REGIONAL BREAKDOWN OF AEROSOL EFFECTS
!
!     9     LOW         ESO2 = ESO2(REG 1+2)         3      1
!    10     MID         ESO2 = ESO2(REG 1+2)         3      2
!    11    HIGH         ESO2 = ESO2(REG 1+2)         3      3
!    12    USER         ESO2 = ESO2(REG 1+2)         3      4
!    13     LOW         ESO2 = ESO2(REG 2+3)         4      1
!    14     MID         ESO2 = ESO2(REG 2+3)         4      2
!    15    HIGH         ESO2 = ESO2(REG 2+3)         4      3
!    16    USER         ESO2 = ESO2(REG 2+3)         4      4
!    17     LOW         ESO2 = ESO2(REG 3+1)         5      1
!    18     MID         ESO2 = ESO2(REG 3+1)         5      2
!    19    HIGH         ESO2 = ESO2(REG 3+1)         5      3
!    20    USER         ESO2 = ESO2(REG 3+1)         5      4
!
!  NOTE : NSIM=5-20 ONLY USED IF ISCENGEN=1 (I.E., USER PLANS TO
!    GO INTO SCENGEN AFTER MAGICC).
!
      DO 1 NSIM=1,NUMSIMS
      NESO2=1+INT((NSIM-0.1)/4.0)
      NCLIM=NSIM
!
!  RE-SET NCLIM FOR SULPHATE PATTERN WEIGHT CASES (NSIM.GE.5).
!
      IF(NSIM.GE.5)NCLIM=NSIM-4
      IF(NSIM.GE.9)NCLIM=NSIM-8
      IF(NSIM.GE.13)NCLIM=NSIM-12
      IF(NSIM.GE.17)NCLIM=NSIM-16
!
!  RE-SET NCLIM=4 (USER CASE) IF ONLY ONE SIMULATION (ISCENGEN=9).
!
      IF(ISCENGEN.EQ.9)NCLIM=4
!
!  ****************************************************************
!
      IF(NESO2.EQ.1)THEN
        DO KE=226,KEND+1
        ESO2(KE)=ESO2SUM(KE)
        END DO
      ENDIF
!
      IF(NESO2.EQ.2)THEN
        DO KE=226,KEND+1
        ESO2(KE)=ES1990
        END DO
      ENDIF
!
      IF(NESO2.EQ.3)THEN
        DO KE=226,KEND+1
        ESO2(KE)=ESO21(KE)
        END DO
      ENDIF
!
      IF(NESO2.EQ.4)THEN
        DO KE=226,KEND+1
        ESO2(KE)=ESO22(KE)
        END DO
      ENDIF
!
      IF(NESO2.EQ.5)THEN
        DO KE=226,KEND+1
        ESO2(KE)=ESO23(KE)
        END DO
      ENDIF
!
!  SET CLIMATE SENSITIVITY
!
      IF(NCLIM.EQ.1)TE=1.5        ! LOW
      IF(NCLIM.EQ.2)TE=3.0        ! MID
      IF(NCLIM.EQ.3)TE=6.0        ! HIGH
      IF(NCLIM.EQ.4)TE=DT2XUSER   ! USER
!
      IF(IXLAM.EQ.1)THEN
        CALL LAMCALC(Q2X,FL(1),FL(2),XKLO,XKNS,TE,RLO,XLAMO,XLAML)
      ENDIF
!
      XLAM=Q2X/TE
!
      CALL INIT
!
      IF(NESO2.EQ.1)THEN
        WRITE (8,179)
        WRITE (8,176) NSIM,TE
        WRITE (88,1761) TE
        IF(NESO2.EQ.1)WRITE(8,186)
        IF(NESO2.EQ.2)WRITE(8,187)
        IF(NESO2.EQ.3)WRITE(8,188)
        IF(NESO2.EQ.4)WRITE(8,189)
        IF(NESO2.EQ.5)WRITE(8,190)
        WRITE(8,1220)IVARW
        IF(IVARW.EQ.0)THEN
          WRITE (8,122)
        ENDIF
        IF(IVARW.EQ.1)THEN
          WRITE (8,123) TW0NH
          WRITE (8,124) TW0SH
          IF(KEYDW.EQ.1)WRITE (8,1231)
          IF(KEYDW.EQ.2)WRITE (8,1232)
          IF(KEYDW.EQ.3)WRITE (8,1233)
          IF(KEYDW.EQ.4)WRITE (8,1234)
          IF(KEYDW.EQ.5)WRITE (8,1235)
        ENDIF
        IF(IVARW.EQ.2)THEN
          WRITE (8,126) WTHRESH
          WRITE (8,127) TW0NH
          IF(KEYDW.EQ.1)WRITE (8,1231)
          IF(KEYDW.EQ.2)WRITE (8,1232)
          IF(KEYDW.EQ.3)WRITE (8,1233)
          IF(KEYDW.EQ.4)WRITE (8,1234)
          IF(KEYDW.EQ.5)WRITE (8,1235)
        ENDIF
        IF(IVARW.EQ.3)THEN
          WRITE (8,125)
        ENDIF
!
        WRITE (8,12) XKNS,XKLO
        WRITE (8,120) HM,YK
        WRITE (8,121) PI,W0
!
        IF(IXLAM.EQ.1)THEN
          WRITE(8,914) RLO,XLAML,XLAMO
          IF(XLAML.LT.0.0)WRITE(8,916)
        ELSE
          WRITE(8,915) XLAM
        ENDIF
      ENDIF
!
!  ***********************************************************
!
      CALL RUNMOD
!
!  EXTRA CALL TO RUNMOD TO GET FINAL FORCING VALUES FOR K=KEND
!   WHEN DT=1.0
!
!      IF((K.EQ.KEND).AND.(DT.EQ.1.0))CALL RUNMOD
!
!  SAVE SULPHATE AEROSOL FORCINGS IN FIRST PASS THROUGH OF NSIM
!   LOOP, WHEN TOTAL SO2 EMISSIONS ARE BEING USED.
!
      IF(NSIM.EQ.1)THEN
        DO K=1,KEND
          QSO2SAVE(K)=QSO2(K)
          QDIRSAVE(K)=QDIR(K)
        END DO
      ENDIF
!
!  PRINT OUT RESULTS
!
      DT1    = TGAV(226)-TGAV(116)
      DMSL1  = SLT(226)-SLT(116)
      DTNH1  = TNHAV(226)-TNHAV(116)
      DTSH1  = TSHAV(226)-TSHAV(116)
      DTLAND = TLAND(226)-TLAND(116)
      DTOCEAN= TOCEAN(226)-TOCEAN(116)
      DTNHO  = TNHO(226)-TNHO(116)
      DTSHO  = TSHO(226)-TSHO(116)
      DTNHL  = TNHL(226)-TNHL(116)
      DTSHL  = TSHL(226)-TSHL(116)
!
      IF(NESO2.EQ.1)THEN
        WRITE (8,140) DT1,DMSL1
        WRITE (8,141) DTNHL,DTNHO,DTSHL,DTSHO
        WRITE (8,142) DTNH1,DTSH1,DTLAND,DTOCEAN
        WRITE (8,15) KYRREF
        WRITE (8,16)
!
        IF(IVARW.GE.1)THEN
          WRITE(8,178)TE
        ELSE
          WRITE(8,177)TE
        ENDIF
!
        IF(NCLIM.EQ.1)WRITE(8,161)
        IF(NCLIM.EQ.2)WRITE(8,162)
        IF(NCLIM.EQ.3)WRITE(8,163)
        IF(NCLIM.EQ.4)WRITE(8,164)
!
        IF(NOUT.EQ.1)WRITE(8,171)
        IF(NOUT.EQ.2)WRITE(8,172)
        IF(NOUT.EQ.3)WRITE(8,173)
        IF(NOUT.EQ.4)WRITE(8,174)
        IF(NOUT.EQ.5)THEN
          WRITE(8,175)
        ENDIF
!
!  PRINTOUT OPTIONS
!
        IF(NOUT.EQ.1)THEN
          COL9   = TNHAV(226)
          COL10  = TSHAV(226)
        ENDIF
        IF(NOUT.EQ.2.OR.NOUT.EQ.5)THEN
          COL9   = TLAND(226)
          COL10  = TOCEAN(226)
          IF(COL10.NE.0.0)THEN
            COL11= COL9/COL10
          ELSE
            COL11= 9.999
          ENDIF
        ENDIF
        IF(NOUT.EQ.3.OR.NOUT.EQ.4)THEN
          COL9   = TEQU(226)-TGAV(226)
          COL10  = TDEEP(226)
        ENDIF
!
        TEOUT=TEQU(226)
!
!  THE METHOD FOR CALCULATING SLT SEEMS TO BE WRONG. IT ATTEMPTS TO
!   USE QUADRATURE FOR THE ERRORS IN INDIVIDUAL COMPONENTS, BUT DOES
!   NOT DO THIS CONSISTENTLY. SO IT IS BETTER TO SUM THE INDIVIDUAL
!   VALUES.
!
        SLT(226)=EX(226)+SLI(226)+SLG(226)+SLA(226)+SLO(226)         
        IF(NOUT.EQ.1)THEN
          SLICE=SLA(226)+SLG(226)
          SLRAW=SLT(226)-SLO(226)
          WRITE(8,181)QGLOBE(226),TEOUT,TGAV(226),EX(226),SLI(226), &
         SLG(226),SLA(226),SLO(226),SLT(226),COL9,COL10,WNH(226), &
         WSH(226),SLICE,SLRAW
        ENDIF
        IF(NOUT.EQ.2) THEN
          WRITE(8,182)QGLOBE(226),TEOUT,TGAV(226),EX(226),SLI(226), &
         SLG(226),SLA(226),SLO(226),SLT(226),COL9,COL10,COL11,WNH(226), &
         WSH(226)
        ENDIF
        IF(NOUT.EQ.3)THEN
          WRITE(8,183)QGLOBE(226),TEOUT,TGAV(226),EX(226),SLI(226), &
         SLG(226),SLA(226),SLO(226),SLT(226),COL9,COL10,WNH(226), &
         WSH(226)
        ENDIF
        IF(NOUT.EQ.4)THEN
!
!  CONVERT W/M**2 TO EQUIV CO2 RELATIVE TO END-1765 CO2 CONC
!
          EQUIVCO2=COBS(1)*EXP(QGLOBE(226)/QXX)
          WRITE(8,184)EQUIVCO2,TEOUT,TGAV(226),EX(226),SLI(226), &
         SLG(226),SLA(226),SLO(226),SLT(226),COL9,COL10,WNH(226), &
         WSH(226)
        ENDIF
        IF(NOUT.EQ.5)THEN
          WRITE(8,185)QGLOBE(226),TGAV(226),COL11,SLT(226),EX(226), &
         SLI(226),SLG(226),SLA(226),SLO(226),WNH(226)
        ENDIF
!
!  ****************************************************************
!
!  MAIN PRINT OUT LOOP
!
        TE1 = 0.
        TT1 = 0.
        TN1 = 0.
        TS1 = 0.
!
        QR    = QGLOBE(KREF)
        XPRT  = FLOAT(ITEMPRT)
        NPRT  = INT(225./XPRT +0.01)
        MPRT  = NPRT*ITEMPRT
        KYEAR0= 1990-MPRT
!
        TREFSUM=0.0
!
        DO 987 K=1,KEND
!
          KYEAR=1764+K
          QK = QGLOBE(K)
          Q1 = QK-QR
          TEQUIL = TEQU(K)
          TEQUIL0= TEQU(KREF)
!
          TE1 = TEQUIL-TEQUIL0
          TT1 = TGAV(K)-TGAV(KREF)
          TN1 = TNHAV(K)-TNHAV(KREF)
          TS1 = TSHAV(K)-TSHAV(KREF)
!
!  CALCULATE 1981-2000 MEAN TEMPERATURE AS REFERENCE LEVEL FOR
!   CALCULATION OF INPUT INTO SCENGEN DRIVER FILES.
!  NOTE : TREF DEPENDS ON CLIMATE MODEL PARAMS (I.E., ON NCLIM)
!
          IF(K.GE.217.AND.K.LE.236)TREFSUM=TREFSUM+TGAV(K)
          IF(K.EQ.236)TREF(NCLIM)=TREFSUM/20.
!
!  ******************************************************
!
!  PRINTOUT OPTIONS
!
          IF(NOUT.EQ.1)THEN
            COL9   = TN1
            COL10  = TS1
          ENDIF
!
          IF(NOUT.EQ.2.OR.NOUT.EQ.5)THEN
            COL9   = TLAND(K)-TLAND(KREF)
            COL10  = TOCEAN(K)-TOCEAN(KREF)
            IF(TOCEAN(K).NE.0.0)THEN
              COL11= TLAND(K)/TOCEAN(K)
            ELSE
              COL11= 9.999
            ENDIF
          ENDIF
!
          IF(NOUT.EQ.3.OR.NOUT.EQ.4)THEN
            COL9   = TE1-TT1
            COL10  = TDEEP(K)-TDEEP(KREF)
          ENDIF
!
          EX1=EX(K) -EX(KREF)
          SI1=SLI(K)-SLI(KREF)
          SG1=SLG(K)-SLG(KREF)
          SA1=SLA(K)-SLA(KREF)
          ST1=SLT(K)-SLT(KREF)
          SO1=SLO(K)-SLO(KREF)
          ST1=EX1+SI1+SG1+SA1+SO1 
!
!  PUT TEMPERATURE AND SEA LEVEL RESULTS FOR FULL GLOBAL FORCING
!   INTO DISPLAY OUTPUT FILES
!
          IF(ISCENGEN.NE.9)THEN
            IF(NSIM.EQ.1)THEN
              TEMLO(K)  = TT1
              SLLO(K)   = ST1
            ENDIF
          ENDIF
!
          IF(NSIM.EQ.2)THEN
            TEMMID(K) = TT1
            SLMID(K)  = ST1
          ENDIF
!
          IF(NSIM.EQ.3)THEN
            TEMHI(K)  = TT1
            SLHI(K)   = ST1
          ENDIF
!
          IF((ISCENGEN.EQ.9).OR.(NSIM.EQ.4))THEN
            TEMUSER(K)= TT1
            SLUSER(K) = ST1
          ENDIF
!
!  RESULTS FOR ESO2 CONST AFTER 1990 STORED ONLY FOR MID CLIMATE CASE.
!   ZERO VALUES STORED IF ISCENGEN=0 OR =9
!
          IF(ISCENGEN.EQ.0.OR.ISCENGEN.EQ.9)THEN
            TEMNOSO2(K)= 0.0
          ENDIF
!
          IF(NSIM.EQ.6)THEN
            TEMNOSO2(K)= TT1
          ENDIF
!
!  PRINT OUT FLAG IS KKKK=1
!
          KKKK=0
!
!  ALWAYS PRINT OUT 1765, IY0 AND 1990 VALUES
!
          IF(KYEAR.EQ.1764.OR.KYEAR.EQ.IY0.OR.KYEAR.EQ.1990)KKKK=1
!
          IF(KYEAR.GE.IY0)THEN
            PRIN=(KYEAR-KYEAR0+0.01)/XPRT
            BIT=PRIN-INT(PRIN)
            IF(PRIN.GT.0.0.AND.BIT.LT.0.02)KKKK=1
            IF(KKKK.EQ.1)THEN
!
!  ADD CONSTANT TO ALL TEMPS FOR IPCC DETEX TIME FIGURE
!
              TT1=TT1+TOFFSET
!
              IF(NOUT.EQ.1)THEN
                SLICE1=SG1+SA1
                SLRAW1=ST1-SO1
                WRITE (8,191) KYEAR,Q1,TE1,TT1,EX1,SI1,SG1,SA1,SO1,ST1, &
                COL9,COL10,WNH(K),WSH(K),KYEAR,SLICE1,SLRAW1
              ENDIF
!
              IF(NOUT.EQ.2)THEN
                WRITE (8,192) KYEAR,Q1,TE1,TT1,EX1,SI1,SG1,SA1,SO1,ST1, &
                COL9,COL10,COL11,WNH(K),WSH(K),KYEAR
              ENDIF
!
              IF(NOUT.EQ.3)THEN
                WRITE (8,193) KYEAR,Q1,TE1,TT1,EX1,SI1,SG1,SA1,SO1,ST1, &
                COL9,COL10,WNH(K),WSH(K),KYEAR
              ENDIF
!
              IF(NOUT.EQ.4)THEN
                EQUIVCO2=COBS(1)*EXP(QK/QXX)
                WRITE (8,194) KYEAR,EQUIVCO2,TE1,TT1,EX1,SI1,SG1,SA1, &
                SO1,ST1,COL9,COL10,WNH(K),WSH(K),KYEAR
              ENDIF
!
              IF(NOUT.EQ.5)THEN
                WRITE(8,195) KYEAR,Q1,TT1,COL11,ST1,EX1,SI1,SG1,SA1,SO1, &
                WNH(K),KYEAR
              ENDIF
!
            ENDIF
          ENDIF
 987  CONTINUE
!
          IF(NOUT.EQ.1)WRITE(8,171)
          IF(NOUT.EQ.2)WRITE(8,172)
          IF(NOUT.EQ.3)WRITE(8,173)
          IF(NOUT.EQ.4)WRITE(8,174)
          IF(NOUT.EQ.5)WRITE(8,175)
          WRITE(8,30)
      ENDIF
!
!  **************************************************************
!
!  DEFINE TEMPERATURE ARRAYS FOR WRITING TO SCENGEN DRIVER FILES.
!   ARRAY SUBSCRIPT NCLIM=1,2,3,4 CORRESPONDS TO LO, MID, HIGH
!   AND USER CLIMATE MODEL PARAMETER SETS.
!  NOTE THAT THESE ARRAYS START WITH KSG=1 IN 1990.
!
!  TSO21,2,3 ARE THE RAW TEMPERATURES IN RESPONSE TO REGIONAL
!   FORCING. THERE ARE AT LEAST TWO WAYS TO CALCULATE THESE.
!  ORIGINALLY (METHOD-1 = SAR VERSION OF SCENGEN) I COMPARED
!   GHG-ALONE RESULTS WITH (GHG) + (REGi EMISSIONS) RESULTS; THE
!   DIFFERENCE GIVING THE RESPONSE TO REGi EMISSIONS.
!  METHOD 2 IS TO COMPARE THE RESULTS FOR 'ALL' EMISSIONS WITH 
!   THOSE FOR .....
!   (ALL) MINUS (REGi EMISSIONS), WHICH EQUALS
!   (GHG)  + (REGj EMISSIONS) + (REGk EMISSIONS)
!   WHERE j AMD k DIFFER FROM i.
!  IN BOTH CASES THERE ARE INTERNAL INCONSISTENCIES BECAUSE OF THE
!   NONLINEAR RELATIONSHIP BETWEEN ESO2 AND INDIRECT AEROSOL FORCING.
!   IN OTHER WORDS, IN GENERAL, TALL MINUS TGHG WILL NOT EQUAL
!   TSO21+TSO22+TSO23.
!  TO CORRECT FOR THIS, I SCALE TSO2i (GIVING XSO2i) BY
!   (DIFF)/(SUM TSO2i) WHERE DIFF = TALL-TGHG.
!  THIS CORRECTION CAN BE A LITTLE ODD AT TIMES. FOR INSTANCE,
!   SUM TSO2i MAY CHANGE SIGN AT A DIFFERENT TIME FROM DIFF, LEADING
!   TO 'WILD' FLUCTUATIONS IN THE RATIO.
!
          DO K=197,KEND
        KSG=K-196
        KKYR=K+1764
!
        IF(NESO2.EQ.1)THEN
          TALL(NCLIM,KSG)=TGAV(K)
        ENDIF
!
        IF(NESO2.EQ.2)THEN
          TGHG(NCLIM,KSG)=TGAV(K)
        ENDIF
!
        IF(NESO2.EQ.3)TSO21(NCLIM,KSG)=TGAV(K)-TGHG(NCLIM,KSG)
        IF(NESO2.EQ.4)TSO22(NCLIM,KSG)=TGAV(K)-TGHG(NCLIM,KSG)
        IF(NESO2.EQ.5)TSO23(NCLIM,KSG)=TGAV(K)-TGHG(NCLIM,KSG)
!
        IF(KKYR.EQ.1990)THEN
          TALLREF =TALL(NCLIM,KSG)
          TGHGREF =TGHG(NCLIM,KSG)
          TSO21REF=TSO21(NCLIM,KSG)
          TSO22REF=TSO22(NCLIM,KSG)
          TSO23REF=TSO23(NCLIM,KSG)
        ENDIF
      END DO
!
      DO K=197,KEND
        KSG=K-196
        TALL(NCLIM,KSG)=TALL(NCLIM,KSG)-TALLREF
        TGHG(NCLIM,KSG)=TGHG(NCLIM,KSG)-TGHGREF
        TSO21(NCLIM,KSG)=TSO21(NCLIM,KSG)-TSO21REF
        TSO22(NCLIM,KSG)=TSO22(NCLIM,KSG)-TSO22REF
        TSO23(NCLIM,KSG)=TSO23(NCLIM,KSG)-TSO23REF
      END DO
!
!  **************************************************************
!
!  PRINT OUT EMISSIONS, CONCS AND FORCING DETAILS
!
!  PRINT OUT INPUT EMISSIONS
!
        IF(NESO2.EQ.1)THEN
          WRITE (8,30)
          WRITE (8,31)
          WRITE (8,30)
          WRITE (8,23)
          WRITE (8,231)
          WRITE (8,21)
!
!  PRINTOUT INTERVAL IS DET BY VALUE OF IEMPRT
!
          DO K=226,KEND,IEMPRT
            IYEAR=1764+K
            ES1=ESO21(K)-ES1990
            ES2=ESO22(K)-ES1990
            ES3=ESO23(K)-ES1990
            EST=ES1+ES2+ES3
            WRITE (8,222) IYEAR,EF(K),EDNET(K),ECH4(K),EN2O(K),ENOX(K), &
             EVOC(K),ECO(K),ES1,ES2,ES3,ECF4(K),EC2F6(K),E125(K), &
             E134A(K),E143A(K),E227(K),E245(K),ESF6(K),EST,EBC(K),EOC(K),IYEAR
          END DO
!
          WRITE (8,21)
          WRITE (8,30)
          WRITE (8,31)
          WRITE (8,30)
!
!  **************************************************************
!
!  PRINT OUT USER CARBON CYCLE DETAILS
!
          WRITE(8,24)
          WRITE(8,241)LEVCO2
          WRITE(8,800)R(1)
          WRITE(8,801)R(2)
          WRITE(8,802)R(3)
          WRITE(8,803)DUSER,R(4)
          WRITE(8,804)
          WRITE(8,805)
!
          if(iMeth.eq.1) then
            write(8,806)
          else
            write(8,807)
          endif
!
          WRITE(8,8071)
          MID=0
          IF(MID.NE.1)WRITE(8,810)
          IF(MID.EQ.1)WRITE(8,811)
          WRITE(8,812)
!
!  PRINTOUT INTERVAL IS DET BY VALUE OF ICO2PRT. NOTE THAT CARBON
!   CYCLE MODEL RESULTS GIVE RAW (UNCORRECTED) CO2 CONC OUTPUT.
!
          DO K=226,KEND,ICO2PRT
            IYEAR=1764+K
            CONCOUT=CCO2(LEVCO2,K)
            IF(MID.EQ.1)CONCOUT=(CCO2(LEVCO2,K-1)+CCO2(LEVCO2,K))/2.
!
            IF(IMETH.EQ.0)THEN
              TOTE=EF(K)+EDNET(K)
            ELSE
              TOTE=EF(K)+EDNET(K)+EMETH(K)
            ENDIF
!
            IF(TOTE.EQ.0.0)THEN
              IF(DELMASS(4,K).EQ.0.0)THEN
                ABX=1.0
              ELSE
                ABX=DELMASS(4,K)/ABS(DELMASS(4,K))
              ENDIF
              ABFRAC(4,K)=ABX*9.999
            ELSE
              ABFRAC(4,K)=DELMASS(4,K)/TOTE
            ENDIF
!
            IF(ABFRAC(4,K).GT.9.999)ABFRAC(4,K)=9.999
            IF(ABFRAC(4,K).LT.-9.999)ABFRAC(4,K)=-9.999
!
            ECH4OX=EMETH(K)
            IF(IMETH.EQ.0)ECH4OX=0.0
            WRITE(8,813)IYEAR,TOTE,EF(K),ECH4OX,EDNET(K),EDGROSS(4,K), &
            FOC(4,K),ABFRAC(4,K),PL(4,K),HL(4,K),SOIL(4,K),CONCOUT, &
            DELMASS(4,K),IYEAR
!
          END DO
          WRITE(8,812)
!
!  **************************************************************
!
!  PRINT OUT CONCENTRATIONS
!
          WRITE (8,30)
          WRITE (8,31)
          WRITE (8,30)
          IF(KSTART.EQ.0)WRITE (8,20)
          IF(KSTART.EQ.1)WRITE (8,202)
          IF(KSTART.EQ.2)WRITE (8,203)
          WRITE (8,201)
          WRITE (8,210)
!
!  PRINTOUT INTERVAL IS DET BY VALUE OF ICONCPRT
!
         CO2(0) =CO2(1)
         CH4(0) =CH4(1)-0.4
         CN2O(0)=CN2O(1)
!
         DO K=1,KEND,ICONCPRT
           IYEAR=1764+K
!
!  CONVERT END OF YEAR TO MIDYEAR CONCS
!
           CO2MID =(CO2(K)+CO2(K-1))/2.
           CH4MID =(CH4(K)+CH4(K-1))/2.
           CN2OMID=(CN2O(K)+CN2O(K-1))/2.
!
           IF(K.GE.226)THEN
!
             CH4LMID=(CH4L(K)+CH4L(K-1))/2.
             CH4BMID=(CH4B(K)+CH4B(K-1))/2.
             CH4HMID=(CH4H(K)+CH4H(K-1))/2.
!
             CO2LMID=(CCO2(1,K)+CCO2(1,K-1))/2.
             CO2BMID=(CCO2(2,K)+CCO2(2,K-1))/2.
             CO2HMID=(CCO2(3,K)+CCO2(3,K-1))/2.
!
!  ADD CORRECTIONS TO LO, MID, HI CO2 TO FIT OBSERVED DATA IN 2000
!
             IF(ICO2CORR.EQ.1)THEN
               CO2LMID=CO2LMID+CORREN1
               CO2BMID=CO2BMID+CORREN2
               CO2HMID=CO2HMID+CORREN3
             ENDIF
!
             IF(K.LE.236)THEN
               CO2LMID=CO2MID
               CO2BMID=CO2MID
               CO2HMID=CO2MID
             ENDIF
!
!  DEFINE LOW, MID AND HIGH CH4 VALUES OVER 1991 TO JSTART YEAR
!
             IF(K.LT.236)THEN
               CH4LMID=CH4MID
               CH4BMID=CH4MID
               CH4HMID=CH4MID
             ENDIF
!
!  SPECIFY METHANE LIFETIME OUTPUT
!
             IF(K.LE.236)THEN
               TOR=TTUSER
             ELSE
               TOR=TCH4(K)
             ENDIF
             IF(K.EQ.236)TORREF=TOR
!
!  IF KSTART SPECIFIED IN MAGRUN.CFG AS 1, OVERWRITE MIDYEAR
!   CONCENTRATION VALUES WITH START OR END YEAR VALUES (START IS
!   WHAT TAR USES, AT LEAST FOR NON-CO2 GASES).
!
             IF(KSTART.EQ.1)THEN
               CO2MID=CO2(K-1)
               CH4MID=CH4(K-1)
               CN2OMID=CN2O(K-1)
             ENDIF
!
             IF(KSTART.EQ.2)THEN
               CO2MID=CO2(K)
               CH4MID=CH4(K)
               CN2OMID=CN2O(K)
             ENDIF
!
             WRITE (8,220) IYEAR,CO2MID,CH4MID,CN2OMID, &
             ch4lMID,ch4bMID,ch4hMID, &
             CO2LMID,CO2BMID,CO2HMID,IYEAR,TOR
           ELSE
             WRITE (8,221) IYEAR,CO2MID,CH4MID,CN2OMID,IYEAR
           ENDIF
         END DO
!
         WRITE (8,210)
         WRITE (8,201)
!
!  **************************************************************
!
!  PRINT OUT TABLES OF DELTA-Q FROM IYRQALL AND 1765 TO MAG.OUT.
!  FIRST CALCULATE REFERENCE VALUES (MID IYRQALL)
!
         M00=IYRQALL-1764
         M01=M00-1
!
         QQQCO2R  = (qco2(M00)     +qco2(M01))     /2.
         QQQMR    = (QM(M00)       +QM(M01))       /2.
         QQQNR    = (QN(M00)       +QN(M01))       /2.
         QQQCFCR  = (QCFC(M00)     +QCFC(M01))     /2.
         QQQSO2R  = (QSO2SAVE(M00) +QSO2SAVE(M01)) /2.
         QQQDIRR  = (QDIRSAVE(M00) +QDIRSAVE(M01)) /2.
         QQQFOCR  = (QFOC(M00)     +QFOC(M01))     /2.
         QQQMNR   = (QMN(M00)      +QMN(M01))      /2.
!
! NOTE SPECIAL CASE FOR QOZ BECAUSE OF NONLINEAR CHANGE OVER 1990
!
         QQQOZR=(QOZ(M00)+QOZ(M01))/2.
         IF(IYRQALL.EQ.1990)QQQOZR=QOZ(M00)
!
         QQQLANDR = (QLAND(M00)    +QLAND(M01))     /2.
         QQQBIOR  = (QBIO(M00)     +QBIO(M01))     /2.
         QQQMO3R  = (QCH4O3(M00)   +QCH4O3(M01))   /2.
         QQRSTROZ = (QSTRATOZ(M00) +QSTRATOZ(M01)) /2.
         QQRKYMAG = (QKYMAG(M00)   +QKYMAG(M01))   /2.
         QQRMONT  = (QMONT(M00)    +QMONT(M01))    /2.
         QQROTHER = (QOTHER(M00)   +QOTHER(M01))   /2.
!
!   PRINT OUT DELTA-Q FROM MID 1990 TO MAG.OUT
!
         write(8,30)
         write(8,31)
         WRITE(8,30)
         write(8,55)IYRQALL
         write(8,56)
         write(8,561)
         write(8,5611)
         IF(IO3FEED.EQ.1)write(8,562)
         IF(IO3FEED.EQ.0)write(8,563)
         write(8,57)
!
!  PRINTOUT INTERVAL IS DET BY VALUE OF IQGASPRT
!
         DO K=1990,IYEND,IQGASPRT
           IYR = K-1990+226
           IYRP=IYR-1
! 
           DELQCO2 = (QCO2(IYR)+QCO2(IYRP))/2.-QQQCO2R
           DELQM   = (QM(IYR)+QM(IYRP))/2.    -QQQMR
           DELQN   = (QN(IYR)+QN(IYRP))/2.    -QQQNR
           DELQCFC = (QCFC(IYR)+QCFC(IYRP))/2.-QQQCFCR
!
!  NOTE : DELQSO2 AND DELQDIR BOTH INCLUDE QFOC
!
           DELQSO2 = (QSO2SAVE(IYR)+QSO2SAVE(IYRP))/2.-QQQSO2R
           DELQDIR = (QDIRSAVE(IYR)+QDIRSAVE(IYRP))/2.-QQQDIRR
           DELQIND = DELQSO2-DELQDIR
           DELQFOC = (QFOC(IYR)+QFOC(IYRP))/2.-QQQFOCR
           DELQD   = DELQDIR-DELQFOC
           DELQMN  = (QMN(IYR)+QMN(IYRP))/2.-QQQMNR
!
! NOTE SPECIAL CASE FOR QOZ BECAUSE OF NONLINEAR CHANGE OVER 1990
!
           IF(IYR.EQ.226)THEN
             QOZMID= QOZ(IYR)
           ELSE
             QOZMID= (QOZ(IYR)+QOZ(IYRP))/2.
           ENDIF
           DELQOZ  = QOZMID-QQQOZR
!
           DELQLAND= (QLAND(IYR)+QLAND(IYRP))/2.-QQQLANDR
           DELQBIO = (QBIO(IYR)+QBIO(IYRP))/2.-QQQBIOR
           DELQTOT = DELQCO2+DELQM+DELQN+DELQCFC+DELQSO2+DELQBIO &
           +DELQOZ+DELQLAND+DELQMN
!
           DQCH4O3 = (QCH4O3(IYR)+QCH4O3(IYRP))/2.-QQQMO3R
           DELQM   = DELQM-DQCH4O3
           DELQOZ  = DELQOZ+DQCH4O3
!
           DELSTROZ= (QSTRATOZ(IYR)+QSTRATOZ(IYRP))/2.-QQRSTROZ
           IF(IO3FEED.EQ.0)DELSTROZ=0.0
!
           DELKYMAG = (QKYMAG(IYR) +QKYMAG(IYRP))  /2.-QQRKYMAG
           DELMONT  = (QMONT(IYR)  +QMONT(IYRP))   /2.-QQRMONT
           DELOTHER = (QOTHER(IYR) +QOTHER(IYRP))  /2.-QQROTHER
           DELKYOTO = DELKYMAG+DELOTHER
!
           WRITE(8,571)K,DELQCO2,DELQM,DELQN,DELQCFC,DELQOZ, &
           DELQD,DELQIND,DELQBIO,DELQFOC,DELQMN,DELQLAND,DELQTOT, &
           K,DQCH4O3,DELSTROZ,DELMONT,DELKYOTO
         END DO
!
!  ************************************************************
!
!  SAVE ARRAYS FOR TROPOZ, STRATOZ, CFC12, C11EFF
!
        ALF11=0.000250
        ALF12=0.000320
      DO KK=1,IYEND-1764
        KKP=1
        IF(KK.GT.1)KKP=KK-1
        QQQCH4O3=(QCH4O3(KK)+QCH4O3(KKP))/2.
        QTROZ(KK)=QQQCH4O3+(QOZ(KK)+QOZ(KKP))/2.
        QSTROZ(KK)=(QSTRATOZ(KK)+QSTRATOZ(KKP))/2.
        QQQCFC=(QCFC(KK)+QCFC(KKP))/2.
        C11EFF(KK)=(QQQCFC-QSTROZ(KK)-CFC12(Kk)*ALF12)/ALF11
      END DO
!
!  ************************************************************
!
!  NOW PRINT OUT FORCING CHANGES FROM MID 1765.
!
         WRITE(8,57)
         write(8,30)
         write(8,31)
         WRITE(8,30)
         write(8,58)
         write(8,56)
         write(8,561)
         write(8,5611)
         IF(IO3FEED.EQ.1)write(8,562)
         IF(IO3FEED.EQ.0)write(8,563)
         write(8,573)
!
       DO K=1770,IYEND,IQGASPRT
         IYR = K-1990+226
         IYRP=IYR-1
!
         QQQSO2 = 0.0
         QQQDIR = 0.0
         IF(K.GT.1860)THEN
           QQQSO2 = (QSO2SAVE(IYR)+QSO2SAVE(IYRP))/2.
           QQQDIR = (QDIRSAVE(IYR)+QDIRSAVE(IYRP))/2.
         ENDIF
         QQQIND = QQQSO2-QQQDIR
! 
         QQQCO2 = (QCO2(IYR)+QCO2(IYRP))/2.
         QQQM   = (QM(IYR)+QM(IYRP))/2.
         QQQN   = (QN(IYR)+QN(IYRP))/2.
         QQQCFC = (QCFC(IYR)+QCFC(IYRP))/2.
         QQQOZ  = (QOZ(IYR)+QOZ(IYRP))/2.
         QQQFOC = (QFOC(IYR)+QFOC(IYRP))/2.
         QQQMN  = (QMN(IYR)+QMN(IYRP))/2.
!
! NOTE SPECIAL CASE FOR QOZ BECAUSE OF NONLINEAR CHANGE OVER 1990
!
         IF(IYR.EQ.226)QQQOZ=QOZ(IYR)
!
         QQQLAND= (QLAND(IYR)+QLAND(IYRP))/2.
         QQQBIO = (QBIO(IYR)+QBIO(IYRP))/2.
         QQQTOT = QQQCO2+QQQM+QQQN+QQQCFC+QQQSO2+QQQBIO+QQQOZ+QQQLAND &
         +QQQMN
!
         QQCH4O3= (QCH4O3(IYR)+QCH4O3(IYRP))/2.
         QQQM   = QQQM-QQCH4O3
         QQQOZ  = QQQOZ+QQCH4O3
         QQQD   = QQQDIR-QQQFOC
!
         QQQSTROZ= (QSTRATOZ(IYR)+QSTRATOZ(IYRP))/2.
         IF(IO3FEED.EQ.0)QQQSTROZ=0.0
!
         QQQKYMAG = (QKYMAG(IYR)+QKYMAG(IYRP))/2.
         QQQMONT  = (QMONT(IYR) +QMONT(IYRP)) /2.
         QQQOTHER = (QOTHER(IYR)+QOTHER(IYRP))/2.
         QQQKYOTO = QQQKYMAG+QQQOTHER
!
! Add BC, OC, and QExtra forcing to output. Note this is not included in foring total since is in QExtra instead
         QQQEXTRA = ( QEXNH(IYR)+QEXSH(IYR)+QEXNHO(IYR)+QEXNHL(IYR) + &
                      QEXNH(IYRP)+QEXSH(IYRP)+QEXNHO(IYRP)+QEXNHL(IYRP) )/2.
         QQQBC = ( QBC(IYR) + QBC(IYRP) )/2.
         QQQOC = ( QOC(IYR) + QOC(IYRP) )/2.

         WRITE(8,571)K,QQQCO2,QQQM,QQQN,QQQCFC,QQQOZ,QQQD,QQQIND, &
         QQQBIO,QQQFOC,QQQMN,QQQLAND,QQQTOT,K,QQCH4O3,QQQSTROZ,QQQMONT, &
         QQQKYOTO, QQQBC, QQQOC, QQQEXTRA
       END DO
!
       WRITE(8,573)


! *******************************************************************************************
! sjs -- write out halocarbon forcings separately as well
! *******************************************************************************************

! Calculate 1990 halocarbon forcings so these can be output
	QCF4_ar(226) = CF4(226) * ( QCF4_ar(227)/CF4(227) )
	QC2F6_ar(226) = C2F6(226) * ( QC2F6_ar(227)/C2F6(227) )
	qSF6_ar(226) = CSF6(226) * ( qSF6_ar(227)/CSF6(227) )

! Approximate to same 1989 forcing
	QCF4_ar(225) = QCF4_ar(226)
	QC2F6_ar(225) = QC2F6_ar(226)
	qSF6_ar(225) = qSF6_ar(226)

!
!

       write(8,30)
        write(8,31)
        WRITE(8,30)
        WRITE(8,*) "Halocarbon Emissions"
        WRITE(8,588)

        DO K=1990,IYEND,IQGASPRT
          IYR = K-1990+226
          IYRP=IYR-1
!
        WRITE(8,589)K,E245(IYR),E134A(IYR),E125(IYR),E227(IYR), &
      E143A(IYR),ECF4(IYR),EC2F6(IYR),ESF6(IYR)
         
      END DO

       write(8,30)
        write(8,31)
        WRITE(8,30)
        WRITE(8,*) "Halocarbon Concentrations"
        WRITE(8,588)

        DO K=1990,IYEND,IQGASPRT
          IYR = K-1990+226
          IYRP=IYR-1

        WRITE(8,589)K,C245(IYR),C134A(IYR),C125(IYR),C227(IYR), &
      C143A(IYR),CF4(IYR),C2F6(IYR),CSF6(IYR)
          
      END DO

       write(8,30)
        write(8,31)
        WRITE(8,30)
        WRITE(8,*) "Halocarbon Forcing"
        write(8,590)

        DO K=1990,IYEND,IQGASPRT
          IYR = K-1990+226
          IYRP=IYR-1

        WRITE(8,589)K, &
      Q245_ar(IYR),Q134A_ar(IYR),Q125_ar(IYR), &
      Q227_ar(IYR),Q143A_ar(IYR),QCF4_ar(IYR), &
      QC2F6_ar(IYR),qSF6_ar(IYR), QOTHER(IYR), &
      QMONT(IYR),QSTRATOZ(IYR),QMONT(IYR)+ &
      QKYMAG(IYR)+QOTHER(IYR)+QSTRATOZ(IYR), &
      QKYMAG(IYR)+QOTHER(IYR)


      END DO
      write(8,590)
        WRITE(8,30)
        WRITE(8,30)

 588  FORMAT (1X,'YEAR,HFC245,HFC134A,HFC125,HFC227,HFC143A,','CF4,C2F6,SF6,')
 590  FORMAT (1X,'YEAR,HFC245,HFC134A,HFC125,HFC227,HFC143A,','CF4,C2F6,SF6,Qother,QMont,QStratOz,HaloTot,','KyotoTot')
 589  FORMAT (1X,I5,',',15(e18.10,',')) 
		

! *******************************************************************************************
! End halocarbon write
! *******************************************************************************************

      ENDIF

!*******************************************************************
!*******************************************************************
!	minicam csv output mrj 4/26/00
!   revised for TAR vsn 5/03 mrj


!**** following code is from mag.csv (formerly mag.out) computations
        QQQCO2R  = (qco2(226)     +qco2(225))     /2.
        QQQMR    = (QM(226)       +QM(225))       /2.
        QQQNR    = (QN(226)       +QN(225))       /2.
        QQQCFCR  = (QCFC(226)     +QCFC(225))     /2.
        QQQSO2R  = (QSO2SAVE(226) +QSO2SAVE(225)) /2.
        QQQDIRR  = (QDIRSAVE(226) +QDIRSAVE(225)) /2.
        QQQFOCR  = (QFOC(226)     +QFOC(225))     /2.
        QQQOZR   = QOZ(226)
        QQQBIOR  = (QBIO(226)     +QBIO(225))     /2.
        QQQMO3R  = (QCH4O3(226)   +QCH4O3(225))   /2.
        QQRSTROZ = (QSTRATOZ(226) +QSTRATOZ(225)) /2.
        QQRKYMAG = (QKYMAG(226)   +QKYMAG(225))   /2.
        QQRMONT  = (QMONT(226)    +QMONT(225))    /2.
        QQROTHER = (QOTHER(226)   +QOTHER(225))   /2.
!*** end code block

	OPEN (UNIT=9, FILE='MAGOUT.CSV')

  100 FORMAT(I5,1H,,27(F15.5,1H,))

  101 FORMAT('Year,Temp,CO2Conc,CH4Conc,N2OConc,', &
     'FcCO2,FcCH4,FcN2O,FcHALOS,FcTROPO3,', &
     'FcSO4DIR,FcSO4IND,FcBIOAER,', &
     'FcTOTAL,FOSSCO2,NETDEFOR,CH4Em,N2OEm,SO2-REG1,SO2-REG2,SO2-REG3,', &
     'SeaLevel,FcKyoto,FcHFC,FcCFC+SF6,FcCH4H2O')

	WRITE(9,101)  !header row

        IIPRT=5	! sjs -- changed to 5 year interval in order to save more data points
        DO K=1990,IYEND,IIPRT
          IYR = K-1990+226
          IYRP=IYR-1

! code to pass these items to MiniCAM in Results array

	 MAGICCCResults(0,(K-1990)/IIPRT+1) = Float(K)
	 MAGICCCResults(1,(K-1990)/IIPRT+1) = TEMUSER(IYR)+TGAV(226)
	 MAGICCCResults(2,(K-1990)/IIPRT+1) = CO2(IYR)
	 MAGICCCResults(3,(K-1990)/IIPRT+1) = CH4(IYR)
	 MAGICCCResults(4,(K-1990)/IIPRT+1) = CN2O(IYR)
	 MAGICCCResults(5,(K-1990)/IIPRT+1) = getForcing( 1, K ) ! CO2
	 MAGICCCResults(6,(K-1990)/IIPRT+1) = getForcing( 2, K ) ! CH4 (no indirect components)
	 MAGICCCResults(7,(K-1990)/IIPRT+1) = getForcing( 3, K ) ! N2O
	 MAGICCCResults(8,(K-1990)/IIPRT+1) = & ! Halocarbon forcing
	    getForcing( 4, K ) + getForcing( 9, K ) + getForcing( 10, K ) + &! Long-lived F-gases
	    getForcing( 5, K ) + getForcing( 6, K ) + getForcing( 7, K ) + &
	    getForcing( 8, K ) + getForcing( 11, K ) + getForcing( 12, K ) ! Shorter-lived F-gases
	 MAGICCCResults(9,(K-1990)/IIPRT+1) = getForcing( 15, K ) !O3 including CH4 part
	 MAGICCCResults(10,(K-1990)/IIPRT+1) = getForcing( 14, K ) ! SO2 direct only
	 MAGICCCResults(11,(K-1990)/IIPRT+1) = getForcing( 13, K ) - getForcing( 14, K ) ! indirect only
	 MAGICCCResults(12,(K-1990)/IIPRT+1) = getForcing( 20, K ) ! biomas burning (MAGICC internal)
	 MAGICCCResults(13,(K-1990)/IIPRT+1) = getForcing( 0, K ) ! Total antro forcing
	 MAGICCCResults(14,(K-1990)/IIPRT+1) = EF(IYR)
	 MAGICCCResults(15,(K-1990)/IIPRT+1) = EDNET(IYR)
	 MAGICCCResults(16,(K-1990)/IIPRT+1) = ECH4(IYR)
	 MAGICCCResults(17,(K-1990)/IIPRT+1) = EN2O(IYR)
	 MAGICCCResults(18,(K-1990)/IIPRT+1) = ESO21(IYR)-ES1990
	 MAGICCCResults(19,(K-1990)/IIPRT+1) = ESO22(IYR)-ES1990
	 MAGICCCResults(20,(K-1990)/IIPRT+1) = ESO23(IYR)-ES1990
	 MAGICCCResults(21,(K-1990)/IIPRT+1) = getSLR( IYR )
	 MAGICCCResults(22,(K-1990)/IIPRT+1) = & !Kyoto Forcing
	    getForcing( 1, K ) + getForcing( 2, K )  + getForcing( 3, K ) + & ! CO2, CH4, and N2O
	    getForcing( 4, K ) + getForcing( 9, K ) + getForcing( 10, K ) + &! Long-lived F-gases
	    getForcing( 5, K ) + getForcing( 6, K ) + getForcing( 7, K ) + &
	    getForcing( 8, K ) + getForcing( 11, K ) + getForcing( 12, K ) ! Shorter-lived F-gases
	 MAGICCCResults(23,(K-1990)/IIPRT+1) = &
	    getForcing( 5, K ) + getForcing( 6, K ) + getForcing( 7, K ) + &
	    getForcing( 8, K ) + getForcing( 11, K ) + getForcing( 12, K ) ! Shorter-lived F-gases
	 MAGICCCResults(24,(K-1990)/IIPRT+1) = &
	    getForcing( 4, K ) + getForcing( 9, K ) + getForcing( 10, K ) ! Long-lived F-gases
	 MAGICCCResults(25,(K-1990)/IIPRT+1) = getForcing( 17, K )	! Strat H2O forcing from CH4
	 MAGICCCResults(26,(K-1990)/IIPRT+1) = getForcing( 24, K )	! BC forcing 
	 MAGICCCResults(27,(K-1990)/IIPRT+1) = getForcing( 25, K )	! OC forcing 

! now we can write stuff out

	   WRITE (9,100) K,MAGICCCResults(1:25,(K-1990)/IIPRT+1)

	END DO

	WRITE(9,*)
!     ******* END MINICAM OUTPUT ***
	CLOSE (9)
!
!
!  ***************************************************************
!
!  WRITE CONCENTRATIONS CONSISTENT WITH USER CLIMATE MODEL AND WITH
!   THE CORRESPONDING SET OF RESULTS IN THE MAG.OUT CONCS
!   DISPLAY FILE.
!
      IF(ISCENGEN.EQ.9.OR.NSIM.EQ.4)THEN
!
      open(unit=9,file='../cvs/objects/magicc/outputs/concs.dis',status='UNKNOWN')
!
        WRITE (9,211)
!
!  PRINTOUT INTERVAL FOR DISPLAY PURPOSES SET BY IDIS IN MAGEXTRA.CFG
!
        DO K=1,KEND,IDIS
!
!  CONVERT END OF YEAR TO MIDYEAR CONCS
!
          CO2MID =(CO2(K)+CO2(K-1))/2.
          CH4MID =(CH4(K)+CH4(K-1))/2.
          CN2OMID=(CN2O(K)+CN2O(K-1))/2.
!
          IYEAR=1764+K
!
          IF(K.GE.226)THEN
!
            CH4LMID=(CH4L(K)+CH4L(K-1))/2.
            CH4BMID=(CH4B(K)+CH4B(K-1))/2.
            CH4HMID=(CH4H(K)+CH4H(K-1))/2.
!
            CO2LMID=(CCO2(1,K)+CCO2(1,K-1))/2.
            CO2BMID=(CCO2(2,K)+CCO2(2,K-1))/2.
            CO2HMID=(CCO2(3,K)+CCO2(3,K-1))/2.
!
!  ADD CORRECTIONS TO LO, MID, HI CO2 TO FIT OBSERVED DATA IN 2000
!
            IF(ICO2CORR.EQ.1)THEN
              CO2LMID=CO2LMID+CORREN1
              CO2BMID=CO2BMID+CORREN2
              CO2HMID=CO2HMID+CORREN3
            ENDIF
!
            IF(K.LE.236)THEN
              CO2LMID=CO2MID
              CO2BMID=CO2MID
              CO2HMID=CO2MID
            ENDIF
!
!  DEFINE LOW, MID AND HIGH CH4 VALUES OVER 1991 TO JSTART YEAR
!
            IF(K.LT.236)THEN
              CH4LMID=CH4MID
              CH4BMID=CH4MID
              CH4HMID=CH4MID
            ENDIF
!
!  SPECIFY METHANE LIFETIME OUTPUT (CENTRAL VALUE)
!
            IF(K.LE.236)THEN
              TOR=TORREF
            ELSE
              TOR=TCH4(K)
            ENDIF
!
          ENDIF
!
          IF(IYEAR.LT.1990) &
           WRITE (9,223) IYEAR,CO2MID,CO2MID,CO2MID,CO2MID, &
           CH4MID,CH4MID,CH4MID,CH4MID,CN2OMID
          IF(IYEAR.GE.1990)THEN
            IF(IYEAR.LE.2000)THEN
              CO2LMID=CO2MID
              CO2BMID=CO2MID
              CO2HMID=CO2MID
            ENDIF
            WRITE (9,224) IYEAR,CO2MID,CO2LMID,CO2BMID,CO2HMID, &
           CH4MID,CH4LMID,CH4BMID,CH4HMID,CN2OMID,TOR
          ENDIF
!
        END DO
!
        WRITE (9,211)
!
      CLOSE(9)
!
!  ************************************************************
!
!  WRITE FORCING CHANGES FROM MID-1990 TO MAG DISPLAY FILE
!
      open(unit=9,file='../cvs/objects/magicc/outputs/forcings.dis',status='UNKNOWN')
!
        WRITE (9,57)
!
!  PRINTOUT INTERVAL FOR DISPLAY PURPOSES SET BY IDIS IN MAGEXTRA.CFG
!
        DO K=1990,IYEND,IDIS
          IYR = K-1990+226
          IYRP=IYR-1
!
          DELQCO2 = (QCO2(IYR)+QCO2(IYRP))/2.-QQQCO2R
          DELQM   = (QM(IYR)+QM(IYRP))/2.    -QQQMR
          DELQN   = (QN(IYR)+QN(IYRP))/2.    -QQQNR
          DELQCFC = (QCFC(IYR)+QCFC(IYRP))/2.-QQQCFCR
!
!  NOTE : DELQSO2 INCLUDES QFOC
!
          DELQSO2 = (QSO2SAVE(IYR)+QSO2SAVE(IYRP))/2.-QQQSO2R
          DELQDIR = (QDIRSAVE(IYR)+QDIRSAVE(IYRP))/2.-QQQDIRR
          DELQIND = DELQSO2-DELQDIR
          DELQFOC = (QFOC(IYR)+QFOC(IYRP))/2.-QQQFOCR
          DELQD   = DELQDIR-DELQFOC
!
! NOTE SPECIAL CASE FOR QOZ BECAUSE OF NONLINEAR CHANGE OVER 1990
!
          IF(IYR.EQ.226)THEN
            QOZMID= QOZ(IYR)
          ELSE
            QOZMID= (QOZ(IYR)+QOZ(IYRP))/2.
          ENDIF
          DELQOZ  = QOZMID-QQQOZR
!
          DELQMN  = (QMN(IYR)+QMN(IYRP))/2.-QQQMNR
          DELQLAND= (QLAND(IYR)+QLAND(IYRP))/2.-QQQLANDR
          DELQBIO = (QBIO(IYR)+QBIO(IYRP))/2.-QQQBIOR
          DELQTOT = DELQCO2+DELQM+DELQN+DELQCFC+DELQSO2+DELQBIO &
         +DELQOZ+DELQLAND+DELQMN
!
          DQCH4O3 = (QCH4O3(IYR)+QCH4O3(IYRP))/2.-QQQMO3R
          DELQM   = DELQM-DQCH4O3
          DELQOZ  = DELQOZ+DQCH4O3
          DELSTROZ= (QSTRATOZ(IYR)+QSTRATOZ(IYRP))/2.-QQRSTROZ
          IF(IO3FEED.EQ.0)DELSTROZ=0.0
!
          DELKYMAG = (QKYMAG(IYR) +QKYMAG(IYRP))  /2.-QQRKYMAG
          DELMONT  = (QMONT(IYR)  +QMONT(IYRP))   /2.-QQRMONT
          DELOTHER = (QOTHER(IYR) +QOTHER(IYRP))  /2.-QQROTHER
          DELKYOTO = DELKYMAG+DELOTHER
!
          WRITE(9,571)K,DELQCO2,DELQM,DELQN,DELQCFC,DELQOZ, &
         DELQD,DELQIND,DELQBIO,DELQFOC,DELQMN,DELQLAND,DELQTOT,K, &
         DQCH4O3,DELSTROZ,DELMONT,DELKYOTO
        END DO
!
        WRITE (9,57)
!
      CLOSE(9)
!
      ENDIF
!
!  **************************************************************
!
!  end of NSIM loop
!
  1   CONTINUE
!
!  **************************************************************
!
!  SCALE TEMPERATURES TO GET DRIVER TEMPERATURES, XSO2i. THIS IS IN
!   A LONG IF STATEMENT, BRACKETTED BY THE TRIPLE '******' LINES.
!
      IF(ISCENGEN.EQ.1)THEN
!
        DO 565 NCLIM=1,4
!
          DO K=197,KEND
            KSG=K-196
            iiiyr=ksg+1960
            XTSUM=TALL(NCLIM,KSG)-TGHG(NCLIM,KSG)
            YTSUM=TSO21(NCLIM,KSG)+TSO22(NCLIM,KSG)+TSO23(NCLIM,KSG)
!
            SCALER(K)=1.0
            IF(YTSUM.NE.0.0)THEN
              SCALER(K)=XTSUM/YTSUM
              IF(SCALER(K).GT.2.0)SCALER(K)=2.0
              IF(SCALER(K).LT.0.0)SCALER(K)=0.0
            ENDIF
            XGHG(NCLIM,KSG) =XGHG(NCLIM,KSG)*SCALER(K)
!
          END DO
!
!  SMOOTHED VERSION OF METHOD 1
!
          ISMOOTH=1
          IF(ISMOOTH.EQ.1)THEN
            DO K=200,KEND-3
              SS1=SCALER(K-3)
              SS2=SCALER(K-2)
              SS3=SCALER(K-1)
              SS4=SCALER(K-0)
              SS5=SCALER(K+1)
              SS6=SCALER(K+2)
              SS7=SCALER(K+3)
!              SCALAR(K)=SS1+SS7+6.0*(SS2+SS6)+15.0*(SS3+SS5)+20.0*SS4
!              SCALAR(K)=SCALAR(K)/64.0
              SCALAR(K)=SS1+SS7+SS2+SS6+SS3+SS5+SS4
              SCALAR(K)=SCALAR(K)/7.0
              KSG=K-196
                XSO21(NCLIM,KSG)=TSO21(NCLIM,KSG)*SCALAR(K)
                XSO22(NCLIM,KSG)=TSO22(NCLIM,KSG)*SCALAR(K)
                XSO23(NCLIM,KSG)=TSO23(NCLIM,KSG)*SCALAR(K)
            END DO
!
            DO K=197,199
              SCALAR(K)=SCALER(K)
            END DO
!
            DO K=KEND-2,KEND
              SCALAR(K)=SCALER(K)
            END DO
          ENDIF
!
 565    CONTINUE
!
!  **************************************************************
!
!  WRITE TEMPERATURES TO OLD AND NEW SCENGEN DRIVER FILES.
!   UNSCALED TEMPS GO TO OLD FILES, SCALED TEMPS TO NEW FILES.
!
        OPEN(UNIT=10,file='../cvs/objects/magicc/outputs/lodrive.raw' ,STATUS='UNKNOWN')
        OPEN(UNIT=11,file='../cvs/objects/magicc/outputs/middrive.raw',STATUS='UNKNOWN')
        OPEN(UNIT=12,file='../cvs/objects/magicc/outputs/hidrive.raw' ,STATUS='UNKNOWN')
        OPEN(UNIT=13,file='../cvs/objects/magicc/outputs/usrdrive.raw',STATUS='UNKNOWN')
!
        OPEN(UNIT=14,file='../cvs/objects/magicc/outputs/lodrive.out' ,STATUS='UNKNOWN')
        OPEN(UNIT=15,file='../cvs/objects/magicc/outputs/middrive.out',STATUS='UNKNOWN')
        OPEN(UNIT=16,file='../cvs/objects/magicc/outputs/hidrive.out' ,STATUS='UNKNOWN')
        OPEN(UNIT=17,file='../cvs/objects/magicc/outputs/usrdrive.out',STATUS='UNKNOWN')
!
        DO NCLIM=1,4
        KSGL=KEND-196
        DO KSG=1,KSGL
        KYY=KSG+1960
!
!  BECAUSE OF SMOOTHING, TSOij AND XSOij ARE NOT DEFINED FOR THE
!   LAST 3 YEARS OF THE RUN. WE THEREFORE DEFINE THEN BY LINEAR
!   EXTRAPOLATION.
!
        IF(KSG.EQ.KSGL-3)THEN
          DT21=(TSO21(NCLIM,KSG)-TSO21(NCLIM,KSG-3))/3.0
          DT22=(TSO22(NCLIM,KSG)-TSO22(NCLIM,KSG-3))/3.0
          DT23=(TSO23(NCLIM,KSG)-TSO23(NCLIM,KSG-3))/3.0
          DX21=(XSO21(NCLIM,KSG)-XSO21(NCLIM,KSG-3))/3.0
          DX22=(XSO22(NCLIM,KSG)-XSO22(NCLIM,KSG-3))/3.0
          DX23=(XSO23(NCLIM,KSG)-XSO23(NCLIM,KSG-3))/3.0
        ENDIF
        IF(KSG.GT.KSGL-3)THEN
          KKK=KSG-(KSGL-3)
          TSO21(NCLIM,KSG)=TSO21(NCLIM,KSGL-3)+KKK*DT21
          TSO22(NCLIM,KSG)=TSO22(NCLIM,KSGL-3)+KKK*DT22
          TSO23(NCLIM,KSG)=TSO23(NCLIM,KSGL-3)+KKK*DT23
          XSO21(NCLIM,KSG)=XSO21(NCLIM,KSGL-3)+KKK*DX21
          XSO22(NCLIM,KSG)=XSO22(NCLIM,KSGL-3)+KKK*DX22
          XSO23(NCLIM,KSG)=XSO23(NCLIM,KSGL-3)+KKK*DX23
        ENDIF  
        IF(NCLIM.EQ.1)THEN
          IF(KSG.EQ.1)THEN
            WRITE(10,937)mnem
            WRITE(10,930)
            WRITE(10,934)
            WRITE(10,936)TREF(NCLIM)
            WRITE(14,937)mnem
            WRITE(14,930)
            WRITE(14,934)
            WRITE(14,936)TREF(NCLIM)
          ENDIF
          WRITE(10,935)KYY,TGHG(NCLIM,KSG),TSO21(NCLIM,KSG), &
         TSO22(NCLIM,KSG),TSO23(NCLIM,KSG),TALL(NCLIM,KSG)
          WRITE(14,935)KYY,TGHG(NCLIM,KSG),XSO21(NCLIM,KSG), &
         XSO22(NCLIM,KSG),XSO23(NCLIM,KSG),TALL(NCLIM,KSG)
        ENDIF
!
        IF(NCLIM.EQ.2)THEN
          IF(KSG.EQ.1)THEN
            WRITE(11,937)mnem
            WRITE(11,931)
            WRITE(11,934)
            WRITE(11,936)TREF(NCLIM)
            WRITE(15,937)mnem
            WRITE(15,931)
            WRITE(15,934)
            WRITE(15,936)TREF(NCLIM)
          ENDIF
          WRITE(11,935)KYY,TGHG(NCLIM,KSG),TSO21(NCLIM,KSG), &
         TSO22(NCLIM,KSG),TSO23(NCLIM,KSG),TALL(NCLIM,KSG)
          WRITE(15,935)KYY,TGHG(NCLIM,KSG),XSO21(NCLIM,KSG), &
         XSO22(NCLIM,KSG),XSO23(NCLIM,KSG),TALL(NCLIM,KSG)
        ENDIF
!
        IF(NCLIM.EQ.3)THEN
          IF(KSG.EQ.1)THEN
            WRITE(12,937)mnem
            WRITE(12,932)
            WRITE(12,934)
            WRITE(12,936)TREF(NCLIM)
            WRITE(16,937)mnem
            WRITE(16,932)
            WRITE(16,934)
            WRITE(16,936)TREF(NCLIM)
          ENDIF
          WRITE(12,935)KYY,TGHG(NCLIM,KSG),TSO21(NCLIM,KSG), &
         TSO22(NCLIM,KSG),TSO23(NCLIM,KSG),TALL(NCLIM,KSG)
          WRITE(16,935)KYY,TGHG(NCLIM,KSG),XSO21(NCLIM,KSG), &
         XSO22(NCLIM,KSG),XSO23(NCLIM,KSG),TALL(NCLIM,KSG)
        ENDIF
!
        IF(NCLIM.EQ.4)THEN
          IF(KSG.EQ.1)THEN
            WRITE(13,937)mnem
            WRITE(13,933)
            WRITE(13,934)
            WRITE(13,936)TREF(NCLIM)
            WRITE(17,937)mnem
            WRITE(17,933)
            WRITE(17,934)
            WRITE(17,936)TREF(NCLIM)
          ENDIF
          WRITE(13,935)KYY,TGHG(NCLIM,KSG),TSO21(NCLIM,KSG), &
         TSO22(NCLIM,KSG),TSO23(NCLIM,KSG),TALL(NCLIM,KSG)
          WRITE(17,935)KYY,TGHG(NCLIM,KSG),XSO21(NCLIM,KSG), &
         XSO22(NCLIM,KSG),XSO23(NCLIM,KSG),TALL(NCLIM,KSG)
        ENDIF
!
        END DO
        END DO
!
        CLOSE(10)
        CLOSE(11)
        CLOSE(12)
        CLOSE(13)
        CLOSE(14)
        CLOSE(15)
        CLOSE(16)
        CLOSE(17)
!
      ENDIF
!
!  **************************************************************
!
!  WRITE TEMPERATURES TO MAG DISPLAY FILE. NOTE THAT APPROPRIATE
!   TEMP (AND SEA LEVEL) DATA ARE SAVED AT THE RIGHT POINTS IN THE
!   NSIM LOOP, SO THESE DISPLAY FILES CAN BE PRODUCED *OUTSIDE*
!   THE NSIM LOOP.
!
      open(unit=9,file='../cvs/objects/magicc/outputs/temps.dis',status='UNKNOWN')
!
        WRITE (9,213)
!
!  PRINTOUT INTERVAL FOR DISPLAY PURPOSES SET BY IDIS IN MAGEXTRA.CFG
!
        DO K=1,KEND,IDIS
          IYEAR=1764+K
          WRITE (9,226) IYEAR,TEMUSER(K),TEMLO(K),TEMMID(K), &
         TEMHI(K),TEMNOSO2(K)
        END DO
!
        WRITE (9,213)
!
      CLOSE(9)
!
!  **************************************************************
!
!  WRITE SEALEVEL CHANGES TO MAG DISPLAY FILE
!
      open(unit=9,file='../cvs/objects/magicc/outputs/sealev.dis',status='UNKNOWN')
!
        WRITE (9,214)
!
!  PRINTOUT INTERVAL FOR DISPLAY PURPOSES SET BY IDIS IN MAGEXTRA.CFG
!
        DO K=1,KEND,IDIS
          IYEAR=1764+K
            WRITE (9,227) IYEAR,SLUSER(K),SLLO(K),SLMID(K), &
           SLHI(K)
        END DO
!
        WRITE (9,214)
!
      CLOSE(9)
!
!  **************************************************************
!
!  WRITE EMISSIONS TO MAG DISPLAY FILE
!
      open(unit=9,file='../cvs/objects/magicc/outputs/emiss.dis',status='UNKNOWN')
!
        WRITE (9,212)
!
!  PRINTOUT INTERVAL FOR DISPLAY PURPOSES SET BY IDIS IN MAGEXTRA.CFG
!   NOTE THAT ESO2(K) IS OVERWRITTEN IN LAST LOOP OF CLIMATE MODEL
!   SIMULATIONS, BUT ESO2i(K) REMAIN AS INPUTTED.
!  FOR ESO2 DISPLAY, NEED TO SUBTRACT THE 1990 TOTAL VALUE FROM EACH
!   REGION THEN ADD THE REGIONAL 1990 VALUE. THE REGIONAL VALUES FROM
!   BEFORE WERE 37,28,10 TgSO4, SUMMING TO 75 TgSO4.
!
        DO K=1,225
          EESS1(K)=0.0
          EESS2(K)=0.0
          EESS3(K)=0.0
          EESST(K)=0.0
        END DO
! 
        DO K=226,KEND,IDIS
          IYEAR=1764+K
          EESS1(K)=ESO21(K)-ES1990*(1.0-37.0/75.0)
          EESS2(K)=ESO22(K)-ES1990*(1.0-28.0/75.0)
          EESS3(K)=ESO23(K)-ES1990*(1.0-10.0/75.0)
          EESST(K)=EESS1(K)+EESS2(K)+EESS3(K)
          WRITE (9,225) IYEAR,EF(K),EDNET(K),ECH4(K),EN2O(K), &
          EESS1(K),EESS2(K),EESS3(K),EESST(K)
        END DO
!
        WRITE (9,212)
!
      CLOSE(9)
!
!  ************************************************************
!
!  OPEN NEW OUTPUT FILE (FRACLEFT.OUT).
!
      OPEN(UNIT=888,FILE='../cvs/objects/magicc/outputs/FRACLEFT.OUT',STATUS='UNKNOWN')
!
!  FRACTION OF CO2 REMAINING IN ATMOSPHERE
!
      WRITE(888,887)
      EMTOT=300.0
!
      DO K=226,KEND
        EMTOT=EMTOT+EF(K)+EDNET(K)
        ATBIT=2.123*(CO2(K)-278.)
        FRACLEFT=ATBIT/EMTOT
        IIYY=K+1764
        WRITE(888,889)IIYY,ATBIT,EMTOT,FRACLEFT
      END DO
 887  FORMAT(/1X,'  YEAR    ATMASS    CUMEMS  FRACLEFT')
 889  FORMAT(1X,I6,2F10.3,F10.5)
!
!  **************************************************************
!
!  WRITE DATA TO CCSM FILE
!
      IF(ICCSM.EQ.1)THEN
        WRITE(88,883)
        WRITE(88,882)
        DO K=1,IYEND-1764
          KKYR=K+1764
!
!  CONVERT END OF YEAR TO MIDYEAR CONCS
!
          CO2MID =(CO2(K)+CO2(K-1))/2.
          CH4MID =(CH4(K)+CH4(K-1))/2.
          CN2OMID=(CN2O(K)+CN2O(K-1))/2.
          IF(K.LE.225)THEN
            XBC=0.0
            XOC=0.0
          ELSE
            XBC=EBC(K)
            XOC=EOC(K)
          ENDIF
          WRITE(88,881)KKYR,CO2MID,CH4MID,CN2OMID,CFC12(K),C11EFF(K), &
          QTROZ(K),QSTROZ(K),EESST(K),XBC,XOC,KKYR
        END DO
      ENDIF
!
 881  FORMAT(1X,I5,5F10.3,2F10.4,3F10.3,I9)
 882  FORMAT(/2X,'YEAR       CO2       CH4       N2O     CFC12', &
     '    C11EFF   QTROPOZ  QSTRATOZ      ESO2', &
     '        BC        OC     YEAR')
 883  FORMAT(/1X,'*** MIDYEAR CONCENTRATIONS : ESO2, BC & OC SET', &
     ' TO ZERO BEFORE 1990 ***')
!                  
!  **************************************************************
!  **************************************************************
!
!  FORMAT STATEMENTS
!
 10   FORMAT (/1X,'CO2-DOUBLING FORCING IN W/M**2 =',F6.3)
 11   FORMAT (1X,'FNHOC= ',F4.2,' * FSHOC= ',F4.2,' * FNHLAND= ',F4.2, &
     ' * FSHLAND= ',F4.2)
 110  FORMAT (1X,A4,' CONCENTRATION PROJECTION FOR CO2')
 1100 FORMAT (3X,'(CO2-CLIMATE FEEDBACK NOT INCLUDED)')
 1101 FORMAT (3X,'(CO2-CLIMATE FEEDBACK INCLUDED)')
 111  FORMAT (1X,'Dn(1980s) =',F6.3,' : Foc(1980s) =',F6.3)
 112  FORMAT (1X,A4,' CONCENTRATION PROJECTION FOR CH4')
 113  FORMAT (1X,'CH4 CONCS USE CONSTANT LIFETIME OF',F7.3,'YEARS')
 114  FORMAT (1X,A4,' 1990 FORCINGS FOR SO4 AEROSOL')
 115  FORMAT (1X,'LEVCO2, LEVCH4 AND/OR LEVSO4 WRONGLY SET > 4 :', &
     ' RESET AT 2')
 117  FORMAT (2X,'STRAT OZONE DEPLETION FEEDBACK OMITTED')
 1171 FORMAT (2X,'STRAT OZONE DEPLETION FEEDBACK INCLUDED')
 118  FORMAT (2X,'FOR HALOCARBONS NOT IN GAS.EMK,', &
     ' EMS DROP TO ZERO OVER 2100-2200')
 1181 FORMAT (2X,'FOR HALOCARBONS NOT IN GAS.EMK,', &
     ' EMS CONSTANT AFTER 2100')
 116  FORMAT (/1X,'CLIMATE MODEL SELECTED = ',A7)
 1161 FORMAT (1X,'USER ICE MELT = LOW')
 1162 FORMAT (1X,'USER ICE MELT = MID')
 1163 FORMAT (1X,'USER ICE MELT = HIGH')
 1164 FORMAT (1X,'TAR GSIC SENSITIVITY =',F8.4,' CM/YR-DEGC : VZERO =', &
     F5.1,'CM')
 12   FORMAT (1X,'XKNS=',F4.1,' : XKLO=',F4.1)
 120  FORMAT (1X,'HM=',F5.1,'M : XK=',F6.4,'CM**2/SEC')
 121  FORMAT (1X,'PI=',F6.4,' : INITIAL W=',F5.2,'M/YR',/)
 122  FORMAT (1X,'CONSTANT W CASE')
 1220 FORMAT (1X,'IVARW SET AT',I2)
 123  FORMAT (1X,'VARIABLE W : NH W = ZERO WHEN TEMPERATURE =',F6.2, &
     'degC')
 1231 FORMAT (1X,'FULL W SCALED WITH GLOBAL-MEAN TEMPERATURE',/)
 1232 FORMAT (1X,'FULL W SCALED WITH GLOBAL-MEAN OCEAN TEMPERATURE',/)
 1233 FORMAT (1X,'FULL W SCALED WITH HEMISPHERIC-MEAN OCEAN', &
     'TEMPERATURE',/)
 1234 FORMAT (1X,'ACTIVE W SCALED WITH GLOBAL-MEAN TEMPERATURE',/)
 1235 FORMAT (1X,'ACTIVE W SCALED WITH GLOBAL-MEAN OCEAN TEMPERATURE',/)
 124  FORMAT (1X,'VARIABLE W : SH W = ZERO WHEN TEMPERATURE =',F6.2, &
     'degC')
 125  FORMAT (1X,'VARIABLE W : NH AND SH W(t) SPECIFIED IN WINPUT.IN')
 126  FORMAT (1X,'PERMANENT THC SHUTDOWN AT W =',F6.2,'M/YR')
 127  FORMAT (1X,'W = ZERO WHEN TEMPERATURE =',F6.2, &
     'degC')
 140  FORMAT (/1X,'1880-1990 CHANGES : GLOBAL DTEMP =',F7.3, &
     ' :   DMSL =',F7.3)
 141  FORMAT (1X,'          DTNHL =',F7.3,' : DTNHO =',F7.3, &
     ' :  DTSHL =',f7.3,' :   DTSHO =',f7.3)
 142  FORMAT (1X,'           DTNH =',F7.3,' :  DTSH =',F7.3, &
     ' : DTLAND =',f7.3,' : DTOCEAN =',f7.3)
 15   FORMAT (/1X,'** TEMPERATURE AND SEA LEVEL CHANGES FROM',I5,' **')
 16   FORMAT (1X,'     (FIRST LINE GIVES 1765-1990 CHANGES : ', &
                      'ALL VALUES ARE MID-YEAR TO MID-YEAR)')
 161  FORMAT (/1X,'LOW CLIMATE AND SEA LEVEL MODEL PARAMETERS')
 162  FORMAT (/1X,'MID CLIMATE AND SEA LEVEL MODEL PARAMETERS')
 163  FORMAT (/1X,'HIGH CLIMATE AND SEA LEVEL MODEL PARAMETERS')
 164  FORMAT (/1X,'USER CLIMATE AND SEA LEVEL MODEL PARAMETERS')
 171  FORMAT (1X,' YEAR,DELTAQ, TEQU, TEMP, EXPN, GLAC,', &
      ' GREENL,ANTAR,Z-XTRA,MSLTOT, TNH, TSH, WNH, WSH,YEAR,', &
      '  GR+ANT,ZTOT-ZXTRA')
 172  FORMAT (1X,' YEAR,DELTAQ, TEQU, TEMP, EXPN, GLAC,', &
      ' GREENL,ANTAR, Z-XTRA, MSLTOT, TLAND,  TOCN, TL/TO,   WNH,   WSH,', &
      '  YEAR')
 173  FORMAT (1X,' YEAR,DELTAQ, TEQU, TEMP, EXPN, GLAC,', &
      ' GREENL,  ANTAR, Z-XTRA, MSLTOT, TEQ-T, TDEEP,   WNH,   WSH,  YEAR,')
 174  FORMAT (1X,' YEAR,EQVCO2, TEQU, TEMP, EXPN, GLAC,', &
      ' GREENL,ANTAR.Z-XTRA.MSLTOT.TEQ-T.TDEEP, WNH, WSH,YEAR,')
 175  FORMAT (1X,' YEAR,DELTAQ,   TEMP,TL/TO,MSLTOT, EXPN, GLAC,', &
      ' GREENL,ANTAR Z-XTRA, WNH,YEAR')
 176  FORMAT (/1X,'NSIM =',I3,' : DELT(2XCO2) =',F6.3,'DEGC')
1761  FORMAT (/1X,' DELT(2XCO2) =',F6.3,'DEGC')
 177  FORMAT (/1X,'DT2X =',F5.2,' : CONSTANT W')
 178  FORMAT (/1X,'DT2X =',F5.2,' : VARIABLE W')
 179  FORMAT (/1X,'*************************************************')
 181  FORMAT ('TO1990, ',e18.10,20(',',e18.10))
 182  FORMAT ('TO1990, ',e18.10,20(',',e18.10))
 183  FORMAT ('TO1990, ',e18.10,20(',',e18.10))
 184  FORMAT ('TO1990, ',e18.10,20(',',e18.10))
 185  FORMAT ('TO1990, ',e18.10,20(',',e18.10))
 186  FORMAT (1X,'FULL GLOBAL SO2 EMISSIONS',/)
 187  FORMAT (1X,'SO2 EMISSIONS CONSTANT AFTER 1990',/)
 188  FORMAT (1X,'REGION 1 SO2 EMISSIONS',/)
 189  FORMAT (1X,'REGION 2 SO2 EMISSIONS',/)
 190  FORMAT (1X,'REGION 3 SO2 EMISSIONS',/)
 191  FORMAT (1X,I5,',',e18.10,12(',',e18.10),',',I6,2(',',e18.10))
 192  FORMAT (1X,I5,',',e18.10,12(',',e18.10),',',I6)
 193  FORMAT (1X,I5,',',e18.10,11(',',e18.10),',',I6)
 194  FORMAT (1X,I5,',',e18.10,11(',',e18.10),',',I6)
 195  FORMAT (1X,I5,',',e18.10,8(',',e18.10),',',I6)
!
 20   FORMAT (1X,'*** CONCENTRATIONS (CO2,PPM : CH4,N2O,PPB) ***', &
     /1X,'*** MIDYEAR VALUES ***')
 202  FORMAT (1X,'*** CONCENTRATIONS (CO2,PPM : CH4,N2O,PPB) ***', &
     /1X,'*** START OF YEAR VALUES FOR YR.GE.1990 IN COLS 2,3,4 ***')
 203  FORMAT (1X,'*** CONCENTRATIONS (CO2,PPM : CH4,N2O,PPB) ***', &
     /1X,'*** END OF YEAR VALUES FOR YR.GE.1990 IN COLS 2,3,4 ***')
 201  FORMAT (5X,'<- USER MODEL CONCS ->', &
      '<------ CH4 & CO2 MID CONCS & RANGES ------->')
 21   FORMAT (1X,'YEAR,EFOSS,NETDEF,CH4,N2O,NOX,VOC,CO,SO2REG1,SO2REG2,SO2REG3,',&
                 'CF4,C2F6,HFC125,HFC134A,HFC143A,HFC227ea,HFC245ca,SF6,ESO2TOT,YEAR')
 210  FORMAT (1X,'YEAR      CO2     CH4    N2O', &
     '   CH4LO  CH4MID   CH4HI   CO2LO  CO2MID   CO2HI  YEAR', &
     ' TAUCH4')
 211  FORMAT (1X,'YEAR CO2USER   CO2LO  CO2MID   CO2HI', &
                ' CH4USER   CH4LO  CH4MID   CH4HI     N2O', &
     ' MIDTAUCH4')
 212  FORMAT (1X,'YEAR  FOSSCO2 NETDEFOR      CH4      N2O', &
     ' SO2-REG1 SO2-REG2 SO2-REG3   SO2-GL')
 213  FORMAT (1X,'YEAR  TEMUSER    TEMLO   TEMMID    TEMHI TEMNOSO2')
 214  FORMAT (1X,'YEAR  MSLUSER    MSLLO   MSLMID    MSLHI')
 220  FORMAT (1X,I4,',',e18.10,',',e18.10,7(',',e18.10),',',I6,',',e18.10)
 221  FORMAT (1X,I4,',',e18.10,',',e18.10,',',e18.10,',',',,,,,,',I6)
 222  FORMAT (1X,I4,',',21(e18.10,','),I6)
 223  FORMAT (1X,I4,9F8.1)
 224  FORMAT (1X,I4,9F8.1,F10.2)
 225  FORMAT (1X,I4,8F9.2)
 226  FORMAT (1X,I4,5F9.3)
 227  FORMAT (1X,I4,5F9.1)
 23   FORMAT (1X,'** INPUT EMISSIONS **')
 231  FORMAT (4X,'BALANCED EMISSIONS FOR CH4 & N2O : SO2 EMISSIONS', &
     ' RELATIVE TO 1990')
 24   FORMAT (1X,'** CARBON CYCLE DETAILS **')
 241  FORMAT (1X,'CONCENTRATIONS ARE UNCORRECTED MODEL OUTPUT', &
     ' : LEVCO2 =',I2)
! 25   FORMAT (1X,'FEEDBACKS ** TEMPERATURE * GPP :',F7.4,' * RESP :'
!     +,F7.4,' * LITT OXDN :',F7.4,'  **  FERTIL :',F7.4)
 28   FORMAT (1X,F8.1,7F8.2,4f8.1)
!
 30   FORMAT (1X,'  ')
 31   FORMAT (1X,'****************************************************')
 47   FORMAT (1X,'** DECADAL CONTRIBUTIONS TO', &
      ' GLOBAL RADIATIVE FORCING **')
 48   FORMAT (1X,'   (DELTA-Q in W/m**2 : PERCENTAGES IN BRACKETS : ', &
      'BASED ON END-OF-YEAR FORCING VALUES)')
!
 50   FORMAT (1X,'  INTERVAL')
 53   FORMAT (1X,'STRAT H2O FROM CH4 : DELQH2O/DELQCH4 =',F6.3)
 55   FORMAT (1X,'** GAS BY GAS DELTA-Q FROM',I5' : MIDYEAR VALUES **')
 56   FORMAT (1X,'(BASED ON MID-YEAR FORCING VALUES : QEXTRA', &
     ' NOT INCLUDED)')
 561  FORMAT (1X,'CH4tot INCLUDES STRATH2O : TROPO3 INCLUDES CH4', &
     ' COMPONENT')
5611  FORMAT (1X,'QAERMN IS THE SUM OF NITRATE AND MINERAL DUST', &
     ' AEROSOL FORCING')
 562  FORMAT (1X,'HALOtot INCLUDES STRAT O3')
 563  FORMAT (1X,'HALOtot (AND QTOTAL) DOES NOT INCLUDE STRAT O3')
 57   FORMAT (1X,'YEAR,CO2,CH4tot,N2O, HALOtot,','TROPOZ,SO4DIR,SO4IND,BIOAER,FOC+FBC,QAERMN,QLAND,',&
 	   ' TOTAL, YEAR,CH4-O3,',&
 		' STRATO3, MONTDIR,QKYOTO')
 573   FORMAT (1X,'YEAR,CO2,CH4tot,N2O, HALOtot,','TROPOZ,SO4DIR,SO4IND,BIOAER,FOC+FBC,QAERMN,QLAND,',&
 	   ' TOTAL, YEAR,CH4-O3,',&
 		' STRATO3, MONTDIR,QKYOTO,BC,OC,QEXTRA')
 571  FORMAT (1X,I4,12(',',e18.10),',',I4,10(',',e18.10))
 58   FORMAT (1X,'** GAS BY GAS DELTA-Q FROM 1765 : MIDYEAR VALUES **')
!
 60   FORMAT (1X,'1990 DIRECT AEROSOL FORCING          =',F6.3,'W/m**2')
 61   FORMAT (1X,'1990 INDIRECT AEROSOL FORCING        =',F6.3,'W/m**2')
 62   FORMAT (1X,'1990 BIOMASS AEROSOL FORCING         =',F6.3,'W/m**2')
 63   FORMAT (1X,'1990 FOSSIL ORG C + BLACK C FORCING  =',F6.3,'W/m**2')
!
 756  FORMAT (/1X,'NO EXTRA FORCING ADDED')
 757  FORMAT (/1X,'EXTRA GLOBAL MEAN FORCING ADDED FROM', &
     ' QEXTRA.IN OVER',I5,' TO',I5,' INCLUSIVE')
 758  FORMAT (/1X,'EXTRA HEMISPHERIC FORCINGS ADDED FROM', &
     ' QEXTRA.IN OVER',I5,' TO',I5,' INCLUSIVE')
 759  FORMAT (/1X,'EXTRA NHO, NHL, SHO, SHL FORCINGS ADDED FROM', &
     ' QEXTRA.IN OVER',I5,' TO',I5,' INCLUSIVE')
 760  FORMAT (2X,F10.3,' W/m**2 SUBTRACTED FROM ALL VALUES')
 761  FORMAT (2X,'FORCING SCALED BY',F7.3,' AFTER OFFSET')
 762  FORMAT (/1X,'QEXTRA FORCING USED ALONE')
!
 800  FORMAT (1X,'LOW CONC CASE  : NETDEF(80s) = 1.80GtC/yr', &
     ' : GIFFORD FERTILIZATION FACTOR =',F6.3)
 801  FORMAT (1X,'MID CONC CASE  : NETDEF(80s) = 1.10GtC/yr', &
     ' : GIFFORD FERTILIZATION FACTOR =',F6.3)
 802  FORMAT (1X,'HIGH CONC CASE : NETDEF(80s) = 0.40GtC/yr', &
     ' : GIFFORD FERTILIZATION FACTOR =',F6.3)
 803  FORMAT (1X,'USER CONC CASE : NETDEF(80s) =',F5.2, &
     'GtC/yr : GIFFORD FERTILIZATION FACTOR =',F6.3)
 804  FORMAT (/1X,'ALL CASES USE 1980s MEAN OCEAN FLUX OF 2.0GtC/yr')
 805  FORMAT (1X,'DETAILED CARBON CYCLE OUTPUT IS FOR LEVCO2 CASE ONLY')
 806  FORMAT (1X,'METHANE OXIDATION TERM INCLUDED IN EMISSIONS')
 807  FORMAT (1X,'METHANE OXIDATION TERM NOT INCLUDED IN EMISSIONS')
 8071 FORMAT (1X,'NOTE: CORRECTION TO MATCH OBSERVED IN 2000 NOT', &
     ' APPLIED IN THIS SECTION')
 808  FORMAT (/1X,'*** ERROR : D80SIN SET TOO LOW AT',F7.3, &
     ' : RESET AT'F7.3,' ***')
 809  FORMAT (/1X,'*** ERROR : D80SIN SET TOO HIGH AT',F7.3, &
     ' : RESET AT'F7.3,' ***')
 810  FORMAT (/77X,'ENDYEAR')
 811  FORMAT (/77X,'MIDYEAR')
 812  FORMAT (1X,'YEAR, ETOTAL,  EFOSS, CH4OXN,   NETD, GROSSD,  OFLUX,',' ABFRAC, PLANT C, HLITT,    SOIL,',&
 '    CONC,  DEL-M,  YEAR') 
 813  FORMAT (1X,I4,',',e18.10,11(',',e18.10),',',I6)
!
 871  FORMAT (/1X,'CO2 CONC INPUT OVERWRITES CO2 EMISSIONS :', &
     ' POST-1990 CO2 FORCING SCALED UP BY',f5.1,'%')
 872  FORMAT (/1X,'CO2 CONC INPUT OVERWRITES CO2 EMISSIONS :', &
     ' OTHER GAS EMISSIONS AS SPECIFIED IN GAS.EMK')
 873  FORMAT (/1X,'CO2 CONC INPUT OVERWRITES CO2 EMISSIONS :', &
     ' SO2 EMISSIONS AS SPECIFIED IN GAS.EMK')
!
 900  FORMAT (1X,I5)
 901  FORMAT (1X,2I5)
 902  FORMAT (1X,I5,F10.0)
 903  FORMAT (1X,I5,2F10.0)
 904  FORMAT (1X,I5,4F10.0)
!
 914  FORMAT (/1X,'DIFF/L SENSITIVITY CASE : RLO =',F6.3,' : XLAML =', &
     F10.4,' : XLAMO =',F10.4)
 915  FORMAT (/1X,'GLOBAL SENSITIVITY CASE : INITIAL XLAM =',F10.4)
 916  FORMAT (1X,'  **  WARNING, XLAML<0.0 : USE SMALLER XKLO **')
 930  FORMAT (/1X,'LOW CLIMATE MODEL PARAMETERS')
 931  FORMAT (/1X,'MID CLIMATE MODEL PARAMETERS')
 932  FORMAT (/1X,'HIGH CLIMATE MODEL PARAMETERS')
 933  FORMAT (/1X,'USER CLIMATE MODEL PARAMETERS')
 934  FORMAT (/2X,'YEAR       GHG     ESO21     ESO22     ESO23', &
     '       ALL')
 935  FORMAT (1X,I5,5F10.4)
 936  FORMAT (1X,'REF T',40X,F10.4)
 937  format (1x,'PROFILE: ',A20)
!
 4240 FORMAT (I10)
 4241 FORMAT (F10.0)
 4242 FORMAT (1X,I5,20F10.0)
 4243 FORMAT (I2)
 4445 FORMAT(1X,I5,2F10.0)
 4446 FORMAT(1X,2I5)
 4447 FORMAT(1X,I5,4F10.0,20X,F10.0)
 4448 FORMAT(1X,I5,2F10.0,20X,3F10.0)
!
      END
!
!********************************************************************
!
      BLOCK DATA
!
      parameter (iTp=740)
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
      COMMON/COBS/COBS(0:236)
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
!
      DATA FL(1)/0.420/,FL(2)/0.210/
!
      DATA RHO/1.026/,SPECHT/0.9333/,HTCONS/4.1856/
!
!  INITIALISE CARBON CYCLE MODEL PARAMETERS.
!  FIRST SPECIFY CUMULATIVE EMISSIONS TRANSITION POINTS.
!
      DATA EL1/141./,EL2/565./,EL3/2500./
!
      DATA DEE1/0.25/,DEE2/0.5/,DEE3/1.0/,DEE4/2.0/ &
     ,DEE5/4.0/,DEE6/8.0/
!
!  THESE ARE THE INVERSE DECAY TIMES AND MULTIPLYING CONSTANTS
!
      DATA (TINV0(J),J=1,5)/0.0,0.0030303,0.0125,0.05,0.625/
      DATA (A(1,J),J=1,5)/0.131,0.216,0.261,0.294,0.098/
      DATA (A(2,J),J=1,5)/0.142,0.230,0.335,0.198,0.095/
      DATA (A(3,J),J=1,5)/0.166,0.363,0.304,0.088,0.079/
!
        end
!
!********************************************************************
!
      SUBROUTINE INIT
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      common /Limits/KEND
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)
!
      COMMON /FORCE/qco2(0:iTp),qm(0:iTp),qn(0:iTp),QCFC(0:iTp), &
     QMONT(0:iTp),QOTHER(0:iTp),QSTRATOZ(0:iTp),QCH4O3(0:iTp), &
     CFC12(0:iTp), QCH4H2O(0:iTp),QBC(0:iTp),QOC(0:iTp)
!
      common /Sulph/S90DIR,S90IND,S90BIO,ENAT,ES1990,ECO90,FOC90,IFOC
      COMMON /VARW/Z(40),W(2),DW(2),TO0(2),TP0(2),WNH(iTp),WSH(iTp), &
     TW0NH,TW0SH,IVARW,KEYDW
!
      COMMON /ICE/T1990,G1990,SEN,SENG,SENA,ERRG,ERRA, &
     DMG,DMA,SENI,SENP,SENS,DSENI,DSENP,DSENS,ICE,MODEL, &
     NEWGSIC,IXG,VZERO,XG
!
      COMMON /AREAS/FNO,FNL,FSO,FSL
!
      COMMON /NSIM/NSIM,NCLIM,ISCENGEN,TEMEXP(2,40),IWNHOFF,IWSHOFF, &
     WTHRESH
!
!  THE PROGRAM USES VARIOUS COUNTERS TO KEEP TRACK OF TIME.
!   IC BEGINS WITH IC=1 TO IDENTIFY THE YEAR 1765. THUS IC
!   =226 IS THE YEAR 1990, IC=336 IS THE YEAR 2100, ETC.
!   CONC AND FORCING ARRAYS GIVE VALUES AT THE END OF THE
!   YEAR. THUS CONC(1) IS THE VALUE AT THE END OF 1765, ETC.
!   TIME (T) IS COUNTED FROM T=0 AT THE MIDDLE OF 1765, SO
!   THAT THE MIDDLE OF 1990 IS T=225.0. TEMP AND SEALEVEL
!   OUTPUT VALUES ARE AVERAGES OVER CALENDAR YEARS WITH THE
!   VALUES BEING THOSE CALCULATED AT THE MIDPOINTS OF YEARS.
!   TEMP(1) IS THEREFORE THE VALUE FOR THE MIDDLE OF 1765
!   CORRESPONDING TO T=0.0 AND IC=1. EMISSIONS ARE TOTALS
!   OVER CALENDAR YEARS, SO THE E(1) WOULD BE THE TOTAL FOR
!   1765, E(226) THE TOTAL FOR 1990, ETC.
!
!  ****************************************************************
!
      FNL=FL(1)/2.0
      FNO=(1.0-FL(1))/2.0
      FSL=FL(2)/2.0
      FSO=(1.0-FL(2))/2.0
      FLSUM=2.0*(FNL+FSL)
      FOSUM=2.0*(FNO+FSO)
!
      IWNHOFF=0
      IWSHOFF=0
      IP=0
      IC=1
      KC=1
      T=0.0
      DZ=100.
      DZ1=DZ/2.
      DTH=DT/HM
      DTZ=DT/DZ
      XXX=XK/DZ1
      YYY=XK/DZ
      AL=-DTZ*YYY
!
!  INITIALIZE TO(I,L) = OCEAN TEMP CHANGE IN HEMISPHERE "I"
!   AT LEVEL "L", AND TOCN(L) = AREA WEIGHTED MEAN OF HEMIS TEMPS.
!
      DO L=1,40
      TOCN(L)=0.0
        DO I=1,2
        TO(I,L)=0.0
        END DO
      END DO
!
      Y(1)=0.0
      Y(2)=0.0
      Y(3)=0.0
      Y(4)=0.0
      HEM(1)=0.0
      HEM(2)=0.0
!
!  Z(I) DEPTH FROM BOTTOM OF MIXED LAYER FOR VARIABLE W
!
      DO I=2,40
      Z(I)=(I-2)*DZ+0.5*DZ
      ENDDO
!
!  DEFINE INITIAL TEMP PROFILE (TEM(I)) AND PRESSURE (P(I)).
!
      ZED=HM/2.
      P(1)=0.0098*(0.1005*ZED+10.5*(EXP(-ZED/3500.)-1.))
      TEM(1)=20.98-13.12/HM-0.04025*HM
      DO I=2,40
      ZED=HM+(I-1)*DZ-DZ/2.
      P(I)=0.0098*(0.1005*ZED+10.5*(EXP(-ZED/3500.)-1.))
      ZZ=ZED/100.
      IF(ZED.LE.130.)THEN
      TEM(I)=18.98-4.025*ZZ
      ELSE IF(ZED.LE.500.0)THEN
      TEM(I)=17.01-2.829*ZZ+0.228*ZZ*ZZ
      ELSE IF(ZED.LT.2500.)THEN
      TEM(I)=EXP(EXP(1.007-0.0665*ZZ))
      ELSE
      TEM(I)=2.98-0.052*ZZ
      ENDIF
      END DO
!
!  DEFINE THEORETICAL INITIAL TEMP PROFILE
!
      TO0(1)=17.2      ! INITIAL MIXED LAYER TEMPE
      TO0(2)=17.2      ! DITTO
      TP0(1)=1.0       ! INITIAL TEMP OF POLAR SINKING WATER
      TP0(2)=1.0       ! DITTO
!
      DO I=1,2
      DO L=2,40
      TEMEXP(I,L)=TP0(I)+(TO0(I)-TP0(I))*EXP(-W0*Z(L)/XK)
      END DO
      END DO
!
!   SET INITIAL VALUES FOR USE WITH VARIABLE W
!
      W(1)=W0
      W(2)=W0
      DW(1)=0.0
      DW(2)=0.0
!
!  DEFINE INITIAL TEMP AND SEA LEVEL COMPONENTS.
!
      TGAV(1)=0.0
      TDEEP(1)=0.0
      SLI(1)=0.0
      SLG(1)=0.0
      SLA(1)=0.0
      SLT(1)=0.0
      EX(0)=0.0
!
!  CALCULATE NEW RADIATIVE FORCINGS EVERY FOURTH LOOP (I.E., WHEN
!   NSIM=1,5,9,13,17) WHEN NEW SO2 EMISSIONS ARE USED.
!
      IF(NCLIM.EQ.1.OR.ISCENGEN.EQ.9)THEN
!
        CALL DELTAQ
!
!  INITIALISE QTOT ETC AT START OF 1765.
!  THIS ENSURES THAT ALL FORCINGS ARE ZERO AT THE MIDPOINT OF 1765.
!
        QTOT(0)      = -qtot(1)
        qso2(0)      = -qso2(1)
        qdir(0)      = -qdir(1)
        qco2(0)      = -qco2(1)
        qm(0)        = -qm(1)
        qn(0)        = -qn(1)
        qcfc(0)      = -qcfc(1)
        QCH4O3(0)    = -QCH4O3(1)
        qgh(0)       = -qgh(1)
        QBIO(0)      = -QBIO(1)
        QLAND(0)     = -QLAND(1)
        QMN(0)       = -QMN(1)
      ENDIF
!
      RETURN
      END
!
!  *******************************************************************
!
      SUBROUTINE TSLCALC(N)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      DIMENSION SLI1(iTp),SLG1(iTp),SLA1(iTp),SLO1(iTp),ZALL1(iTp), &
     EX1(iTp),ZALL(iTp), &
     SLI2(iTp),SLG2(iTp),SLA2(iTp),SLO2(iTp),ZALL2(iTp),EX2(iTp), &
     SLI3(iTp),SLG3(iTp),SLA3(iTp),SLO3(iTp),ZALL3(iTp),EX3(iTp), &
     SLI4(iTp),SLG4(iTp),SLA4(iTp),SLO4(iTp),ZALL4(iTp),EX4(iTp)
!
      common /Limits/KEND
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)
!
      COMMON /VARW/Z(40),W(2),DW(2),TO0(2),TP0(2),WNH(iTp),WSH(iTp), &
     TW0NH,TW0SH,IVARW,KEYDW
      COMMON /QSPLIT/QNHO,QNHL,QSHO,QSHL,QGLOBE(0:iTp), &
     QQNHO(0:iTp),QQNHL(0:iTp),QQSHO(0:iTp),QQSHL(0:iTp), &
     QQQNHO(0:iTp),QQQNHL(0:iTp),QQQSHO(0:iTp),QQQSHL(0:iTp), &
     EHistBC(iTp),EHistOC(iTp) ! Vars to store read-in BC-OC history.

!
      COMMON /ICE/T1990,G1990,SEN,SENG,SENA,ERRG,ERRA, &
     DMG,DMA,SENI,SENP,SENS,DSENI,DSENP,DSENS,ICE,MODEL, &
     NEWGSIC,IXG,VZERO,XG
!
      COMMON /NSIM/NSIM,NCLIM,ISCENGEN,TEMEXP(2,40),IWNHOFF,IWSHOFF, &
     WTHRESH
!
      QQNHO(N)  = QNHO
      QQNHL(N)  = QNHL
      QQSHO(N)  = QSHO
      QQSHL(N)  = QSHL
      TNHO(N)  = Y(1)
      TNHL(N)  = Y(3)
      TSHO(N)  = Y(2)
      TSHL(N)  = Y(4)
      TNHAV(N) = FO(1)*Y(1)+FL(1)*Y(3)
      TSHAV(N) = FO(2)*Y(2)+FL(2)*Y(4)
      TLAND(N) = (FL(1)*Y(3)+FL(2)*Y(4))/FLSUM
      TOCEAN(N)= (FO(1)*Y(1)+FO(2)*Y(2))/FOSUM
      TGAV(N)  = (TNHAV(N)+TSHAV(N))/2.
!
!  CALCULATE MEAN OCEAN TEMP CHANGE PROFILE AND ITS INCREMENTAL
!   CHANGE OVER ONE YEAR
!
      DO L=1,40
        TOCNPREV(L)=TOCN(L)
        TOCN(L)=(FO(1)*TO(1,L)+FO(2)*TO(2,L))/FOSUM
      END DO
      TDEEP(N)=TOCN(40)
!
!  INCREMENTAL THERMAL EXPN CONTRIBUTION TO SEA LEVEL CHANGE.
!
      EXPAN=EX(N-1)
!
      ZLAYER=HM
!
      DO I=1,40
!
        DELTOC=TOCN(I)-TOCNPREV(I)
        DELTBAR=(TOCN(I)+TOCNPREV(I))/2.0
!
        TL1=TEM(I)+DELTBAR
        TL2=TL1*TL1
        TL3=TL2*TL1/6000.
        PPL=P(I)
        COEFE=52.55+28.051*PPL-0.7108*PPL*PPL+TL1*(12.9635-1.0833*PPL)- &
        TL2*(0.1713-0.019263*PPL)+TL3*(10.41-1.1338*PPL)
        DLR=COEFE*DELTOC*ZLAYER/10000.
        ZLAYER=DZ
        EXPAN=EXPAN+DLR
!
      END DO
!
      EX(N)=EXPAN
!
!  ICE MELT CONTRIBUTIONS TO SEA LEVEL RISE.
!  FOR TAR MODELS, KEY TEMPERATURE PROBABLY SHOULD BE CHANGE
!   FROM 1880, BUT CHANGE FROM PRE-INDUISTRIAL TIMES WAS USED.
!  FOR MAGICC (MODEL=0) T1990=TBASE
!
      IF(N.LE.226)THEN
        TBAR = 0.0
        TCUM = 0.0
        SLT(N)=EX(N)
      ENDIF
!
      IF(N.EQ.226)THEN
        TBASE=TGAV(N)
        XX=G1990
        GS1990=0.934*XX-0.01165*XX*XX        ! CM
        B19901=(0.934-0.0233*XX)*SEN*0.6                 ! NEW CODE
        B19902=(0.934-0.0233*XX)*SEN                     ! NEW CODE
        B19903=(0.934-0.0233*XX)*SEN*1.4                 ! NEW CODE
        B19904=(0.934-0.0233*XX)*SEN*(1.0+(ICE-2)*0.4)   ! NEW CODE
!
!  YG IS TO ALLOW BZERO SCALING TO BE TURNED OFF
!
        YG=XG                                            ! NEW CODE
        IF(IXG.EQ.0)YG=1.0                               ! NEW CODE
!
!  ERROR BOUNDS ON VZERO CHANGED FROM +/-10 TO FOLLOW AR4 (JUNE 2008)
!
        VZ1=VZERO-11.                                    ! NEW CODE
        VZ2=VZERO                                        ! NEW CODE
        VZ3=VZERO+15.                                    ! NEW CODE
        VZ4=VZERO+(ICE-2)*11.                            ! NEW CODE
        IF(ICE.EQ.3)VZ4=VZ4+4.
        BZERO1=B19901/((1.0-GS1990/VZ1)**YG)             ! NEW CODE
        BZERO2=B19902/((1.0-GS1990/VZ2)**YG)             ! NEW CODE
        BZERO3=B19903/((1.0-GS1990/VZ3)**YG)             ! NEW CODE
        BZERO4=B19904/((1.0-GS1990/VZ4)**YG)             ! NEW CODE
        GSPREV1=GS1990                                   ! NEW CODE
        GSPREV2=GS1990                                   ! NEW CODE
        GSPREV3=GS1990                                   ! NEW CODE
        GSPREV4=GS1990                                   ! NEW CODE
!        WRITE(8,*)SEN,VZ4,B19904,BZERO4,GSPREV4
      ENDIF
      IF(MODEL.EQ.0)T1990=TBASE
!
!  NEED TCUM = INTEGRAL OF TEMP CHANGE FROM MID 1990
!
      IF(N.GE.226)THEN
!        TBAR=(TGAV(N)+TGAV(N-1))/2.0-TGAV(226)
        TBAR=(TGAV(N)+TGAV(N-1))/2.0
        IF(N.EQ.226)TBAR=0.0
        TCUM=TCUM+TBAR
        DTB=0.15
        AAA=T1990-TBASE
        DYR=FLOAT(N-226)
        BBB=AAA*DYR+TCUM
!
!  NEW GSIC. NOTE THAT LO, MID, HIGH AND USER CASES MUST ALL BE
!   CARRIED THRU TOGETHER SINCE THEY CANNOT BE CALCULATED BY
!   SIMPLY SCALING THE CENTRAL VALUE AS PREVIOUSLY.
!
        IF(NEWGSIC.EQ.1)THEN                                     ! NEW CODE
!
          FF1=BZERO1*(DTB+AAA+TGAV(N))                           ! NEW CODE
          FF2=BZERO2*(DTB+AAA+TGAV(N))                           ! NEW CODE
          FF3=BZERO3*(DTB+AAA+TGAV(N))                           ! NEW CODE
          FF4=BZERO4*(DTB+AAA+TGAV(N))                           ! NEW CODE
          X1=1.0-GSPREV1/VZ1                                     ! NEW CODE
          X2=1.0-GSPREV2/VZ2                                     ! NEW CODE
          X3=1.0-GSPREV3/VZ3                                     ! NEW CODE
          X4=1.0-GSPREV4/VZ4                                     ! NEW CODE
          DEL1=FF1*(X1**XG)/(1.0+0.5*FF1*XG*(X1**(XG-1.0))/VZ1)  ! NEW CODE
          DEL2=FF2*(X2**XG)/(1.0+0.5*FF2*XG*(X2**(XG-1.0))/VZ2)  ! NEW CODE
          DEL3=FF3*(X3**XG)/(1.0+0.5*FF3*XG*(X3**(XG-1.0))/VZ3)  ! NEW CODE
          DEL4=FF4*(X4**XG)/(1.0+0.5*FF4*XG*(X4**(XG-1.0))/VZ4)  ! NEW CODE
          GS1=GSPREV1+DEL1                                       ! NEW CODE
          GS2=GSPREV2+DEL2                                       ! NEW CODE
          GS3=GSPREV3+DEL3                                       ! NEW CODE
          GS4=GSPREV4+DEL4                                       ! NEW CODE
!
          GSPREV1=GS1                                            ! NEW CODE
          GSPREV2=GS2                                            ! NEW CODE
          GSPREV3=GS3                                            ! NEW CODE
          GSPREV4=GS4                                            ! NEW CODE
        ELSE                                                     ! NEW CODE
!
!  GSICs, GS = MELT CONTRIB FROM 1880, DGS = 1-SIGMA UNCERT.,
!   SEN = GSIC SENSITIVITY.
!
          GU=G1990+DTB*SEN*DYR+SEN*BBB         ! THIS IS IN CM
!
!  TRAP TO AVOID UNREALISTIC BEHAVIOR IN GS FOR LARGE GU. THIS
!   IMPOSES AN UPPER BOUND ON THE CENTRAL GU VALUE OF 40.1 CM, WITH
!   A CORRESP. UPPER BOUND ON GS OF 18.7201 CM.
!
          IF(GU.GT.40.0858)GU=40.0858          ! GU IS IN CM
          GUM=GU/100.                          ! THIS IS IN M
          GSM=0.934*GUM-1.165*GUM*GUM          ! AREA CORRECTED, IN M
          GS=GSM*100.                          ! BACK TO CM
!
        ENDIF                                                    ! NEW CODE
!
        GREF=GS-GS1990
        DGS=0.40*GREF
        IF(NEWGSIC.EQ.1)DGS=(GS3-GS1)/2.0                        ! NEW CODE
!
!  GREENLAND AND ANTARCTICA  (ZGR AND ZAN, FROM 1990)
!
        ZGR=SENG*BBB
        DZGR1=ERRG*DMG*BBB
        DZGR2=0.1*ZGR
!
        ZAN=SENA*BBB
        DZAN=ERRA*DMA*BBB
!
!  ICE MELT UNCERTAINTY TERM
!
        DHV=SQRT(DGS**2+DZGR1**2+DZGR2**2+DZAN**2)
!
!  OTHER CONTRIBUTORS
!
        ZI=SENI*DYR
        DZI=DSENI*DYR
        ZP=SENP*DYR
        DZP=DSENP*DYR
        ZS=SENS*DYR
        DZS=DSENS*DYR
!
!  TOTAL NON-EXPANSION SEA LEVEL RISE, FROM 1880 BUT IGNORING
!   ALL CHANGES OVER 1880-1990 EXCEPT GSICs
!
        ZTOT=GS+ZGR+ZAN+ZI+ZP+ZS
        IF(NEWGSIC.EQ.1)ZTOT=GS2+ZGR+ZAN+ZI+ZP+ZS       ! REVISED CODE
!
!  UNCERTAINTY TERM (2-SIGMA)
!
        DZTOT=2.0*DHV+DZI+DZP+DZS
!
!  ABOVE GIVES MID YEAR VALUES.
!
        SLI(N)=GS
        IF(NEWGSIC.EQ.1)SLI(N)=GS2           ! NEW CODE
        SLG(N)=ZGR
        SLA(N)=ZAN
        SLO(N)=ZI+ZP+ZS
        ZALL(N)=ZTOT
!
!  CASES:
!   ICE MELT ONLY CALCULATED FOR NSIM=1,2,3 OR 4.
!   NCLIM=1 = LOW = LOW EXPAN + LOW MELT
!
       IF(NSIM.EQ.1)THEN
          SLI(N)=GS-2.0*DGS
!                       
! THE FACTOR 2.0 IS BECAUSE THIS IS THE 2-SIGMA UNCERTAINTY
!
          IF(NEWGSIC.EQ.1)SLI(N)=GS1          ! NEW CODE
          SLG(N)=ZGR-2.0*SQRT(DZGR1**2+DZGR2**2)
          SLA(N)=ZAN-2.0*DZAN
          SLO(N)=0.0
          ZALL(N)=ZTOT-DZTOT
!
          SLI1(N) =SLI(N)
          SLG1(N) =SLG(N)
          SLA1(N) =SLA(N)
          SLO1(N) =SLO(N)
          ZALL1(N)=ZALL(N)
          EX1(N)=EX(N)
        ENDIF
!
!     NCLIM=2 = MID = MID EXPAN + MID MELT
!
        IF(NSIM.EQ.2)THEN
          SLI(N)=GS
          IF(NEWGSIC.EQ.1)SLI(N)=GS2          ! NEW CODE
          SLG(N)=ZGR
          SLA(N)=ZAN
          SLO(N)=ZI+ZP+ZS
          ZALL(N)=ZTOT
!
          SLI2(N) =SLI(N)
          SLG2(N) =SLG(N)
          SLA2(N) =SLA(N)
          SLO2(N) =SLO(N)
          ZALL2(N)=ZALL(N)
          EX2(N)=EX(N)
        ENDIF
!
!     NCLIM=3 = HIGH = HIGH EXPAN + HIGH MELT
!
        IF(NSIM.EQ.3)THEN
          SLI(N)=GS+DGS                       ! PREVIOUSLY +2.0*DGS (??)
          IF(NEWGSIC.EQ.1)SLI(N)=GS3          ! NEW CODE
          SLG(N)=ZGR+2.0*SQRT(DZGR1**2+DZGR2**2)
          SLA(N)=ZAN+2.0*DZAN
          SLO(N)=2.0*(ZI+ZP+ZS)
          ZALL(N)=ZTOT+DZTOT
!
          SLI3(N) =SLI(N)
          SLG3(N) =SLG(N)
          SLA3(N) =SLA(N)
          SLO3(N) =SLO(N)
          ZALL3(N)=ZALL(N)
          EX3(N)=EX(N)
        ENDIF
!
!  NCLIM=4 = USER = USER EXPAN + USER MELT
!   NOTE THAT NSIM=1 RESULTS ABOVE (LOW CASE) ARE OVER-WRITTEN
!    BY USER CASE IF ISCENGEN=9
!   PARAMETER 'ICE' DETERMINES WHETHER USER HAS CHOSEN TO USE
!    LOW, MID OR HIGH ICE MELT
!
        IF(NSIM.EQ.4.OR.ISCENGEN.EQ.9)THEN
          SCALE=(ICE-2)*2.0
!
          SLI(N)=GS+SCALE*DGS
          IF(NEWGSIC.EQ.1)SLI(N)=GS4          ! NEW CODE
          SLG(N)=ZGR+SCALE*SQRT(DZGR1**2+DZGR2**2)
          SLA(N)=ZAN+SCALE*DZAN
          SLO(N)=(ICE-1)*(ZI+ZP+ZS)
          ZALL(N)=ZTOT+SCALE*DZTOT/2.0
!
          SLI4(N) =SLI(N)
          SLG4(N) =SLG(N)
          SLA4(N) =SLA(N)
          SLO4(N) =SLO(N)
          ZALL4(N)=ZALL(N)
          EX4(N)=EX(N)
        ENDIF
!
!  NOW TRANSFER APPROPRIATE MELT CASE RESULTS FOR NSIM VALUES
!   GREATER THAN 4.
!
        IF(NSIM.EQ.5.OR.NSIM.EQ.9.OR.NSIM.EQ.13.OR.NSIM.EQ.17)THEN
          SLI(N) =SLI1(N)
          SLG(N) =SLG1(N)
          SLA(N) =SLA1(N)
          SLO(N) =SLO1(N)
          ZALL(N)=ZALL1(N)
          EX(N)=EX1(N)
        ENDIF
!
        IF(NSIM.EQ.6.OR.NSIM.EQ.10.OR.NSIM.EQ.14.OR.NSIM.EQ.18)THEN
          SLI(N) =SLI2(N)
          SLG(N) =SLG2(N)
          SLA(N) =SLA2(N)
          SLO(N) =SLO2(N)
          ZALL(N)=ZALL2(N)
          EX(N)=EX2(N)
        ENDIF
!
        IF(NSIM.EQ.7.OR.NSIM.EQ.11.OR.NSIM.EQ.15.OR.NSIM.EQ.19)THEN
          SLI(N) =SLI3(N)
          SLG(N) =SLG3(N)
          SLA(N) =SLA3(N)
          SLO(N) =SLO3(N)
          ZALL(N)=ZALL3(N)
          EX(N)=EX3(N)
        ENDIF
!
        IF(NSIM.EQ.8.OR.NSIM.EQ.12.OR.NSIM.EQ.16.OR.NSIM.EQ.20)THEN
          SLI(N) =SLI4(N)
          SLG(N) =SLG4(N)
          SLA(N) =SLA4(N)
          SLO(N) =SLO4(N)
          ZALL(N)=ZALL4(N)
          EX(N)=EX4(N)
        ENDIF
!
        SLT(N)=ZALL(N)+EX(N)
      ENDIF
!
      RETURN
      END
!
!  *******************************************************************
!
      SUBROUTINE SPLIT(QGLOBE,A,BN,BS,QNO,QNL,QSO,QSL)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      COMMON /AREAS/FNO,FNL,FSO,FSL
!
!  Q VALUES ARE FORCINGS OVER AREAS IN W/M**2, F VALUES ARE THESE
!   MULTIPLIED BY AREA FRACTIONS. 
!   The resulting fractions times the appropriate area fractions
!   (FNO,FNL,FSO,FSL) sum to the global forcing. sjs
!
!  FIRST SPLIT QGLOBE INTO NH AND SH
!
      Q=QGLOBE
      QS=2.*Q/(A+1.)
      QN=A*QS
!
!  NOW SPLIT NH AND SH INTO LAND AND OCEAN
!
      FFN=2.0*(BN*FNL+FNO)
      QNO=QN/FFN
      QNL=BN*QNO
!
      FFS=2.0*(BS*FSL+FSO)
      QSO=QS/FFS
      QSL=BS*QSO
!
      RETURN
      END
!
!  *******************************************************************
!
      SUBROUTINE RUNMOD
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      DIMENSION AA(40),BB(40),A(40),B(40),C(40),D(40),XLLGLOBE(2), &
     XLLDIFF(2)
!
      common /Limits/KEND
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)
!
      COMMON /CO2READ/ICO2READ,XC(226:iTp),CO2SCALE,qtot86,LEVCO2
!
      common /Sulph/S90DIR,S90IND,S90BIO,ENAT,ES1990,ECO90,FOC90,IFOC
      COMMON /DSENS/IXLAM,XLAML,XLAMO,ADJUST
      COMMON /VARW/Z(40),W(2),DW(2),TO0(2),TP0(2),WNH(iTp),WSH(iTp), &
     TW0NH,TW0SH,IVARW,KEYDW
      COMMON /QSPLIT/QNHO,QNHL,QSHO,QSHL,QGLOBE(0:iTp), &
     QQNHO(0:iTp),QQNHL(0:iTp),QQSHO(0:iTp),QQSHL(0:iTp), &
     QQQNHO(0:iTp),QQQNHL(0:iTp),QQQSHO(0:iTp),QQQSHL(0:iTp), &
      EHistBC(iTp),EHistOC(iTp) ! Vars to store read-in BC-OC history.

      COMMON /AREAS/FNO,FNL,FSO,FSL
!
      COMMON /QADD/IQREAD,OrgIQREAD,JQFIRST,JQLAST,QEX(0:iTp),QEXNH(0:iTp), &
     QEXSH(0:iTp),QEXNHO(0:iTp),QEXNHL(0:iTp),QEXSHO(0:iTp), &
     QEXSHL(0:iTp),IOLDTZ
! BCOC params to set read-in forcing
      REAL*4 FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing !sjs
      COMMON/BCOC/FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing
      COMMON /FORCE/qco2(0:iTp),qm(0:iTp),qn(0:iTp),QCFC(0:iTp), &
      QMONT(0:iTp),QOTHER(0:iTp),QSTRATOZ(0:iTp),QCH4O3(0:iTp), &
      CFC12(0:iTp), QCH4H2O(0:iTp),QBC(0:iTp),QOC(0:iTp)
!
      COMMON /NSIM/NSIM,NCLIM,ISCENGEN,TEMEXP(2,40),IWNHOFF,IWSHOFF, &
     WTHRESH
!
  11  CONTINUE
!
!  INCREMENT COUNTER AND ADD TIME STEP.
!   T CORRESPONDS TO THE TIME AT WHICH NEW VALUES ARE TO
!   BE CALCULATED
!
      IP=IC
      T=T+DT
!
      IC=INT(T+1.49)
!
!  PROTECT AGAINST CUMULATIVE ROUND-OFF ERROR IN T.
!   (IF T IS VERY NEAR AN INTEGER, ROUND UP OR DOWN TO INTEGER.)
!
      DIFF=ABS(T-INT(T))
      IF(DIFF.LE.0.5)THEN
        XT=FLOAT(INT(T))
      ELSE
        DIFF=1.0-DIFF
        XT=FLOAT(INT(T)+1)
      ENDIF
      IF(DIFF.LT.0.01)T=XT
!
!  AS SOON AS A NEW YEAR IS ENCOUNTERED (I.E. IC IS
!   INCREMENTED), CALCULATE NEW END OF YEAR VALUES FOR
!   CONCENTRATIONS AND RADIATIVE FORCING.
!  THIS IS ONLY NECESSARY FOR FIRST PASS THROUGH NUMSIMS LOOP
!   WHICH WILL SET ALL VALUES OF FORCING COMPONENT ARRAYS.
!
!      IF(NCLIM.EQ.1.OR.ISCENGEN.EQ.9)THEN
!
       IF(IC.GT.IP) CALL DELTAQ
!
!      ENDIF
!
!  INTERPOLATE FORCING FROM VALUES AT ENDS OF YEARS TO
!   VALUE AT MIDPOINT OF TIME STEP.
!
!  ***********************************************************
!
!  REVISED ALGORITHM FOR INTERPOLATION (15 APR, 1994)
!
!  FIRST CALCULATE FRACTION OF YEAR THAT TIME CORRESPONDS TO AND
!   IDENTIFY THE INTEGER (JC) THAT IS THE END OF THE YEAR IN
!   WHICH THE TIME LIES.
!
      T1=T-DT/2.0
      JC=INT(T1+1.49)
      FRAC=T1+0.5-INT(T1+0.5)
      IF(FRAC.LT.0.001)FRAC=1.0
!
!  CALCULATE GREENHOUSE GAS AND BIOMASS AEROSOL COMPONENTS OF
!   FORCING AT START (0) AND END (1) OF YEAR, AND AT START OF
!   PREVIOUS YEAR (P).
!
      JPREV=0
      IF(JC.GE.2)JPREV=JC-2
!
      QGHP  = QGH(JPREV)
      QGH0  = QGH(JC-1)
      QGH1  = QGH(JC)
!
      QBIOP = QBIO(JPREV)
      QBIO0 = QBIO(JC-1)
      QBIO1 = QBIO(JC)
!
      QLANDP= QLAND(JPREV)
      QLAND0= QLAND(JC-1)
      QLAND1= QLAND(JC)
!
      QMNP  = QMN(JPREV)
      QMN0  = QMN(JC-1)
      QMN1  = QMN(JC)
!
!  RELABEL DIRECT AEROSOL AND OZONE FORCINGS
!
      QDIRP = QDIR(JPREV)
      QDIR0 = QDIR(JC-1)
      QDIR1 = QDIR(JC)
      QOZP  = QOZ(JPREV)
      QOZ0  = QOZ(JC-1)
      QOZ1  = QOZ(JC)
!
!  CALCULATE INDIRECT AEROSOL COMPONENT.
!
      QINDP  =QSO2(JPREV)-QDIRP
      QIND0  =QSO2(JC-1)-QDIR0
      QIND1  =QSO2(JC)-QDIR1
!
!  ***********************************************************
!
!  SPLIT AEROSOL & TROP O3 FORCING INTO LAND AND OCEAN IN NH AND SH
!
!  A IS THE NH/SH FORCING RATIO
!  BN IS THE LAND/OCEAN FORCING RATIO IN THE NH
!  BS IS THE LAND/OCEAN FORCING RATIO IN THE SH
!
      ADIR = 4.0
      AIND = 2.0
      AOZ  =99.0
      BNDIR= 9.0
      BNIND= 9.0
      BNOZ = 9.0
      BSDIR= 9.0
      BSIND= 9.0
      BSOZ = 9.0
!
      CALL SPLIT(QINDP,AIND,BNIND,BSIND,QINDNOP,QINDNLP, &
     QINDSOP,QINDSLP)
      CALL SPLIT(QIND0,AIND,BNIND,BSIND,QINDNO0,QINDNL0, &
     QINDSO0,QINDSL0)
      CALL SPLIT(QIND1,AIND,BNIND,BSIND,QINDNO1,QINDNL1, &
     QINDSO1,QINDSL1)
!
      CALL SPLIT(QDIRP,ADIR,BNDIR,BSDIR,QDIRNOP,QDIRNLP, &
     QDIRSOP,QDIRSLP)
      CALL SPLIT(QDIR0,ADIR,BNDIR,BSDIR,QDIRNO0,QDIRNL0, &
     QDIRSO0,QDIRSL0)
      CALL SPLIT(QDIR1,ADIR,BNDIR,BSDIR,QDIRNO1,QDIRNL1, &
     QDIRSO1,QDIRSL1)
!
      CALL SPLIT(QOZP,AOZ,BNOZ,BSOZ,QOZNOP,QOZNLP, &
     QOZSOP,QOZSLP)
      CALL SPLIT(QOZ0,AOZ,BNOZ,BSOZ,QOZNO0,QOZNL0, &
     QOZSO0,QOZSL0)
      CALL SPLIT(QOZ1,AOZ,BNOZ,BSOZ,QOZNO1,QOZNL1, &
     QOZSO1,QOZSL1)
!
      QSNHOP =QDIRNOP+QINDNOP+QOZNOP
      QSNHLP =QDIRNLP+QINDNLP+QOZNLP
      QSSHOP =QDIRSOP+QINDSOP+QOZSOP
      QSSHLP =QDIRSLP+QINDSLP+QOZSLP
!
      QSNHO0 =QDIRNO0+QINDNO0+QOZNO0
      QSNHL0 =QDIRNL0+QINDNL0+QOZNL0
      QSSHO0 =QDIRSO0+QINDSO0+QOZSO0
      QSSHL0 =QDIRSL0+QINDSL0+QOZSL0
!
      QSNHO1 =QDIRNO1+QINDNO1+QOZNO1
      QSNHL1 =QDIRNL1+QINDNL1+QOZNL1
      QSSHO1 =QDIRSO1+QINDSO1+QOZSO1
      QSSHL1 =QDIRSL1+QINDSL1+QOZSL1
!
!  ***********************************************************
!
!  IF EXTRA FORCINGS ADDED THROUGH QEXTRA.IN, CALC CORRESP
!   'P', '0' AND '1' COMPONENTS FOR THESE.  NOTE THAT THESE
!   DATA ARE INPUT AS ANNUAL-MEAN VALUES, SO THEY MUST
!   BE APPLIED EQUALLY AT THE START AND END OF THE YEAR,
!   I.E., Q0=Q1=Q(JC).
!
      QEXNHOP=0.0
      QEXSHOP=0.0
      QEXNHLP=0.0
      QEXSHLP=0.0
      QEXNHO0=0.0
      QEXSHO0=0.0
      QEXNHL0=0.0
      QEXSHL0=0.0
      QEXNHO1=0.0
      QEXSHO1=0.0
      QEXNHL1=0.0
      QEXSHL1=0.0
!
      IF(IQREAD.GE.1)THEN
        IF((JC.GE.JQFIRST).AND.(JC.LE.JQLAST))THEN
          QEXNHOP=QEXNHO(JC-1)
          QEXSHOP=QEXSHO(JC-1)
          QEXNHLP=QEXNHL(JC-1)
          QEXSHLP=QEXSHL(JC-1)
          QEXNHO0=QEXNHO(JC)
          QEXSHO0=QEXSHO(JC)
          QEXNHL0=QEXNHL(JC)
          QEXSHL0=QEXSHL(JC)
          QEXNHO1=QEXNHO(JC)
          QEXSHO1=QEXSHO(JC)
          QEXNHL1=QEXNHL(JC)
          QEXSHL1=QEXSHL(JC)
        ENDIF
      ENDIF

! If read-in, calc explicit BCOC forcing, split into hemispheres and add to QEXTRA here
     IF( IFOC.GE.3 .AND. IQREAD.NE.2 )THEN
        ! Save total BC and OC Forcing
        QBC(JC) = EHistBC(JC) * aBCUnitForcing
        QOC(JC) = EHistOC(JC) * aOCUnitForcing

!  A IS THE NH/SH FORCING RATIO
!  BN IS THE LAND/OCEAN FORCING RATIO IN THE NH
!  BS IS THE LAND/OCEAN FORCING RATIO IN THE SH
!
      A_BCOC = 8.0
      BN_BCOC = 9.0
      BS_BCOC = 9.0
 
        QBCOCP = ( EHistBC(JPREV) * aBCUnitForcing + EHistOC(JPREV) * aOCUnitForcing )
        QBCOC0 = ( EHistBC(JC-1) * aBCUnitForcing + EHistOC(JC-1) * aOCUnitForcing )
        QBCOC1 = QBC(JC) + QOC(JC)
        QBCOCP = QBC(JPREV) + QOC(JPREV)
        QBCOC0 = QBC(JC-1) + QOC(JC-1)
        
        ! If 1990 or later, then use values from input file
        ! Input values are in units of Tg
        IF ( JC .GT. 225 ) THEN
            QBC(JC) = EBC(JC) * aBCUnitForcing
            QOC(JC) = EOC(JC) * aOCUnitForcing
            
            QBCOCP = QBC(JPREV) + QOC(JPREV)
            QBCOC0 = QBC(JC-1) + QOC(JC-1)
            QBCOC1 = QBC(JC) + QOC(JC)
        ENDIF

		! Split into N and S Hem and ocean same as SO2 Dir
        CALL SPLIT(QBCOCP,A_BCOC,BN_BCOC,BS_BCOC,QBCOCNOP,QBCOCNLP,QBCOCSOP,QBCOCSLP)
        CALL SPLIT(QBCOC0,A_BCOC,BN_BCOC,BS_BCOC,QBCOCNO0,QBCOCNL0,QBCOCSO0,QBCOCSL0)
        CALL SPLIT(QBCOC1,A_BCOC,BN_BCOC,BS_BCOC,QBCOCNO1,QBCOCNL1,QBCOCSO1,QBCOCSL1)

        QEXNHOP = QEXNHOP + QBCOCNOP
        QEXNHLP = QEXNHLP + QBCOCNLP
        QEXSHOP = QEXSHOP + QBCOCSOP
        QEXSHLP = QEXSHLP + QBCOCSLP
        QEXNHO0 = QEXNHO0 + QBCOCNO0
        QEXNHL0 = QEXNHL0 + QBCOCNL0
        QEXSHO0 = QEXSHO0 + QBCOCSO0
        QEXSHL0 = QEXSHL0 + QBCOCSL0
        QEXNHO1 = QEXNHO1 + QBCOCNO1
        QEXNHL1 = QEXNHL1 + QBCOCNL1
        QEXSHO1 = QEXSHO1 + QBCOCSO1
        QEXSHL1 = QEXSHL1 + QBCOCSL1
    
      ENDIF

!
!  IF EXTRA NH AND SH FORCING INPUT THROUGH QEXTRA.IN, ADD
!   TO AEROSOL FORCING
!  IF IQREAD=2, USE EXTRA FORCING ONLY
!
      IQR=1
      IF(IQREAD.EQ.2)IQR=0
!
      QSNHOP=IQR*QSNHOP+QEXNHOP
      QSSHOP=IQR*QSSHOP+QEXSHOP
      QSNHLP=IQR*QSNHLP+QEXNHLP
      QSSHLP=IQR*QSSHLP+QEXSHLP
      QGHP  =IQR*QGHP
      QBIOP =IQR*QBIOP
      QLANDP=IQR*QLANDP
      QMNP  =IQR*QMNP
!
      QSNHO0=IQR*QSNHO0+QEXNHO0
      QSSHO0=IQR*QSSHO0+QEXSHO0
      QSNHL0=IQR*QSNHL0+QEXNHL0
      QSSHL0=IQR*QSSHL0+QEXSHL0
      QGH0  =IQR*QGH0
      QBIO0 =IQR*QBIO0
      QLAND0=IQR*QLAND0
      QMN0  =IQR*QMN0
!
      QSNHO1=IQR*QSNHO1+QEXNHO1
      QSSHO1=IQR*QSSHO1+QEXSHO1
      QSNHL1=IQR*QSNHL1+QEXNHL1
      QSSHL1=IQR*QSSHL1+QEXSHL1
      QGH1  =IQR*QGH1
      QBIO1 =IQR*QBIO1
      QLAND1=IQR*QLAND1
      QMN1  =IQR*QMN1
!
!  CALCULATE FORCING COMPONENTS FOR MIDPOINT OF INTERVAL.
!
      QSNHLM =(QSNHL0+QSNHL1)/2.0
      QSSHLM =(QSSHL0+QSSHL1)/2.0
      QSNHOM =(QSNHO0+QSNHO1)/2.0
      QSSHOM =(QSSHO0+QSSHO1)/2.0
      QGHM   =(QGH0  +QGH1  )/2.0
      QBIOM  =(QBIO0 +QBIO1 )/2.0
      QLANDM =(QLAND0+QLAND1)/2.0
      QMNM   =(QMN0+QMN1)/2.0
!
!  ************************************************************
!
!   PUT TOTAL FORCINGS AT MIDPOINT OF YEAR JC INTO ARRAYS.
!
      QQQNHL(JC)=QSNHLM+QGHM+QBIOM+QLANDM+QMNM
      QQQNHO(JC)=QSNHOM+QGHM+QBIOM+QLANDM+QMNM
      QQQSHL(JC)=QSSHLM+QGHM+QBIOM+QLANDM+QMNM
      QQQSHO(JC)=QSSHOM+QGHM+QBIOM+QLANDM+QMNM
      FNHL=QQQNHL(JC)*FNL
      FNHO=QQQNHO(JC)*FNO
      FSHL=QQQSHL(JC)*FSL
      FSHO=QQQSHO(JC)*FSO
      QGLOBE(JC)=FNHL+FNHO+FSHL+FSHO
      TEQU(JC)=TE*QGLOBE(JC)/Q2X
!
!  CALCULATE FORCING INCREMENTS OVER YEAR IN WHICH TIME STEP LIES.
!   DONE FOR 1ST AND 2ND HALVES OF YEAR SEPARATELY.
!
      DSNHL0M =(QSNHLM-QSNHL0)*2.0
      DSSHL0M =(QSSHLM-QSSHL0)*2.0
      DSNHO0M =(QSNHOM-QSNHO0)*2.0
      DSSHO0M =(QSSHOM-QSSHO0)*2.0
      DGH0M   =(QGHM  -QGH0  )*2.0
      DBIO0M  =(QBIOM -QBIO0 )*2.0
      DLAND0M =(QLANDM-QLAND0)*2.0
      DMN0M   =(QMNM-QMN0)*2.0
!
      DSNHLM1 =(QSNHL1-QSNHLM)*2.0
      DSSHLM1 =(QSSHL1-QSSHLM)*2.0
      DSNHOM1 =(QSNHO1-QSNHOM)*2.0
      DSSHOM1 =(QSSHO1-QSSHOM)*2.0
      DGHM1   =(QGH1  -QGHM  )*2.0
      DBIOM1  =(QBIO1 -QBIOM )*2.0
      DLANDM1 =(QLAND1-QLANDM)*2.0
      DMNM1   =(QMN1-QMNM)*2.0
!
!  NOW CALCULATE THE FORCING VALUES AT THE MIDPOINT OF THE TIME STEP.
!
      IF(FRAC.LE.0.5)THEN
        QSNHL =QSNHL0+FRAC*DSNHL0M
        QSSHL =QSSHL0+FRAC*DSSHL0M
        QSNHO =QSNHO0+FRAC*DSNHO0M
        QSSHO =QSSHO0+FRAC*DSSHO0M
        QGHG  =QGH0  +FRAC*DGH0M
        QBIOG =QBIO0 +FRAC*DBIO0M
        QLANDG=QLAND0+FRAC*DLAND0M
        QMNG  =QMN0+FRAC*DMN0M
      ELSE
        QSNHL =QSNHLM+(FRAC-0.5)*DSNHLM1
        QSSHL =QSSHLM+(FRAC-0.5)*DSSHLM1
        QSNHO =QSNHOM+(FRAC-0.5)*DSNHOM1
        QSSHO =QSSHOM+(FRAC-0.5)*DSSHOM1
        QGHG  =QGHM  +(FRAC-0.5)*DGHM1
        QBIOG =QBIOM +(FRAC-0.5)*DBIOM1
        QLANDG=QLANDM+(FRAC-0.5)*DLANDM1
        QMNG  =QMNM+(FRAC-0.5)*DMNM1
      ENDIF
!
!  COMBINE GREENHOUSE, (SO4 AEROSOL + TROP O3 + QEXTRA) AND BIO
!   AEROSOL FORCINGS
!
      QNHL=QGHG+QSNHL+QBIOG+QLANDG+QMNG
      QNHO=QGHG+QSNHO+QBIOG+QLANDG+QMNG
      QSHL=QGHG+QSSHL+QBIOG+QLANDG+QMNG
      QSHO=QGHG+QSSHO+QBIOG+QLANDG+QMNG
!
!  **********************************************************
!
      DO 10 II=1,2
!
!  *****  START OF DIFFERENTIAL SENSITIVITY TERMS  *****
!
        IF(IXLAM.EQ.1)THEN
          WWW=FO(II)*(XKLO+FL(II)*XLAML)
          XLLDIFF(II)=ADJUST*(XLAMO+XLAML*XKLO*FL(II)/WWW)
          XLL=XLLDIFF(II)
        ELSE
          WWW=FO(II)*(XKLO+FL(II)*XLAM)
          XLLGLOBE(II)=ADJUST*XLAM*(1.+XKLO*FL(II)/WWW)
          XLL=XLLGLOBE(II)
        ENDIF
!
!  *****  END OF DIFFERENTIAL SENSITIVITY TERMS  *****
!
        CL=-DTZ*(YYY+W(II))
        BL=1.-AL-CL
!
        A(1)=1.+DTH*(XXX+W(II)*PI+XLL/FK)
        B(1)=-DTH*(XXX+W(II))
        A(2)=-DTZ*XXX
        C(2)=CL
        B(2)=1.-A(2)-C(2)
        D(2)=TO(II,2)
!
!  TERMS FOR VARIABLE W
!
        DTZW=DTZ*DW(II)
!
      IF(IVARW.GE.1)THEN
        IF(IOLDTZ.EQ.1)THEN
          D(2)=D(2)+DTZW*(TEMEXP(II,3)-TEMEXP(II,2))
        ELSE
          D(2)=D(2)+DTZW*(TEM(3)-TEM(2))
        ENDIF
      ENDIF
!
        DO L=3,39
          A(L)=AL
          B(L)=BL
          C(L)=CL
          D(L)=TO(II,L)
!
!  TERMS FOR VARIABLE W
!
!      TEMEXP(I,L)=TP0(I)+(TO0(I)-TP0(I))*EXP(-W0*Z(L)/XK)
        IF(IVARW.GE.1)THEN
          IF(IOLDTZ.EQ.1)THEN
            D(L)=D(L)+DTZW*(TEMEXP(II,L+1)-TEMEXP(II,L))
          ELSE
            D(L)=D(L)+DTZW*(TEM(L+1)-TEM(L))
          ENDIF
        ENDIF
!
        END DO
!
        A(40)=AL
        B(40)=1.-CL
        D(40)=TO(II,40)+TO(II,1)*PI*DTZ*W(II)
!
!  TERMS FOR VARIABLE W
!
        IF(IVARW.GE.1)THEN
          IF(IOLDTZ.EQ.1)THEN
            D(40)=D(40)+DTZW*(TP0(II)-TEMEXP(II,40))
          ELSE
            D(40)=D(40)+DTZW*(TP0(II)-TEM(40))
          ENDIF
        ENDIF
!
!  FORL is the land forcing term
!
        if(ii.eq.1) then
          forl = qnhl*xklo*fl(ii)/www
          heat = (qnho+hem(ii)+forl)*dth/fk
        else
          forl = qshl*xklo*fl(ii)/www
          heat = (qsho+hem(ii)+forl)*dth/fk
        endif
!
        D(1)=TO(II,1)+HEAT
!
!  TERMS FOR VARIABLE W
!
        IF(IVARW.GE.1)THEN
          IF(IOLDTZ.EQ.1)THEN
            D(1)=D(1)+DTH*DW(II)*(TEMEXP(II,2)-TP0(II))
          ELSE
            D(1)=D(1)+DTH*DW(II)*(TEM(2)-TP0(II))
          ENDIF
        ENDIF
!
!  THIS IS THE OLD BAND SUBROUTINE
!
        AA(1)=-B(1)/A(1)
        BB(1)=D(1)/A(1)
        DO L=2,39
          VV=A(L)*AA(L-1)+B(L)
          AA(L)=-C(L)/VV
          BB(L)=(D(L)-A(L)*BB(L-1))/VV
        END DO
        TO(II,40)=(D(40)-A(40)*BB(39))/(A(40)*AA(39)+B(40))
        DO I=1,39
          L=40-I
          TO(II,L)=AA(L)*TO(II,L+1)+BB(L)
        END DO
!
  10  CONTINUE
!
!  Y(1,2,3,4) ARE NH OCEAN, SH OCEAN, NH LAND & SH LAND TEMPS.
!
      Y(1)=TO(1,1)*ADJUST
      Y(2)=TO(2,1)*ADJUST
!
!  DIFFERENTIAL SENSITIVITY TERMS
!
      IF(IXLAM.EQ.1)THEN
        Y(3)=(FL(1)*qnhl+XKLO*Y(1))/(FL(1)*XLAML+XKLO)
        Y(4)=(FL(2)*qshl+XKLO*Y(2))/(FL(2)*XLAML+XKLO)
      ELSE
        Y(3)=(FL(1)*qnhl+XKLO*Y(1))/(FL(1)*XLAM+XKLO)
        Y(4)=(FL(2)*qshl+XKLO*Y(2))/(FL(2)*XLAM+XKLO)
      ENDIF
!
!  *****  END OF DIFFERENTIAL SENSITIVITY TERMS  *****
!
      HEM(1)=(XKNS/FO(1))*(Y(2)-Y(1))
      HEM(2)=(XKNS/FO(2))*(Y(1)-Y(2))
!
!  VARIABLE W TERMS
!
      IF(IVARW.EQ.0)THEN
        W(1)=W0
        DW(1)=0.0
        W(2)=W0
        DW(2)=0.0
      ENDIF
!
      OCEANT=(FO(1)*Y(1)+FO(2)*Y(2))/(FO(1)+FO(2))
      GLOBET=(FO(1)*Y(1)+FL(1)*Y(3)+FO(2)*Y(2)+FL(2)*Y(4))/2.0
!
!  ALTERNATIVE WAYS TO DEFINE W(t) (SEE TOP OF CODE FOR DETAILS).
!
      AW=1.0
      IF((IVARW.EQ.2).AND.(KEYDW.GE.4))AW=1.0-WTHRESH/W0
!
      IF((KEYDW.EQ.1).OR.(KEYDW.EQ.4))THEN
        TNKEY=GLOBET
        TSKEY=GLOBET
      ENDIF
      IF((KEYDW.EQ.2).OR.(KEYDW.EQ.5))THEN
        TNKEY=OCEANT
        TSKEY=OCEANT
      ENDIF
      IF(KEYDW.EQ.3)THEN
        TNKEY=Y(1)
        TSKEY=Y(2)
      ENDIF
!
!  DROP FULL W TO 0.1 BUT RECOVER IF TEMPERATURE RECOVERS
!
      IF(IVARW.EQ.1)THEN
        DW(1)=-AW*W0*TNKEY/TW0NH
        W(1)=W0+DW(1)
        IF(W(1).LT.0.1)W(1)=0.1
!
        DW(2)=-AW*W0*TSKEY/TW0SH
        W(2)=W0+DW(2)
        IF(W(2).LT.0.1)W(1)=0.1
      ENDIF
!
!  DROP TO EITHER FULL OR ACTIVE W TO WTHRESH AND STAY THERE
!
      IF(IVARW.EQ.2)THEN
        DW(1)=-AW*W0*TNKEY/TW0NH
        W(1)=W0+DW(1)
        IF((W(1).LT.WTHRESH).OR.(IWNHOFF.EQ.1))THEN
          IWNHOFF=1
          W(1)=WTHRESH
          DW(1)=WTHRESH-W0
        ENDIF
!
        DW(2)=-AW*W0*TSKEY/TW0SH
        W(2)=W0+DW(2)
        IF((W(2).LT.WTHRESH).OR.(IWSHOFF.EQ.1))THEN
          IWSHOFF=1
          W(2)=WTHRESH
          DW(2)=WTHRESH-W0
        ENDIF
      ENDIF
!
!  SPACE FOR CODE TO USE INPUT WNH AND WSH TIME SERIES
!
!      IF(IVARW.EQ.3)THEN
!        if(jc.ge.246) w(1)=wthresh
!        if(jc.ge.246) w(2)=wthresh
!        if(jc.ge.246) dw(1)=0.0
!        if(jc.ge.246) dw(2)=0.0
        WNH(JC)=W(1)
        WSH(JC)=W(2)
!
!  HAVING CALCULATED VALUES AT NEW TIME 'T', DECIDE WHETHER OR NOT
!   TEMPS ARE ANNUAL VALUES (I.E., CORRESPOND TO T=MIDPOINT OF
!   YEAR).  IF SO, GO TO TSLCALC, CALCULATE GLOBAL MEAN TEMP (TGAV)
!   AND INSERT INTO ARRAY, AND CALCULATE SEA LEVEL RISE COMPONENTS.
!  NOTE THAT, BECAUSE FORCING VALUES ARE GIVEN AT ENDS OF YEARS
!   AND TIMES ARE INTEGERS AT MIDPOINTS OF YEARS, A ONE YEAR TIME
!   STEP WILL STILL GIVE MID-YEAR VALUES FOR CALCULATED TEMPERATURES.
!
      KP=KC
      KC=INT(T+1.01)
      IF(KC.GT.KP)CALL TSLCALC(KC)
!
      IF(T.GE.TEND)RETURN
      GO TO  11
      END
!
!  *******************************************************************
!
      SUBROUTINE DELTAQ
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      common /Limits/KEND
!
      COMMON/OZ/OZ00CH4,OZCH4,OZNOX,OZCO,OZVOC
!
      COMMON/CLIM/IC,IP,KC,DT,DZ,FK,HM,Q2X,QXX,PI,T,TE,TEND,W0,XK,XKLO, &
     XKNS,XLAM,FL(2),FO(2),FLSUM,FOSUM,HEM(2),P(40),TEM(40),TO(2,40), &
     AL,BL,CL,DTH,DTZ,DZ1,XLL,WWW,XXX,YYY,RHO,SPECHT,HTCONS,Y(4)
!
      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/NEWCONCS/CF4(iTp),C2F6(iTp),C125(iTp),C134A(iTp), &
     C143A(iTp),C227(iTp),C245(iTp),CSF6(iTp), &
     ECF4(226:iTp+1),EC2F6(226:iTp+1),E125(226:iTp+1),E134A(226:iTp+1), &
     E143A(226:iTp+1),E227(226:iTp+1),E245(226:iTp+1),ESF6(226:iTp+1)
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
!
      COMMON /METH1/emeth(226:iTp),imeth,ch4l(225:iTp),ch4b(225:iTp), &
     ch4h(225:iTp),ef4(226:iTp),StratH2O,TCH4(iTp),iO3feed, &
     ednet(226:iTp+1),DUSER,FUSER,CORRUSER,CORRMHI,CORRMMID,CORRMLO
!
      COMMON /FORCE/qco2(0:iTp),qm(0:iTp),qn(0:iTp),QCFC(0:iTp), &
     QMONT(0:iTp),QOTHER(0:iTp),QSTRATOZ(0:iTp),QCH4O3(0:iTp), &
     CFC12(0:iTp), QCH4H2O(0:iTp),QBC(0:iTp),QOC(0:iTp)
!
      COMMON /METH2/LEVCH4,ch4bar90,QQQN2O
!
      COMMON /METH3/TCH4CON,TAUINIT,SCH4,DELSS,DELTAU, &
     ANOX,ACO,AVOC,DELANOX,DELACO,DELAVOC,ICH4FEED
!
      COMMON /METH4/GAM,TAUOTHER,BBCH4,CM00
      common /TauNitr/TN2000,BBN2O,SN2O,CN00,NOFFSET
      common /Sulph/S90DIR,S90IND,S90BIO,ENAT,ES1990,ECO90,FOC90,IFOC
!
      COMMON /NSIM/NSIM,NCLIM,ISCENGEN,TEMEXP(2,40),IWNHOFF,IWSHOFF, &
     WTHRESH
!
      COMMON /CO2READ/ICO2READ,XC(226:iTp),CO2SCALE,qtot86,LEVCO2
!
      COMMON /JSTART/JSTART,FOSSHIST(0:236),QKYMAG(0:iTp),IGHG, &
     QCH4OZ,QFOC(0:iTp),ICO2CORR,TROZSENS
!
      COMMON /CORREN/CORREN1,CORREN2,CORREN3,CORREN4,CORREN
!
      SAVE T00LO,T00MID,T00HI,T00USER
! sjs -- change to make MAGICC  work. need to save these vars

! sjs -- add storage for halocarbon variables
      COMMON /HALOF/QCF4_ar(0:iTp),QC2F6_ar(0:iTp),qSF6_ar(0:iTp), &
      Q125_ar(0:iTp),Q134A_ar(0:iTp), &
      Q143A_ar(0:iTp),Q227_ar(0:iTp),Q245_ar(0:iTp)

! sjs-- g95 seems to have optomized away these local variables, so put them in common block
     COMMON /TEMPSTOR/DQOZPP, DQOZ

!
!  THIS SUBROUTINE IS ONLY ENTERED WHEN THE IC YEAR COUNT
!   INCREMENTS.  CONCENTRATIONS AND RADIATIVE FORCINGS ARE
!   THEN CALCULATED FOR THE END OF THE IC YEAR.  SINCE THE
!   IC INCREMENT MAY BE GREATER THAN 1, A LOOP IS NEEDED TO
!   FILL IN THE MISSING IC VALUES.
!
      QLAND90=-0.2
!
      DO 10 J=IP+1,IC
!
!********************************************************
!
!  LAND ALBEDO CHANGE FORCING
!
      IF(J.LE.226)THEN
        QLAND(J)=QLAND90*FLOAT(J)/226.0
      ELSE
        QLAND(J)=QLAND90
      ENDIF
!
!  *******************************************************
!
!  START OF LONG SET OF IF STATEMENTS (MODIFIED AUGUST, 2000).
!
!  CARBON CYCLE MODEL STILL RUNS FROM 1990, BUT A CORRECTION
!   IS APPLIED FOR 2000 ONWARDS TO ENSURE CONSISTENCY WITH
!   OBSERVED VALUES IN 2000.
!
!  HISTORY
!  FIRST ACCESS HISTORY DATA
!
      IF(J.LE.JSTART)THEN
!
!  NOTE : FOR PROTOCOL GASES, ONLY 1990 CONCENTRATION VALUE IS GIVEN
!   (FOR ALL J.LE.JSTART) SINCE THIS IS ALL THAT IS NEEDED TO
!   INITIALIZE FUTURE CONCS
!
        if(j.ge.226)then
          ejkeep=eso2(j)
          ej1keep=eso2(j+1)
        endif
!
        CALL HISTORY(J,CO2(J),CH4(J),CN2O(J),eso2(J),eso2(j+1), &
       CF4(J),C2F6(J),C125(J),C134A(J),C143A(J),C227(J),C245(J), &
       CSF6(J))
!
        if(j.ge.226)then
          eso2(j)=ejkeep
          eso2(j+1)=ej1keep
        endif
!
        IF(J.EQ.JSTART)THEN
          CM00=CH4(JSTART-1)
          CN00=CN2O(JSTART-1)
        ENDIF
!
        if(j.eq.jstart) then
          ch4l(jstart-1) = ch4(jstart-1)
          ch4b(jstart-1) = ch4(jstart-1)
          ch4h(jstart-1) = ch4(jstart-1)
          ch4l(jstart) = ch4(jstart)
          ch4b(jstart) = ch4(jstart)
          ch4h(jstart) = ch4(jstart)
        endif
!
!  Calculate additional CO2 emissions due to CH4 oxidation for
!   jstart year.
!  First specify fossil fuel fraction of total CH4 emissions
!   (updated to 0.18 in August 2000 based on TAR).
!
        if(j.ge.226)then
          fffrac = 0.18
          emeth(j) = fffrac*0.0020625*(ch4(j)-700.)/TAUINIT
          if(imeth.eq.1) then
            ef4(j) = ef(j)+emeth(j)
          else
            ef4(j) = ef(j)
          endif
        endif
!
      ENDIF
!
!  *******************************************************
!
!  FOR CONCS BEYOND THE END OF 1990, CALL THE VARIOUS EMISSIONS
!   TO CONCENTRATIONS MODELS.  NOTE THAT THE INPUT EMISSIONS
!   ARRAYS ARE NUMBERED AS FOR OTHER VARIABLES ; I.E. E(226)
!   IS THE 1990 VALUE. EMISSIONS VALUES UP TO AND INCLUDING E(225)
!   ARE NOT USED.
!
!  FOR CALCULATING FEEDBACKS IN CARBON AND METHANE, NEED TO USE
!   EXTRAPOLATED VALUES FOR TEMPERATURE AND CO2 CONCENTRATION.
!   RELEVANT VALUES ARE FROM START YEAR FOR MODEL PROJECTIONS.
!
      IF(J.GE.226)THEN
        TX=2.0*TGAV(J-1)-TGAV(J-2)
        IF(J.EQ.226)DELT90=TX
        IF(J.EQ.236)DELT00=TX
      ENDIF
!
      IF(J.GT.JSTART)THEN
!
!  SET INITIAL (YEAR 2000) LIFETIMES
!
        IF(j.eq.jstart+1) then
          t00lo=TAUINIT-DELTAU
          t00mid=TAUINIT
          t00hi=TAUINIT+DELTAU
          if(LEVCH4.eq.1)t00user=t00lo
          if(LEVCH4.eq.2)t00user=t00mid
          if(LEVCH4.eq.3)t00user=t00hi
          if(LEVCH4.eq.4)t00user=TCH4CON
        ENDIF
!
!  *******************************************************
!
!  CH4
!  PRATHER'S TAR METHOD INCORPORATED, AUGUST 2000
!  FOR METHANE CONC PROJECTIONS, NEED TO USE EMISSIONS CONSISTENT WITH
!   THE LIFETIME. THIS IS DONE USING CORRECTION FACTORS CALCULATED
!   IN THE MAIN PROGRAM. NOTE THAT THE INPUT EMISSIONS HAVE ALREADY
!   BEEN OFFSET BY THE AMOUNT APPROPRIATE TO THE USER-SPECIFIED
!   LIFETIME (I.E., BY CORRUSER).
!  THIS WAS CORRECTED ON 97/12/13.
!
        DENOX=ENOX(J)-ENOX(236)
        DECO=ECO(J) -ECO(236)
        DEVOC=EVOC(J)-EVOC(236)
!
!  ESTIMATED TEMPERATURE CHANGE FROM 2000
!
        DELTAT=TX-DELT00
!
!  LOW LIFETIME
!
        EECH4 = ECH4(J)-CORRUSER+CORRMLO
!
        SSLO=SCH4-DELSS
        ANOXLO=ANOX+DELANOX
        ACOLO=ACO-DELACO
        AVOCLO=AVOC-DELAVOC
!
        CALL METHANE(ICH4FEED,CH4L(J-1),EECH4,DENOX,DECO,DEVOC,CH4L(J), &
       T00LO,TAULO,SSLO,ANOXLO,ACOLO,AVOCLO,DELTAT)
!
!  MID (BEST) LIFETIME
!
        EECH4 = ECH4(J)-CORRUSER+CORRMMID
!
        CALL METHANE(ICH4FEED,CH4B(J-1),EECH4,DENOX,DECO,DEVOC,CH4B(J), &
       T00MID,TAUBEST,SCH4,ANOX,ACO,AVOC,DELTAT)
!
!  HIGH LIFETIME
!
        EECH4 = ECH4(J)-CORRUSER+CORRMHI
!
        SSHI=SCH4+DELSS
        ANOXHI=ANOX-DELANOX
        ACOHI=ACO+DELACO
        AVOCHI=AVOC+DELAVOC
!
        CALL METHANE(ICH4FEED,CH4H(J-1),EECH4,DENOX,DECO,DEVOC,CH4H(J), &
       T00HI,TAUHI,SSHI,ANOXHI,ACOHI,AVOCHI,DELTAT)
!
!  USER LIFETIME (ONE OF ABOVE, OR CONSTANT AT SPECIFIED 1990 VALUE)
!
        EECH4 = ECH4(J)
!
!  SET MODEL PARAMETERS FOR USER CASE
!
        IF(LEVCH4.EQ.1)THEN
          SSUSER=SCH4-DELSS
          ANOXUSER=ANOX+DELANOX
          ACOUSER=ACO-DELACO
          AVOCUSER=AVOC-DELAVOC
        ENDIF
!
        IF(LEVCH4.EQ.2)THEN
          SSUSER=SCH4
          ANOXUSER=ANOX
          ACOUSER=ACO
          AVOCUSER=AVOC
        ENDIF
!
        IF(LEVCH4.EQ.3)THEN
          SSUSER=SCH4+DELSS
          ANOXUSER=ANOX-DELANOX
          ACOUSER=ACO+DELACO
          AVOCUSER=AVOC+DELAVOC
        ENDIF
!
        IF(LEVCH4.EQ.4)THEN
          SSUSER=0.0
          ANOXUSER=0.0
          ACOUSER=0.0
          AVOCUSER=0.0
        ENDIF
!
        CALL METHANE(ICH4FEED,CH4(J-1),EECH4,DENOX,DECO,DEVOC,CH4(J), &
       T00USER,TAUCH4,SSUSER,ANOXUSER,ACOUSER,AVOCUSER,DELTAT)
!
!  SAVE USER-MODEL METHANE LIFETIME. TCH4(J) = CHEMICAL (OH)
!   LIFETIME. THIS IS THE SAME AS ......
!   TCH4EFF(J)=CH4BAR/(ECH4(J)/BBCH4-DELCH4-SOILSINK-STRATSINK)
!
        TCH4(J)=TAUCH4
!
! Methane oxidation source: based on user methane projection only.
!  User projection determined by choice of LEVCH4 (1,2,3,or 4).
!
        CH4BAR=(CH4(J-1)+CH4(J))/2
        EMETH(J) = FFFRAC*0.0020625*(CH4BAR-700.)/TAUCH4
        IF(IMETH.EQ.1)THEN
          EF4(J) = EF(J)+EMETH(J)
        ELSE
          EF4(J) = EF(J)
        ENDIF
!
      ENDIF
!
!  *******************************************************
!
      IF(J.GT.JSTART)THEN
!
!  N2O
!  N2O CONCs
!
!  NOFFSET IS THE TIME IT TAKES FOR N2O TO MIX TO THE STRATOSPHERE
!
        J1=J-1
        J2=J-NOFFSET
        J3=J-NOFFSET-1
!
        CALL NITROUS(CN2O(J1),CN2O(J2),CN2O(J3),EN2O(J),CN2O(J))
!
      ENDIF
!
!  *******************************************************
!
!  HALOCARBS, ETC.
!  CONC CALCULATIONS FROM 1991 ONWARDS FOR KYOTO PROTOCOL HFCs,
!   PFCs AND SF6. NOTE : FOR PRESENT VERSION, ALTHO CONCS ARE
!   CALCULATED, THEY ARE NOT OUTPUT. ONLY THE TOTAL FORCING IS USED.
!  HALO FORCINGS FOR 1990 AND EARLIER ARE GIVEN IN QHALOS.IN, BROKEN
!   DOWN INTO MONTREAL GASES, MAGICC KYOTO GASES, OTHER GASES AND 
!   STRAT OZONE. FOR 1991+, QHALOS.IN GIVES FORCINGS FOR MONTREAL
!   GASES, OTHER GASES AND STRAT OZONE.
!  EFFECT OF OH CHANGES ON LIFETIMES ADDED 000909
!
       T0=TAUINIT
!
      IF(J.GT.226)THEN
        IF(J.LE.JSTART)THEN
          TM=T0
        ELSE
!
!  PREVIOUS VERSION USED TAUBEST HERE. IT IS MORE CONSISTENT TO USE
!   TAUCH4, WHICH IS THE USER LIFETIME. THIS WILL GIVE HALOCARBON
!   LIFETIMES CONSISTENT WITH USER METHANE LIFETIME.
!
          TM=TAUCH4
        ENDIF
!
        CALL HALOCARB(1,CF4(J-1),  ECF4(J), CF4(J)  ,QCF4 ,T0,TM)
        CALL HALOCARB(2,C2F6(J-1), EC2F6(J),C2F6(J) ,QC2F6,T0,TM)
        CALL HALOCARB(3,C125(J-1), E125(J), C125(J) ,Q125 ,T0,TM)
        CALL HALOCARB(4,C134A(J-1),E134A(J),C134A(J),Q134A,T0,TM)
        CALL HALOCARB(5,C143A(J-1),E143A(J),C143A(J),Q143A,T0,TM)
        CALL HALOCARB(6,C227(J-1), E227(J), C227(J) ,Q227 ,T0,TM)
        CALL HALOCARB(7,C245(J-1), E245(J), C245(J) ,Q245 ,T0,TM)
        CALL HALOCARB(8,CSF6(J-1), ESF6(J), CSF6(J) ,QSF6 ,T0,TM)
!
        QKYMAG(J)=QCF4+QC2F6+Q125+Q134A+Q143A+Q227+Q245+QSF6
!
! sjs -- Save halocarbon forcing

	QCF4_ar(J) = QCF4
	QC2F6_ar(J) = QC2F6
	qSF6_ar(J) = QSF6
	Q125_ar(J) = Q125
	Q134A_ar(J) = Q134A
	Q143A_ar(J) = Q143A
	Q227_ar(J) = Q227
	Q245_ar(J) = Q245

      ENDIF
!
!  *******************************************************
!
!  CO2
!  CARBON CYCLE MODEL CALL. NOTE THAT THIS IS CALLED FROM 1991
!   ONWARDS, IRRESPECTIVE OF JSTART VALUE
!
      IF(J.GT.226)THEN
!
!  NC=1, BCO2 BASED ON D80S=1.8 TO GIVE LOWER BOUND CONCS
!  NC=2, BCO2 BASED ON D80S=1.1 TO GIVE BEST GUESS CONCS
!  NC=3, BCO2 BASED ON D80S=0.4 TO GIVE UPPER BOUND CONCS
!  NC=4, BCO2 BASED ON USER SELECTED D80S
!  ALL CASES USE F80S =2.0
!
!  BEST GUES CHANGED TO 1.5 (MAY 2008)
!
        DO 444 NC = 1,4
!
!  CALL INITCAR TO INITIALIZE CARBON CYCLE MODEL
!
        IF(J.EQ.227)THEN
          FIN=2.0
          DIN=2.9-0.7*NC
!         DIN=2.5-0.7*NC
          IF(NC.EQ.4)THEN
            FIN=FUSER
            DIN=DUSER
          ENDIF
          CALL INITCAR(NC,DIN,FIN)
        ENDIF
!
!  IF IDRELAX.NE.O, OVERWRITE EDNET(J) FOR 1990 TO 1990+DRELAX WITH
!   A LINEAR INTERP BETWEEN THE 1990 VALUE BASED ON BALANCING THE
!   1980S-MEAN CARBON BUDGET TO THE APPROPRIATE VALUE OBTAINED FROM
!   THE EMISSIONS INPUT FILE.
!
        IDRELAX=10
        IF(IDRELAX.NE.0)THEN
          EDNET(226)=EDNET90(NC)
          JDEND=226+IDRELAX
          DELED=(EDNET(JDEND)-EDNET(226))/FLOAT(IDRELAX)
          DO JD=227,JDEND-1
          EDNET(JD)=EDNET(226)+DELED*(JD-226)
          END DO
        ENDIF
!
!  Note: for temp feedback on CO2, temp from default or user carbon cycle
!        model is used in all four nc cases.
!        Strictly in (eg) the upper bound case one should
!        use the corresponding temp. However the upper bound CO2 is not
!        generally passed to the climate model so this temp is not
!        calculated. The error in making this approx must be small
!        as it is only a second order effect.
!  Note: this also applies to the methane model.
!
        TEMP=TX-DELT90
!
        CALL CARBON(NC,TEMP,EF4(J),EDNET(J),CCO2(NC,J-3),CCO2(NC,J-2), &
       CCO2(NC,J-1), &
       PL(NC,J-1),HL(NC,J-1),SOIL(NC,J-1),REGROW(NC,J-1),ETOT(NC,J-1), &
       PL(NC,J)  ,HL(NC,J)  ,SOIL(NC,J)  ,REGROW(NC,J)  ,ETOT(NC,J)  , &
       ESUM(J),FOC(NC,J),DELMASS(NC,J),EDGROSS(NC,J),CCO2(NC,J))
!
  444   CONTINUE
!
!  SELECT CO2 VALUES (CO2(J)) TO CARRY ON TO FORCING :
!   THE PARTICULAR CARBON CYCLE MODEL OUTPUT THAT IS CARRIED ON IS
!   DETERMINED BY THE SPECIFIED VALUE OF LEVCO2.
!  NOTE THAT, IF ICO2CORR=1 (THE DEFAULT VALUE) ALL CO2 ARRAYS ARE
!   CORRECTED (CHANGE MADE ON 6/10/03). THE ARRAYS ARE CORRECTED TO
!   AGREE WITH OBSERVATIONS THROUGH JSTART. THE ARRAY CO2(J) HAS
!   ALREADY BEEN SPECIFIED AS HISTORICAL OBSERVED DATA THROUGH
!   J=JSTART. WHEN J=JSTART A CORRECTION FACTOR IS CALCULATED AND
!   THIS IS APPLIED TO ALL SUBSEQUENT YEARS.
!
        IF(J.EQ.JSTART)THEN
          CORREN1=CO2(J)-CCO2(1,J)
          CORREN2=CO2(J)-CCO2(2,J)
          CORREN3=CO2(J)-CCO2(3,J)
          CORREN4=CO2(J)-CCO2(4,J)
          CORREN=CO2(J)-CCO2(LEVCO2,J)
        ENDIF
!
        IF(J.GE.JSTART)THEN
          CO2(J)=CCO2(LEVCO2,J)
          IF(ICO2CORR.EQ.1)THEN
            CO2(J)=CCO2(LEVCO2,J)+CORREN
          ENDIF
        ENDIF
!
!  FEEDBACK PERCENTILE VALUES
!
!       IF(J.GE.JSTART)THEN
!         CO2(J)=CO2(J)*(1.0-0.0855*(J-236)/100.0)          !! 10%
!         CO2(J)=CO2(J)*(1.0-0.0414*(J-236)/100.0)          !! 30%
!         CO2(J)=CO2(J)*(1.0+0.0650*((J-236)/100.0)**1.5)   !! 70%
!         CO2(J)=CO2(J)*(1.0+0.2340*((J-236)/100.0)**1.5)   !! 90%
!       ENDIF
!
!  OVERWRITE CARBON CYCLE CO2 CONCS FOR YEARS.GE.1990 WITH INPUT
!   DATA FROM CO2INPUT.DAT IF ICO2READ.GE.1.
!
        IF(ICO2READ.GE.1.AND.ICO2READ.LE.4) co2(J)=xc(J)
!
      ENDIF
!
!      NSAVE=4
!      IF(ISCENGEN.EQ.9)NSAVE=1
!      IF(NSIM.EQ.NSAVE)THEN
      IF(NSIM.LE.4.AND.NCLIM.EQ.4)THEN
        CO2SAVE(J)=CO2(J)
      ENDIF
!
!  **************************************************
!
!  END OF LONG SEQUENCE OF IF STATEMENTS
!
!  *******************************************************
!
!  HALOCARBON FORCING (IOLDHALO OPTION DELETED, 8 OCT 2000)
!
      QCFC(J)=QMONT(J)+QKYMAG(J)+QOTHER(J)+QSTRATOZ(J)
!
!  SUBTRACT STRAT OZONE FORCING IF IO3FEED=0 (I.E., NFB CASE)
!
      IF(IO3FEED.EQ.0)QCFC(J)=QCFC(J)-QSTRATOZ(J)
!
!  *******************************************************
!
!   METHANE FORCING
!
      QCH4=0.036*(SQRT(CH4(J))-SQRT(CH4(1)))
!
      XM=CH4(J)/1000.
      WW=CN2O(1)/1000.
      AB=0.636*((XM*WW)**0.75) + 0.007*XM*((XM*WW)**1.52)
!
      XM0=CH4(1)/1000.
      AB0=0.636*((XM0*WW)**0.75) + 0.007*XM0*((XM0*WW)**1.52)
!
      QMeth=QCH4+0.47*ALOG((1.+AB0)/(1.+AB))
!
!  QH2O IS THE ADDITIONAL INDIRECT CH4 FORCING DUE TO PRODUCTION
!   OF STRAT H2O FORM CH4 OXIDATION.  QCH4OZ IS THE ENHANCEMENT
!   OF QCH4 DUE TO CH4-INDUCED OZONE PRODUCTION.
!  THE DENOMINATOR IN QCH4OZ HAS BEEN CHOSEN TO GIVE 0.08W/m**2
!   FORCING IN MID 1990. IT DIFFERS SLIGHTLY FROM THE VALUE
!   ORIGINALLY ADVISED BY PRATHER (WHICH WAS 353). THE 0.0025
!   CORRECTION TERM IS TO MAKE THE CHANGE RELATIVE TO MID 1765.
!
      QH2O=STRATH2O*QCH4
!
!  QCH4OZ IS THE TROP OZONE FORCING FROM CH4 CHANGES.
!   HISTORY : USE THE TAR LOGARITHMIC RELATIONSHIP, SCALED TO
!    OZ00CH4 (THE CENTRAL TAR CH4-RELATED FORCING IN 2000).
!
      IF(J.LE.235)THEN
        AAA=OZ00CH4/ALOG(1760./700.)
        QCH4OZ=AAA*ALOG(CH4(J)/700.0)
      ELSE
        QCH4OZ=OZ00CH4+TROZSENS*OZCH4*ALOG(CH4(J)/CH4(235))
      ENDIF
!
      QM(J) = qMeth+qH2O+QCH4OZ
      QCH4O3(J)=QCH4OZ
!
!  *******************************************************
!
!  TROPOSPHERIC OZONE FORCING NOT ASSOCIATED WITH CH4.
!   HISTORY : SCALE WITH FOSSIL CO2 EMISSIONS AS A PROXY FOR
!    THE INFLUENCE OF THE REACTIVE GASES. EMISSIONS HISTORY
!    IS SMOOTHED VERSION OF MARLAND'S DATA TO 1990, WITH
!    SRES TO 2000. SCALING FACTOR CHOSEN TO MAKE TOTAL TROP
!    OZONE FORCING = 0.35 W/m**2 AT BEGINNING OF 2000.
!   FUTURE : USE TAR RELATIONSHIP AND REACTIVE GAS EMISSIONS.
!
      QREF=0.33-OZ00CH4
      IF(J.LE.235)THEN
        FOSS0=FOSSHIST(1)
        QOZ(J)=QREF*(FOSSHIST(J)-FOSS0)/(FOSSHIST(235)-FOSS0)
        IF(J.EQ.234)QOZ1=QOZ(J)
        IF(J.EQ.235)DQOZ=QOZ(J)-QOZ1
      ELSE
        DDEN=ENOX(J)-ENOX(236)
        DDEC=ECO(J) -ECO(236)
        DDEV=EVOC(J)-EVOC(236)
        QOZ(J)=QREF+DQOZ &
       +TROZSENS*(OZNOX*DDEN+OZCO*DDEC+OZVOC*DDEV)
      ENDIF
!
      IF(IGHG.LE.1)QOZ(J)=0.0
!
!  *******************************************************
!
!   NITROUS OXIDE FORCING
!
      QN2O=QQQN2O*(SQRT(CN2O(J))-SQRT(CN2O(1)))
!
      XM=XM0
      WW=CN2O(J)/1000.
      AB=0.636*((XM*WW)**0.75) + 0.007*(XM*(XM*WW)**1.52)
      QN(J)=QN2O+0.47*ALOG((1.+AB0)/(1.+AB))
!
!  *******************************************************
!
!   TOTAL GREENHOUSE FORCING
!
      QCO2(J)=QXX*ALOG(CO2(J)/CO2(1))
      QGH(J)=QCO2(J)+QM(J)+QN(J)+QCFC(J)
!
      IF(IGHG.EQ.0)QGH(J)=0.0
      IF(IGHG.EQ.1)QGH(J)=QCO2(J)
!
!  *******************************************************
!
!   CALCULATE BIOMASS BURNING AEROSOL TERM (SUM OF ORGANIC PLUS
!    BLACK CARBON).
!   HISTORY : ASSUME LINEAR RAMP UP OVER 1765-1990. THIS VERY
!    ROUGHLY FOLLOWS THE GROSS DEFORESTATION HISTORY
!   FUTURE : (1991 ONWARDS) SCALED WITH GROSS DEFORESTATION
!    OUTPUT FROM CARBON CYCLE CALCULATIONS, BUT CONSTRAINED
!    NEVER TO GO ABOVE ZERO. (NOTE THAT WITH THE LINEAR
!    RELATIONSHIP THIS COULD HAPPEN IF EDGROSS BECAME LESS
!    THAN ZERO, WHICH CAN HAPPEN WITH THE PRESENT CARBON CYCLE
!    MODEL. NOTE TOO THAT EDGROSS LESS THAN ZERO IS POSSIBLE:
!    THIS CORRRESPONDS TO NET REFORESTATION. CLEARLY, HOWEVER,
!    THIS WOULD NOT LEAD TO POSITIVE QBIO FORCING.)
!
      IF(J.LE.226)QBIO(J)=S90BIO*FLOAT(J)/226.0
      IF(J.GT.226)THEN
        EDG=EDGROSS(LEVCO2,J)
        IF(EDG.LT.0.0)EDG=0.0
        QBIO(J)=S90BIO*EDG/EDGROSS(LEVCO2,226)
! sjs - Check if EDGROSS(1990) is < 0, if so, ramp 1990 forcing down to zero by 2050
        IF(EDGROSS(LEVCO2,226) .LT. 0) THEN
           QBIO(J)=S90BIO*(1.0 - (FLOAT(J)-226)/60.0)
           IF (QBIO(J) .GT. 0 ) QBIO(J) = 0
        ENDIF
      ENDIF

!
!  *******************************************************
!
!   GLOBAL SULPHATE, FOSSIL ORGANIC AND FOSSIL BLACK CARBON
!    AEROSOL FORCING.
!   NOT : BOTH QSO2 AND QDIR OUTPUTS INCLUDE QFOC
!
      CALL SULPHATE(J,ESO2(J),ESO2(J+1),COE(J),QSO2(J),QDIR(J),QFOC(J), &
     QMN(J))
!
!   TOTAL GLOBAL FORCING INCLUDING AEROSOLS. NOTE THAT QSO2(J)
!    ALREADY INCLUDES QFOC(J)
!
      qtot(J) = QGH(J)+qso2(J)+qoz(J)+QBIO(J)+qland(j)+QMN(J)
!
      if(j.eq.86)qtot86=qtot(J)
!
!  ***************************************************************
!
!  SWITCH TO OVERWRITE CO2 CONCS CALCULATED BY  CARBON CYCLE MODEL.
!   ICO2READ=1, THEN DELTA-QTOT FROM 1990 IS A DIRECT MULTIPLE
!    OF THE CO2 FORCING WITH SCALING FACTOR FROM CFG FILE.
!   ICO2READ=2, QTOT IS THE SUM OF THE NEW CO2 FORCING AND OTHER
!    FORCINGS AS DETERMINED BY THE GAS.EMK EMISSIONS INPUTS.
!   ICO2READ=3, QTOT IS THE SUM OF THE NEW CO2 FORCING AND SULPHATE
!    FORCING AS DETERMINED BY THE EMISSIONS INPUTS.
!
      IF(ICO2READ.EQ.1.AND.J.GT.226)THEN
        QTOT(J) =QTOT(226)+CO2SCALE*(QXX*ALOG(CO2(J)/CO2(226)))
        QSO2(J) =QSO2(226)
        QDIR(J) =QDIR(226)
        QOZ(J)  =QOZ(226)
        QBIO(J) =QBIO(226)
        QLAND(J)=QLAND(226)
        QMN(J)  =QMN(226)
        QGH(J)  =QGH(226)+CO2SCALE*(QXX*ALOG(CO2(J)/CO2(226)))
      ENDIF
!
!  IF ICO2READ=2, THE CHANGE REQUIRED IS ONLY FOR CO2 AND THIS HAS
!   ALREADY BEEN MADE.
!
      IF((ICO2READ.EQ.3.OR.ICO2READ.EQ.4).AND.J.GT.226)THEN
        QTOT(J) =QTOT(226)+CO2SCALE*(QXX*ALOG(CO2(J)/CO2(226)))
        QTOT(J) =QTOT(J)+(QSO2(J)-QSO2(226))
        QOZ(J)  =QOZ(226)
        QBIO(J) =QBIO(226)
        QLAND(J)=QLAND(226)
        QMN(J)  =QMN(226)
        QGH(J)  =QGH(226)+CO2SCALE*(QXX*ALOG(CO2(J)/CO2(226)))
      ENDIF
!
      IF(ICO2READ.EQ.5.AND.J.GT.236)THEN
        QTOT(J) =QTOT(236)+QXX*ALOG(CO2(J)/CO2(236))
        QSO2(J) =QSO2(236)
        QDIR(J) =QDIR(236)
        QOZ(J)  =QOZ(236)
        QBIO(J) =QBIO(236)
        QLAND(J)=QLAND(236)
        QMN(J)  =QMN(236)
        QGH(J)  =QGH(236)+QXX*ALOG(CO2(J)/CO2(236))
      ENDIF
!
      IF(J.EQ.225)THEN
        QTOT89 =QTOT(J)
        QSO289 =QSO2(J)
        QDIR89 =QDIR(J)
        QOZ89  =QOZ(J)
        QBIO89 =QBIO(J)
        QLAND89=QLAND(J)
        QMN89  =QMN(J)
        QGH89  =QGH(J)
      ENDIF
!
      IF(J.EQ.226)THEN
        QTOT90 =QTOT(J)
        QSO290 =QSO2(J)
        QDIR90 =QDIR(J)
        QOZ90  =QOZ(J)
        QBIO90 =QBIO(J)
        QLAND90=QLAND(J)
        QMN90  =QMN(J)
        QGH90  =QGH(J)
        QTOTM =(QTOT89+QTOT90)/2.0
        QSO2M =(QSO289+QSO290)/2.0
        QDIRM =(QDIR89+QDIR90)/2.0
        QOZM  =(QOZ89+QOZ90)/2.0
        QBIOM =(QBIO89+QBIO90)/2.0
        QLANDM=(QLAND89+QLAND90)/2.0
        QMNM  =(QMN89+QMN90)/2.0
        QGHM  =(QGH89+QGH90)/2.0
      ENDIF
!
  10  CONTINUE
!
      RETURN
      END
!
!  *******************************************
!
      SUBROUTINE HALOCARB(N,C0,E,C1,Q,TAU00,TAUCH4)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
!  N   GASNAME AND FORMULA
!  1   CF4           (CF4)
!  2   C2F6         (C2F6)
!  3   HFC125    (CHF2CF3)
!  4   HFC134a   (CH2FCF3)
!  5   HFC143a    (CH3CF3)
!  6   HFC227ea    (C3HF7)
!  7   HFC245ca   (C3H3F5)
!  8   SF6           (SF6)
!
!  THE FOLLOWING CENTRED DIFFERENCE FORMULA IS ONLY GOOD FOR
!   TAU.GT.(dt/2), SO IT FAILS IF TAU.LT.0.5yr.  AN ALTERNATIVE
!   IS TO USE THE EXACT SOLUTION OVER THE ONE YEAR INCREMENT.
!   THIS IS ...
!     XXX=E(J,K)/B(J)
!     EX=EXP(-1.0/TAU(J))
!     C(K) = TAU(J)*XXX*(1.0-EX) + C(K-1)*EX
!
      DIMENSION B(10),TAU(10),ANFB(10)
!
      B(1)=15.10
      B(2)=23.68
      B(3)=20.17
      B(4)=17.14
      B(5)=14.12
      B(6)=28.57
      B(7)=22.52
      B(8)=25.05
!
      TAU(1)=50000.0
      TAU(2)=10000.0
      TAU(3)=   29.0
      TAU(4)=   13.8
      TAU(5)=   52.0
      TAU(6)=   33.0
      TAU(7)=    6.6
      TAU(8)= 3200.0
!
      ANFB(1)=0.08
      ANFB(2)=0.26
      ANFB(3)=0.23
      ANFB(4)=0.15
      ANFB(5)=0.13
      ANFB(6)=0.30
      ANFB(7)=0.23
      ANFB(8)=0.52
!
!  LIFETIME CHANGE FACTOR (ADDED 000909)
!
      IF((N.LE.2).OR.(N.EQ.8))THEN
        FACTOR=1.0
      ELSE
        FACTOR=TAUCH4/TAU00
      ENDIF
      TAU(N)=TAU(N)*FACTOR
!
      XXX=E/B(N)
      TT=1.0/(2.0*TAU(N))
!
      IF(TAU(N).GE.1.0)THEN
        UU=1.-TT
        C1=(C0*UU+XXX)/(1.+TT)
      ELSE
        EX=EXP(-1.0/TAU(N))
        C1=TAU(N)*XXX*(1.0-EX)+C0*EX
      ENDIF
!
      Q=C1*ANFB(N)/1000.
!
      RETURN
      END
!
!  *******************************************
!
      SUBROUTINE INITCAR(NN,D80,F80)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      INTEGER FERTTYPE,TOTEM,CONVTERP
!
      COMMON/COBS/COBS(0:236)
!
      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),CO2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
!
!  FIRST INITIALISE PARAMETERS THAT DEPEND ON MM
!
!  BCO2 ***************************
!
!  COMPLETELY REVISED ON 6/12/95
!  REVISED AGAIN ON 8/8/95. CUBIC RETAINED AS BASIC APPROXIMATION
!   FORMULA FOR BCO2, BUT CORRECTION ADDED FOR D80<0.4 OR >1.8.
!   FORMULA RAPIDLY LOSES ACCURACY OUTSIDE RANGE SHOWN BELOW.
!  FORMULA ADDED TO ACCOUNT FOR CASES WHERE F80S.NE.2.0 USES
!   FACT THAT BCO2 FOR (F80),(D80) IS APPROX THE SAME AS FOR
!   (F80-DEL),(D80-DEL)
!
      DD =(D80-1.1)-(F80-2.0)
      DD2=DD*DD
      DD3=DD*DD2
      BCO2(NN)=0.27628+DD*0.301304+DD2*0.060673+DD3*0.012383
      XD=ABS(DD)-0.7
      IF(XD.GT.0.0) BCO2(NN)=BCO2(NN)-(0.0029*XD-.022*XD*XD)
!
!  CORRECTION FOR F80.NE.2.0.  ERROR IN BCO2 LESS THAN 0.0014
!   FOR 1.0<F80<3.0
!
      BCO2(NN)=BCO2(NN)-0.0379*(F80-2.0)
!
!  COMPARISON OF FIT TO TRUE BCO2 FOR F80=2.0
!
!     D80 BCO2(TRUE)  BCO2(FIT)  TRUE-FIT
!     0.0   0.00365    0.00414   -0.00049
!     0.1   0.02438    0.02438    0.00000
!     0.4   0.09085    0.09085    0.00000
!     0.8   0.19092    0.19102   -0.00010
!     1.1   0.27628    0.27628    0.00000
!     1.4   0.37237    0.37247   -0.00010
!     1.8   0.52117    0.52117    0.00000
!     2.2   0.69994    0.69997   -0.00003
!     2.6   0.91868    0.91830    0.00038
!     3.0   1.19350    1.18092    0.01258
!
!  EDNET ETC. **********************
!
!  LATEST (8/8/95) VALUES. NOT YET INSERTED.
!
!  YEAR     EDNET    REGROW     PLANT     HLITT      SOIL      ETOT
!  1989      .724     1.251   707.895    84.195  1416.528   284.230
!  1990      .762     1.254   708.285    84.300  1416.655   289.707
!
!  EDNET90 CORRECTED ON 8/8/95. LEADING TERMS ONLY IN  OTHER ITEMS
!   CORRECTED.
!
      EDNET90(NN)    =0.762+1.1185*DD-0.0020*DD2
!
      REGROW(NN,226) =1.254+0.584*DD-0.0173*DD2
      EDGROSS(NN,226)=EDNET90(NN)+REGROW(NN,226)
!
      PL(NN,226)     = 708.285-6.131*DD+0.137*DD2
      HL(NN,226)     =  84.300+4.569*DD-0.039*DD2
      SOIL(NN,226)   =1416.655+1.564*DD-0.099*DD2
!
!  NEXT THREE ITEMS NOT UPDATED
!
      FOC(NN,226)    =   2.24
      DELMASS(NN,226)=   3.609
      ABFRAC(NN,226) =   0.514-0.084*(D80-1.0)+0.013*(D80-1.0)**2
!
!  ******************************
!
!  SPECIFY INIT, END-1988, END-1989 AND END-1990 CO2 CONCS.
!
      C0          =COBS(0)
      CCO2(NN,224)=COBS(224)
      CCO2(NN,225)=COBS(225)
      CCO2(NN,226)=COBS(226)
!
      ETOT(NN,226) = 290.797
!
      PL0  = 750.0
      HL0  =  80.0
      SOIL0=1450.0
!
      FERTTYPE=2
      TOTEM   =1
      CONVTERP=1
      FACTOR  =2.123
!
!  ADJUST INVERSE DECAY TIMES ACCORDING TO 1980S-MEAN OCEAN FLUX.
!   PSI CONTROLS THE MAGNITUDE OF THE FLUX INTO THE OCEAN.
!   (IF PSI IS LESS THAN 1, FLUX IS LESS THAN IN THE ORIGINAL
!   MAIER-REIMER AND HASSELMANN MODEL.)
!  A SIMPLE BUT ACCURATE APPROXIMATE EMPIRICAL EXPRESSION IS USED
!   TO ESTIMATE PSI AS A FUNCTION OF F80SIN. THE PSI-F80SIN RELATION
!   DEPENDS ON THE ASSUMED HISTORY OF OBSERVED CONCENTRATION
!   CHANGES. THUS, DIFFERENT PSI-F80SIN RELATIONSHIPS APPLY TO
!   DIFFERENT CO2 HISTORIES.
!
!  REVISED ON 3/16/95, BUT APSI ONLY (HENCE OK FOR F80=2.0 ONLY)
!  REVISED AGAIN ON 4/2/95
!  REVISED AGAIN ON 6/12/95
!  REVISED AGAIN ON 8/8/95
!
      FF  =F80-2.0
      FF2 =FF*FF
      APSI=1.029606
      BPSI=0.873692
      CPSI=0.165084
      PSI =APSI+BPSI*FF+CPSI*FF2
!
!  PSI COMPARISON
!
!      F80   PSITRUE    PSIEST
!      1.0   .320730   .320998
!      1.5   .634031   .634031
!      2.0  1.029606  1.029606
!      2.5  1.507723  1.502733
!      3.0  2.074348  2.068382
!
      DO J=1,5
      TINV(NN,J)=TINV0(J)*PSI
      END DO
!
!  SPECIFY 1990 (J=226) PARTIAL CONCS AND CONVOLUTION CONSTANTS
!   REVISED ON 3/16/95
!   REVISED AGAIN ON 4/2/95
!   REVISED AGAIN ON 6/12/95 (AA NOT CHANGED, CPART VERY MINOR)
!   REVISED AGAIN ON 8/8/95 (AA AND CPART CHANGED)
!
      CPART(NN,1)=18.40290
      CPART(NN,2)=25.51023
      CPART(NN,3)=22.51496
      CPART(NN,4)= 9.64078
      CPART(NN,5)= 0.38709
!
      AA(NN,1)= 0.13486
      AA(NN,2)= 0.22091
      AA(NN,3)= 0.28695
      AA(NN,4)= 0.26033
      AA(NN,5)= 0.09695
!
!  SPECIFY OR CALCULATE OTHER MAIN MODEL PARAMETERS
!
!  GPP IS THE PART OF GPP THAT IS NOT IMMEDIATELY RESPIRED BY
!   LEAVES AND GROUND VEG
!  RESP IS THE PART OF RESPIRATION THAT COMES FROM THE TREES
!  RG=RESP0/GPP0
!
      GPP0 =76.0
      RESP0=14.0
      PHI  =0.98
      XL   =0.05
      G1   =0.35
      G2   =0.60
      GAMP =0.70
      GAMH =0.05
!
      RG  =RESP0/GPP0
      G3  =1.0-G1-G2
      GAMS=1.0-GAMP-GAMH
!
!  TEMPERATURE FEEDBACK TERMS SPECIFIED IN MAG3GAS.CFG
!
      THPL=G1*GPP0-RESP0
      TAUP=PL0/THPL
      THP =1./(2.*TAUP)
      TAUH=HL0/(G2*GPP0+PHI*THPL)
      THH0=0.5/TAUH
      TAUS=SOIL0/(GPP0-RESP0-(1.0-XL)*HL0/TAUH)
      THS0=0.5/TAUS
!
!  QA0 IS THE INITIAL HLITT DECOMPOSITION FLUX TO ATMOSPHERE.
!
      QA0=(1.0-XL)*HL0/TAUH
!
!  QS0 IS THE INITIAL HLITT FLUX TO SOIL : U0 DITTO SOIL TO ATMOS
!
      QS0=XL*HL0/TAUH
      U0 =SOIL0/TAUS
!
!      FOC(NN,0) =0.0
!      EF(0)     =0.0
!      ESUM(0)   =0.0
!      ETOT(NN,0)=0.0
!
      FL1 =EL1/100.
      FL2 =EL2/100.
      FL3 =EL3/100.
      EL21=FL2-FL1
      EL32=FL3-FL2
      XX1 =FL1-DEE1
      XX2 =FL1+DEE2
      XX3 =FL2-DEE3
      XX4 =FL2+DEE4
      XX5 =FL3-DEE5
      XX6 =FL3+DEE6
!
      RETURN
      END
!
!  *******************************************
!
      SUBROUTINE CARBON(MM,TEM,EFOSS,ENETDEF,CPP,CPREV,C, &
      PL ,HU ,SO ,REGRO ,ETOT , &
      PL1,HU1,SO1,REGRO1,ETOT1, &
      SUMEM1,FLUX,DELM,EGROSSD,C1)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      DIMENSION A1(4,5)
!
      INTEGER FERTTYPE,TOTEM,CONVTERP
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
!
!  TERRESTRIAL CARBON CYCLE SECTION
!
!  FOR CALCULATING FEEDBACKS, NEED TO USE EXTRAPOLATED CO2
!   CONCENTRATION FOR THE MIDPOINT OF YEAR 'J' AFTER 1990.
!   FORMULA BELOW GIVES QUADRATIC EXTRAPOLATED RESULT.
!
!      CBAR=C+0.5*(C-CPREV)
      CBAR=(3.0*CPP-10.0*CPREV+15.0*C)/8.0
!
!  NOW CALCULATE GROSS DEFOR CORRESP TO INPUT NET DEFOR
!
      REGRO1=(REGRO*(TAUP-0.5)+GAMP*ENETDEF)/(TAUP+0.5-GAMP)
      EGROSSD=ENETDEF+REGRO1
!
!  TEMPERATURE TERMS
!
      FG=EXP(BTGPP*TEM)
      FR=EXP(BTRESP*TEM)
      FH=EXP(BTHUM*TEM)
      FS=EXP(BTSOIL*TEM)
!
!  DEFORESTATION TERMS
!
      GDP=GAMP*EGROSSD
      GDH=GAMH*EGROSSD
      GDS=GAMS*EGROSSD
!
!  CO2 FERTILIZATION TERMS. LOG FORM FIRST THEN FORM USED BY ENTING,
!   THEN FORM USED BY GIFFORD. ALSO CALCULATE BCO2 AT C=CCC=340PPMV
!
      IF(FERTTYPE.EQ.1)THEN
        Y1=BCO2(MM)*ALOG(CBAR/C0)+1.0
        B340(MM)=BCO2(MM)
      ELSE
!
!        CONCBASE=80.
!        GINF=2.4
!        BEE=C0*(GINF-1.0)-GINF*CONCBASE
!        GEE=GINF*(CBAR-CONCBASE)/(CBAR+BEE)
!        Y1=BCO2(MM)*(GEE-1.0)+1.0
!
        CB=31.
        R(MM)=(1.+BCO2(MM)*ALOG(680./C0))/(1.+BCO2(MM)*ALOG(340./C0))
        AR=680.-CB
        BR=340.-CB
        BEE=999.9
        IF(R(MM).NE.1.)BEE=(AR/BR-R(MM))/(R(MM)-1.)/AR
        DR=CBAR-CB
        CR=C0-CB
        Y1=1.0
        CCC=340.
        B340(MM)=0.0
        IF(R(MM).NE.1.)THEN
          Y1=(1./CR+BEE)/(1./DR+BEE)
          B340(MM)=(1./CR+BEE)*CCC/(1.+BEE*(CCC-CB))**2
        ENDIF
      ENDIF
!
      GPP=GPP0*Y1*FG
!
      PGPP=GPP*G1
      DPGPP=PGPP-GPP0*G1
      HGPP=GPP*G2
      DHGPP=HGPP-GPP0*G2
      SGPP=GPP*G3
      DSGPP=SGPP-GPP0*G3
      RESP=RESP0*Y1*FR
!
      DRESP=RESP-RESP0
!
!  NEW PLANT MASS
!
      PTERM=PGPP-RESP-GDP
      PL1=(PL*(1.0-THP)+PTERM)/(1.0+THP)
!
!  NEW HLITT MASS
!
      THH=THH0*FH
      Y2=THP*(PL+PL1)
      HTERM=HGPP+PHI*Y2-GDH
      HU1=(HU*(1.0-THH)+HTERM)/(1.0+THH)
!
!  NEW SOIL MASS
!
      THS=THS0*FS
      Y3=THH*(HU+HU1)
      STERM=SGPP+(1.0-PHI)*Y2+XL*Y3-GDS
      SO1=(SO*(1.0-THS)+STERM)/(1.0+THS)
!
!  FERTILIZATION FEEDBACK FLUX
!
      BFEED1=GPP0-RESP0-(GPP-RESP)
!
!  FEEDBACK FLUX DUE TO ACTIVE TERRESTRIAL BIOMASS
!
      HUBAR=(HU+HU1)/2.0
      SOBAR=(SO+SO1)/2.0
      QA1=FH*(1.0-XL)*HUBAR/TAUH
      U1=FS*SOBAR/TAUS
      AFEED1=QA1+U1-(QA0+U0)
!
!  TOTAL BIOMASS CHANGE
!
      DELSOIL=HU1+SO1-HU-SO
      DELB=PL1-PL+DELSOIL
!
!  ANN SUM OF EMISSIONS, OCEAN FLUX AND CUM SUM OF EMISSIONS.
!
      SUMEM1=EFOSS-DELB
      FLUX=SUMEM1-FACTOR*DELC
      IF(TOTEM.EQ.1)ETOT1=ETOT+SUMEM1
      IF(TOTEM.NE.1)ETOT1=ETOT+EFOSS+EGROSSD
!      IF(TOTEM.NE.1)ETOT1=ETOT+EFOSS-DELB
!
!  CALCULATE CONVOLUTION CONSTANTS AT THE END OF YEAR I. THIS
!    MAY BE DONE IN TWO WAYS, DETERMINED BY CONVTERP. NORMALLY
!    CONVTERP=1 SHOULD BE USED.
!
      EE=ETOT1/100.
!
      IF(CONVTERP.EQ.1)THEN
!
        DO K=1,5
        D21=(A(2,K)-A(1,K))/EL21
        D32=(A(3,K)-A(2,K))/EL32
        IF(EE.LE.XX1)THEN
          A1(MM,K)=A(1,K)
!
        ELSE IF(EE.LE.XX2)THEN
          DY=D21*DEE2
          X1=DEE1+DEE2
          X12=X1*X1
          AX=(D21-2.0*DY/X1)/X12
          BX=(3.*DY/X1-D21)/X1
          U=EE-XX1
          U2=U*U
          A1(MM,K)=A(1,K)+BX*U2+AX*U2*U
!
        ELSE IF(EE.LE.XX3)THEN
          U=EE-FL1
          A1(MM,K)=A(1,K)+D21*U
!
        ELSE IF(EE.LE.XX4)THEN
          Y0=A(2,K)-D21*DEE3
          DY=D21*DEE3+D32*DEE4
          DD=D21+D32
          X1=DEE3+DEE4
          X12=X1*X1
          AX=(DD-2.0*DY/X1)/X12
          BX=(3.*DY/X1-DD-D21)/X1
          U=EE-XX3
          U2=U*U
          A1(MM,K)=Y0+D21*U+BX*U2+AX*U2*U
!
        ELSE IF(EE.LE.XX5)THEN
          U=EE-FL2
          A1(MM,K)=A(2,K)+D32*U
!
        ELSE IF(EE.LE.XX6)THEN
          Y0=A(3,K)-D32*DEE5
          DY=D32*DEE5
          X1=DEE5+DEE6
          X12=X1*X1
          AX=(D32-2.0*DY/X1)/X12
          BX=(3.*DY/X1-2.0*D32)/X1
          U=EE-XX5
          U2=U*U
          A1(MM,K)=Y0+D32*U+BX*U2+AX*U2*U
!
        ELSE
          A1(MM,K)=A(3,K)
        ENDIF
!
        END DO
!
      ELSE
!
        XXX1=0.75*FL1
        XXX2=0.75*FL2
        XXX3=1.25*FL2
        XXX4=1.25*FL3
        DX12=XXX2-XXX1
        DX23=XXX4-XXX3
!
        DO K=1,5
        IF(EE.LE.XXX1)THEN
          A1(MM,K)=A(1,K)
        ELSE IF(EE.LE.XXX2)THEN
          Z1=EE-XXX1
          Z2=EE-XXX2
          DY12=A(2,K)-A(1,K)
          A1(MM,K)=A(1,K)+(DY12/DX12**3)*Z1*Z1*(Z1-3.0*Z2)
        ELSE IF(EE.LE.XXX3)THEN
          A1(MM,K)=A(2,K)
        ELSE IF(EE.LE.XXX4)THEN
          Z1=EE-XXX3
          Z2=EE-XXX4
          DY23=A(3,K)-A(2,K)
          A1(MM,K)=A(2,K)+(DY23/DX23**3)*Z1*Z1*(Z1-3.0*Z2)
        ELSE
          A1(MM,K)=A(3,K)
        ENDIF
        END DO
!
      ENDIF
!
!  ******************************************************************
!
!  CALCULATE NEW PARTIAL CONCS AND NEW CONCENTRATION.
!
      DELC=0.0
      DO J=1,5
      DELA=A1(MM,J)-AA(MM,J)
      ABAR=(A1(MM,J)+AA(MM,J))/2.0
      Z=(TINV(MM,J)-DELA/ABAR)/2.0
      DEL=(ABAR*SUMEM1/FACTOR-2.0*Z*CPART(MM,J))/(1.0+Z)
      CPART(MM,J)=CPART(MM,J)+DEL
      DELC=DELC+DEL
      FLUX=SUMEM1-FACTOR*DELC
      AA(MM,J)=A1(MM,J)
      END DO
      C1=C+DELC
      CBAR=(C1+C)/2.0
!
!  CALCULATE ANNUAL CHANGES IN ATMOSPHERIC MASS
!
      DELM=FACTOR*(C1-C)
!
      RETURN
      END
!
!  *******************************************
!
      SUBROUTINE HISTORY(JJJ,CO2,CH4,CN2O,eso2,eso21, &
      CF4,C2F6,C125,C134A,C143A,C227,C245,CSF6)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
!  THIS SUBROUTINE CALCULATES THE CONCS UP TO AND INCLUDING
!   1990 USING FITS TO OBSERVED DATA.
!  Concs are end of year values. Conc(1) is end of 1765 etc.
!  SO2 emissions values are for whole year, assumed to apply to
!   midpoint of year.
!  FOR THE KYOTO PROTOCOL GASES, ONLY THE 1990 VALUE IS GIVEN,
!   SINCE CURRENT VERSION OF CODE DOES NOT ALLOW CONCS FOR THESE
!   TO BE OUTPUT. THE 1990 VALUE IS NEEDED TO INITIALIZE CONC
!   CALCULATIONS FOR 1991 ONWARDS.
!
      COMMON/COBS/COBS(0:236)
      common /Sulph/S90DIR,S90IND,S90BIO,ENAT,ES1990,ECO90,FOC90,IFOC
!
!  ****************** HALOCARBONS AND RELATED SPECIES
!
!  SINCE PRE-1990 VALUES OF THESE 'HALO' CONCS ARE NOT USED, 
!   SUBROUTINE HISTORY SETS ALL THESE PRE-1990 VALUES TO THEIR
!   1990 LEVEL
!
      CF4    =  69.7
      C2F6   =   3.6
      C125   =    .0
      C134A  =    .0
      C143A  =    .0
      C227   =    .0
      C245   =    .0
      CSF6   =   3.2
!
!  ****************** CO2
!
!  CO2 : END OF YEAR CONCS ARE SPECIFIED IN A DATA STATEMENT IN
!   BLOCK DATA, IN ARRAY COBS. THIS ARRAY IS THE IPCC DATA SET
!   GENERATED BY ENTING AND WIGLEY FOR THE IPCC CONC STABILIZATION
!   EXERCISE. IMPLEMENTED ON DEC 30, 1993, UPDATED MAR 11, 1995
!
      CO2=COBS(JJJ)
!
!  ****************** CH4
!
      Y=JJJ+1764.0
!
!  Y CORRESPS TO END OF YEAR. E.G. IF JJJ=236, Y=2000.0, SO CONC
!   OUTPUT IS VALUE AT END OF YEAR 2000.
!
!  NEW CH4 (AUG. 2000). BEGINS WITH 700ppbv AT START OF 1750 (I.E.,
!   Y=1749.0) AND GOES TO 1100ppbv AT END OF 1940 (I.E., Y=1940.0).
!
      IF(Y.LE.1940.0)THEN
!
        Y1=Y-1749.
        CH4=700.0+400.0*Y1*Y1/(191.0**2)
!
      ELSE
!
        IF((Y.LE.1970.0).AND.(Y.GT.1940.0))THEN
          YY=Y-1940.
          CONC0=1100.0
          A=4.1885
          B=0.26643
          D=-0.0010469
        ENDIF
!
        IF((Y.LE.1980.0).AND.(Y.GT.1970.0))THEN
          YY=Y-1969.
          CONC0=1420.0
          A=17.0
          B=-0.5
          D=0.03
        ENDIF
!
        IF((Y.LE.1990.0).AND.(Y.GT.1980.0))THEN
          YY=Y-1979.
          CONC0=1570.0
          A=16.0
          B=-0.3
          D=0.0
        ENDIF
!
        IF((Y.LE.2001.0).AND.(Y.GT.1990.0))THEN
          YY=Y-1989.
          CONC0=1700.0
          A=10.0
          B=-1.0
          D=0.06
        ENDIF
!
        YY2=YY*YY
        CH4=CONC0+A*YY+B*YY2+D*YY*YY2
!
      ENDIF
!
!  ****************** N2O
!
      Y=JJJ+1764.0
!
!  Y CORRESPS TO END OF YEAR. E.G. IF JJJ=236, Y=2000.0, SO CONC
!   OUTPUT IS VALUE AT END OF YEAR 2000.
!
!  NEW N2O (AUG. 2000). BEGINS WITH 270ppbv AT START OF 1750 (I.E.,
!   Y=1749.0) AND GOES TO 290ppbv AT END OF 1950 (I.E., Y=1950.0).
!
      IF(Y.LE.1950.0)THEN
!
        Y1=Y-1749.
        CN2O=270.0+20.0*Y1*Y1/(201.0**2)
!
      ELSE
!
        IF((Y.LE.1970.0).AND.(Y.GT.1950.0))THEN
!
          YY=Y-1950.
          CONC0=290.0
          A=0.199
          B=-0.0083435
          D=0.00061685
        ENDIF
!
        IF((Y.LE.1980.0).AND.(Y.GT.1970.0))THEN
          YY=Y-1969.
          CONC0=295.0
          A=0.55
          B=0.005
          D=0.0
        ENDIF
!
        IF((Y.LE.1990.0).AND.(Y.GT.1980.0))THEN
          YY=Y-1979.
          CONC0=301.0
          A=0.65
          B=0.005
          D=0.0
        ENDIF
!
        IF((Y.LE.2001.0).AND.(Y.GT.1990.0))THEN
          YY=Y-1989.
          CONC0=308.0
          A=0.75
          B=0.01
          D=-0.0005
        ENDIF
!
        YY2=YY*YY
        CN2O=CONC0+A*YY+B*YY2+D*YY*YY2
!
      ENDIF
!
!  ****************** SO2 EMISSIONS
!
!  SO2 EMISSIONS : NEED TO CALC JJJ & JJJ+1 VALUES.
!   eso2 IS THE VALUE FOR YEAR J, NOMINALLY A MID-YEAR VALUE.
!   eso21 IS THE VALUE FOR YEAR J+1, NEEDED TO CALCULATE AN
!   EFFECTIVE END OF YEAR VALUE IN DETERMINING FORCING.
!  EXTENDED TO 2000 WITH SRES VALUES (AUG. 2000)
!
      DO I=0,1
      J=jjj+I
      ymid = J+1764.
      if(ymid.lt.1860.) then
        ee = 0.0
      else if(ymid.lt.1953) then
        ee = 35.0*(ymid-1860.)/93.0
      else if(ymid.lt.1973) then
        ee = 35.0+33.0*(ymid-1953.)/20.
      else IF(YMID.LT.1990)THEN
        ee = 68.0+(ES1990-68.0)*(ymid-1973.)/17.
      else IF(YMID.LT.2000)THEN
        ee = ES1990-1.876*(ymid-1990.)/10.
      endif
      IF(I.EQ.0)eso2=ee
      IF(I.EQ.1)eso21=ee
      END DO
!
      RETURN
      END
!
!  *******************************************
!
!     CALL METHANE(CH4B(J-1),EECH4,DENOX,DECO,DEVOC,CH4B(J),
!  &  T00MID,TAUBEST,SCH4,ANOX,ACO,AVOC)
!
      SUBROUTINE METHANE(ICH4F,CPREV,E,DEN,DEC,DEV,CONC, &
      TAU00,TAUOUT,S,AANOX,AACO,AAVOC,TEMP)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
!  ********************************************************************
!
!  METHANE MODEL USING PRATHER'S METHOD (FOR TAR)
!  MODIFIED TO BEGIN IN 2000
!  TAR METHOD :
!   dOH/0H = S*dB/B + AANOX*dEN +AACO*dEC +AAVOC*dEV   (Table 4.11)
!    WHERE S = -0.32 (Table 4.11) (Table 4.2 GIVES -0.34 ??)
!   dTAU/TAU = GAM * dOH/OH (GAM=-1.145, FROM DATA IN Table 4.2)
!    GAM SPECIFIED IN METH3 COMMON BLOCK
!
!  NOTE THAT CONC AND TAU VALUES ARE END-OF-YEAR VALUES
!
!  ********************************************************************
!
      COMMON /METH4/GAM,TAUOTHER,BBCH4,CM00
      Real TauSave(10)
!  ************************************************************
!
!  METHANE CONC PROJECTION.
!
!  FIRST ITERATION
!
      TAU0=TAU00
      B=CPREV*BBCH4
      B00=CM00*BBCH4
      AAA=EXP(GAM*(AANOX*DEN+AACO*DEC+AAVOC*DEV))
      X=GAM*S
      U=TAU00*AAA
	TauSave(1) = U
!
!  FIRST ITERATION
!
      BBAR=B
      TAUBAR=U*((BBAR/B00)**X)
      IF(ICH4F.EQ.1)TAUBAR=TAU00/(TAU00/TAUBAR+0.0316*TEMP)
      DB1=E-BBAR/TAUBAR-BBAR/TAUOTHER
      B1=B+DB1
!
!  SECOND ITERATION
!
      BBAR=(B+B1)/2.0
      TAUBAR=U*((BBAR/B00)**X)
      TAUBAR=TAUBAR*(1.0-0.5*X*DB1/B)
      IF(ICH4F.EQ.1)TAUBAR=TAU00/(TAU00/TAUBAR+0.0316*TEMP)
      DB2=E-BBAR/TAUBAR-BBAR/TAUOTHER
      B2=B+DB2
!
!  THIRD ITERATION
!
      BBAR=(B+B2)/2.0
      TAUBAR=U*((BBAR/B00)**X)
      TAUBAR=TAUBAR*(1.0-0.5*X*DB2/B)
      IF(ICH4F.EQ.1)TAUBAR=TAU00/(TAU00/TAUBAR+0.0316*TEMP)
      DB3=E-BBAR/TAUBAR-BBAR/TAUOTHER
      B3=B+DB3
    TauSave(2) = U*((BBAR/B00)**X)
	TauSave(3) = TAUBAR
!
!  FOURTH ITERATION
!
      BBAR=(B+B3)/2.0
      TAUBAR=U*((BBAR/B00)**X)
      TAUBAR=TAUBAR*(1.0-0.5*X*DB3/B)
      IF(ICH4F.EQ.1)TAUBAR=TAU00/(TAU00/TAUBAR+0.0316*TEMP)
      DB4=E-BBAR/TAUBAR-BBAR/TAUOTHER
      B4=B+DB4
	TauSave(4) = U*((BBAR/B00)**X)
	TauSave(5) = TAUBAR
!
!  LIFETIME AND CONCENTRATION AT END OF STEP
!
      TAUOUT=TAUBAR
      CONC=B4/BBCH4
!
      RETURN
      END
!
!  ********************************************************************
!
      SUBROUTINE NITROUS(C,CP,CPP,E,C1)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
      common /TauNitr/TN2000,BBN2O,SN2O,CN00,NOFFSET
!
!  *******************************************************
!
!  N2O CONC PROJECTIONS.
!
      B=C*BBN2O
      B00=CN00*BBN2O
      BBARPREV=0.5*(CP+CPP)*BBN2O
      S=SN2O
!
!  FIRST ITERATION
!
      BBAR=B
      TAUBAR=TN2000*((BBAR/B00)**S)
      DB1=E-BBARPREV/TAUBAR
      B1=B+DB1
!
!  NOTE : TAUBAR IS MIDYR VALUE; B1 IS ENDYR VALUE
!
!  SECOND ITERATION
!
      BBAR=(B+B1)/2.0
      TAUBAR=TN2000*((BBAR/B00)**S)
      DB2=E-BBARPREV/TAUBAR
      B2=B+DB2
!
!  THIRD ITERATION
!
      BBAR=(B+B2)/2.0
      TAUBAR=TN2000*((BBAR/B00)**S)
      DB3=E-BBARPREV/TAUBAR
      B3=B+DB3
!
!  FOURTH ITERATION
!
      BBAR=(B+B3)/2.0
      TAUBAR=TN2000*((BBAR/B00)**S)
      DB4=E-BBARPREV/TAUBAR
      B4=B+DB4
      C1=B4/BBN2O
!
      RETURN
      END
!
!  ***************************************
!
      SUBROUTINE INTERP(N,ISTART,IY,X,Y)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp =700)
!
      common /Limits/KEND
!
      DIMENSION IY(100),X(100),Y(226:iTp+1)
!
      IEND=ISTART+IY(N)
      DO I=0,IY(N)-1
        DO K=1,N
          IF(I.GE.IY(K).AND.I.LT.IY(K+1))THEN
            J=I+ISTART
            Y(J)=X(K)+(I-IY(K))*(X(K+1)-X(K))/(IY(K+1)-IY(K))
          ENDIF
        END DO
      END DO
      Y(IEND)=X(N)
!
! If last year in profile (relative to 1990) not KEND, then assume
!  constant emissions from last year specified in emissions profile
!  to KEND.
!
      if(iy(n).lt.KEND) then
        do i=iend+1,KEND
          y(i) = x(n)
        end do
      end if
!
      RETURN
      END
!
!*************************************************
!
      SUBROUTINE SULPHATE(JY,ESO2,ESO21,ECO,QSO2,QDIR,QFOC,QMN)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
      parameter (iTp=740)
!
      common /Sulph/S90DIR,S90IND,S90BIO,ENAT,ES1990,ECO90,FOC90,IFOC
!
!  DIRECT AND INDIRECT SULPHATE FORCING
!
!  Tall stack effect factor
!
      if(jy.lt.186) then
        f = 0.7
      else if(jy.lt.206) then
        f = 0.7 + 0.3*(jy-186)/20.
      else
        f = 1.0
      endif
!
      ky = jy + 1
      if(ky.lt.186) then
        f1 = 0.7
      else if(ky.lt.206) then
        f1 = 0.7 + 0.3*(ky-186)/20.
      else
        f1 = 1.0
      endif
!
!  Calculate end of year emissions and ditto corrected for tall
!   stack effect
!
      eraw=(eso2+eso21)/2.0
      e = (f*eso2+f1*eso21)/2.
!
!  Calculate global forcing at end of year.
!
!  Initialise SO2 parameters.  ORIGINALLY USED VALUES BASED ON
!   CHARLSON ET AL. ALTERED TO FIT IPCC94 ON OCT 16, 1994.
!   FURTHER MODIFIED ON FEB 24, 1995  FOR IPCC95
!  MOVED FROM SUBROUTINE INIT TO SUBROUTINE SULPHATE ON 3/10/95
!   WITH ASO2 AND BSO2 ELIMINATED
!
      qdir   = e*s90dir/ES1990
      qindir = s90ind*(alog(1.0+e/ENAT))/(alog(1.0+ES1990/ENAT))
!
      qso2   =  qdir+qindir
!
!********************************************************
!
!  FOSSIL ORGANIC PLUS BLACK CARBON
!   HISTORY : FOR SIMPLICITY, SCALE WITH SO2 EMISSIONS
!   FUTURE : IF IFOC=0, QFOC CONSTANT AT 1990 LEVEL
!            IF IFOC=1, SCALE WITH SO2 EMISSIONS
!            IF IFOC=2, SCALE WITH CO EMISSIONS
!
      IF(JY.LE.226)QFOC=E*FOC90/ES1990
      IF(JY.GT.226)THEN
        IF(IFOC.EQ.0)QFOC=FOC90
        IF(IFOC.EQ.1)QFOC=E*FOC90/ES1990
        IF(IFOC.EQ.2)QFOC=ECO*FOC90/ECO90
      ENDIF
!
!********************************************************
!
!  ADD NITRATE AND MINERAL DUST TO QDIR AND QSO2
!
      QNO390=-0.1
      QMIN90=-0.1
      IF(JY.LE.226)THEN
        QNO3=QNO390*FLOAT(JY)/226.0
        QMIN=QMIN90*FLOAT(JY)/226.0
      ELSE
        QNO3=QNO390
        QMIN=QMIN90
      ENDIF
      QMN=QNO3+QMIN
!
!********************************************************
!
!  NOTE : BECAUSE THESE FORCINGS MUST BE SPLIT INTO NH/SH AND
!   LAND/OCEAN, QDIR AND QSO2 ARE COMBINED HERE WITH QFOC.
!   QFOC IS STILL TRANSFERRED TO MAIN PROGRAM IN CASE IT NEEDS
!   TO BE SPLIT OFF LATER
!
      QDIR=QDIR+QFOC
      QSO2=QSO2+QFOC
!
      RETURN
      END
!
!  ******************************************************************
!
      SUBROUTINE LAMCALC(Q,FNHL,FSHL,XK,XKH,DT2X,A,LAMOBEST,LAMLBEST)
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
!
! Revision history:
!  950215 : CONVERTED TO SUBROUTINE FOR STAG.FOR
!  950208 : ITERATION ALGORITHM IMPROVED YET AGAIN
!  950206 : ITERATION ALGORITHM IMPROVED AGAIN
!  950205 : MATRIX INVERSION CORRECTED
!  950204 : ITERATION ALGORITHM IMPROVED
!  950203 : FIRST VERSION OF PROGRAM WRITTEN
!
!  THIS SUBROUTINE CALCULATES LAND AND OCEAN FEEDBACK
!   PARAMETER VALUES GIVEN THE GLOBAL DT2X AND THE LAND TO
!   OCEAN EQUILIBRIUM WARMING RATIO (A).
!  BOTH THE INPUT VALUES OF FNHL AND FSHL, AND THE INPUT XK
!   (XKLO IN MAIN) AND XKH (XKNS IN MAIN) ARE DOUBLE WHAT
!   ARE USED HERE.
!
      DIMENSION AEST(100),DIFF(100)
!
      REAL LAMO(100),LAML(100),LAMOBEST,LAMLBEST,LAM,KLO,KNS
!
      KLO=XK/2.0
      KNS=XKH/2.0
      FNL=FNHL/2.0
      FSL=FSHL/2.0
!
      IMAX=40
      DLAMO=1.0
      DIFFLIM=0.001
!
      FNO=0.5-FNL
      FSO=0.5-FSL
      FL=FNL+FSL
      FO=FNO+FSO
      FRATIO=FO/FL
!
      DT2XO=DT2X/(FO+A*FL)
      DT2XL=A*DT2XO
      LAM=Q/DT2X
      LAMO(1)=LAM
      LAMO(2)=LAM+DLAMO
!
      IFLAG=0
      DO 1 I=1,IMAX
!
      LAML(I)=LAM+FRATIO*(LAM-LAMO(I))/A
!
!  SOLVE FOR NH/SH OCEAN/LAND TEMPS
!   FIRST SPECIFY COEFFICIENT MATRIX : A(I,J)
!
      A11= FNO*LAMO(I)+KLO+KNS
      A12=-KLO
      A13=-KNS
      A14= 0.0
      A22= FNL*LAML(I)+KLO
      A23= 0.0
      A24= 0.0
      A33= FSO*LAMO(I)+KLO+KNS
      A34= A12
      A44= FSL*LAML(I)+KLO
!
!  CALCULATE INVERSE OF COEFFICIENT MATRIX : B(I,J)
!   FIRST DETERMINE DETERMINANT OF A(I,J) MATRIX
!
      C1 = A11*A22-A12*A12
      C2 = A33*A44-A12*A12
      C3 = A22*A13
      C4 = A44*A13
      DET= C1*C2-C3*C4
!
      B11= A22*C2/DET
      B12=-A12*C2/DET
      B13=-A44*C3/DET
      B14= A12*C3/DET
      B22= (A11*C2-A13*C4)/DET
      B23= A12*C4/DET
      B24=-A12*A12*A13/DET
      B33= A44*C1/DET
      B34=-A12*C1/DET
      B44= (A33*C1-A13*C3)/DET
!
!  CALCULATE ESTIMATED NH/SH OCEAN/LAND EQUILIBRIUM TEMPS
!
      TNO=(B11*FNO+B12*FNL+B13*FSO+B14*FSL)*Q
      TNL=(B12*FNO+B22*FNL+B23*FSO+B24*FSL)*Q
      TSO=(B13*FNO+B23*FNL+B33*FSO+B34*FSL)*Q
      TSL=(B14*FNO+B24*FNL+B34*FSO+B44*FSL)*Q
!
!  CALCULATE ESTIMATED OCEAN-MEAN AND LAND-MEAN TEMPS
!
      DT2XLE=(TNL*FNL+TSL*FSL)/FL
      DT2XOE=(TNO*FNO+TSO*FSO)/FO
!
!  CALCULATE ESTIMATED N.H. AND S.H. TEMPERATURES
!
      TNH=(TNL*FNL+TNO*FNO)/0.5
      TSH=(TSL*FSL+TSO*FSO)/0.5
!
!  CALCULATE ESTIMATED VALUE OF A
!
      AEST(I)=DT2XLE/DT2XOE
      AAAA=AEST(I)
      DIFF(I)=A-AEST(I)
!
!  TEST DIFF TO DECIDE WHETHER TO END ITERATION LOOP
!
      IF(ABS(DIFF(I)).LT.DIFFLIM)GO TO 2
!
      IF(I.GE.2)THEN
        DD=DIFF(I)*DIFF(I-1)
!
        IF(DD.LT.0.0)THEN
          IFLAG=1
        ELSE
          IF(ABS(DIFF(I)).GT.ABS(DIFF(I-1)))DLAMO=-DLAMO
          LAMO(I+1)=LAMO(I)+DLAMO
        ENDIF
!
        IF(IFLAG.EQ.1)THEN
          IF(DD.LT.0.0)THEN
            RATIO=(LAMO(I)-LAMO(I-1))/(DIFF(I)-DIFF(I-1))
            LAMO(I+1)=LAMO(I)-RATIO*DIFF(I)
          ELSE
            RATIO=(LAMO(I)-LAMO(I-2))/(DIFF(I)-DIFF(I-2))
            LAMO(I+1)=LAMO(I)-RATIO*DIFF(I)
          ENDIF
        ENDIF
!
      ENDIF
!
   1  CONTINUE
   2  CONTINUE
!
      LAMOBEST=LAMO(I)
      LAMLBEST=LAML(I)
!
      RETURN
      END

!*****************************************************************************************
! sjs New routines to get values from MAGICC 
!*****************************************************************************************

      FUNCTION getCO2Conc( inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine co2Conc to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::getCO2Conc

      parameter (iTp=740)

      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),co2(0:iTp),CO2SAVE(0:iTp)

	  REAL*4 getCO2Conc

      IYR = inYear-1990+226

      getCO2Conc = CO2( IYR )

      RETURN 
	  END
	    
      FUNCTION getSLR( inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine co2Conc to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::getCO2Conc

      parameter (iTp=740)

      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)

	  REAL*4 getSLR

      IYR = inYear-1990+226
      ST1=SLT(IYR)
      SO1=SLO(IYR)
      SLRAW1=ST1-SO1

      getSLR = SLRAW1

      RETURN 
	  END

      FUNCTION getGHGConc( ghgNumber, inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine ghgConc to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::getGHGConc

      parameter (iTp=740)

      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),co2(0:iTp),CO2SAVE(0:iTp)

      COMMON/CONCS/CH4(0:iTp),CN2O(0:iTp),ECH4(226:iTp+1), &
     EN2O(226:iTp+1),ECO(226:iTp+1),COE(iTp+1),EVOC(226:iTp+1), &
     ENOX(226:iTp+1),ESO2(0:iTp+1),ESO2SUM(226:iTp+1), &
     ESO21(226:iTp+1),ESO22(226:iTp+1),ESO23(226:iTp+1), &
     EBC(226:iTp+1), EOC(226:iTp+1) ! sjs- add BC-OC
!
      COMMON/NEWCONCS/CF4(iTp),C2F6(iTp),C125(iTp),C134A(iTp), &
     C143A(iTp),C227(iTp),C245(iTp),CSF6(iTp), &
     ECF4(226:iTp+1),EC2F6(226:iTp+1),E125(226:iTp+1),E134A(226:iTp+1), &
     E143A(226:iTp+1),E227(226:iTp+1),E245(226:iTp+1),ESF6(226:iTp+1)

	  REAL*4 getGHGConc
      INTEGER ghgNumber

      IYR = inYear-1990+226
	  
	  ! For consistency, make sure indices are same here as in getForcing
      select case (ghgNumber)
      case(1); getGHGConc = CO2( IYR )
      case(2); getGHGConc = CH4( IYR )
      case(3); getGHGConc = CN2O( IYR )
      case(4); getGHGConc = C2F6( IYR )
      case(5); getGHGConc = C125( IYR )
      case(6); getGHGConc = C134A( IYR )
      case(7); getGHGConc = C143A( IYR )
      case(8); getGHGConc = C245( IYR )
      case(9); getGHGConc = CSF6( IYR )
      case(10); getGHGConc = CF4( IYR )
      case(11); getGHGConc = C227( IYR )
      case default; getGHGConc = -1.0
      end select;
      

      RETURN 
	  END
	  
! Returns mid-year forcing for a given gas
      FUNCTION getForcing( iGasNumber, inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine getForcing to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::getForcing

      parameter (iTp=740)

      COMMON /FORCE/qco2(0:iTp),qm(0:iTp),qn(0:iTp),QCFC(0:iTp), &
     QMONT(0:iTp),QOTHER(0:iTp),QSTRATOZ(0:iTp),QCH4O3(0:iTp), &
     CFC12(0:iTp), QCH4H2O(0:iTp),QBC(0:iTp),QOC(0:iTp)
!
      COMMON /HALOF/QCF4_ar(0:iTp),QC2F6_ar(0:iTp),qSF6_ar(0:iTp), &
      Q125_ar(0:iTp),Q134A_ar(0:iTp), &
      Q143A_ar(0:iTp),Q227_ar(0:iTp),Q245_ar(0:iTp)

      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)

      COMMON /JSTART/JSTART,FOSSHIST(0:236),QKYMAG(0:iTp),IGHG, &
     QCH4OZ,QFOC(0:iTp),ICO2CORR,TROZSENS

      COMMON/STOREDVALS/ TEMUSER(iTp),QSO2SAVE(0:iTp+1),QDIRSAVE(0:iTp+1)

      COMMON /QADD/IQREAD,OrgIQREAD,JQFIRST,JQLAST,QEX(0:iTp),QEXNH(0:iTp), &
     QEXSH(0:iTp),QEXNHO(0:iTp),QEXNHL(0:iTp),QEXSHO(0:iTp), &
     QEXSHL(0:iTp),IOLDTZ

	  REAL*4 getForcing
        
      IYR = inYear-1990+226
      IYRP = IYR - 1
      
! Calculate mid-year forcing components
        QQQCO2 = (QCO2(IYR)+QCO2(IYRP))/2.
        QQQM   = (QM(IYR)+QM(IYRP))/2.
        QQQN   = (QN(IYR)+QN(IYRP))/2.
        QQQCFC = (QCFC(IYR)+QCFC(IYRP))/2.
        QQQOZ  = (QOZ(IYR)+QOZ(IYRP))/2.
        QQQFOCR  = (QFOC(M00)     +QFOC(M01))     /2.

        QQQSO2 = 0.0
        QQQDIR = 0.0
        IF(inYear.GT.1860)THEN
          QQQSO2 = (QSO2SAVE(IYR)+QSO2SAVE(IYRP))/2.
          QQQDIR = (QDIRSAVE(IYR)+QDIRSAVE(IYRP))/2.
        ENDIF
         QQQIND = QQQSO2-QQQDIR
         DELQFOC = (QFOC(IYR)+QFOC(IYRP))/2.-QQQFOCR
!
         QQQCO2 = (QCO2(IYR)+QCO2(IYRP))/2.
         QQQM   = (QM(IYR)+QM(IYRP))/2.
         QQQN   = (QN(IYR)+QN(IYRP))/2.
         QQQCFC = (QCFC(IYR)+QCFC(IYRP))/2.
         QQQOZ  = (QOZ(IYR)+QOZ(IYRP))/2.
         QQQFOC = (QFOC(IYR)+QFOC(IYRP))/2.
         QQQMN  = (QMN(IYR)+QMN(IYRP))/2.
         
         QQQEXTRA = ( QEXNH(IYR)+QEXSH(IYR)+QEXNHO(IYR)+QEXNHL(IYR) + &
                      QEXNH(IYRP)+QEXSH(IYRP)+QEXNHO(IYRP)+QEXNHL(IYRP) )/2.
!
! NOTE SPECIAL CASE FOR QOZ BECAUSE OF NONLINEAR CHANGE OVER 1990
!
         IF(IYR.EQ.226)QQQOZ=QOZ(IYR)
!
         QQQLAND= (QLAND(IYR)+QLAND(IYRP))/2.
         QQQBIO = (QBIO(IYR)+QBIO(IYRP))/2.
         QQQTOT = QQQCO2+QQQM+QQQN+QQQCFC+QQQSO2+QQQBIO+QQQOZ+QQQLAND &
         +QQQMN
!
         QQCH4O3= (QCH4O3(IYR)+QCH4O3(IYRP))/2.
         QQQM   = QQQM-QQCH4O3
         QQQOZ  = QQQOZ+QQCH4O3
         QQQD   = QQQDIR-QQQFOC
 
         QQQSTROZ= (QSTRATOZ(IYR)+QSTRATOZ(IYRP))/2.
         IF(IO3FEED.EQ.0)QQQSTROZ=0.0 
!
         QQQKYMAG = (QKYMAG(IYR)+QKYMAG(IYRP))/2.
         QQQMONT  = (QMONT(IYR) +QMONT(IYRP)) /2.
         QQQOTHER = (QOTHER(IYR)+QOTHER(IYRP))/2.
         QQQKYOTO = QQQKYMAG+QQQOTHER
!
         QQQStratCH4H2O = (QCH4H2O(IYR)+QCH4H2O(IYRP))/2.	! Strat H2O forcing from CH4

         QQQBC = ( QBC(IYR) + QBC(IYRP) )/2.
         QQQOC = ( QOC(IYR) + QOC(IYRP) )/2.
 
 	     QQQTOT = QQQTOT + QQQBC + QQQOC
 	     QQQEXTRA = QQQEXTRA - (QQQBC + QQQOC)
 	     
	  ! For consistency, make sure indices are same here as in getGHGConc for gases that overlap
      select case (iGasNumber)
      case(0); getForcing = QQQTOT	! Total anthropogenic forcing
      case(1); getForcing = (QCO2(IYR)+QCO2(IYRP))/2.
      case(2); getForcing = (qm(IYR)+qm(IYRP))/2. - QQQStratCH4H2O - QQCH4O3! CH4 forcing, subtract indirect components so are just reporting just CH4 forcing
      case(3); getForcing = (qn(IYR)+qn(IYRP))/2.  ! N2O forcing
      case(4); getForcing = (QC2F6_ar(IYR)+QC2F6_ar(IYRP))/2.
      case(5); getForcing = (Q125_ar(IYR)+Q125_ar(IYRP))/2.
      case(6); getForcing = (Q134A_ar(IYR)+Q134A_ar(IYRP))/2.
      case(7); getForcing = (Q143A_ar(IYR)+Q143A_ar(IYRP))/2.
      case(8); getForcing = (Q245_ar(IYR)+Q245_ar(IYRP))/2.
      case(9); getForcing = (qSF6_ar(IYR)+qSF6_ar(IYRP))/2.
      case(10); getForcing = (QCF4_ar(IYR)+QCF4_ar(IYRP))/2.
      case(11); getForcing = (Q227_ar(IYR)+Q227_ar(IYRP))/2.
      case(12); getForcing = (QOTHER(IYR)+QOTHER(IYRP))/2.	! Other halo forcing (exogenous input)
      case(13); getForcing = QQQSO2 - DELQFOC ! Total SO2 forcing. Note QSO2 and QDIR includes FOC
      case(14); getForcing = QQQDIR	- DELQFOC ! SO2 direct forcing only. Note QSO2 and QDIR includes FOC
      case(15); getForcing = QQQOZ ! Tropospheric Ozone forcing, including CH4 component
      case(16); getForcing = (QCH4O3(IYR)+QCH4O3(IYRP))/2.	! Trop O3 change due to CH4
      case(17); getForcing = (QCH4H2O(IYR)+QCH4H2O(IYRP))/2.	! Strat H2O forcing from CH4
      case(18); getForcing = (QMONT(IYR)+QMONT(IYRP))/2.	! Montreal Protocol Gases forcing
      case(19); getForcing = (QSTRATOZ(IYR)+QSTRATOZ(IYRP))/2.	! Stratospheric Ozone Forcing due to CFC emissions changes
      case(20); getForcing = QQQBIO  ! MAGICC biomass burning aerosol forcing
      case(21); getForcing = (QFOC(IYR)+QFOC(IYRP))/2. ! MAGICC internal fossil BC+OC
      case(22); getForcing = QQQLAND ! Land Surface Albedo forcing
      case(23); getForcing = QQQMN	! Mineral and nitrous oxide aerosol forcing
      case(24); getForcing = QQQBC	! Custom BC forcing (total BC; land + combustion)
      case(25); getForcing = QQQOC	! Custom OC forcing (total BC; land + combustion)
      ! Note, QEXTRA is not included in total (since this is not always anthropogenic).
      case(26); getForcing = QQQEXTRA	! User (exogenous) input forcing
      ! RCPForcing. This is the older TAR definition of total forcing , exclusive of Albedo, Mineral and nitrous oxide aerosol forcing.
      case(27); getForcing = QQQTOT - (QQQLAND + QQQMN)	! User (exogenous) input forcing
      case default; getForcing = -1.0
      end select;
      
      RETURN 
	  END
	  
      FUNCTION getGMTemp( inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine gmTemp to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::gmTemp

      parameter (iTp=740)

      COMMON/STOREDVALS/ TEMUSER(iTp),QSO2SAVE(0:iTp+1),QDIRSAVE(0:iTp+1)

      COMMON/TANDSL/TEQU(iTp),TGAV(iTp),TNHO(iTp), &
     TSHO(iTp),TNHL(iTp),TSHL(iTp),TDEEP(iTp),TNHAV(iTp),TSHAV(iTp), &
     TLAND(iTp),TOCEAN(iTp),TOCN(40),TOCNPREV(40), &
     SIP,SGP,SAP,SLI(iTp),SLG(iTp),SLA(iTp),EX(0:iTp),SLT(iTp), &
     QTOT(0:iTp),QGH(0:iTp),QOZ(0:iTp),QBIO(0:iTp),SLO(iTp), &
     QSO2(0:iTp+1),QDIR(0:iTp+1),QLAND(0:iTp),QMN(0:iTp+1)

	  REAL*4 getGMTemp

      IYR = inYear-1990+226
      getGMTemp = TEMUSER(IYR)+TGAV(226)

      RETURN 
	  END

! Routine to pass in new values of parameters from calling program (e.g. ObjECTS) - sjs	  
    SUBROUTINE setParameterValues( index, value )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine co2Conc to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::setParameterValues

	  REAL*4 value
      
	  REAL*4 aNewClimSens, aNewBTsoil, aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, aNewSO2dir1990, aNewSO2ind1990
      COMMON/NEWPARAMS/aNewClimSens, aNewBTsoil, DT2XUSER,aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, &
      					aNewSO2dir1990, aNewSO2ind1990
      REAL*4 FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing !sjs
      COMMON/BCOC/FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing

      select case (index)
      case(1); aNewClimSens = value
      case(2); aNewBTsoil = value
      case(3); aNewBTHumus = value
      case(4); aNewBTGPP = value
      case(5); aNewDUSER = value
      case(6); aNewFUSER = value
      case(7); aNewSO2dir1990 = value
      case(8); aNewSO2ind1990 = value
      case(9); aBCUnitForcing = value
      case(10); aOCUnitForcing = value
      case default; 
      end select;

      RETURN 
	  END

! Routine to overide MAGICC parameeters with new values if these have been read-in
    SUBROUTINE overrideParameters( )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)

      parameter (iTp=740)

	  REAL*4 aNewClimSens, aNewBTsoil, aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, aNewSO2dir1990, aNewSO2ind1990
      COMMON/NEWPARAMS/aNewClimSens, aNewBTsoil, DT2XUSER,aNewBTGPP,aNewBTHumus,aNewDUSER,aNewFUSER, &
      					aNewSO2dir1990, aNewSO2ind1990

      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)

      COMMON /METH1/emeth(226:iTp),imeth,ch4l(225:iTp),ch4b(225:iTp), &
     ch4h(225:iTp),ef4(226:iTp),StratH2O,TCH4(iTp),iO3feed, &
     ednet(226:iTp+1),DUSER,FUSER,CORRUSER,CORRMHI,CORRMMID,CORRMLO

      REAL*4 FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing !sjs
      COMMON/BCOC/FBC1990, FOC1990, FSO2_dir1990,FSO2_ind1990, aBCUnitForcing, aOCUnitForcing

      IF(aNewClimSens.GT.0)THEN
        DT2XUSER   = aNewClimSens
      ENDIF

      IF(aNewBTsoil.GT.0)THEN
        BTSOIL   = aNewBTsoil
      ENDIF
      
      IF(aNewBTHumus.GT.0)THEN
        BTHUM   = aNewBTHumus
      ENDIF
      
      IF(aNewBTGPP.GT.0)THEN
        BTGPP   = aNewBTGPP
      ENDIF
      
      IF(aNewDUSER.GT.0)THEN
        DUSER   = aNewDUSER
      ENDIF
      
      IF(aNewFUSER.GT.0)THEN
        FUSER   = aNewFUSER
      ENDIF
      
      IF(aNewSO2dir1990.LT.0)THEN
        FSO2_dir1990   = aNewSO2dir1990
      ENDIF
      
      IF(aNewSO2ind1990.LT.0)THEN
        FSO2_ind1990   = aNewSO2ind1990
      ENDIF

      RETURN 
	  END
	    
! Returns climate results forcing for a given gas
      FUNCTION getCarbonResults( iResultNumber, inYear )
      IMPLICIT REAL*4 (a-h,o-z), Integer (I-N)
! Expose subroutine getCarbonResults to users of this DLL
!DEC$ATTRIBUTES DLLEXPORT::getCarbonResults

      parameter (iTp=740)

      COMMON/CARB/CCO2(4,224:iTp),EDGROSS(4,226:iTp),EF(226:iTp+1), &
     REGROW(4,226:iTp),PL(4,226:iTp),HL(4,226:iTp),SOIL(4,226:iTp), &
     TTT(226:iTp),ESUM(226:iTp),ETOT(4,226:iTp),EDNET90(4), &
     FOC(4,226:iTp),co2(0:iTp),CO2SAVE(0:iTp)
!
      COMMON/CAR/EL1,EL2,EL3,TINV0(5),TINV(4,5),A(3,5),AA(4,5), &
     BCO2(4),BTGPP,BTRESP,BTHUM,GAMP,GPP0,RESP0,QA0,U0,C0,B340(4), &
     PHI,RG,TAUP,TAUH,TAUS,THP,THS,THH0,THS0,THPL,G1,G2,G3,FACTOR, &
     EL21,EL32,XX1,XX2,XX3,XX4,XX5,XX6,DEE1,DEE2,DEE3,DEE4,DEE5,DEE6, &
     FL1,FL2,FL3,XL,GAMH,GAMS,QS0,BTSOIL,FERTTYPE,TOTEM,CONVTERP, &
     R(4),CPART(4,5),DELMASS(4,226:iTp),ABFRAC(4,226:iTp)
 
      COMMON /METH1/emeth(226:iTp),imeth,ch4l(225:iTp),ch4b(225:iTp), &
     ch4h(225:iTp),ef4(226:iTp),StratH2O,TCH4(iTp),iO3feed, &
     ednet(226:iTp+1),DUSER,FUSER,CORRUSER,CORRMHI,CORRMMID,CORRMLO

	  REAL*4 getCarbonResults
	  REAL*4 NetDef, GrossDef

        
      IYR = inYear-1990+226

!	  Branch for years > 1990

      IF ( inYear .ge. 1990 ) THEN
      IF(IMETH.EQ.0)THEN
        TOTE=EF(IYR)+EDNET(IYR)
      ELSE
        TOTE=EF(IYR)+EDNET(IYR)+EMETH(IYR)
      ENDIF
	    NetDef = EDNET(IYR)
	    GrossDef = EDGROSS(4,IYR)
	  ELSE
        TOTE = -1.0
		NetDef = -1.0
		GrossDef = -1.0
	  ENDIF
!
      ECH4OX=EMETH(IYR)
      IF(IMETH.EQ.0)ECH4OX=0.0
      
      getCarbonResults = - 1.0
      
      select case (iResultNumber)
      case(0); getCarbonResults = TOTE    ! Total emissions (fossil + netDef + Oxidation)
      case(1); getCarbonResults = EF(IYR) ! Fossil Emissions as used by MAGICC
      case(2); getCarbonResults = NetDef  ! Net Deforestation
      case(3); getCarbonResults = GrossDef  ! Gross Deforestation
      case(4); getCarbonResults = FOC(4,IYR)  ! Ocean Flux
      case(5); getCarbonResults = PL(4,IYR) ! Plant Carbon
      case(6); getCarbonResults = HL(4,IYR) ! Carbon in Litter
      case(7); getCarbonResults = SOIL(4,IYR) ! Carbon in Soils
      case(8); getCarbonResults = DELMASS(4,IYR)  ! Atmospheric Increase
      case(9); getCarbonResults = ECH4OX  ! Oxidation Addition to Atmosphere
      case(10); IF(inYear .ge. 1990 ) getCarbonResults = EF(IYR)+ECH4OX-(FOC(4,IYR)+DELMASS(4,IYR)) ! Net Terrestrial Uptake
      case default; getCarbonResults = -1.0
      end select;

      RETURN 
	  END

