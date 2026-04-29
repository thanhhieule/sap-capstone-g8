    CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
      PRIVATE SECTION.
        METHODS:
          get_global_authorizations FOR GLOBAL AUTHORIZATION
            IMPORTING
            REQUEST requested_authorizations FOR header
            RESULT result,
          get_instance_features FOR INSTANCE FEATURES
            IMPORTING keys REQUEST requested_features FOR header RESULT result.

        METHODS releasePO FOR MODIFY
          IMPORTING keys FOR ACTION header~releasePO RESULT result.

        METHODS unreleasePO FOR MODIFY
          IMPORTING keys FOR ACTION header~unreleasePO RESULT result.
        METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
          IMPORTING keys REQUEST requested_authorizations FOR header RESULT result.
    ENDCLASS.

    CLASS lcl_handler IMPLEMENTATION.
      METHOD get_global_authorizations.
      ENDMETHOD.
      METHOD get_instance_features.

        READ ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
          ENTITY header
          FIELDS ( Status )
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_po).

        result = VALUE #(
          FOR ls_po IN lt_po
          (
            %tky = ls_po-%tky

            %features-%action-releasePO = COND #(
                WHEN ls_po-Status = 'Not release'
                OR   ls_po-Status = ''
                THEN if_abap_behv=>fc-o-enabled
                ELSE if_abap_behv=>fc-o-disabled )

*            %features-%action-unreleasePO = COND #(
*                WHEN ls_po-Status = 'PO Released'
*                  OR ls_po-Status = 'Not release'
*                THEN if_abap_behv=>fc-o-enabled
*                ELSE if_abap_behv=>fc-o-disabled )

            %features-%action-Edit = if_abap_behv=>fc-o-disabled
          )
        ).

      ENDMETHOD.

      METHOD releasePO.

        DATA: lo_po_release TYPE REF TO zcl_po_release,
              ls_output     TYPE zcl_po_release=>gts_parallel_output.

        DATA: lt_sendmail       TYPE zcl_pr_sendmail=>gtt_filedata,
              ls_sendmail       TYPE zcl_pr_sendmail=>gts_filedata,
              ls_sendmail_input TYPE zcl_pr_sendmail=>gts_parallel_input.

        "1. Read entity data
        READ ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
          ENTITY header
          ALL FIELDS
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_po_data).



        LOOP AT lt_po_data INTO DATA(ls_po).

          lo_po_release = NEW zcl_po_release( ).

          ls_output = lo_po_release->execute_parallel(
                        is_input = ls_po-Ebeln ).


          DATA(lv_status_text) =
            COND zi_rlshead_g8-status(
              WHEN ls_output-criticality = 3
                OR ls_output-criticality = 2
              THEN 'PO Released'
              WHEN ls_output-criticality = 1
              THEN 'Release Fail'
            ).

          IF ls_output-criticality = 3
          OR ls_output-criticality = 2.
            MOVE-CORRESPONDING ls_po TO ls_sendmail.
            APPEND ls_sendmail TO lt_sendmail.
          ENDIF.


          MODIFY ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
            ENTITY header
            UPDATE
            FIELDS ( Status Criticality MessageStandardtable )
            WITH VALUE #(
              (
                %tky                 = ls_po-%tky
                Status               = lv_status_text
                Criticality          = ls_output-criticality
                MessageStandardtable = ls_output-message
              )
            ).

        ENDLOOP.



        "Send mail giống PR
        IF lt_sendmail IS NOT INITIAL.

          ls_sendmail_input-iv_filename = ls_po-DefineKey.
          ls_sendmail_input-it_data     = lt_sendmail.
          ls_sendmail_input-iv_subject  = 'PO Released List'.

          DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
          lo_process_sendmail->execute_parallel( ls_sendmail_input ).

        ENDIF.



        READ ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
          ENTITY header
          ALL FIELDS
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_updated).

        LOOP AT lt_updated INTO DATA(ls_updated).
          INSERT VALUE #(
            %tky   = ls_updated-%tky
            %param = ls_updated
          ) INTO TABLE result.
        ENDLOOP.

      ENDMETHOD.

