REPORT zalv_po_from_pr_g8_2.

TABLES: ekko, zpo_rlsitem_g8.

SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln,
  s_banfn FOR zpo_rlsitem_g8-banfn,
  s_bedat FOR ekko-bedat,
  s_lifnr FOR ekko-lifnr,
  s_matnr FOR zpo_rlsitem_g8-matnr,
  s_werks FOR zpo_rlsitem_g8-werks.

START-OF-SELECTION.

 DATA lo_report TYPE REF TO zcl_g8_po_from_pr_alv_2.

CREATE OBJECT lo_report
  EXPORTING
    it_ebeln = s_ebeln[]
    it_banfn = s_banfn[]
    it_bedat = s_bedat[]
    it_lifnr = s_lifnr[]
    it_matnr = s_matnr[].

lo_report->run( ).
