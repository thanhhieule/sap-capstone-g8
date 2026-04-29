CLASS  zcl_pr_sendmail DEFINITION
  PUBLIC FINAL
  INHERITING FROM cl_abap_parallel
  CREATE PUBLIC.

  PUBLIC SECTION.
    " 1. Định nghĩa các cấu trúc dữ liệu kinh doanh (Business Data)
    TYPES: BEGIN OF gts_filedata,
             prno                        TYPE zi_list_g8-prno,
             pritem                      TYPE zi_list_g8-pritem,
             purchaserequisitiontype     TYPE zi_list_g8-purchaserequisitiontype,
             purreqndescription          TYPE zi_list_g8-purreqndescription,
             purchaserequisitionitemtext TYPE zi_list_g8-purchaserequisitionitemtext,
             material                    TYPE zi_list_g8-material,
             materialgroup               TYPE zi_list_g8-materialgroup,
             quantityreq                 TYPE zi_list_g8-quantityreq,
             unit                        TYPE zi_list_g8-unit,
             purchaserequisitionprice    TYPE zi_list_g8-purchaserequisitionprice,
             purreqnitemcurrency         TYPE zi_list_g8-purreqnitemcurrency,
             plant                       TYPE zi_list_g8-plant,
             purchasinggroup             TYPE zi_list_g8-purchasinggroup,
             purchasingorganization      TYPE zi_list_g8-purchasingorganization,
             accountassignmentcategory   TYPE zi_list_g8-accountassignmentcategory,
             deliverydate                TYPE zi_list_g8-deliverydate,
             status                      TYPE zi_list_g8-Status,
             url                         TYPE zi_list_g8-url,
             rejectreason                TYPE zpr_rlshead_g8-cancel_note,
           END OF gts_filedata.

    TYPES: gtt_filedata TYPE STANDARD TABLE OF gts_filedata WITH EMPTY KEY.

    " --- 2. CẤU TRÚC DỮ LIỆU CHO PARALLEL PROCESSING ---

    " Input cho 1 task: Bao gồm data file và thông tin người nhận
    TYPES: BEGIN OF gts_parallel_input,
             iv_filename TYPE zi_att_g8-FileName,
             it_data     TYPE gtt_filedata,
             iv_subject  TYPE so_obj_des,
           END OF gts_parallel_input.

    " Output cho 1 task: Chỉ trả về message đơn giản
    TYPES: BEGIN OF gts_parallel_output,
             result_message TYPE string,
           END OF gts_parallel_output.

    " --- 3. PHƯƠNG THỨC ---

    " Hàm gọi chạy song song (Wrapper)
    METHODS execute_parallel
      IMPORTING
        is_input         TYPE gts_parallel_input
      RETURNING
        VALUE(rs_output) TYPE gts_parallel_output.

    " Hàm gửi mail (Logic chính)
    METHODS send_mail_pr
      IMPORTING
        iv_filename TYPE zi_att_g8-FileName
        it_data     TYPE gtt_filedata
        iv_receiver TYPE ad_smtpadr
        iv_user     TYPE ztmail_g8-username
        iv_subject  TYPE so_obj_des DEFAULT 'PR Notification'
      EXPORTING
        ev_sent     TYPE abap_bool
        ev_message  TYPE string.

    METHODS send_mail_pr_release
      IMPORTING
        iv_filename TYPE zi_att_g8-FileName
        it_data     TYPE gtt_filedata
        iv_receiver TYPE ad_smtpadr
        iv_user     TYPE ztmail_g8-username
        iv_role     TYPE ztmail_g8-role
        iv_subject  TYPE so_obj_des DEFAULT 'PR Release Notification'
      EXPORTING
        ev_sent     TYPE abap_bool
        ev_message  TYPE string.

    METHODS send_mail_pr_reject
      IMPORTING
        iv_filename TYPE zi_att_g8-FileName
        it_data     TYPE gtt_filedata
        iv_receiver TYPE ad_smtpadr
        iv_user     TYPE ztmail_g8-username
        iv_subject  TYPE so_obj_des DEFAULT 'PR Reject Notification'
      EXPORTING
        ev_sent     TYPE abap_bool
        ev_message  TYPE string.


    " Override phương thức DO của class cha
    METHODS do REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_pr_sendmail IMPLEMENTATION.

  METHOD execute_parallel.
    " --- CHUẨN BỊ ---
    DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
          ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
          lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lds_input  TYPE gts_parallel_input,
          lds_output TYPE gts_parallel_output.

    " 1. Lấy dữ liệu đầu vào
    lds_input = is_input.

    " 2. Đóng gói (Serialize) vào buffer
    EXPORT param_input = lds_input TO DATA BUFFER lds_xinput.
    APPEND lds_xinput TO ldt_xinput.

    run( EXPORTING p_in_tab = ldt_xinput IMPORTING p_out_tab = ldt_xoutput ).
    " 4. Nhận kết quả (Deserialize)
    READ TABLE ldt_xoutput INTO lds_xoutput INDEX 1.
    IF sy-subrc = 0 AND lds_xoutput-result IS NOT INITIAL.
      IMPORT param_output = lds_output
        FROM DATA BUFFER lds_xoutput-result.
    ELSE.
      lds_output-result_message = 'No result returned from parallel task'.
    ENDIF.

    " 5. Trả về kết quả
    rs_output = lds_output.
  ENDMETHOD.


  METHOD do.

    DATA: lds_input  TYPE gts_parallel_input,
          lds_output TYPE gts_parallel_output.

    DATA: lv_sent     TYPE abap_bool,
          lv_msg      TYPE string,
          lv_receiver TYPE ad_smtpadr,
          lv_username TYPE ztmail_g8-username.

    " 1. Đọc input
    IMPORT param_input = lds_input FROM DATA BUFFER p_in.

    " 2. Xác định receiver theo subject
    CASE lds_input-iv_subject.
      WHEN 'PR List'.
        SELECT SINGLE email, username
          INTO ( @lv_receiver, @lv_username )
          FROM ztmail_g8
          WHERE role = 'M_INV'.

        me->send_mail_pr(
          EXPORTING
            iv_filename = lds_input-iv_filename
            it_data     = lds_input-it_data
            iv_receiver = lv_receiver
            iv_user     = lv_username
            iv_subject  = lds_input-iv_subject
          IMPORTING
            ev_sent     = lv_sent
            ev_message  = lv_msg
        ).

      WHEN 'PR Released List' OR 'PR Rejected List'.

        IF lds_input-iv_subject = 'PR Released List'.
          SELECT SINGLE email, username
            INTO ( @lv_receiver, @lv_username )
            FROM ztmail_g8
            WHERE role = 'S_INV'.

          me->send_mail_pr_release(
            EXPORTING
              iv_filename = lds_input-iv_filename
              it_data     = lds_input-it_data
              iv_receiver = lv_receiver
              iv_user     = lv_username
              iv_role     = 'S_INV'
              iv_subject  = lds_input-iv_subject
            IMPORTING
              ev_sent     = lv_sent
              ev_message  = lv_msg
          ).

          SELECT SINGLE email, username
            INTO ( @lv_receiver, @lv_username )
            FROM ztmail_g8
            WHERE role = 'S_PRC'.

          me->send_mail_pr_release(
            EXPORTING
              iv_filename = lds_input-iv_filename
              it_data     = lds_input-it_data
              iv_receiver = lv_receiver
              iv_user     = lv_username
              iv_role     = 'S_PRC'
              iv_subject  = lds_input-iv_subject
            IMPORTING
              ev_sent     = lv_sent
              ev_message  = lv_msg
          ).
        ELSE.

          SELECT SINGLE email, username
            INTO ( @lv_receiver, @lv_username )
            FROM ztmail_g8
            WHERE role = 'S_INV'.

          me->send_mail_pr_reject(
            EXPORTING
              iv_filename = lds_input-iv_filename
              it_data     = lds_input-it_data
              iv_receiver = lv_receiver
              iv_user     = lv_username
              iv_subject  = lds_input-iv_subject
            IMPORTING
              ev_sent     = lv_sent
              ev_message  = lv_msg
          ).
        ENDIF.

    ENDCASE.

    " 3. Result
    IF lv_sent = abap_true.
      lds_output-result_message = 'Success'.
    ELSE.
      lds_output-result_message = |Error: { lv_msg }|.
    ENDIF.

    " 4. Export output
    EXPORT param_output = lds_output TO DATA BUFFER p_out.

  ENDMETHOD.


  METHOD send_mail_pr.
    DATA: lo_send_request  TYPE REF TO cl_bcs,
          lo_document      TYPE REF TO cl_document_bcs,
          lo_sender        TYPE REF TO cl_sapuser_bcs,
          lo_recipient     TYPE REF TO if_recipient_bcs,
          lo_sender_usr    TYPE REF TO cl_sapuser_bcs,
          lo_bcs_exception TYPE REF TO cx_bcs.

    DATA: it_contents_txt TYPE soli_tab,
          lv_subject      TYPE so_obj_des.

    DATA: lv_string       TYPE string,
          lv_string_table TYPE string,
          lv_xstring      TYPE xstring,
          lv_sent_to_all  TYPE os_boolean,
          it_binary       TYPE solix_tab.

    DATA: wa_content LIKE LINE OF it_contents_txt.

    ev_sent = abap_false.

    " --- 1. XÂY DỰNG NỘI DUNG HTML ---
    APPEND '<!DOCTYPE html><html><body style="font-family:Arial, sans-serif; font-size:12px;">' TO it_contents_txt.
    APPEND |<p>Dear <strong>{ iv_user }</strong>,</p>| TO it_contents_txt.

    wa_content-line = |<p><strong>Define Key:</strong> { iv_filename }</p>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h2 style="color: #4CAF50;">{ iv_subject }</h2>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h2 style="color: #4CAF50;">Release PR Application link: </h2>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<a href="https://s35.gb.ucc.cit.tum.de/sap/bc/ui5_ui5/sap/zsb_u2_pr_rls?sap-client=302">Mass PR release</a>|.
    APPEND wa_content TO it_contents_txt.

    APPEND '<p>Please check the list of <strong>Purchase Requisitions</strong> below:</p>' TO it_contents_txt.

    " Mở bảng - Thêm overflow-x để nếu quá dài thì có thanh trượt (trên webmail support)
    APPEND '<div style="overflow-x:auto;">' TO it_contents_txt.
    APPEND '<table style="border-collapse:collapse; width:100%; border:1px solid #ddd; font-size:11px;">' TO it_contents_txt.

    " --- UPDATED TABLE HEADER (HIỂN THỊ HẾT CÁC CỘT) ---
    APPEND '<tr style="background-color:#fff7cc; text-align:left;">' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Status</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">PR No</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Item</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Type</th>' TO it_contents_txt.       " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Material</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Mat. Grp</th>' TO it_contents_txt.   " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Description</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Item Text</th>' TO it_contents_txt.  " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Qty</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Unit</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Price</th>' TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Plant</th>' TO it_contents_txt.      " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">P.Grp</th>' TO it_contents_txt.      " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">P.Org</th>' TO it_contents_txt.      " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Acct Cat</th>' TO it_contents_txt.   " NEW
    APPEND '<th style="border:1px solid #ccc; padding:4px;">Deliv. Date</th>' TO it_contents_txt.
    APPEND '</tr>' TO it_contents_txt.

    " --- UPDATED TABLE DATA LOOP ---
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<fs_row>).
      APPEND '<tr>' TO it_contents_txt.

      DATA(lv_status_color) = ''.
      DATA(lv_status_text)  = ''.

      lv_status_text = <fs_row>-status.

      CASE lv_status_text.
        WHEN 'Not release'.
          lv_status_color = '#9e9e9e'.   " gray
        WHEN 'PR Released'.
          lv_status_color = '#2e7d32'.   " green
        WHEN 'Release Fail' OR 'PR Rejected'.
          lv_status_color = '#c62828'.   " red
        WHEN OTHERS.
          lv_status_color = '#000000'.   " default black
      ENDCASE.

      wa_content-line =
        |<td style="border:1px solid #ccc; padding:4px; font-weight:bold; color:{ lv_status_color };">{ lv_status_text }</td>|.

      APPEND wa_content TO it_contents_txt.

      " 1. PR No
      " --- FIX: Tách nhỏ chuỗi để tránh lỗi quá 255 ký tự làm mất thẻ đóng </td> ---

      " Bước 1: Mở thẻ TD
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">|.
      APPEND wa_content TO it_contents_txt.

      IF <fs_row>-url IS NOT INITIAL.
        " Bước 2: Thẻ A phần đầu (nếu URL dài, nó sẽ nằm trọn ở dòng này hoặc dòng sau)
        wa_content-line = |<a href="{ <fs_row>-url }" target="_blank" |.
        APPEND wa_content TO it_contents_txt.

        " Bước 3: Thẻ A phần đuôi và Text
        wa_content-line = |style="color:#1a73e8; text-decoration:underline;">{ <fs_row>-prno }</a>|.
        APPEND wa_content TO it_contents_txt.
      ELSE.
        " Trường hợp không có URL
        wa_content-line = <fs_row>-prno.
        APPEND wa_content TO it_contents_txt.
      ENDIF.

      " Bước 4: Đóng thẻ TD (Quan trọng: Đảm bảo thẻ này luôn được append riêng)
      wa_content-line = '</td>'.
      APPEND wa_content TO it_contents_txt.
      " 2. Item
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-pritem }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 3. Type (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-purchaserequisitiontype }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 4. Material
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px; white-space:nowrap;">{ <fs_row>-material }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 5. Material Group (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-materialgroup }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 6. Description
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-purreqndescription }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 7. Item Text (NEW)
      DATA(lv_short_text) = <fs_row>-purchaserequisitionitemtext.
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px; font-style:italic; color:#555;">{ lv_short_text }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 8. Quantity
      DATA(lv_qty) = <fs_row>-quantityreq.
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px; text-align:right;">{ lv_qty }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 9. Unit
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-unit }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 10. Price + Currency
      DATA(lv_price) = <fs_row>-purchaserequisitionprice.
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px; text-align:right; white-space:nowrap;">{ lv_price } { <fs_row>-purreqnitemcurrency }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 11. Plant (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-plant }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 12. Purchasing Group (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-purchasinggroup }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 13. Purchasing Org (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-purchasingorganization }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 14. Account Assignment Category (NEW)
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px;">{ <fs_row>-accountassignmentcategory }</td>|.
      APPEND wa_content TO it_contents_txt.

      " 15. Delivery Date
      wa_content-line = |<td style="border:1px solid #ccc; padding:4px; white-space:nowrap;">{ <fs_row>-deliverydate DATE = USER }</td>|.
      APPEND wa_content TO it_contents_txt.

      APPEND '</tr>' TO it_contents_txt.
    ENDLOOP.

    APPEND '</table>' TO it_contents_txt.
    APPEND '</div>' TO it_contents_txt. " Đóng thẻ div overflow
    APPEND '<br><p>Best regards,<br><strong>System</strong></p>' TO it_contents_txt.
    APPEND '</body></html>' TO it_contents_txt.


    " --- 2. TẠO ATTACHMENT (EXCEL) ---
    CLEAR: lv_string_table.
    CONCATENATE 'Status' 'PR Number' 'Item' 'Type' 'Description' 'Material' 'Mat Group' 'Qty' 'Unit' 'Price' 'Currency' 'Plant' 'P.Group' 'P.Org' 'Deliv Date'
      INTO lv_string SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
    CONCATENATE lv_string lv_string_table INTO lv_string_table SEPARATED BY cl_abap_char_utilities=>newline.

    DATA: lv_qty_char   TYPE string,
          lv_price_char TYPE string.

    LOOP AT it_data ASSIGNING <fs_row>.
      CLEAR lv_string.
      lv_qty_char = <fs_row>-quantityreq.
      CONDENSE lv_qty_char.
      lv_price_char = <fs_row>-purchaserequisitionprice.
      CONDENSE lv_price_char.

      CONCATENATE <fs_row>-status <fs_row>-prno <fs_row>-pritem <fs_row>-purchaserequisitiontype <fs_row>-purreqndescription
                  <fs_row>-material <fs_row>-materialgroup lv_qty_char <fs_row>-unit lv_price_char
                  <fs_row>-purreqnitemcurrency <fs_row>-plant <fs_row>-purchasinggroup
                  <fs_row>-purchasingorganization <fs_row>-deliverydate
      INTO lv_string SEPARATED BY cl_abap_char_utilities=>horizontal_tab.

      CONCATENATE lv_string_table lv_string INTO lv_string_table SEPARATED BY cl_abap_char_utilities=>newline.
    ENDLOOP.

    IF lv_string_table IS NOT INITIAL.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = lv_string_table
        IMPORTING
          buffer = lv_xstring.
      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING
          buffer     = lv_xstring
        TABLES
          binary_tab = it_binary.
    ENDIF.

    " --- 3. GỬI MAIL ---
    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        lo_document = cl_document_bcs=>create_document(
                        i_type    = 'HTM'
                        i_subject = iv_subject
                        i_text    = it_contents_txt ).

        IF it_binary[] IS NOT INITIAL.
          lo_document->add_attachment(
              i_attachment_type    = 'XLS'
              i_attachment_subject = iv_subject
              i_att_content_hex    = it_binary ).
        ENDIF.

        lo_send_request->set_document( lo_document ).
        lo_sender_usr = cl_sapuser_bcs=>create( i_user = sy-uname ).
        lo_send_request->set_sender( lo_sender_usr ).

        lo_recipient = cl_cam_address_bcs=>create_internet_address( iv_receiver ).
        lo_send_request->add_recipient( i_recipient = lo_recipient i_express = 'X' ).

        lo_send_request->send_request->set_link_to_outbox( 'X' ).
        lo_send_request->set_send_immediately( 'X' ).

        lo_send_request->send(
          EXPORTING i_with_error_screen = ' ' " Quan trọng: Tắt màn hình lỗi khi chạy ngầm
          RECEIVING result              = lv_sent_to_all ).

        IF lv_sent_to_all = abap_true.
          ev_sent = abap_true.
          ev_message = 'Email sent successfully'.
          COMMIT WORK. " Bắt buộc để trigger gửi mail
        ELSE.
          ev_sent = abap_false.
          ev_message = 'Email send returned False'.
        ENDIF.

      CATCH cx_bcs INTO lo_bcs_exception.
        " Bắt lỗi và trả về biến, KHÔNG dùng WRITE
        ev_sent = abap_false.
        ev_message = lo_bcs_exception->get_text( ).
    ENDTRY.

  ENDMETHOD.

  METHOD send_mail_pr_release.

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

    wa_content-line = |<p><strong>Define Key:</strong> { iv_filename }</p>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h3 style="color:#4CAF50;">{ iv_subject }</h3>|.
    APPEND wa_content TO it_contents_txt.

    IF iv_role = 'S_PRC'.

    wa_content-line = |<h2 style="color: #4CAF50;">Convert PR to PO Application link: </h2>|.
    APPEND wa_content TO it_contents_txt.
      wa_content-line = |<a href="https://s35.gb.ucc.cit.tum.de/sap/bc/ui5_ui5/sap/zsb_u2_pr_rls?sap-client=302">Mass PR release</a>|.
      wa_content-line = |<a href="https://s35.gb.ucc.cit.tum.de/sap/bc/ui5_ui5/sap/zsb_u2_convert?sap-client=302">Mass convert PR to PO</a>|.
      APPEND wa_content TO it_contents_txt.
    ENDIF.

    APPEND '<p>Purchase Requisition summary information:</p>'
        TO it_contents_txt.

    " ===== TABLE HEADER =====
    APPEND '<table style="border-collapse:collapse; width:70%; border:1px solid #ccc;">'
        TO it_contents_txt.
    APPEND '<tr style="background-color:#e8f5e9;">'
        TO it_contents_txt.

    APPEND '<th style="border:1px solid #ccc; padding:6px;">PR No</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">PR Type</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Plant</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Purch. Org</th>'
        TO it_contents_txt.
    APPEND '</tr>' TO it_contents_txt.

    " ===== TABLE DATA =====
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<fs_row>).
      APPEND '<tr>' TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-prno }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-purchaserequisitiontype }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-plant }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-purchasingorganization }</td>|.
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


  METHOD send_mail_pr_reject.
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

    wa_content-line = |<p><strong>Define Key:</strong> { iv_filename }</p>|.
    APPEND wa_content TO it_contents_txt.

    wa_content-line = |<h3 style="color:#4CAF50;">{ iv_subject }</h3>|.
    APPEND wa_content TO it_contents_txt.

    APPEND '<p>Purchase Requisition summary information:</p>'
        TO it_contents_txt.

    " ===== TABLE HEADER =====
    APPEND '<table style="border-collapse:collapse; width:70%; border:1px solid #ccc;">'
        TO it_contents_txt.
    APPEND '<tr style="background-color:#e8f5e9;">'
        TO it_contents_txt.

    APPEND '<th style="border:1px solid #ccc; padding:6px;">PR No</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">PR Type</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Plant</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Purch. Org</th>'
        TO it_contents_txt.
    APPEND '<th style="border:1px solid #ccc; padding:6px;">Reject Reason</th>'
        TO it_contents_txt.
    APPEND '</tr>' TO it_contents_txt.

    " ===== TABLE DATA =====
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<fs_row>).
      APPEND '<tr>' TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-prno }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-purchaserequisitiontype }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-plant }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-purchasingorganization }</td>|.
      APPEND wa_content TO it_contents_txt.

      wa_content-line = |<td style="border:1px solid #ccc; padding:6px;">{ <fs_row>-rejectreason }</td>|.
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
