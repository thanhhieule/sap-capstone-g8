 CLASS zcl_reject_pr DEFINITION
  PUBLIC FINAL
  INHERITING FROM cl_abap_parallel
  CREATE PUBLIC .

  PUBLIC SECTION.

    "クリティカリティ (Criticality)
    CONSTANTS:
      gcf_criticality_error   TYPE i VALUE 1,
      gcf_criticality_warning TYPE i VALUE 2,
      gcf_criticality_success TYPE i VALUE 3,

      "更新ステータス (Status)
      gcf_normal              TYPE ZI_RLSHEAD_G8-status VALUE 'Success',
      gcf_error               TYPE ZI_RLSHEAD_G8-status VALUE 'Error'.

    TYPES: BEGIN OF gts_job_log_message,
             severity TYPE if_bali_item_setter=>ty_severity,
             message  TYPE cl_bali_free_text_setter=>ty_text.
    TYPES: END OF gts_job_log_message.
    TYPES: gtt_job_log_message TYPE TABLE OF gts_job_log_message WITH EMPTY KEY.

    TYPES: BEGIN OF gts_parallel_input,
             pr_no TYPE ZI_RLSHEAD_G8-PrNo.
    TYPES: END OF gts_parallel_input.

    TYPES: gtt_release_g8 TYPE TABLE OF ZI_RLSHEAD_G8 WITH DEFAULT KEY,
           gtt_message    TYPE TABLE OF string.

    TYPES: BEGIN OF gts_parallel_output,
             Criticality TYPE ZI_RLSHEAD_G8-Criticality,
             message     TYPE ZI_RLSHEAD_G8-MessageStandardtable,
           END OF gts_parallel_output.

    METHODS execute_parallel
      IMPORTING is_input        TYPE gts_parallel_input-pr_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS do REDEFINITION.

    METHODS main_process
      IMPORTING is_input        TYPE gts_parallel_input-pr_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS reset_release_pr
      IMPORTING is_prno     TYPE gts_parallel_input-pr_no
      EXPORTING ef_success  TYPE abap_boolean
                ef_message  TYPE string
                ef_severity TYPE if_abap_behv_message=>t_severity.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_reject_pr IMPLEMENTATION.


  METHOD execute_parallel.
    DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
          ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
          lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lds_input  TYPE gts_parallel_input-pr_no,
          lds_output TYPE gts_parallel_output.

    "入力の設定 (Setup Input)
    lds_input = is_input.

    EXPORT param_input = lds_input TO DATA BUFFER lds_xinput.
    APPEND lds_xinput TO ldt_xinput.

    "並列処理タスクの実行トリガーを呼び出す (Trigger Parallel Run)
    run( EXPORTING p_in_tab = ldt_xinput IMPORTING p_out_tab = ldt_xoutput ).

    "出力パラメータを取得する (Get Output)
    READ TABLE ldt_xoutput INTO lds_xoutput INDEX 1.
    IF sy-subrc = 0 AND lds_xoutput-result IS NOT INITIAL.
      IMPORT param_output = lds_output
        FROM DATA BUFFER lds_xoutput-result.
    ENDIF.

    "出力パラメータとして値を返す (Return Result)
    rs_ouput = lds_output.
  ENDMETHOD.


  METHOD do.
    DATA: lds_input  TYPE gts_parallel_input-pr_no,
          lds_output TYPE gts_parallel_output.

    "入力パラメータを取得する
    IMPORT param_input = lds_input FROM DATA BUFFER p_in.

    "メイン処理を実行する
    lds_output = me->main_process( is_input = lds_input ).

    "出力パラメータをエクスポートする
    EXPORT param_output = lds_output TO DATA BUFFER p_out.

  ENDMETHOD.


  METHOD main_process.

    DATA:
      ldf_prno        TYPE ZI_RLSHEAD_G8-PrNo,
      ldf_message     TYPE string,
      ldf_criticality TYPE i,
      lds_output      TYPE gts_parallel_output.

    ldf_prno = is_input.

    CHECK ldf_prno IS NOT INITIAL.
    "ヘッダーユニットの条件
    CLEAR:
      ldf_message,
      ldf_criticality.

    DATA:
      ldf_release_fail  TYPE abap_boolean,
      ldf_boif_success  TYPE abap_boolean,
      ldf_status        TYPE ZI_RLSHEAD_G8-status,
      ldf_boif_severity TYPE  if_abap_behv_message=>t_severity.


    "スケール更新データなし→BOインターフェースで更新
    " *** CHANGE: Gọi method reset_release_pr thay vì release_pr ***
    me->reset_release_pr(
      EXPORTING
        is_prno = ldf_prno
      IMPORTING
        ef_success        = ldf_boif_success
        ef_message        = ldf_message
        ef_severity       = ldf_boif_severity
    ).

    IF ldf_boif_success <> abap_true
    OR ldf_boif_severity = if_abap_behv_message=>severity-error.
      ldf_status      = gcf_error.
      ldf_criticality = gcf_criticality_error.
    ELSEIF ldf_boif_severity = if_abap_behv_message=>severity-warning.
      ldf_status      = gcf_normal.
      ldf_criticality = gcf_criticality_warning.
    ELSE.
      ldf_status      = gcf_normal.
      ldf_criticality = gcf_criticality_success.
    ENDIF.

    "出力の返却
    rs_ouput = VALUE #(
       criticality = ldf_criticality
       message     = ldf_message
    ).

  ENDMETHOD.


  METHOD reset_release_pr.
    DATA:
      ls_eban     TYPE eban,
      ls_t16fs    TYPE t16fs,
      lt_codes    TYPE TABLE OF frgco,
      lv_code     TYPE frgco,
      lt_return   TYPE TABLE OF bapiret2,
      ls_return   TYPE bapiret2,
      lv_bapi_suc TYPE abap_boolean.

    " 内部テーブル定義
    DATA:
      ldt_messages TYPE TABLE OF string.

    CLEAR: ef_success, ef_severity.

    " ---------------------------------------------------------
    " 1. EBANから承認グループと承認方針を取得
    " ---------------------------------------------------------
    SELECT SINGLE frggr, frgst
      FROM eban
      INTO CORRESPONDING FIELDS OF @ls_eban
      WHERE banfn = @is_prno.

    IF sy-subrc <> 0.
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-error.
      ef_message  = |PR { is_prno } Not Found|.
      RETURN.
    ENDIF.

    " ---------------------------------------------------------
    " 2. T16FSから承認コードを取得
    " ---------------------------------------------------------
    SELECT SINGLE *
      FROM t16fs
      INTO @ls_t16fs
      WHERE frggr = @ls_eban-frggr
        AND frgsx = @ls_eban-frgst.


    " 承認コードを収集
    IF ls_t16fs-frgc1 IS NOT INITIAL. APPEND ls_t16fs-frgc1 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc2 IS NOT INITIAL. APPEND ls_t16fs-frgc2 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc3 IS NOT INITIAL. APPEND ls_t16fs-frgc3 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc4 IS NOT INITIAL. APPEND ls_t16fs-frgc4 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc5 IS NOT INITIAL. APPEND ls_t16fs-frgc5 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc6 IS NOT INITIAL. APPEND ls_t16fs-frgc6 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc7 IS NOT INITIAL. APPEND ls_t16fs-frgc7 TO lt_codes. ENDIF.
    IF ls_t16fs-frgc8 IS NOT INITIAL. APPEND ls_t16fs-frgc8 TO lt_codes. ENDIF.

    " ---------------------------------------------------------
    " [QUAN TRỌNG] Đảo ngược thứ tự Code để Reset từ cao xuống thấp
    " ---------------------------------------------------------
    SORT lt_codes DESCENDING.

    " ---------------------------------------------------------
    " 3. BAPI実行 (RESET)
    " ---------------------------------------------------------
    ef_success = abap_true.
    ef_severity = if_abap_behv_message=>severity-success.

    LOOP AT lt_codes INTO lv_code.
      CLEAR: lt_return, lv_bapi_suc.


      CALL FUNCTION 'BAPI_REQUISITION_RELEASE_GEN'
        EXPORTING
          number   = is_prno
          rel_code = lv_code
        TABLES
          return   = lt_return.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

      " BAPI呼び出し (RESET RELEASE)
      CALL FUNCTION 'BAPI_REQUISITION_RESET_REL_GEN'
        EXPORTING
          number   = is_prno
          rel_code = lv_code
        TABLES
          return   = lt_return.

      IF sy-subrc = 0.
        " 成功時にコミット
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
        ef_success  = abap_true.
        ef_severity = if_abap_behv_message=>severity-success.
      ELSE.
        ef_success  = abap_false.
        ef_severity = if_abap_behv_message=>severity-error.

        APPEND |Can not reach to reject PR |
          TO ldt_messages.
      ENDIF.



    ENDLOOP.

    " ---------------------------------------------------------
    " 4. メッセージ整理
    " ---------------------------------------------------------
    IF ldt_messages IS INITIAL.
      APPEND 'Purchase requisition rejected' TO ldt_messages.
    ENDIF.

    SORT ldt_messages.
    DELETE ADJACENT DUPLICATES FROM ldt_messages COMPARING ALL FIELDS.
    ef_message = xco_cp=>strings( ldt_messages )->join( | / | )->value.

  ENDMETHOD.
ENDCLASS.
