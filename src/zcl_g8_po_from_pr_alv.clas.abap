CLASS zcl_g8_po_from_pr_alv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS:
      constructor
        IMPORTING
          iv_banfn TYPE banfn OPTIONAL
          iv_ebeln TYPE ebeln OPTIONAL,

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
      mv_banfn TYPE banfn,
      mv_ebeln TYPE ebeln,
      gt_data  TYPE STANDARD TABLE OF ty_data,
      go_alv   TYPE REF TO cl_salv_table.

    METHODS:
      get_data,
      display_alv,
      on_double_click
        FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.

ENDCLASS.


CLASS zcl_g8_po_from_pr_alv IMPLEMENTATION.


  METHOD constructor.

    mv_banfn = iv_banfn.
    mv_ebeln = iv_ebeln.

  ENDMETHOD.



  METHOD run.

    get_data( ).
    display_alv( ).

  ENDMETHOD.



  METHOD get_data.

    SELECT
      a~ebeln,
      a~ebelp,
      a~banfn,
      a~bnfpo,
      a~matnr,
      a~werks,
      a~menge,
      a~meins,
      a~netpr,
      a~waers,
      a~eindt,
      b~lifnr,
      b~bedat
    FROM zpo_rlsitem_g8 AS a
    LEFT JOIN ekko AS b
      ON a~ebeln = b~ebeln
    WHERE a~banfn IS NOT INITIAL
      AND ( a~banfn = @mv_banfn OR @mv_banfn IS INITIAL )
      AND ( a~ebeln = @mv_ebeln OR @mv_ebeln IS INITIAL )
    INTO TABLE @gt_data.

  ENDMETHOD.


  METHOD display_alv.

    DATA lo_events TYPE REF TO cl_salv_events_table.

    IF gt_data IS INITIAL.
      MESSAGE 'No data found' TYPE 'I'.
      RETURN.
    ENDIF.

    cl_salv_table=>factory(
      IMPORTING r_salv_table = go_alv
      CHANGING  t_table      = gt_data ).

* Enable standard ALV functions
    go_alv->get_functions( )->set_all( abap_true ).

* Optimize column width
    go_alv->get_columns( )->set_optimize( abap_true ).

* Zebra pattern
    go_alv->get_display_settings( )->set_striped_pattern( abap_true ).

* Register double click event
    lo_events = go_alv->get_event( ).

    SET HANDLER me->on_double_click FOR lo_events.

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
