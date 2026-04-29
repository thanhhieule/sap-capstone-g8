 CLASS zcl_po_sendmail DEFINITION
  PUBLIC
  FINAL
  INHERITING FROM cl_abap_parallel
  CREATE PUBLIC.

  PUBLIC SECTION.

    " ===== PO DATA =====
    TYPES: BEGIN OF gts_po_data,
             ebeln TYPE ebeln,
             bsart TYPE bsart,
             bukrs TYPE bukrs,
             lifnr TYPE lifnr,
             ekorg TYPE ekorg,
             ekgrp TYPE ekgrp,
             waers TYPE waers,
             erdat TYPE sydatum,
           END OF gts_po_data.

    TYPES: gtt_po_data TYPE STANDARD TABLE OF gts_po_data WITH EMPTY KEY.

    " ===== PARALLEL INPUT =====
    TYPES: BEGIN OF gts_parallel_input,
             iv_define_key TYPE sysuuid_x16,
             it_data       TYPE gtt_po_data,
             iv_receiver   TYPE ad_smtpadr,
             iv_subject    TYPE so_obj_des,
           END OF gts_parallel_input.

    " ===== PARALLEL OUTPUT =====
    TYPES: BEGIN OF gts_parallel_output,
             result_message TYPE string,
           END OF gts_parallel_output.

    " ===== WRAPPER =====
    METHODS execute_parallel
      IMPORTING
        is_input         TYPE gts_parallel_input
      RETURNING
        VALUE(rs_output) TYPE gts_parallel_output.

    " ===== MAIN LOGIC =====
    METHODS send_mail_po
      IMPORTING
        iv_define_key TYPE sysuuid_x16
        it_data       TYPE gtt_po_data
        iv_receiver   TYPE ad_smtpadr
        iv_user       TYPE ztmail_g8-username
        iv_subject    TYPE so_obj_des
      EXPORTING
        ev_sent       TYPE abap_bool
        ev_message    TYPE string.

    METHODS do REDEFINITION.

ENDCLASS.

