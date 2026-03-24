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
             maktx TYPE maktx,
             werks TYPE werks_d,
             menge TYPE menge_d,
             meins TYPE meins,
             netpr TYPE p LENGTH 16 DECIMALS 2,
             netpr_ext TYPE char20,
             waers TYPE waers,
             eindt TYPE eindt,
             lifnr TYPE lifnr,
             bedat TYPE bedat,
             ebeln_org TYPE ebeln,
             banfn_org TYPE banfn,
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
      apply_duplicate_suppression,
      display_alv,
      format_net_price
        IMPORTING
          iv_netpr TYPE ty_data-netpr
          iv_waers TYPE waers
        RETURNING
          VALUE(rv_netpr_ext) TYPE char20,

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

   DATA(lv_has_ebeln) = xsdbool( mt_ebeln IS NOT INITIAL ).
   DATA(lv_has_banfn) = xsdbool( mt_banfn IS NOT INITIAL ).
   DATA(lv_has_bedat) = xsdbool( mt_bedat IS NOT INITIAL ).
   DATA(lv_has_lifnr) = xsdbool( mt_lifnr IS NOT INITIAL ).
   DATA(lv_has_matnr) = xsdbool( mt_matnr IS NOT INITIAL ).
   DATA(lv_has_werks) = xsdbool( mt_werks IS NOT INITIAL ).
   DATA(lv_has_netpr) = xsdbool( mt_netpr IS NOT INITIAL ).
   DATA(lv_has_eindt) = xsdbool( mt_eindt IS NOT INITIAL ).

   SELECT
     a~ebeln,
     a~ebelp,
     a~banfn,
     a~bnfpo,
     a~matnr,
     c~maktx,
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
   LEFT JOIN makt AS c
     ON a~matnr = c~matnr
    AND c~spras = @sy-langu
   WHERE a~banfn IS NOT INITIAL
     AND ( @lv_has_ebeln = @abap_false OR a~ebeln IN @mt_ebeln )
     AND ( @lv_has_banfn = @abap_false OR a~banfn IN @mt_banfn )
     AND ( @lv_has_bedat = @abap_false OR b~bedat IN @mt_bedat )
     AND ( @lv_has_lifnr = @abap_false OR b~lifnr IN @mt_lifnr )
     AND ( @lv_has_matnr = @abap_false OR a~matnr IN @mt_matnr )
     AND ( @lv_has_werks = @abap_false OR a~werks IN @mt_werks )
     AND ( @lv_has_netpr = @abap_false OR a~netpr IN @mt_netpr )
     AND ( @lv_has_eindt = @abap_false OR a~eindt IN @mt_eindt )
   INTO CORRESPONDING FIELDS OF TABLE @gt_data.

   LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
     <ls_data>-netpr_ext = me->format_net_price(
       iv_netpr = <ls_data>-netpr
       iv_waers = <ls_data>-waers ).
     <ls_data>-ebeln_org = <ls_data>-ebeln.
     <ls_data>-banfn_org = <ls_data>-banfn.
   ENDLOOP.

   SORT gt_data BY ebeln banfn bnfpo ebelp.

   apply_duplicate_suppression( ).

ENDMETHOD.

 METHOD apply_duplicate_suppression.

   DATA lv_prev_ebeln TYPE ebeln.
   DATA lv_prev_banfn TYPE banfn.

   LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).

     IF <ls_data>-ebeln = lv_prev_ebeln.
       CLEAR <ls_data>-ebeln.
     ENDIF.

     IF <ls_data>-ebeln_org = lv_prev_ebeln
        AND <ls_data>-banfn_org = lv_prev_banfn.
       CLEAR <ls_data>-banfn.
     ENDIF.

     lv_prev_ebeln = <ls_data>-ebeln_org.
     lv_prev_banfn = <ls_data>-banfn_org.
   ENDLOOP.

 ENDMETHOD.

 METHOD format_net_price.
   DATA lv_vnd_amount TYPE p LENGTH 16 DECIMALS 0.

   IF iv_waers = 'VND'.
     lv_vnd_amount = iv_netpr * 100.
     WRITE lv_vnd_amount TO rv_netpr_ext.
   ELSE.
     WRITE iv_netpr CURRENCY iv_waers TO rv_netpr_ext.
   ENDIF.
 ENDMETHOD.

 METHOD display_alv.

  DATA lo_events    TYPE REF TO cl_salv_events_table.
  DATA lo_columns   TYPE REF TO cl_salv_columns_table.
  DATA lo_column    TYPE REF TO cl_salv_column_table.
  DATA lo_layout    TYPE REF TO cl_salv_layout.
  DATA ls_layo_key  TYPE salv_s_layout_key.

  IF gt_data IS INITIAL.
    MESSAGE 'No data found' TYPE 'I'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = gt_data ).

