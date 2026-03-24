CLASS zcl_g8_vendor_pr_po_rate_alv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      ty_r_ebeln TYPE RANGE OF ekko-ebeln,
      ty_r_banfn TYPE RANGE OF zpo_rlsitem_g8-banfn,
      ty_r_bedat TYPE RANGE OF ekko-bedat,
      ty_r_lifnr TYPE RANGE OF ekko-lifnr,
      ty_r_ekgrp TYPE RANGE OF eban-ekgrp,
      ty_r_matnr TYPE RANGE OF zpo_rlsitem_g8-matnr,
      ty_r_netpr TYPE RANGE OF zpo_rlsitem_g8-netpr,
      ty_r_eindt TYPE RANGE OF zpo_rlsitem_g8-eindt.

    METHODS constructor
      IMPORTING
        it_ebeln           TYPE ty_r_ebeln OPTIONAL
        it_banfn           TYPE ty_r_banfn OPTIONAL
        it_bedat           TYPE ty_r_bedat OPTIONAL
        it_lifnr           TYPE ty_r_lifnr OPTIONAL
        it_ekgrp           TYPE ty_r_ekgrp OPTIONAL
        it_matnr           TYPE ty_r_matnr OPTIONAL
        it_netpr           TYPE ty_r_netpr OPTIONAL
        it_eindt           TYPE ty_r_eindt OPTIONAL
        iv_include_deleted TYPE abap_bool DEFAULT abap_false.

    METHODS run.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_source,
             banfn TYPE zpo_rlsitem_g8-banfn,
             bnfpo TYPE zpo_rlsitem_g8-bnfpo,
             ebeln TYPE zpo_rlsitem_g8-ebeln,
             lifnr TYPE ekko-lifnr,
           END OF ty_source.

    TYPES: BEGIN OF ty_pr_item,
             banfn TYPE zpo_rlsitem_g8-banfn,
             bnfpo TYPE zpo_rlsitem_g8-bnfpo,
           END OF ty_pr_item.

    TYPES: BEGIN OF ty_item_vendor,
             banfn TYPE zpo_rlsitem_g8-banfn,
             bnfpo TYPE zpo_rlsitem_g8-bnfpo,
             lifnr TYPE ekko-lifnr,
           END OF ty_item_vendor.

    TYPES: BEGIN OF ty_banfn_vendor,
             banfn TYPE zpo_rlsitem_g8-banfn,
             lifnr TYPE ekko-lifnr,
           END OF ty_banfn_vendor.

    TYPES: BEGIN OF ty_vendor_name,
             lifnr TYPE lfa1-lifnr,
             name1 TYPE lfa1-name1,
           END OF ty_vendor_name.

    TYPES: BEGIN OF ty_output,
             lifnr           TYPE lfa1-lifnr,
             name1           TYPE lfa1-name1,
             total_pr_item   TYPE i,
             success_pr_item TYPE i,
             failed_pr_item  TYPE i,
             success_pct     TYPE p LENGTH 7 DECIMALS 2,
             success_pct_txt TYPE char12,
           END OF ty_output.

    DATA mt_ebeln TYPE ty_r_ebeln.
    DATA mt_banfn TYPE ty_r_banfn.
    DATA mt_bedat TYPE ty_r_bedat.
    DATA mt_lifnr TYPE ty_r_lifnr.
    DATA mt_ekgrp TYPE ty_r_ekgrp.
    DATA mt_matnr TYPE ty_r_matnr.
    DATA mt_netpr TYPE ty_r_netpr.
    DATA mt_eindt TYPE ty_r_eindt.
    DATA mv_include_deleted TYPE abap_bool.

    DATA gt_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.
    DATA go_alv TYPE REF TO cl_salv_table.

    METHODS get_data.
    METHODS display_alv.
ENDCLASS.


