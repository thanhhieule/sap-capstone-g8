REPORT zalv_po_from_pr_g8_2.

TABLES: ekko, zpo_rlsitem_g8.

* Texts are maintained in Report Text Elements: hieu
* - Text Symbols: T01 (block title), I01/I02 (hints)
* - Selection Texts: S_EBELN, S_BANFN, S_BEDAT, S_NETPR, S_LIFNR, S_MATNR, S_WERKS

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
SELECTION-SCREEN COMMENT /1(79) TEXT-i01.
SELECTION-SCREEN COMMENT /1(79) TEXT-i02.

SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln NO INTERVALS,
  s_banfn FOR zpo_rlsitem_g8-banfn NO INTERVALS,
  s_bedat FOR ekko-bedat,
  s_netpr FOR zpo_rlsitem_g8-netpr,
  s_lifnr FOR ekko-lifnr NO INTERVALS,
  s_werks FOR zpo_rlsitem_g8-werks NO INTERVALS,
  s_matnr FOR zpo_rlsitem_g8-matnr NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  IF s_bedat[] IS INITIAL.
    APPEND VALUE #( sign = 'I'
                    option = 'BT'
                    low = sy-datum
                    high = sy-datum ) TO s_bedat.
  ENDIF.

  IF s_netpr[] IS INITIAL.
    APPEND VALUE #( sign = 'I'
                    option = 'GE'
                    low = CONV zpo_rlsitem_g8-netpr( 0 ) ) TO s_netpr.
  ENDIF.

AT SELECTION-SCREEN.
  PERFORM validate_single_exact_values.

" If you want to rename technical variable names (e.g. S_EBELN),
" update both places:
" 1) SELECT-OPTIONS declaration above
" 2) Constructor mapping in CREATE OBJECT below (it_ebeln = s_ebeln[] ...)

START-OF-SELECTION.

 DATA lo_report TYPE REF TO zcl_g8_po_from_pr_alv_2.

CREATE OBJECT lo_report
  EXPORTING
    it_ebeln = s_ebeln[]
    it_banfn = s_banfn[]
    it_bedat = s_bedat[]
    it_netpr = s_netpr[]
    it_lifnr = s_lifnr[]
    it_matnr = s_matnr[]
    it_werks = s_werks[].

lo_report->run( ).