* Enable toolbar
      go_alv->get_functions( )->set_all( abap_true ).

* Use controlled widths so item headers are not truncated
      lo_columns = go_alv->get_columns( ).
      lo_columns->set_optimize( abap_false ).

* Zebra pattern
      go_alv->get_display_settings( )->set_striped_pattern( abap_true ).

* Keep internal amount column hidden; show only external formatted value
      lo_column ?= lo_columns->get_column( 'NETPR' ).
      lo_column->set_visible( abap_false ).
      lo_column ?= lo_columns->get_column( 'EBELN_ORG' ).
      lo_column->set_visible( abap_false ).
      lo_column ?= lo_columns->get_column( 'BANFN_ORG' ).
      lo_column->set_visible( abap_false ).

* Professional order: PR first, then PO
      lo_columns->set_column_position( columnname = 'BANFN'     position = 1 ).
      lo_columns->set_column_position( columnname = 'BNFPO'     position = 2 ).
      lo_columns->set_column_position( columnname = 'EBELN'     position = 3 ).
      lo_columns->set_column_position( columnname = 'EBELP'     position = 4 ).
      lo_columns->set_column_position( columnname = 'MATNR'     position = 5 ).
      lo_columns->set_column_position( columnname = 'MAKTX'     position = 6 ).
      lo_columns->set_column_position( columnname = 'WERKS'     position = 7 ).
      lo_columns->set_column_position( columnname = 'MENGE'     position = 8 ).
      lo_columns->set_column_position( columnname = 'MEINS'     position = 9 ).
      lo_columns->set_column_position( columnname = 'NETPR_EXT' position = 10 ).
      lo_columns->set_column_position( columnname = 'WAERS'     position = 11 ).
      lo_columns->set_column_position( columnname = 'EINDT'     position = 12 ).
      lo_columns->set_column_position( columnname = 'LIFNR'     position = 13 ).
      lo_columns->set_column_position( columnname = 'BEDAT'     position = 14 ).

      lo_column ?= lo_columns->get_column( 'BANFN' ).
      lo_column->set_short_text( 'PR No.' ).
      lo_column->set_medium_text( 'Purchase Requisition' ).
      lo_column->set_long_text( 'Purchase Requisition' ).
      lo_column->set_output_length( 16 ).

      lo_column ?= lo_columns->get_column( 'BNFPO' ).
      lo_column->set_short_text( 'Req.Item' ).
      lo_column->set_medium_text( 'Requisition Item' ).
      lo_column->set_long_text( 'Requisition Item' ).
      lo_column->set_output_length( 13 ).

      lo_column ?= lo_columns->get_column( 'EBELN' ).
      lo_column->set_short_text( 'PO No.' ).
      lo_column->set_medium_text( 'Purchase Order' ).
      lo_column->set_long_text( 'Purchase Order' ).
      lo_column->set_output_length( 15 ).

      lo_column ?= lo_columns->get_column( 'EBELP' ).
      lo_column->set_short_text( 'PO Item' ).
      lo_column->set_medium_text( 'Purchasing Doc. Item' ).
      lo_column->set_long_text( 'Purchasing Doc Item' ).
      lo_column->set_output_length( 6 ).

      lo_column ?= lo_columns->get_column( 'MATNR' ).
      lo_column->set_short_text( 'Material' ).
      lo_column->set_medium_text( 'Material' ).
      lo_column->set_long_text( 'Material' ).
      lo_column->set_output_length( 8 ).

      lo_column ?= lo_columns->get_column( 'MAKTX' ).
      lo_column->set_short_text( 'Mat. Name' ).
      lo_column->set_medium_text( 'Material Name' ).
      lo_column->set_long_text( 'Material Name' ).
      lo_column->set_output_length( 10 ).

      lo_column ?= lo_columns->get_column( 'WERKS' ).
      lo_column->set_short_text( 'Plant' ).
      lo_column->set_medium_text( 'Plant' ).
      lo_column->set_long_text( 'Plant' ).
      lo_column->set_output_length( 4 ).

      lo_column ?= lo_columns->get_column( 'MENGE' ).
      lo_column->set_short_text( 'Qty' ).
      lo_column->set_medium_text( 'Quantity' ).
      lo_column->set_long_text( 'Quantity' ).
      lo_column->set_output_length( 6 ).

      lo_column ?= lo_columns->get_column( 'MEINS' ).
      lo_column->set_short_text( 'Unit' ).
      lo_column->set_medium_text( 'Unit' ).
      lo_column->set_long_text( 'Unit' ).
      lo_column->set_output_length( 4 ).

      lo_column ?= lo_columns->get_column( 'NETPR_EXT' ).
      lo_column->set_short_text( 'Net Price' ).
      lo_column->set_medium_text( 'Net Price' ).
      lo_column->set_long_text( 'Net Price' ).
      lo_column->set_output_length( 6 ).

      lo_column ?= lo_columns->get_column( 'WAERS' ).
      lo_column->set_short_text( 'Curr.' ).
      lo_column->set_medium_text( 'Currency' ).
      lo_column->set_long_text( 'Currency' ).
      lo_column->set_output_length( 6 ).

      lo_column ?= lo_columns->get_column( 'EINDT' ).
      lo_column->set_short_text( 'Deliv.Date' ).
      lo_column->set_medium_text( 'Delivery Date' ).
      lo_column->set_long_text( 'Delivery Date' ).
      lo_column->set_output_length( 10 ).

      lo_column ?= lo_columns->get_column( 'LIFNR' ).
      lo_column->set_short_text( 'Supplier' ).
      lo_column->set_medium_text( 'Supplier' ).
      lo_column->set_long_text( 'Supplier' ).
      lo_column->set_output_length( 10 ).

      lo_column ?= lo_columns->get_column( 'BEDAT' ).
      lo_column->set_short_text( 'PO Date' ).
      lo_column->set_medium_text( 'PO Date' ).
      lo_column->set_long_text( 'PO Date' ).
      lo_column->set_output_length( 10 ).

* Let users save/load professional column order as ALV layout
      lo_layout = go_alv->get_layout( ).
      ls_layo_key-report = sy-repid.
      lo_layout->set_key( ls_layo_key ).
      lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

* Register double click
      lo_events = go_alv->get_event( ).

      SET HANDLER me->on_double_click FOR lo_events.

* Display ALV
      go_alv->display( ).

    CATCH cx_salv_not_found INTO DATA(lx_not_found).
      MESSAGE lx_not_found->get_text( ) TYPE 'E'.
      RETURN.

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
      RETURN.

  ENDTRY.

ENDMETHOD.



  METHOD on_double_click.

    DATA ls_data TYPE ty_data.

    READ TABLE gt_data INTO ls_data INDEX row.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Open PO
    IF column = 'EBELN'.

      SET PARAMETER ID 'BES' FIELD ls_data-ebeln_org.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.

* Open PR
    ELSEIF column = 'BANFN'.

      SET PARAMETER ID 'BAN' FIELD ls_data-banfn_org.
      CALL TRANSACTION 'ME53N' AND SKIP FIRST SCREEN.

    ENDIF.

  ENDMETHOD.
ENDCLASS.

