REPORT zalv_g8_pr_po_vdr_rate.

TABLES: ekko, eban, zpo_rlsitem_g8.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln NO INTERVALS,
  s_banfn FOR zpo_rlsitem_g8-banfn NO INTERVALS,
  s_bedat FOR ekko-bedat,
  s_lifnr FOR ekko-lifnr NO INTERVALS,
  s_ekgrp FOR eban-ekgrp NO INTERVALS,
  s_matnr FOR zpo_rlsitem_g8-matnr NO INTERVALS,
  s_netpr FOR zpo_rlsitem_g8-netpr,
  s_eindt FOR zpo_rlsitem_g8-eindt.
PARAMETERS p_idel AS CHECKBOX DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  DATA(lo_report) = NEW zcl_g8_vendor_pr_po_rate_alv(
    it_ebeln           = s_ebeln[]
    it_banfn           = s_banfn[]
    it_bedat           = s_bedat[]
    it_lifnr           = s_lifnr[]
    it_ekgrp           = s_ekgrp[]
    it_matnr           = s_matnr[]
    it_netpr           = s_netpr[]
    it_eindt           = s_eindt[]
    iv_include_deleted = p_idel ).

  lo_report->run( ).
