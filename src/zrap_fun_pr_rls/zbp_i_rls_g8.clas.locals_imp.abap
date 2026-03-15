CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR header
        RESULT result,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR header RESULT result.

    METHODS releasePR FOR MODIFY
      IMPORTING keys FOR ACTION header~releasePR RESULT result.
    METHODS unreleasePR FOR MODIFY
      IMPORTING keys FOR ACTION header~unreleasePR RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR header RESULT result.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
    ENTITY header
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(ldt_pr).

    result = VALUE #(
    FOR lds_pr IN ldt_pr
      ( %tky = lds_pr-%tky

        %features-%action-releasePR = COND #(
          WHEN lds_pr-Status = 'Not release'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

          %features-%action-unreleasePR = COND #(
          WHEN lds_pr-Status = 'PR Released'
            OR lds_pr-Status = 'Not release'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

      %features-%update = if_abap_behv=>fc-o-disabled

      %features-%delete = if_abap_behv=>fc-o-disabled

      %features-%action-Edit = if_abap_behv=>fc-o-disabled ) ).
  ENDMETHOD.

  METHOD releasePR.

    DATA: lo_pr_release TYPE REF TO zcl_release_pr,
          ls_output     TYPE zcl_release_pr=>gts_parallel_output.

    DATA: ldt_senmail        TYPE zcl_pr_sendmail=>gtt_filedata,
          lds_senmail        TYPE zcl_pr_sendmail=>gts_filedata,
          lds_sendmail_input TYPE zcl_pr_sendmail=>gts_parallel_input.

    " 1. Đọc dữ liệu Entity để lấy PrNo
    READ ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr_data).



    " 2. Xử lý theo từng PR (group by PrNo)
    LOOP AT lt_pr_data INTO DATA(ls_pr).

      " --- Gọi Class Parallel (1 lần / PR) ---
      lo_pr_release = NEW zcl_release_pr( ).
      ls_output = lo_pr_release->execute_parallel(
                    is_input = ls_pr-PrNo ).

      " Status text theo criticality
      DATA(lv_status_text) =
        COND zi_rlshead_g8-status(
          WHEN ls_output-criticality = 3 OR ls_output-criticality = 2
            THEN 'PR Released'
          WHEN ls_output-criticality = 1
            THEN 'Release Fail'
        ).

      IF ls_output-criticality = 3 OR ls_output-criticality = 2.
        MOVE-CORRESPONDING ls_pr TO lds_senmail.
        APPEND lds_senmail TO ldt_senmail.
      ENDIF.

      " --- Update tất cả line item thuộc PR này ---
      MODIFY ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
        ENTITY header
        UPDATE
        FIELDS ( Status Criticality MessageStandardtable )
        WITH VALUE #(
            ( %tky                 = ls_pr-%tky
              Status               = lv_status_text
              Criticality          = ls_output-criticality
              MessageStandardtable = ls_output-message )
        ).
    ENDLOOP.

    IF ldt_senmail IS NOT INITIAL.
      lds_sendmail_input-iv_filename = ls_pr-DefineKey.
      lds_sendmail_input-it_data = ldt_senmail.
      lds_sendmail_input-iv_receiver = 'datnb258@gmail.com'.
      lds_sendmail_input-iv_subject = 'PR Released List'.
      DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
      lo_process_sendmail->execute_parallel( lds_sendmail_input ).
    ENDIF.

    " 3. Trả kết quả về UI
    READ ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_data).

    LOOP AT lt_updated_data INTO DATA(ls_updated).
      INSERT VALUE #(
        %tky   = ls_updated-%tky
        %param = ls_updated
      ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD unreleasePR.
    DATA: lo_pr_release TYPE REF TO zcl_reject_pr,
          ls_output     TYPE zcl_release_pr=>gts_parallel_output.

    DATA: ldt_senmail        TYPE zcl_pr_sendmail=>gtt_filedata,
          lds_senmail        TYPE zcl_pr_sendmail=>gts_filedata,
          lds_sendmail_input TYPE zcl_pr_sendmail=>gts_parallel_input.

    " 1. Đọc dữ liệu Entity để lấy PrNo dựa trên Keys đầu vào
    READ ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr_data).

    " 3. Lặp và xử lý
    LOOP AT lt_pr_data INTO DATA(ls_pr).

      " --- Gọi Class Parallel ---
      lo_pr_release = NEW zcl_reject_pr( ).
      ls_output = lo_pr_release->execute_parallel( is_input = ls_pr-PrNo ).

      " Xác định Status Text dựa trên Criticality trả về
      DATA(lv_status_text) = COND zi_rlshead_g8-status(
                                WHEN ls_output-criticality = 3 THEN 'PR Rejected').

      DATA(lv_criticality) = COND zi_rlshead_g8-status(
                                WHEN ls_output-criticality = 3 THEN 1
                                WHEN ls_output-criticality = 1 THEN 3 ).

      IF ls_output-criticality = 3.
        DATA(ldv_reason) = keys[ KEY draft %tky = lt_pr_data[ 1 ]-%tky ]-%param-CancelReasonCode.
        DATA ldv_note TYPE zpr_rejres_g8-cancel_reason_note.

        SELECT SINGLE cancel_reason_note
          FROM zpr_rejres_g8
          WHERE cancel_reason_code = @ldv_reason
          INTO @ldv_note.
      ENDIF.

      " --- QUAN TRỌNG: Cập nhật lại vào Entity (Database) ---
      " Tìm tất cả các keys trong danh sách chọn trùng với PrNo đang xử lý
      " và thực hiện Update field Status, Criticality, Message
      IF ls_output-criticality = 3.
        MODIFY ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
          ENTITY header
          UPDATE
          FIELDS ( Status Criticality MessageStandardtable CancelReasonCode CancelNote )
          WITH VALUE #(
            (
              %tky        = ls_pr-%tky

              Status      = lv_status_text
              CancelReasonCode = ldv_reason
              CancelNote = ldv_note
              Criticality = lv_criticality
              MessageStandardtable = ls_output-message
            )
          ).

        MOVE-CORRESPONDING ls_pr TO lds_senmail.
        lds_senmail-rejectreason = ldv_note.
        APPEND lds_senmail TO ldt_senmail.
      ELSE.
        MODIFY ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
         ENTITY header
         UPDATE
         FIELDS ( MessageStandardtable CancelReasonCode CancelNote )
         WITH VALUE #(
           (
             %tky        = ls_pr-%tky

             CancelReasonCode = ldv_reason
             CancelNote = ldv_note
             MessageStandardtable = ls_output-message
           )
         ).
      ENDIF.



    ENDLOOP.
    IF ldt_senmail IS NOT INITIAL.
      lds_sendmail_input-iv_filename = ls_pr-DefineKey.
      lds_sendmail_input-it_data     = ldt_senmail.
      lds_sendmail_input-iv_receiver = 'datnb258@gmail.com'.
      lds_sendmail_input-iv_subject  = 'PR Rejected List'.

      DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
      lo_process_sendmail->execute_parallel( lds_sendmail_input ).
    ENDIF.

    " --- Trả về kết quả cho UI (Result) ---
    " Action bắt buộc phải trả về Result để UI biết dòng đó đã thay đổi
    READ ENTITIES OF zi_rlshead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_data).

    LOOP AT lt_updated_data INTO DATA(ls_updated).
      INSERT VALUE #(
          %tky   = ls_updated-%tky
          %param = ls_updated
      ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.
