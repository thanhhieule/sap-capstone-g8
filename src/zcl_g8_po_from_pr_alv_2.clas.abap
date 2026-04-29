class ZCL_G8_PO_FROM_PR_ALV_2 definition
  public
  final
  create public .

public section.

  types:
* Range types
    ty_r_ebeln TYPE RANGE OF ekko-ebeln .
  types:
    ty_r_banfn TYPE RANGE OF zpo_rlsitem_g8-banfn .
  types:
    ty_r_bedat TYPE RANGE OF ekko-bedat .
  types:
    ty_r_lifnr TYPE RANGE OF ekko-lifnr .
  types:
    ty_r_matnr TYPE RANGE OF zpo_rlsitem_g8-matnr .
  types:
    ty_r_werks TYPE RANGE OF zpo_rlsitem_g8-werks .
  types:
    ty_r_netpr TYPE RANGE OF zpo_rlsitem_g8-netpr .
  types:
    ty_r_eindt TYPE RANGE OF zpo_rlsitem_g8-eindt .

  methods CONSTRUCTOR
    importing
      !IT_EBELN type TY_R_EBELN optional
      !IT_BANFN type TY_R_BANFN optional
      !IT_BEDAT type TY_R_BEDAT optional
      !IT_LIFNR type TY_R_LIFNR optional
      !IT_MATNR type TY_R_MATNR optional
      !IT_WERKS type TY_R_WERKS optional
      !IT_NETPR type TY_R_NETPR optional
      !IT_EINDT type TY_R_EINDT optional .
  methods RUN .
private section.

  types:
    BEGIN OF ty_data,
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
            END OF ty_data .

  data MT_EBELN type TY_R_EBELN .
  data MT_BANFN type TY_R_BANFN .
  data MT_BEDAT type TY_R_BEDAT .
  data MT_LIFNR type TY_R_LIFNR .
  data MT_MATNR type TY_R_MATNR .
  data MT_WERKS type TY_R_WERKS .
  data MT_NETPR type TY_R_NETPR .
  data MT_EINDT type TY_R_EINDT .
  data:
    gt_data TYPE STANDARD TABLE OF ty_data .
  data GO_ALV type ref to CL_SALV_TABLE .
  constants GC_FCODE_PO_INT type SALV_DE_FUNCTION value 'PO_INT' .
  constants GC_FCODE_PO_EXT type SALV_DE_FUNCTION value 'PO_EXT' .
  constants GC_FCODE_PO_VEND type SALV_DE_FUNCTION value 'PO_VEND' .
  constants GC_FCODE_MULTI_FORM type SALV_DE_FUNCTION value 'MFORM' .
  constants GC_FCODE_RESET type SALV_DE_FUNCTION value 'RESET' .

  methods GET_DATA .
  methods RESET_ALV_VIEW .
  methods DISPLAY_ALV .
  methods FORMAT_NET_PRICE
    importing
      !IV_NETPR type TY_DATA-NETPR
      !IV_WAERS type WAERS
    returning
      value(RV_NETPR_EXT) type CHAR20 .
  methods ON_DOUBLE_CLICK
    for event DOUBLE_CLICK of CL_SALV_EVENTS_TABLE
    importing
      !ROW
      !COLUMN .
  methods ON_BEFORE_SALV_FUNCTION
    for event BEFORE_SALV_FUNCTION of CL_SALV_EVENTS_TABLE
    importing
      !E_SALV_FUNCTION .
  methods ON_ADDED_FUNCTION
    for event ADDED_FUNCTION of CL_SALV_EVENTS_TABLE
    importing
      !E_SALV_FUNCTION .
  methods CHOOSE_FORM
    returning
      value(RV_FORMNAME) type TDSFNAME .
  methods CALL_PO_FORM
    importing
      !IV_EBELN type EBELN
      !IV_FORMNAME type TDSFNAME
      !IS_CONTROL type SSFCTRLOP optional .
ENDCLASS.