FORM validate_single_exact_values.

  DATA: ls_ebeln LIKE LINE OF s_ebeln,
        ls_banfn LIKE LINE OF s_banfn,
        ls_netpr LIKE LINE OF s_netpr,
        ls_lifnr LIKE LINE OF s_lifnr,
        ls_werks LIKE LINE OF s_werks,
        ls_matnr LIKE LINE OF s_matnr.

  LOOP AT s_ebeln INTO ls_ebeln.
    IF ls_ebeln-low IS NOT INITIAL
       AND ls_ebeln-low CN ' 0123456789'.
      MESSAGE 'PO Number only allows digits (0-9).' TYPE 'E'.
    ENDIF.
    IF ls_ebeln-high IS NOT INITIAL
       AND ls_ebeln-high CN ' 0123456789'.
      MESSAGE 'PO Number only allows digits (0-9).' TYPE 'E'.
    ENDIF.
  ENDLOOP.

  LOOP AT s_banfn INTO ls_banfn.
    IF ls_banfn-low IS NOT INITIAL
       AND ls_banfn-low CN ' 0123456789'.
      MESSAGE 'PR Number only allows digits (0-9).' TYPE 'E'.
    ENDIF.
    IF ls_banfn-high IS NOT INITIAL
       AND ls_banfn-high CN ' 0123456789'.
      MESSAGE 'PR Number only allows digits (0-9).' TYPE 'E'.
    ENDIF.
  ENDLOOP.

  LOOP AT s_lifnr INTO ls_lifnr.
    IF ls_lifnr-low IS NOT INITIAL
       AND ls_lifnr-low CN ' 0123456789'.
      MESSAGE 'Vendor only allows digits (0-9).' TYPE 'E'.
    ENDIF.
    IF ls_lifnr-high IS NOT INITIAL
       AND ls_lifnr-high CN ' 0123456789'.
      MESSAGE 'Vendor only allows digits (0-9).' TYPE 'E'.
    ENDIF.
  ENDLOOP.

  LOOP AT s_netpr INTO ls_netpr.
    IF ls_netpr-low IS NOT INITIAL
       AND ls_netpr-low < 0.
      MESSAGE 'Net Price must be greater than or equal to 0.' TYPE 'E'.
    ENDIF.
    IF ls_netpr-high IS NOT INITIAL
       AND ls_netpr-high < 0.
      MESSAGE 'Net Price must be greater than or equal to 0.' TYPE 'E'.
    ENDIF.
  ENDLOOP.

  IF lines( s_ebeln ) = 1.
    READ TABLE s_ebeln INTO ls_ebeln INDEX 1.
    IF sy-subrc = 0
       AND ls_ebeln-sign = 'I'
       AND ls_ebeln-option = 'EQ'
       AND ls_ebeln-low IS NOT INITIAL
       AND ls_ebeln-high IS INITIAL.
      SELECT SINGLE ebeln
        FROM ekko
        WHERE ebeln = @ls_ebeln-low
        INTO @DATA(lv_ebeln).
      IF sy-subrc <> 0.
        MESSAGE |PO Number { ls_ebeln-low } does not exist.| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lines( s_banfn ) = 1.
    READ TABLE s_banfn INTO ls_banfn INDEX 1.
    IF sy-subrc = 0
       AND ls_banfn-sign = 'I'
       AND ls_banfn-option = 'EQ'
       AND ls_banfn-low IS NOT INITIAL
       AND ls_banfn-high IS INITIAL.
      SELECT SINGLE banfn
        FROM zpo_rlsitem_g8
        WHERE banfn = @ls_banfn-low
        INTO @DATA(lv_banfn).
      IF sy-subrc <> 0.
        MESSAGE |PR Number { ls_banfn-low } does not exist.| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lines( s_lifnr ) = 1.
    READ TABLE s_lifnr INTO ls_lifnr INDEX 1.
    IF sy-subrc = 0
       AND ls_lifnr-sign = 'I'
       AND ls_lifnr-option = 'EQ'
       AND ls_lifnr-low IS NOT INITIAL
       AND ls_lifnr-high IS INITIAL.
      SELECT SINGLE lifnr
        FROM lfa1
        WHERE lifnr = @ls_lifnr-low
        INTO @DATA(lv_lifnr).
      IF sy-subrc <> 0.
        MESSAGE |Vendor { ls_lifnr-low } does not exist.| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lines( s_werks ) = 1.
    READ TABLE s_werks INTO ls_werks INDEX 1.
    IF sy-subrc = 0
       AND ls_werks-sign = 'I'
       AND ls_werks-option = 'EQ'
       AND ls_werks-low IS NOT INITIAL
       AND ls_werks-high IS INITIAL.
      SELECT SINGLE werks
        FROM t001w
        WHERE werks = @ls_werks-low
        INTO @DATA(lv_werks).
      IF sy-subrc <> 0.
        MESSAGE |Plant { ls_werks-low } does not exist.| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lines( s_matnr ) = 1.
    READ TABLE s_matnr INTO ls_matnr INDEX 1.
    IF sy-subrc = 0
       AND ls_matnr-sign = 'I'
       AND ls_matnr-option = 'EQ'
       AND ls_matnr-low IS NOT INITIAL
       AND ls_matnr-high IS INITIAL.
      SELECT SINGLE matnr
        FROM mara
        WHERE matnr = @ls_matnr-low
        INTO @DATA(lv_matnr).
      IF sy-subrc <> 0.
        MESSAGE |Material { ls_matnr-low } does not exist.| TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.
