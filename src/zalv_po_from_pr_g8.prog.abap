REPORT zalv_po_from_pr_g8.

PARAMETERS:
  p_banfn TYPE banfn,
  p_ebeln TYPE ebeln.

START-OF-SELECTION.

  DATA(lo_report) = NEW zcl_g8_po_from_pr_alv(
                      iv_banfn = p_banfn
                      iv_ebeln = p_ebeln ).

  lo_report->run( ).
