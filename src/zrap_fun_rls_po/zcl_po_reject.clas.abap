CLASS zcl_po_reject DEFINITION
  PUBLIC FINAL
  INHERITING FROM cl_abap_parallel
  CREATE PUBLIC .

  PUBLIC SECTION.

* Criticality
    CONSTANTS:
      gcf_criticality_error   TYPE i VALUE 1,
      gcf_criticality_warning TYPE i VALUE 2,
      gcf_criticality_success TYPE i VALUE 3.

* Parallel Types
    TYPES: BEGIN OF gts_parallel_input,
             po_no TYPE ebeln,
           END OF gts_parallel_input.

    TYPES: BEGIN OF gts_parallel_output,
             criticality TYPE i,
             message     TYPE string,
           END OF gts_parallel_output.

* Wrapper
    METHODS execute_parallel
      IMPORTING is_input        TYPE gts_parallel_input-po_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

* Worker
    METHODS do REDEFINITION.

* Business
    METHODS main_process
      IMPORTING is_input        TYPE gts_parallel_input-po_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS reset_release_po
      IMPORTING iv_ebeln    TYPE ebeln
      EXPORTING ef_success  TYPE abap_boolean
                ef_message  TYPE string
                ef_severity TYPE if_abap_behv_message=>t_severity.

ENDCLASS.


CLASS zcl_po_reject IMPLEMENTATION.

  METHOD execute_parallel.

    DATA:
      lt_in  TYPE cl_abap_parallel=>t_in_tab,
      lt_out TYPE cl_abap_parallel=>t_out_tab,
      ls_in  TYPE LINE OF cl_abap_parallel=>t_in_tab,
      ls_out TYPE LINE OF cl_abap_parallel=>t_out_tab,
      lv_in  TYPE gts_parallel_input-po_no,
      ls_res TYPE gts_parallel_output.

    lv_in = is_input.

    EXPORT param_input = lv_in TO DATA BUFFER ls_in.
    APPEND ls_in TO lt_in.

    run( EXPORTING p_in_tab = lt_in
         IMPORTING p_out_tab = lt_out ).

    READ TABLE lt_out INTO ls_out INDEX 1.
    IF sy-subrc = 0 AND ls_out-result IS NOT INITIAL.
      IMPORT param_output = ls_res
        FROM DATA BUFFER ls_out-result.
    ENDIF.

    rs_ouput = ls_res.

  ENDMETHOD.

  METHOD do.

    DATA:
      lv_input  TYPE gts_parallel_input-po_no,
      ls_output TYPE gts_parallel_output.

    IMPORT param_input = lv_input FROM DATA BUFFER p_in.

    ls_output = main_process( lv_input ).

    EXPORT param_output = ls_output TO DATA BUFFER p_out.

  ENDMETHOD.

  METHOD main_process.

    DATA:
      lv_message     TYPE string,
      lv_criticality TYPE i,
      lv_success     TYPE abap_boolean,
      lv_severity    TYPE if_abap_behv_message=>t_severity.

    CHECK is_input IS NOT INITIAL.

    me->reset_release_po(
      EXPORTING
        iv_ebeln    = is_input
      IMPORTING
        ef_success  = lv_success
        ef_message  = lv_message
        ef_severity = lv_severity ).

* Map severity → criticality
    IF lv_success <> abap_true
    OR lv_severity = if_abap_behv_message=>severity-error.
      lv_criticality = gcf_criticality_error.

    ELSEIF lv_severity = if_abap_behv_message=>severity-warning.
      lv_criticality = gcf_criticality_warning.

    ELSE.
      lv_criticality = gcf_criticality_success.
    ENDIF.

    rs_ouput = VALUE #(
      criticality = lv_criticality
      message     = lv_message ).

  ENDMETHOD.

  METHOD reset_release_po.

    DATA:
      ls_ekko   TYPE ekko,
      ls_t16fs  TYPE t16fs,
      lt_codes  TYPE TABLE OF frgco,
      lv_code   TYPE frgco,
      lt_return TYPE TABLE OF bapiret2,
      lt_msg    TYPE TABLE OF string,
      lv_error  TYPE abap_boolean VALUE abap_false.

    CLEAR: ef_success, ef_severity.

