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