CLASS zcl_po_sendmail IMPLEMENTATION.
  METHOD execute_parallel.

    DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
          ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
          lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lds_input  TYPE gts_parallel_input,
          lds_output TYPE gts_parallel_output.

    lds_input = is_input.

    EXPORT param_input = lds_input TO DATA BUFFER lds_xinput.
    APPEND lds_xinput TO ldt_xinput.

    run(
      EXPORTING p_in_tab  = ldt_xinput
      IMPORTING p_out_tab = ldt_xoutput ).

    READ TABLE ldt_xoutput INTO lds_xoutput INDEX 1.
    IF sy-subrc = 0 AND lds_xoutput-result IS NOT INITIAL.
      IMPORT param_output = lds_output
        FROM DATA BUFFER lds_xoutput-result.
    ELSE.
      lds_output-result_message = 'No result returned from parallel task'.
    ENDIF.

    rs_output = lds_output.

  ENDMETHOD.
  METHOD do.

    DATA: lds_input  TYPE gts_parallel_input,
          lds_output TYPE gts_parallel_output.

    DATA: lv_sent TYPE abap_bool,
          lv_msg  TYPE string,
          lv_receiver TYPE ad_smtpadr,
          lv_username TYPE ztmail_g8-username.

    IMPORT param_input = lds_input FROM DATA BUFFER p_in.

      SELECT SINGLE email, username
        INTO ( @lv_receiver, @lv_username )
        FROM ztmail_g8
        WHERE role = 'M_PRC'.

    me->send_mail_po(
      EXPORTING
        iv_define_key = lds_input-iv_define_key
        it_data       = lds_input-it_data
        iv_receiver   = lv_receiver
        iv_user       = lv_username
        iv_subject    = lds_input-iv_subject
      IMPORTING
        ev_sent       = lv_sent
        ev_message    = lv_msg ).

    IF lv_sent = abap_true.
      lds_output-result_message = 'Success'.
    ELSE.
      lds_output-result_message = |Error: { lv_msg }|.
    ENDIF.

    EXPORT param_output = lds_output TO DATA BUFFER p_out.

  ENDMETHOD.
  METHOD send_mail_po.

    DATA: lo_send_request  TYPE REF TO cl_bcs,
          lo_document      TYPE REF TO cl_document_bcs,
          lo_sender_usr    TYPE REF TO cl_sapuser_bcs,
          lo_recipient     TYPE REF TO if_recipient_bcs,
          lo_bcs_exception TYPE REF TO cx_bcs.

    DATA: it_contents_txt TYPE soli_tab,
          wa_content      LIKE LINE OF it_contents_txt,
          lv_sent_to_all  TYPE os_boolean.

    ev_sent = abap_false.

    " ===== 1. BUILD HTML CONTENT =====
    APPEND '<!DOCTYPE html><html><body style="font-family:Arial; font-size:12px;">'
        TO it_contents_txt.
    APPEND |<p>Dear <strong>{ iv_user }</strong>,</p>| TO it_contents_txt.

    wa_content-line = |<p><strong>Define Key:</strong> { iv_define_key }</p>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h3 style="color:#4CAF50;">{ iv_subject }</h3>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h2 style="color: #4CAF50;">Release PO Application link: </h2>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<a href="https://s35.gb.ucc.cit.tum.de/sap/bc/ui5_ui5/sap/zsb_u2_po_rls?sap-client=302">Mass PO release</a>|.
    APPEND wa_content TO it_contents_txt.

    APPEND '<p>Purchase Order summary information:</p>'
        TO it_contents_txt.

    " ===== TABLE HEADER =====
    APPEND '<table style="border-collapse:collapse; width:90%; border:1px solid #ccc;">'
        TO it_contents_txt.
    APPEND '<tr style="background-color:#e8f5e9;">'
        TO it_contents_txt.

    APPEND '<th style="border:1px solid #ccc; padding:6px;">PO No</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">PO Type</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Company</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Vendor</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Purch. Org</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Purch. Group</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Currency</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Document Date</th>'
        TO it_contents_txt.

    APPEND '</tr>' TO it_contents_txt.

    " ===== TABLE DATA =====
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<fs_po>).
      APPEND '<tr>' TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-ebeln }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-bsart }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-bukrs }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-lifnr }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-ekorg }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-ekgrp }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-waers }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:6px;">{ <fs_po>-erdat DATE = USER }</td>|.
      APPEND wa_content TO it_contents_txt.

      APPEND '</tr>' TO it_contents_txt.
    ENDLOOP.

    APPEND '</table>' TO it_contents_txt.
    APPEND '<br><p>Best regards,<br><strong>System</strong></p>'
        TO it_contents_txt.
    APPEND '</body></html>' TO it_contents_txt.

    " ===== 2. SEND MAIL =====
    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        lo_document = cl_document_bcs=>create_document(
                        i_type    = 'HTM'
                        i_subject = iv_subject
                        i_text    = it_contents_txt ).

        lo_send_request->set_document( lo_document ).

        lo_sender_usr = cl_sapuser_bcs=>create( i_user = sy-uname ).
        lo_send_request->set_sender( lo_sender_usr ).

        lo_recipient =
          cl_cam_address_bcs=>create_internet_address( iv_receiver ).
        lo_send_request->add_recipient(
          i_recipient = lo_recipient
          i_express   = 'X' ).

        lo_send_request->set_send_immediately( 'X' ).

        lo_send_request->send(
          EXPORTING i_with_error_screen = ' '
          RECEIVING result              = lv_sent_to_all ).

        IF lv_sent_to_all = abap_true.
          ev_sent    = abap_true.
          ev_message = 'Email sent successfully'.
          COMMIT WORK.
        ELSE.
          ev_message = 'Send returned false'.
        ENDIF.

      CATCH cx_bcs INTO lo_bcs_exception.
        ev_sent    = abap_false.
        ev_message = lo_bcs_exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


ENDCLASS.