*------------------------------------------------------------------
* 1️⃣ Get Release Strategy from EKKO
*------------------------------------------------------------------
    SELECT SINGLE frggr, frgsx, frgzu
      FROM ekko
      INTO CORRESPONDING FIELDS OF @ls_ekko
      WHERE ebeln = @iv_ebeln.

    IF sy-subrc <> 0.
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-error.
      ef_message  = |PO { iv_ebeln } Not Found|.
      RETURN.
    ENDIF.

    IF ls_ekko-frgzu <> 'X'.

      IF lt_msg IS INITIAL.
        APPEND |PO { iv_ebeln } rejected| TO lt_msg.
      ENDIF.

      SORT lt_msg.
      DELETE ADJACENT DUPLICATES FROM lt_msg.


      ef_success  = abap_true.
      ef_severity = if_abap_behv_message=>severity-success.
    ELSE.
*------------------------------------------------------------------
* 2️⃣ Get Release Codes from T16FS
*------------------------------------------------------------------
      SELECT SINGLE *
        FROM t16fs
        INTO @ls_t16fs
        WHERE frggr = @ls_ekko-frggr
          AND frgsx = @ls_ekko-frgsx.

* Collect codes
      IF ls_t16fs-frgc1 IS NOT INITIAL. APPEND ls_t16fs-frgc1 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc2 IS NOT INITIAL. APPEND ls_t16fs-frgc2 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc3 IS NOT INITIAL. APPEND ls_t16fs-frgc3 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc4 IS NOT INITIAL. APPEND ls_t16fs-frgc4 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc5 IS NOT INITIAL. APPEND ls_t16fs-frgc5 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc6 IS NOT INITIAL. APPEND ls_t16fs-frgc6 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc7 IS NOT INITIAL. APPEND ls_t16fs-frgc7 TO lt_codes. ENDIF.
      IF ls_t16fs-frgc8 IS NOT INITIAL. APPEND ls_t16fs-frgc8 TO lt_codes. ENDIF.

*------------------------------------------------------------------
* ⭐ IMPORTANT — Reset từ level cao xuống thấp
*------------------------------------------------------------------
      SORT lt_codes DESCENDING.

*------------------------------------------------------------------
* 3️⃣ Reset Loop
*------------------------------------------------------------------
      LOOP AT lt_codes INTO lv_code.

        CLEAR lt_return.

        CALL FUNCTION 'BAPI_PO_RESET_RELEASE'
          EXPORTING
            purchaseorder = iv_ebeln
            po_rel_code   = lv_code
          TABLES
            return        = lt_return.

* Analyze result
        LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_ret>).

          APPEND <ls_ret>-message TO lt_msg.

          IF <ls_ret>-type = 'E'
          OR <ls_ret>-type = 'A'.
            lv_error = abap_true.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

*------------------------------------------------------------------
* 4️⃣ Commit / Rollback
*------------------------------------------------------------------
      IF lv_error = abap_false.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.

        ef_success  = abap_true.
        ef_severity = if_abap_behv_message=>severity-success.

      ELSE.

        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        ef_success  = abap_false.
        ef_severity = if_abap_behv_message=>severity-error.

      ENDIF.

*------------------------------------------------------------------
* 5️⃣ Build message
*------------------------------------------------------------------
      IF lt_msg IS INITIAL.
        APPEND |PO { iv_ebeln } rejected| TO lt_msg.
      ENDIF.

      SORT lt_msg.
      DELETE ADJACENT DUPLICATES FROM lt_msg.
    ENDIF.
    ef_message =
      xco_cp=>strings( lt_msg )->join( | / | )->value.

  ENDMETHOD.


ENDCLASS.

