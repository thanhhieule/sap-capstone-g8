REPORT zalv_po_from_pr_g8.

PARAMETERS:
  PO TYPE banfn,
  PR TYPE ebeln.

START-OF-SELECTION.

  DATA(lo_report) = NEW zcl_g8_po_from_pr_alv(
                      iv_banfn = PO
                      iv_ebeln = PR ).

  lo_report->run( ).
