 CLASS zcl_release_pr DEFINITION
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
           gtt_message TYPE TABLE OF string.

    TYPES: BEGIN OF gts_parallel_output,
             Criticality type ZI_RLSHEAD_G8-Criticality,
             message     type ZI_RLSHEAD_G8-MessageStandardtable,
           END OF gts_parallel_output.

    METHODS execute_parallel
      IMPORTING is_input        TYPE gts_parallel_input-pr_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS do REDEFINITION.

    METHODS main_process
      IMPORTING is_input        TYPE gts_parallel_input-pr_no
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS release_pr
      IMPORTING is_prno TYPE gts_parallel_input-pr_no
      EXPORTING ef_success        TYPE abap_boolean
                ef_message        TYPE string
                ef_severity       TYPE if_abap_behv_message=>t_severity.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_release_pr IMPLEMENTATION.


  METHOD execute_parallel.
    DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
          ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
          lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lds_input  TYPE gts_parallel_input-pr_no,
          lds_output TYPE gts_parallel_output.

    "入力の設定
    lds_input = is_input.

    EXPORT param_input = lds_input TO DATA BUFFER lds_xinput.
    APPEND lds_xinput TO ldt_xinput.

    "並列処理タスクの実行トリガーを呼び出す
    run( EXPORTING p_in_tab = ldt_xinput IMPORTING p_out_tab = ldt_xoutput ).

    "出力パラメータを取得する
    READ TABLE ldt_xoutput INTO lds_xoutput INDEX 1.
    IF sy-subrc = 0 AND lds_xoutput-result IS NOT INITIAL.
      IMPORT param_output = lds_output
        FROM DATA BUFFER lds_xoutput-result.
    ENDIF.

    "出力パラメータとして値を返す
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
      me->release_pr(
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


METHOD release_pr.
    DATA:
      ls_eban     TYPE eban,
      ls_t16fs    TYPE t16fs,
      lt_codes    TYPE TABLE OF frgco,
      lv_code     TYPE frgco,
      lt_return   TYPE TABLE OF bapiret2,
      ls_return   TYPE bapiret2,
      lv_bapi_suc TYPE abap_boolean.

    " 内部テーブル定義 (Bảng chứa message tạm)
    DATA:
      ldt_messages TYPE TABLE OF string.

    CLEAR: ef_success, ef_severity.

    " ---------------------------------------------------------
    " 1. EBANから承認グループと承認方針を取得 (Lấy Group & Strategy)
    " ---------------------------------------------------------
    SELECT SINGLE frggr, frgst
      FROM eban
      INTO CORRESPONDING FIELDS OF @ls_eban
      WHERE banfn = @is_prno.

    IF sy-subrc <> 0.
      " PRが見つかりません (Không tìm thấy PR)
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-error.
      ef_message  = |PR { is_prno } Not Found|.
      RETURN.
    ENDIF.

    " 承認対象外の場合 (Nếu không có Group/Strategy -> Không cần Release)
    IF ls_eban-frggr IS INITIAL OR ls_eban-frgst IS INITIAL.
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-success.
      ef_message  = |PR { is_prno } is not subject to release strategy|.
      RETURN.
    ENDIF.

    " ---------------------------------------------------------
    " 2. T16FSから承認コードを取得 (Lấy Release Codes từ T16FS)
    " ---------------------------------------------------------
    SELECT SINGLE *
      FROM t16fs
      INTO @ls_t16fs
      WHERE frggr = @ls_eban-frggr
        AND frgsx = @ls_eban-frgst.

    IF sy-subrc <> 0.
      ef_success  = abap_false.
      ef_severity = if_abap_behv_message=>severity-error.
      ef_message  = |Release Strategy { ls_eban-frggr }/{ ls_eban-frgst } not found in T16FS|.
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

    " ---------------------------------------------------------
    " 3. BAPI実行 (Chạy vòng lặp Release Code để Release)
    " ---------------------------------------------------------
    ef_success = abap_true. "Mặc định là Success, nếu có lỗi sẽ cập nhật lại
    ef_severity = if_abap_behv_message=>severity-success.

    LOOP AT lt_codes INTO lv_code.
      CLEAR: lt_return, lv_bapi_suc.

      " BAPI呼び出し (Gọi BAPI Release)
      CALL FUNCTION 'BAPI_REQUISITION_RELEASE_GEN'
        EXPORTING
          number   = is_prno
          rel_code = lv_code
        TABLES
          return   = lt_return.

      " 結果確認 (Kiểm tra kết quả)
DATA(lv_msg_text) = ''.

LOOP AT lt_return INTO ls_return.

  CLEAR lv_msg_text.

  MESSAGE ID ls_return-id
          TYPE ls_return-type
          NUMBER ls_return-number
          WITH ls_return-message_v1
               ls_return-message_v2
               ls_return-message_v3
               ls_return-message_v4
          INTO lv_msg_text.

  APPEND |{ ls_return-type }: { lv_msg_text } |
         TO ldt_messages.

  IF ls_return-type = 'E' OR ls_return-type = 'A'.
    ef_success  = abap_false.
    ef_severity = if_abap_behv_message=>severity-error.
    lv_bapi_suc = abap_false.
  ELSE.
    lv_bapi_suc = abap_true.
  ENDIF.

ENDLOOP.


      " 成功時にコミット (Commit nếu thành công cho Code này)
      IF ef_success = abap_true OR lv_bapi_suc = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
      ENDIF.
    ENDLOOP.

    " ---------------------------------------------------------
    " 4. メッセージ整理 (Format lại message đầu ra)
    " ---------------------------------------------------------
    IF ldt_messages IS INITIAL.
       APPEND 'Purchase requisition released' TO ldt_messages.
    ENDIF.

    SORT ldt_messages.
    DELETE ADJACENT DUPLICATES FROM ldt_messages COMPARING ALL FIELDS.
    ef_message = xco_cp=>strings( ldt_messages )->join( | / | )->value.

  ENDMETHOD.
ENDCLASS.