CLASS ZCL_G8_PO_FROM_PR_ALV_2 IMPLEMENTATION.


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
  DATA lo_functions TYPE REF TO cl_salv_functions_list.
  DATA lo_layout    TYPE REF TO cl_salv_layout.
  DATA ls_layo_key  TYPE salv_s_layout_key.
  DATA lv_status_program TYPE syrepid.

  IF gt_data IS INITIAL.
    MESSAGE 'No data found' TYPE 'I'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = gt_data ).

* Enable toolbar
      lo_functions = go_alv->get_functions( ).
      lo_functions->set_all( abap_true ).
      lo_functions->set_group_sort( abap_true ).
      lv_status_program = sy-cprog.
      IF lv_status_program IS INITIAL.
        lv_status_program = sy-repid.
      ENDIF.
      go_alv->set_screen_status(
        report        = lv_status_program
        pfstatus      = 'ZALV_G8_3'
        set_functions = go_alv->c_functions_all ).

      TRY.
          lo_functions->add_function(
            name     = gc_fcode_reset
            text     = 'Reset'
            tooltip  = 'Reset view and hide duplicates'
            position = if_salv_c_function_position=>right_of_salv_functions ).
        CATCH cx_salv_existing
              cx_salv_method_not_supported
              cx_salv_wrong_call.
      ENDTRY.

      go_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

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
      lo_column->set_output_length( 10 ).

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
      SET HANDLER me->on_before_salv_function FOR lo_events.
      SET HANDLER me->on_added_function FOR lo_events.

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
    DATA lv_po_item TYPE ebelp.
    DATA lv_pr_item TYPE bnfpo.

    READ TABLE gt_data INTO ls_data INDEX row.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Open PO
    IF column = 'EBELN'.

      IF ls_data-ebeln_org IS INITIAL.
        RETURN.
      ENDIF.

      lv_po_item = ls_data-ebelp.

      SET PARAMETER ID 'BES' FIELD ls_data-ebeln_org.
      SET PARAMETER ID 'BSP' FIELD lv_po_item.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.

