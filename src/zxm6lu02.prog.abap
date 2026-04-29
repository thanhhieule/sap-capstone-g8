*----------------------------------------------------------------------*
* INCLUDE ZXM6LU02 - FIX LỖI XTVAB IS UNKNOWN
*----------------------------------------------------------------------*
DATA: lv_budat        TYPE ekbe-budat,
      lv_eindt        TYPE eket-eindt,
      lv_variance     TYPE i,
      lv_ebeln        TYPE ekbe-ebeln,
      lv_ebelp        TYPE ekbe-ebelp,
      lv_qty_variance TYPE p DECIMALS 2.

FIELD-SYMBOLS: <fs_mseg_menge> TYPE any,
               <fs_ekep_menge> TYPE any,
               <fs_xtvab>      TYPE any. " Dùng cái này để fix lỗi Unknown XTVAB

*----------------------------------------------------------------------*
* 1. TIÊU CHÍ 01: GIAO HÀNG ĐÚNG HẠN
*----------------------------------------------------------------------*
IF xtkrit = '01' OR xtkrit = '1'.
  SELECT a~ebeln a~ebelp a~budat
    INTO (lv_ebeln, lv_ebelp, lv_budat)
    FROM ekbe AS a
    INNER JOIN ekko AS b ON a~ebeln = b~ebeln
    UP TO 1 ROWS
   WHERE b~lifnr = xlifnr
     AND b~ekorg = xekorg
     AND a~vgabe = '1'
     AND a~bwart = '101'
   ORDER BY a~budat DESCENDING.
  ENDSELECT.

  IF sy-subrc = 0.
    SELECT SINGLE eindt FROM eket INTO lv_eindt
     WHERE ebeln = lv_ebeln AND ebelp = lv_ebelp.
    IF sy-subrc = 0 AND lv_eindt IS NOT INITIAL.
      lv_variance = lv_budat - lv_eindt.

      " Gán giá trị vào XTVAB thông qua con trỏ nếu gọi trực tiếp bị lỗi
      ASSIGN ('XTVAB') TO <fs_xtvab>.
      IF <fs_xtvab> IS ASSIGNED.
        <fs_xtvab> = lv_variance.
      ENDIF.

      IF lv_variance <= 0.
        xbeurt = 100.
      ELSEIF lv_variance <= 3.
        xbeurt = 90.
      ELSEIF lv_variance <= 8.
        xbeurt = 80.
      ELSE.
        xbeurt = 10.
      ENDIF.
    ELSE.
      xbeurt = 1.
    ENDIF.
  ELSE.
    xbeurt = 1.
  ENDIF.

*----------------------------------------------------------------------*
* 2. TIÊU CHÍ 02: ĐỦ SỐ LƯỢNG
*----------------------------------------------------------------------*
ELSEIF xtkrit = '02' OR xtkrit = '2'.

  ASSIGN ('(SAPLMEL0)YELKEP-MENGE') TO <fs_ekep_menge>.
  ASSIGN ('(SAPLMEL0)YMSEG-MENGE') TO <fs_mseg_menge>.
  ASSIGN ('XTVAB') TO <fs_xtvab>.

  IF <fs_ekep_menge> IS ASSIGNED AND <fs_ekep_menge> <> 0.
    IF <fs_mseg_menge> IS ASSIGNED.
       lv_qty_variance = ( ( <fs_mseg_menge> - <fs_ekep_menge> ) / <fs_ekep_menge> ) * 100.

       IF <fs_xtvab> IS ASSIGNED.
         <fs_xtvab> = lv_qty_variance.
       ENDIF.

       IF lv_qty_variance = 0.
         xbeurt = 100.
       ELSEIF lv_qty_variance < 0.
         xbeurt = 50.
       ELSE.
         xbeurt = 80.
       ENDIF.
    ENDIF.
  ELSE.
    xbeurt = 1.
  ENDIF.

ENDIF.
