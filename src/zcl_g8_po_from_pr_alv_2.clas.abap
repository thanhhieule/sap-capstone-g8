CLASS zcl_g8_po_from_pr_alv_2 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

* Range types

      TYPES:
  ty_r_ebeln TYPE RANGE OF ekko-ebeln,
  ty_r_banfn TYPE RANGE OF zpo_rlsitem_g8-banfn,
  ty_r_bedat TYPE RANGE OF ekko-bedat,
  ty_r_lifnr TYPE RANGE OF ekko-lifnr,
  ty_r_matnr TYPE RANGE OF zpo_rlsitem_g8-matnr,
  ty_r_werks TYPE RANGE OF zpo_rlsitem_g8-werks,
  ty_r_netpr TYPE RANGE OF zpo_rlsitem_g8-netpr,
  ty_r_eindt TYPE RANGE OF zpo_rlsitem_g8-eindt.


    METHODS:
      constructor
        IMPORTING
          it_ebeln TYPE ty_r_ebeln OPTIONAL
          it_banfn TYPE ty_r_banfn OPTIONAL
          it_bedat TYPE ty_r_bedat OPTIONAL
          it_lifnr TYPE ty_r_lifnr OPTIONAL
          it_matnr TYPE ty_r_matnr OPTIONAL
          it_werks TYPE ty_r_werks OPTIONAL
          it_netpr TYPE ty_r_netpr OPTIONAL
          it_eindt TYPE ty_r_eindt OPTIONAL,

      run.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_data,
             ebeln TYPE ebeln,
             ebelp TYPE ebelp,
             banfn TYPE banfn,
             bnfpo TYPE bnfpo,
             matnr TYPE matnr,
             werks TYPE werks_d,
             menge TYPE menge_d,
             meins TYPE meins,
             netpr TYPE netpr,
             waers TYPE waers,
             eindt TYPE eindt,
             lifnr TYPE lifnr,
             bedat TYPE bedat,
           END OF ty_data.

    DATA:

      mt_ebeln TYPE ty_r_ebeln,
      mt_banfn TYPE ty_r_banfn,
      mt_bedat TYPE ty_r_bedat,
      mt_lifnr TYPE ty_r_lifnr,
      mt_matnr TYPE ty_r_matnr,
      mt_werks TYPE ty_r_werks,
      mt_netpr TYPE ty_r_netpr,
      mt_eindt TYPE ty_r_eindt,

      gt_data TYPE STANDARD TABLE OF ty_data,
      go_alv  TYPE REF TO cl_salv_table.

    METHODS:

      get_data,
      display_alv,

      on_double_click
        FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.

ENDCLASS.


CLASS zcl_g8_po_from_pr_alv_2 IMPLEMENTATION.

METHOD constructor.
  mt_ebeln = it_ebeln.
  mt_banfn = it_banfn.
  mt_bedat = it_bedat.
  mt_lifnr = it_lifnr.
  mt_matnr = it_matnr.
  mt_werks = it_werks.
  mt_netpr = it_netpr.
  mt_eindt = it_eindt.
ENDMETHOD.

METHOD run.
  get_data( ).
  display_alv( ).
ENDMETHOD.

 METHOD get_data.



ENDMETHOD.

 METHOD display_alv.

  DATA lo_events TYPE REF TO cl_salv_events_table.

  IF gt_data IS INITIAL.
    MESSAGE 'No data found' TYPE 'I'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = gt_data ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
      RETURN.

  ENDTRY.

* Enable toolbar
  go_alv->get_functions( )->set_all( abap_true ).

* Optimize column width
  go_alv->get_columns( )->set_optimize( abap_true ).

* Zebra pattern
  go_alv->get_display_settings( )->set_striped_pattern( abap_true ).

* Register double click
  lo_events = go_alv->get_event( ).

  SET HANDLER me->on_double_click FOR lo_events.

* Display ALV
  go_alv->display( ).

ENDMETHOD.



  METHOD on_double_click.

    DATA ls_data TYPE ty_data.

    READ TABLE gt_data INTO ls_data INDEX row.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Open PO
    IF column = 'EBELN'.

      SET PARAMETER ID 'BES' FIELD ls_data-ebeln.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.

* Open PR
    ELSEIF column = 'BANFN'.

      SET PARAMETER ID 'BAN' FIELD ls_data-banfn.
      CALL TRANSACTION 'ME53N' AND SKIP FIRST SCREEN.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