CLASS zcl_g8_vendor_pr_po_rate_alv IMPLEMENTATION.

  METHOD constructor.
    mt_ebeln = it_ebeln.
    mt_banfn = it_banfn.
    mt_bedat = it_bedat.
    mt_lifnr = it_lifnr.
    mt_ekgrp = it_ekgrp.
    mt_matnr = it_matnr.
    mt_netpr = it_netpr.
    mt_eindt = it_eindt.
    mv_include_deleted = iv_include_deleted.
  ENDMETHOD.

  METHOD run.
    get_data( ).
    display_alv( ).
  ENDMETHOD.

  METHOD get_data.
    DATA lt_source TYPE STANDARD TABLE OF ty_source WITH EMPTY KEY.
    DATA lt_pr_items TYPE HASHED TABLE OF ty_pr_item WITH UNIQUE KEY banfn bnfpo.
    DATA lt_item_vendor_raw TYPE STANDARD TABLE OF ty_item_vendor WITH EMPTY KEY.
    DATA lt_item_vendor_map TYPE HASHED TABLE OF ty_item_vendor WITH UNIQUE KEY banfn bnfpo.
    DATA lt_banfn_vendor_raw TYPE STANDARD TABLE OF ty_banfn_vendor WITH EMPTY KEY.
    DATA lt_banfn_vendor_map TYPE HASHED TABLE OF ty_banfn_vendor WITH UNIQUE KEY banfn.
    DATA lt_success_keys TYPE HASHED TABLE OF ty_item_vendor WITH UNIQUE KEY banfn bnfpo lifnr.
    DATA lt_out_hash TYPE HASHED TABLE OF ty_output WITH UNIQUE KEY lifnr.
    DATA lt_vendor_names TYPE STANDARD TABLE OF ty_vendor_name WITH EMPTY KEY.
    DATA lv_lifnr TYPE ekko-lifnr.
    CONSTANTS lc_werks TYPE eban-werks VALUE 'PHE'.
    CONSTANTS lc_ekorg TYPE eban-ekorg VALUE 'PPO1'.

    DATA(lv_has_ebeln) = xsdbool( mt_ebeln IS NOT INITIAL ).
    DATA(lv_has_banfn) = xsdbool( mt_banfn IS NOT INITIAL ).
    DATA(lv_has_bedat) = xsdbool( mt_bedat IS NOT INITIAL ).
    DATA(lv_has_lifnr) = xsdbool( mt_lifnr IS NOT INITIAL ).
    DATA(lv_has_ekgrp) = xsdbool( mt_ekgrp IS NOT INITIAL ).
    DATA(lv_has_matnr) = xsdbool( mt_matnr IS NOT INITIAL ).
    DATA(lv_has_netpr) = xsdbool( mt_netpr IS NOT INITIAL ).
    DATA(lv_has_eindt) = xsdbool( mt_eindt IS NOT INITIAL ).

    FIELD-SYMBOLS: <ls_source> TYPE ty_source,
                   <ls_pr_item> TYPE ty_pr_item,
                   <ls_out_hash> TYPE ty_output,
                   <ls_out> TYPE ty_output.

    CLEAR gt_output.

    IF mv_include_deleted = abap_true.
      SELECT a~banfn, a~bnfpo, a~ebeln, b~lifnr
        FROM zpo_rlsitem_g8 AS a
        INNER JOIN eban AS pr
          ON pr~banfn = a~banfn
         AND pr~bnfpo = a~bnfpo
        LEFT JOIN ekko AS b
          ON b~ebeln = a~ebeln
        WHERE a~banfn IS NOT INITIAL
          AND pr~werks = @lc_werks
          AND pr~ekorg = @lc_ekorg
          AND ( @lv_has_ekgrp = @abap_false OR pr~ekgrp IN @mt_ekgrp )
          AND ( @lv_has_ebeln = @abap_false OR a~ebeln IN @mt_ebeln )
          AND ( @lv_has_banfn = @abap_false OR a~banfn IN @mt_banfn )
          AND ( @lv_has_bedat = @abap_false OR b~bedat IN @mt_bedat )
          AND ( @lv_has_lifnr = @abap_false OR b~lifnr IN @mt_lifnr )
          AND ( @lv_has_matnr = @abap_false OR a~matnr IN @mt_matnr )
          AND ( @lv_has_netpr = @abap_false OR a~netpr IN @mt_netpr )
          AND ( @lv_has_eindt = @abap_false OR a~eindt IN @mt_eindt )
        INTO TABLE @lt_source.
    ELSE.
      SELECT a~banfn, a~bnfpo, a~ebeln, b~lifnr
        FROM zpo_rlsitem_g8 AS a
        INNER JOIN eban AS pr
          ON pr~banfn = a~banfn
         AND pr~bnfpo = a~bnfpo
        LEFT JOIN ekko AS b
          ON b~ebeln = a~ebeln
        WHERE a~banfn IS NOT INITIAL
          AND pr~werks = @lc_werks
          AND pr~ekorg = @lc_ekorg
          AND ( @lv_has_ekgrp = @abap_false OR pr~ekgrp IN @mt_ekgrp )
          AND ( @lv_has_ebeln = @abap_false OR a~ebeln IN @mt_ebeln )
          AND ( @lv_has_banfn = @abap_false OR a~banfn IN @mt_banfn )
          AND ( @lv_has_bedat = @abap_false OR b~bedat IN @mt_bedat )
          AND ( @lv_has_lifnr = @abap_false OR b~lifnr IN @mt_lifnr )
          AND ( @lv_has_matnr = @abap_false OR a~matnr IN @mt_matnr )
          AND ( @lv_has_netpr = @abap_false OR a~netpr IN @mt_netpr )
          AND ( @lv_has_eindt = @abap_false OR a~eindt IN @mt_eindt )
          AND pr~loekz = @space
          AND ( a~ebeln = @space OR b~loekz = @space )
        INTO TABLE @lt_source.
    ENDIF.

    IF lt_source IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_source ASSIGNING <ls_source>.
      INSERT VALUE ty_pr_item(
        banfn = <ls_source>-banfn
        bnfpo = <ls_source>-bnfpo ) INTO TABLE lt_pr_items.

      IF <ls_source>-lifnr IS NOT INITIAL.
        APPEND VALUE ty_item_vendor(
          banfn = <ls_source>-banfn
          bnfpo = <ls_source>-bnfpo
          lifnr = <ls_source>-lifnr ) TO lt_item_vendor_raw.

        APPEND VALUE ty_banfn_vendor(
          banfn = <ls_source>-banfn
          lifnr = <ls_source>-lifnr ) TO lt_banfn_vendor_raw.

        IF <ls_source>-ebeln IS NOT INITIAL.
          INSERT VALUE ty_item_vendor(
            banfn = <ls_source>-banfn
            bnfpo = <ls_source>-bnfpo
            lifnr = <ls_source>-lifnr ) INTO TABLE lt_success_keys.
        ENDIF.
      ENDIF.
    ENDLOOP.

    SORT lt_item_vendor_raw BY banfn bnfpo lifnr.
    DELETE ADJACENT DUPLICATES FROM lt_item_vendor_raw COMPARING banfn bnfpo lifnr.

    LOOP AT lt_item_vendor_raw INTO DATA(ls_item_vendor_raw).
      READ TABLE lt_item_vendor_map WITH TABLE KEY
        banfn = ls_item_vendor_raw-banfn
        bnfpo = ls_item_vendor_raw-bnfpo
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        INSERT ls_item_vendor_raw INTO TABLE lt_item_vendor_map.
      ENDIF.
    ENDLOOP.

    SORT lt_banfn_vendor_raw BY banfn lifnr.
    DELETE ADJACENT DUPLICATES FROM lt_banfn_vendor_raw COMPARING banfn lifnr.

    LOOP AT lt_banfn_vendor_raw INTO DATA(ls_banfn_vendor_raw).
      READ TABLE lt_banfn_vendor_map WITH TABLE KEY
        banfn = ls_banfn_vendor_raw-banfn
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        INSERT ls_banfn_vendor_raw INTO TABLE lt_banfn_vendor_map.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_pr_items ASSIGNING <ls_pr_item>.
      CLEAR lv_lifnr.

      READ TABLE lt_item_vendor_map INTO DATA(ls_item_vendor_map)
        WITH TABLE KEY banfn = <ls_pr_item>-banfn bnfpo = <ls_pr_item>-bnfpo.
      IF sy-subrc = 0.
        lv_lifnr = ls_item_vendor_map-lifnr.
      ELSE.
        READ TABLE lt_banfn_vendor_map INTO DATA(ls_banfn_vendor_map)
          WITH TABLE KEY banfn = <ls_pr_item>-banfn.
        IF sy-subrc = 0.
          lv_lifnr = ls_banfn_vendor_map-lifnr.
        ENDIF.
      ENDIF.

      IF lv_lifnr IS INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE lt_out_hash ASSIGNING <ls_out_hash>
        WITH TABLE KEY lifnr = lv_lifnr.
      IF sy-subrc <> 0.
        INSERT VALUE ty_output( lifnr = lv_lifnr ) INTO TABLE lt_out_hash.
        READ TABLE lt_out_hash ASSIGNING <ls_out_hash>
          WITH TABLE KEY lifnr = lv_lifnr.
      ENDIF.

      <ls_out_hash>-total_pr_item = <ls_out_hash>-total_pr_item + 1.

      READ TABLE lt_success_keys WITH TABLE KEY
        banfn = <ls_pr_item>-banfn
        bnfpo = <ls_pr_item>-bnfpo
        lifnr = lv_lifnr
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        <ls_out_hash>-success_pr_item = <ls_out_hash>-success_pr_item + 1.
      ENDIF.
    ENDLOOP.

    gt_output = CORRESPONDING #( lt_out_hash ).

    IF gt_output IS INITIAL.
      RETURN.
    ENDIF.

    SELECT lifnr, name1
      FROM lfa1
      FOR ALL ENTRIES IN @gt_output
      WHERE lifnr = @gt_output-lifnr
      INTO TABLE @lt_vendor_names.

    SORT lt_vendor_names BY lifnr.

    LOOP AT gt_output ASSIGNING <ls_out>.
      READ TABLE lt_vendor_names INTO DATA(ls_vendor_name)
        WITH KEY lifnr = <ls_out>-lifnr
        BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-name1 = ls_vendor_name-name1.
      ENDIF.

      <ls_out>-failed_pr_item = <ls_out>-total_pr_item - <ls_out>-success_pr_item.

      IF <ls_out>-total_pr_item > 0.
        DATA(lv_success_pct) =
          ( CONV decfloat34( <ls_out>-success_pr_item ) * 100 )
          / CONV decfloat34( <ls_out>-total_pr_item ).
        <ls_out>-success_pct = lv_success_pct.
      ENDIF.

      CLEAR <ls_out>-success_pct_txt.
      WRITE <ls_out>-success_pct TO <ls_out>-success_pct_txt DECIMALS 2.
      SHIFT <ls_out>-success_pct_txt LEFT DELETING LEADING space.
      CONCATENATE <ls_out>-success_pct_txt '%' INTO <ls_out>-success_pct_txt SEPARATED BY space.
    ENDLOOP.

    SORT gt_output BY success_pct DESCENDING total_pr_item DESCENDING.
  ENDMETHOD.

  METHOD display_alv.
    DATA lo_columns TYPE REF TO cl_salv_columns_table.
    DATA lo_column TYPE REF TO cl_salv_column_table.

    IF gt_output IS INITIAL.
      MESSAGE 'No data found for selected filters' TYPE 'I'.
      RETURN.
    ENDIF.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = go_alv
          CHANGING  t_table      = gt_output ).
      CATCH cx_salv_msg INTO DATA(lx_salv).
        MESSAGE lx_salv->get_text( ) TYPE 'E'.
        RETURN.
    ENDTRY.

    go_alv->get_functions( )->set_all( abap_true ).
    lo_columns = go_alv->get_columns( ).
    lo_columns->set_optimize( abap_false ).
    go_alv->get_display_settings( )->set_striped_pattern( abap_true ).

    TRY.
        lo_column ?= lo_columns->get_column( 'LIFNR' ).
        lo_column->set_short_text( 'Supplier' ).
        lo_column->set_medium_text( 'Supplier' ).
        lo_column->set_long_text( 'Supplier' ).
        lo_column->set_output_length( 10 ).

        lo_column ?= lo_columns->get_column( 'NAME1' ).
        lo_column->set_short_text( 'Name' ).
        lo_column->set_medium_text( 'Supplier Name' ).
        lo_column->set_long_text( 'Supplier Name' ).
        lo_column->set_output_length( 24 ).

        lo_column ?= lo_columns->get_column( 'TOTAL_PR_ITEM' ).
        lo_column->set_short_text( 'Total PR' ).
        lo_column->set_medium_text( 'Total PR Item' ).
        lo_column->set_long_text( 'Total PR Item' ).
        lo_column->set_output_length( 13 ).

        lo_column ?= lo_columns->get_column( 'SUCCESS_PR_ITEM' ).
        lo_column->set_short_text( 'Success' ).
        lo_column->set_medium_text( 'Success PR Item' ).
        lo_column->set_long_text( 'Success PR Item' ).
        lo_column->set_output_length( 15 ).

        lo_column ?= lo_columns->get_column( 'FAILED_PR_ITEM' ).
        lo_column->set_short_text( 'Failed' ).
        lo_column->set_medium_text( 'Failed PR Item' ).
        lo_column->set_long_text( 'Failed PR Item' ).
        lo_column->set_output_length( 14 ).

        lo_column ?= lo_columns->get_column( 'SUCCESS_PCT' ).
        lo_column->set_visible( abap_false ).

        lo_column ?= lo_columns->get_column( 'SUCCESS_PCT_TXT' ).
        lo_column->set_short_text( 'Success %' ).
        lo_column->set_medium_text( 'Success %' ).
        lo_column->set_long_text( 'Success %' ).
        lo_column->set_output_length( 12 ).
      CATCH cx_salv_not_found.
    ENDTRY.

    go_alv->display( ).
  ENDMETHOD.
ENDCLASS.

