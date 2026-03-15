CLASS zcl_po_release DEFINITION
  PUBLIC FINAL
  INHERITING FROM cl_abap_parallel
  CREATE PUBLIC .

  PUBLIC SECTION.

    "クリティカリティ
    CONSTANTS:
      gcf_criticality_error   TYPE i VALUE 1,
      gcf_criticality_warning TYPE i VALUE 2,
      gcf_criticality_success TYPE i VALUE 3,

      "更新ステータス
      gcf_normal TYPE ZI_RLSHEAD_G8-status VALUE 'Success',
      gcf_error  TYPE ZI_RLSHEAD_G8-status VALUE 'Error'.

    TYPES: BEGIN OF gts_parallel_input,
             po_no TYPE ekko-ebeln,
           END OF gts_parallel_input.

    TYPES: BEGIN OF gts_parallel_output,
             criticality TYPE ZI_RLSHEAD_G8-Criticality,
             message     TYPE ZI_RLSHEAD_G8-MessageStandardtable,
           END OF gts_parallel_output.

    METHODS execute_parallel
      IMPORTING is_input TYPE gts_parallel_input-po_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS do REDEFINITION.

    METHODS main_process
      IMPORTING is_input TYPE gts_parallel_input-po_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS release_po
      IMPORTING is_pono TYPE gts_parallel_input-po_no
      EXPORTING ef_success  TYPE abap_boolean
                ef_message  TYPE string
                ef_severity TYPE if_abap_behv_message=>t_severity.

ENDCLASS.



CLASS zcl_po_release IMPLEMENTATION.

  METHOD execute_parallel.
    DATA: lt_in  TYPE cl_abap_parallel=>t_in_tab,
          lt_out TYPE cl_abap_parallel=>t_out_tab,
          ls_in  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          ls_out TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lv_input  TYPE gts_parallel_input-po_no,
          ls_output TYPE gts_parallel_output.

    lv_input = is_input.

    EXPORT param_input = lv_input TO DATA BUFFER ls_in.
    APPEND ls_in TO lt_in.

    run( EXPORTING p_in_tab = lt_in
         IMPORTING p_out_tab = lt_out ).

    READ TABLE lt_out INTO ls_out INDEX 1.
    IF sy-subrc = 0 AND ls_out-result IS NOT INITIAL.
      IMPORT param_output = ls_output
        FROM DATA BUFFER ls_out-result.
    ENDIF.

    rs_ouput = ls_output.
  ENDMETHOD.



  METHOD do.
    DATA: lv_input  TYPE gts_parallel_input-po_no,
          ls_output TYPE gts_parallel_output.

    IMPORT param_input = lv_input FROM DATA BUFFER p_in.

    ls_output = me->main_process( lv_input ).

    EXPORT param_output = ls_output TO DATA BUFFER p_out.
  ENDMETHOD.



  METHOD main_process.

    DATA:
      lv_msg        TYPE string,
      lv_crit       TYPE i,
      lv_success    TYPE abap_boolean,
      lv_severity   TYPE if_abap_behv_message=>t_severity.

    me->release_po(
      EXPORTING
        is_pono = is_input
      IMPORTING
        ef_success  = lv_success
        ef_message  = lv_msg
        ef_severity = lv_severity ).

    IF lv_success <> abap_true
       OR lv_severity = if_abap_behv_message=>severity-error.
      lv_crit = gcf_criticality_error.
    ELSEIF lv_severity = if_abap_behv_message=>severity-warning.
      lv_crit = gcf_criticality_warning.
    ELSE.
      lv_crit = gcf_criticality_success.
    ENDIF.

    rs_ouput = VALUE #(
      criticality = lv_crit
      message     = lv_msg ).

  ENDMETHOD.



  METHOD release_po.

  DATA:
    ls_ekko    TYPE ekko,
    ls_t16fs   TYPE t16fs,
    lt_codes   TYPE TABLE OF frgco,
    lv_code    TYPE frgco,
    lt_return  TYPE TABLE OF bapireturn,
    ls_return  TYPE bapireturn,
    lt_msg     TYPE TABLE OF string.

  CLEAR: ef_success, ef_severity.

  "--------------------------------------------------
  "1. Read Release Group/Strategy from EKKO
  "--------------------------------------------------
  SELECT SINGLE frggr, frgsx
    FROM ekko
    INTO CORRESPONDING FIELDS OF @ls_ekko
    WHERE ebeln = @is_pono.

  IF sy-subrc <> 0.
    ef_success  = abap_false.
    ef_severity = if_abap_behv_message=>severity-error.
    ef_message  = |PO { is_pono } Not Found|.
    RETURN.
  ENDIF.

  IF ls_ekko-frggr IS INITIAL OR ls_ekko-frgsx IS INITIAL.
    ef_success  = abap_false.
    ef_severity = if_abap_behv_message=>severity-success.
    ef_message  = |PO { is_pono } not subject to release strategy|.
    RETURN.
  ENDIF.

  "--------------------------------------------------
  "2. Read release codes from T16FS
  "--------------------------------------------------
    SELECT SINGLE *
      FROM t16fs
      INTO @ls_t16fs
      WHERE frggr = @ls_ekko-frggr
        AND frgsx = @ls_ekko-frgsx.

    IF sy-subrc <> 0.
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-error.
      ef_message  = |Release Strategy { ls_ekko-frggr }/{ ls_ekko-frgsx } not found in T16FS|.
      RETURN.
    ENDIF.

    " 承認コードを収集 (T16FS có tối đa 8 code, ta lấy hết các code có giá trị)
    IF ls_t16fs-frgc1 IS NOT INITIAL. APPEND ls_t16fs-frgc1 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc2 IS NOT INITIAL. APPEND ls_t16fs-frgc2 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc3 IS NOT INITIAL. APPEND ls_t16fs-frgc3 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc4 IS NOT INITIAL. APPEND ls_t16fs-frgc4 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc5 IS NOT INITIAL. APPEND ls_t16fs-frgc5 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc6 IS NOT INITIAL. APPEND ls_t16fs-frgc6 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc7 IS NOT INITIAL. APPEND ls_t16fs-frgc7 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc8 IS NOT INITIAL. APPEND ls_t16fs-frgc8 TO lt_codes. ENDIF.

  ef_success  = abap_true.
  ef_severity = if_abap_behv_message=>severity-success.

  "--------------------------------------------------
  "3. Loop release codes → BAPI_PO_RELEASE
  "--------------------------------------------------
  LOOP AT lt_codes INTO lv_code.

    CLEAR lt_return.

    CALL FUNCTION 'BAPI_PO_RELEASE'
      EXPORTING
        purchaseorder  = is_pono
        po_rel_code    = lv_code
        use_exceptions = abap_true
      TABLES
        return         = lt_return.

    LOOP AT lt_return INTO ls_return.

      APPEND |{ ls_return-type }: { ls_return-message }| TO lt_msg.

      IF ls_return-type CA 'EA'.
        ef_success  = abap_false.
        ef_severity = if_abap_behv_message=>severity-error.
      ENDIF.

    ENDLOOP.

    IF ef_success = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING wait = 'X'.
    ENDIF.

  ENDLOOP.

  IF lt_msg IS INITIAL.
    APPEND 'Purchase order released' TO lt_msg.
  ENDIF.

  ef_message = xco_cp=>strings( lt_msg )->join( | / | )->value.

ENDMETHOD.

ENDCLASS.