*  Open PR only when clicking PR number column
  ELSEIF column = 'BANFN'.

      IF ls_data-banfn_org IS INITIAL.
        RETURN.
      ENDIF.

      lv_pr_item = ls_data-bnfpo.

      " ME53N does not always honor item memory IDs from CALL TRANSACTION.
      " Use the standard display FM to open directly at the requested PR item.
      CALL FUNCTION 'MMPUR_REQUISITION_DISPLAY'
        EXPORTING
          im_banfn        = ls_data-banfn_org
          im_bnfpo        = lv_pr_item
          im_display_only = abap_true
        EXCEPTIONS
          no_authority    = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        SET PARAMETER ID 'BAN' FIELD ls_data-banfn_org.
        SET PARAMETER ID 'BNF' FIELD lv_pr_item.
        CALL TRANSACTION 'ME53N' AND SKIP FIRST SCREEN.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD reset_alv_view.
    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      <ls_data>-ebeln = <ls_data>-ebeln_org.
      <ls_data>-banfn = <ls_data>-banfn_org.
    ENDLOOP.

    SORT gt_data BY ebeln banfn bnfpo ebelp.
  ENDMETHOD.


  METHOD on_before_salv_function.
    IF e_salv_function = '&OUP'
       OR e_salv_function = '&ODN'.
      LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
        <ls_data>-ebeln = <ls_data>-ebeln_org.
        <ls_data>-banfn = <ls_data>-banfn_org.
      ENDLOOP.
    ELSEIF e_salv_function = '&REFRESH'.
      reset_alv_view( ).
    ELSEIF e_salv_function CS 'SORT'.
      reset_alv_view( ).
    ENDIF.
  ENDMETHOD.


  METHOD on_added_function.

    DATA lt_rows TYPE salv_t_row.
    DATA lt_ebeln TYPE SORTED TABLE OF ebeln WITH UNIQUE KEY table_line.
    DATA ls_control TYPE ssfctrlop.
    DATA lv_formname TYPE tdsfname.
    DATA lv_use_report TYPE abap_bool VALUE abap_false.
    DATA lv_total TYPE i.
    DATA lv_index TYPE i.

    CASE e_salv_function.
      WHEN GC_FCODE_RESET.
        reset_alv_view( ).
        go_alv->refresh( ).
        RETURN.
      WHEN GC_FCODE_PO_INT OR 'POFORM_INT' OR 'FORM_INT'.
        lv_formname = 'YFG8_PO_FORM'.
      WHEN GC_FCODE_MULTI_FORM OR 'MFORM'.
        lv_use_report = abap_true.
      WHEN GC_FCODE_PO_EXT OR 'PO_FORM' OR 'POFORM' OR 'FORM'.
        lv_formname = 'YFG8_PO_FORM2'.
      WHEN GC_FCODE_PO_VEND OR 'POFORM_V' OR 'FORM_V'.
        lv_formname = 'YFG8_PO_FORM3'.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    IF lv_use_report = abap_false AND lv_formname IS INITIAL.
      RETURN.
    ENDIF.

    lt_rows = go_alv->get_selections( )->get_selected_rows( ).

    IF lt_rows IS INITIAL.
      MESSAGE 'Please select at least one row' TYPE 'I'.
      RETURN.
    ENDIF.

    LOOP AT lt_rows INTO DATA(lv_row).
      READ TABLE gt_data ASSIGNING FIELD-SYMBOL(<ls_data>) INDEX lv_row.
      IF sy-subrc = 0 AND <ls_data>-ebeln_org IS NOT INITIAL.
        INSERT <ls_data>-ebeln_org INTO TABLE lt_ebeln.
      ENDIF.
    ENDLOOP.

    IF lt_ebeln IS INITIAL.
      MESSAGE 'No PO number found in selected rows' TYPE 'I'.
      RETURN.
    ENDIF.

    IF lv_use_report = abap_true.
      DATA lt_s_ponum TYPE RANGE OF ebeln.
      DATA lt_bukrs TYPE SORTED TABLE OF bukrs WITH UNIQUE KEY table_line.
      DATA lv_bukrs TYPE bukrs.

      LOOP AT lt_ebeln INTO DATA(lv_rep_ebeln).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_rep_ebeln ) TO lt_s_ponum.

        SELECT SINGLE bukrs
          FROM ekko
          WHERE ebeln = @lv_rep_ebeln
          INTO @DATA(lv_item_bukrs).
        IF sy-subrc = 0 AND lv_item_bukrs IS NOT INITIAL.
          INSERT lv_item_bukrs INTO TABLE lt_bukrs.
        ENDIF.
      ENDLOOP.

      IF lines( lt_bukrs ) > 1.
        MESSAGE 'Selected POs belong to different company codes. Please select one company code only.' TYPE 'I'.
        RETURN.
      ENDIF.

      READ TABLE lt_bukrs INTO lv_bukrs INDEX 1.
      IF sy-subrc <> 0 OR lv_bukrs IS INITIAL.
        lv_bukrs = 'PH06'.
      ENDIF.

      SUBMIT YG8_FORM_PO
        WITH s_ponum IN lt_s_ponum
        WITH p_bukrs = lv_bukrs
        AND RETURN.
      RETURN.
    ENDIF.

    lv_total = lines( lt_ebeln ).
    lv_index = 0.

    LOOP AT lt_ebeln INTO DATA(lv_ebeln).
      lv_index = lv_index + 1.

      CLEAR ls_control.
      ls_control-no_dialog = abap_true.
      ls_control-preview   = abap_true.
      ls_control-device    = 'PRINTER'.

      IF lv_total = 1.
        ls_control-no_open  = space.
        ls_control-no_close = space.
      ELSEIF lv_index = 1.
        ls_control-no_open  = space.
        ls_control-no_close = abap_true.
      ELSEIF lv_index = lv_total.
        ls_control-no_open  = abap_true.
        ls_control-no_close = space.
      ELSE.
        ls_control-no_open  = abap_true.
        ls_control-no_close = abap_true.
      ENDIF.

      call_po_form(
        iv_ebeln    = lv_ebeln
        iv_formname = lv_formname
        is_control  = ls_control ).
    ENDLOOP.

    MESSAGE |Printed { lv_total } PO(s)| TYPE 'S'.

  ENDMETHOD.


  METHOD choose_form.
    DATA lt_options TYPE STANDARD TABLE OF spopli WITH EMPTY KEY.
    DATA lv_answer TYPE c LENGTH 1.

    APPEND VALUE #( varoption = 'Internal Purchase Order Form' ) TO lt_options.
    APPEND VALUE #( varoption = 'Purchase Order Form' ) TO lt_options.
    APPEND VALUE #( varoption = 'Vendor Selection Approval' ) TO lt_options.

    TRY.
        CALL FUNCTION 'POPUP_TO_DECIDE_LIST'
          EXPORTING
            cursorline = 2
            mark_flag  = 'X'
            textline1  = 'Select form type to print'
            titel      = 'PO Form Selection'
          IMPORTING
            answer     = lv_answer
          TABLES
            t_spopli   = lt_options
          EXCEPTIONS
            OTHERS     = 1.
      CATCH cx_sy_dyn_call_param_not_found.
        CALL FUNCTION 'POPUP_TO_DECIDE_LIST'
          EXPORTING
            cursorline = 2
            textline1  = 'Select form type to print'
            titel      = 'PO Form Selection'
          IMPORTING
            answer     = lv_answer
          TABLES
            t_spopli   = lt_options
          EXCEPTIONS
            OTHERS     = 1.
    ENDTRY.

    IF sy-subrc <> 0 OR lv_answer = 'A'.
      RETURN.
    ENDIF.

    READ TABLE lt_options WITH KEY selflag = 'X' TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE sy-tabix.
      WHEN 1.
        rv_formname = 'YFG8_PO_FORM'.
      WHEN 2.
        rv_formname = 'YFG8_PO_FORM2'.
      WHEN 3.
        rv_formname = 'YFG8_PO_FORM3'.
    ENDCASE.
  ENDMETHOD.


  METHOD call_po_form.

    DATA lv_fm_name TYPE rs38l_fnam.
    DATA ls_import_head TYPE ysg8form_po_head.
    DATA lt_import_item TYPE yttg8_form_po_item.
    DATA lv_called TYPE abap_bool VALUE abap_false.
    DATA ls_compop TYPE ssfcompop.
    DATA lv_bankl TYPE bankk.
    DATA lv_bankn TYPE bankn.
    DATA lv_koinh TYPE koinh_fi.
    DATA lt_src_item TYPE STANDARD TABLE OF zpo_rlsitem_g8.
    FIELD-SYMBOLS <lv_head_comp> TYPE any.
    FIELD-SYMBOLS <ls_src_item> TYPE zpo_rlsitem_g8.
    FIELD-SYMBOLS <ls_tgt_item> TYPE any.
    FIELD-SYMBOLS <lv_item_comp> TYPE any.

    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname = iv_formname
      IMPORTING
        fm_name  = lv_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.

   IF sy-subrc <> 0 OR lv_fm_name IS INITIAL.
      IF iv_formname = 'YFG8_PO_FORM2'.
      lv_fm_name = '/1BCDWB/SF00000273'.
      ELSE.
        MESSAGE |SmartForm { iv_formname } not found| TYPE 'E'.
        RETURN.
      ENDIF.
    ENDIF.

    SELECT SINGLE ebeln,
                  bukrs,
                  lifnr,
                  ekorg,
                  ekgrp,
                  waers,
                  zterm
      FROM ekko
      WHERE ebeln = @iv_ebeln
      INTO CORRESPONDING FIELDS OF @ls_import_head.

    IF sy-subrc <> 0.
      MESSAGE |PO { iv_ebeln } not found in EKKO| TYPE 'E'.
      RETURN.
    ENDIF.

    ls_import_head-erdat = sy-datum.

    SELECT SINGLE werks
      FROM zpo_rlsitem_g8
      WHERE ebeln = @iv_ebeln
      INTO @ls_import_head-werks.

    IF ls_import_head-lifnr IS NOT INITIAL.
      SELECT SINGLE bankl,
                    bankn,
                    koinh
        FROM lfbk
        WHERE lifnr = @ls_import_head-lifnr
        INTO ( @lv_bankl, @lv_bankn, @lv_koinh ).

      ASSIGN COMPONENT 'BANK_KEY' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_bankl.
      ENDIF.
      ASSIGN COMPONENT 'BANKL' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_bankl.
      ENDIF.

      ASSIGN COMPONENT 'BANK_ACC' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_bankn.
      ENDIF.
      ASSIGN COMPONENT 'BANKN' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_bankn.
      ENDIF.

      ASSIGN COMPONENT 'BANK_HOLDER' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_koinh.
      ENDIF.
      ASSIGN COMPONENT 'KOINH' OF STRUCTURE ls_import_head TO <lv_head_comp>.
      IF sy-subrc = 0.
        <lv_head_comp> = lv_koinh.
      ENDIF.
    ENDIF.

    CLEAR: ls_import_head-gesbu,
           ls_import_head-price_score,
           ls_import_head-qual_score,
           ls_import_head-deliv_score,
           ls_import_head-serv_score.

    SELECT *
      FROM zpo_rlsitem_g8
      WHERE ebeln = @iv_ebeln
      INTO TABLE @lt_src_item.

    LOOP AT lt_src_item ASSIGNING <ls_src_item>.
      APPEND INITIAL LINE TO lt_import_item ASSIGNING <ls_tgt_item>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT 'EBELN' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-ebeln. ENDIF.
      ASSIGN COMPONENT 'EBELP' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-ebelp. ENDIF.
      ASSIGN COMPONENT 'BANFN' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-banfn. ENDIF.
      ASSIGN COMPONENT 'BNFPO' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-bnfpo. ENDIF.
      ASSIGN COMPONENT 'MATNR' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-matnr. ENDIF.
      ASSIGN COMPONENT 'WERKS' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-werks. ENDIF.
      ASSIGN COMPONENT 'MENGE' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-menge. ENDIF.
      ASSIGN COMPONENT 'MEINS' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-meins. ENDIF.
      ASSIGN COMPONENT 'NETPR' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-netpr. ENDIF.
      ASSIGN COMPONENT 'WAERS' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-waers. ENDIF.
      ASSIGN COMPONENT 'EINDT' OF STRUCTURE <ls_tgt_item> TO <lv_item_comp>.
      IF sy-subrc = 0. <lv_item_comp> = <ls_src_item>-eindt. ENDIF.
    ENDLOOP.

    ls_compop-tdnewid = abap_true.

    TRY.
        CALL FUNCTION lv_fm_name
          EXPORTING
            control_parameters = is_control
            output_options     = ls_compop
            user_settings      = space
            im_po_head         = ls_import_head
          TABLES
            tab_items          = lt_import_item.
        lv_called = abap_true.
      CATCH cx_sy_dyn_call_param_not_found
            cx_sy_dyn_call_param_missing.
    ENDTRY.

    IF lv_called = abap_false.
      TRY.
          CALL FUNCTION lv_fm_name
            EXPORTING
              im_po_head = ls_import_head
            TABLES
              tab_items  = lt_import_item.
          lv_called = abap_true.
        CATCH cx_sy_dyn_call_param_not_found
              cx_sy_dyn_call_param_missing.
      ENDTRY.
    ENDIF.

    IF lv_called = abap_false.
      MESSAGE 'SmartForm interface mismatch. Expected IM_PO_HEAD and TAB_ITEMS.' TYPE 'E'.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