METHOD unreleasePO.

  DATA: lo_po_release TYPE REF TO zcl_po_reject,
        ls_output     TYPE zcl_po_reject=>gts_parallel_output.

  DATA: ldt_senmail        TYPE zcl_pr_sendmail=>gtt_filedata,
        lds_senmail        TYPE zcl_pr_sendmail=>gts_filedata,
        lds_sendmail_input TYPE zcl_pr_sendmail=>gts_parallel_input.

*------------------------------------------------------------------
* 1️⃣ Read Entity (Get PO numbers)
*------------------------------------------------------------------
  READ ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
    ENTITY header
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_po_data).

*------------------------------------------------------------------
* 2️⃣ Loop process
*------------------------------------------------------------------
  LOOP AT lt_po_data INTO DATA(ls_po).

* ---- Parallel call ----
    lo_po_release = NEW zcl_po_reject( ).
    ls_output =
      lo_po_release->execute_parallel(
        is_input = ls_po-Ebeln ).

*------------------------------------------------------------------
* Status mapping (same logic)
*------------------------------------------------------------------
    DATA(lv_status_text) =
      COND zi_rlshead_po-status(
        WHEN ls_output-criticality = 3
        THEN 'PO Rejected' ).

    DATA(lv_criticality) =
      COND zi_rlshead_po-criticality(
        WHEN ls_output-criticality = 3 THEN 1
        WHEN ls_output-criticality = 1 THEN 3 ).

*------------------------------------------------------------------
* Reason / Note (reuse same customizing table)
*------------------------------------------------------------------
    IF ls_output-criticality = 3.

      DATA(ldv_reason) =
        keys[ KEY draft %tky = ls_po-%tky ]-%param-CancelReasonCode.
    ENDIF.

*------------------------------------------------------------------
* Update Entity
*------------------------------------------------------------------
    IF ls_output-criticality = 3.

      MODIFY ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
        ENTITY header
        UPDATE
        FIELDS ( Status
                 Criticality
                 MessageStandardtable
                 CancelReasonCode
*                 CancelNote
                 )
        WITH VALUE #(
          (
            %tky        = ls_po-%tky
            Status      = lv_status_text
            Criticality = lv_criticality
            MessageStandardtable = ls_output-message
            CancelReasonCode = ldv_reason
*            CancelNote  = ldv_note
          )
        ).

* Mail list
      MOVE-CORRESPONDING ls_po TO lds_senmail.
      lds_senmail-rejectreason = ldv_reason.
      APPEND lds_senmail TO ldt_senmail.

    ELSE.

      MODIFY ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
        ENTITY header
        UPDATE
        FIELDS ( MessageStandardtable
                 CancelReasonCode
*                 CancelNote
                 )
        WITH VALUE #(
          (
            %tky        = ls_po-%tky
            CancelReasonCode = ldv_reason
*            CancelNote  = ldv_note
            MessageStandardtable = ls_output-message
          )
        ).

    ENDIF.

  ENDLOOP.

*------------------------------------------------------------------
* 3️⃣ Send Mail
*------------------------------------------------------------------
  IF ldt_senmail IS NOT INITIAL.

    lds_sendmail_input-iv_filename = ls_po-DefineKey.
    lds_sendmail_input-it_data     = ldt_senmail.
    lds_sendmail_input-iv_subject  = 'PO Rejected List'.

    DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
    lo_process_sendmail->execute_parallel(
      lds_sendmail_input ).

  ENDIF.

*------------------------------------------------------------------
* 4️⃣ Return Result to UI
*------------------------------------------------------------------
  READ ENTITIES OF zi_rlshead_po_g8 IN LOCAL MODE
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


      METHOD get_instance_authorizations.
      ENDMETHOD.

    ENDCLASS.
