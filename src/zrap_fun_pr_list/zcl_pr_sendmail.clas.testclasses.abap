*"* use this source file for your ABAP unit test classes
CLASS ltc_pr_sendmail DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO zcl_pr_sendmail.

    METHODS: setup.
    METHODS: test_send_mail_pr      FOR TESTING.
    METHODS: test_send_mail_release FOR TESTING.
    METHODS: test_send_mail_reject  FOR TESTING.
    METHODS: test_send_mail_error   FOR TESTING.

ENDCLASS.

CLASS ltc_pr_sendmail IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT mo_cut.
  ENDMETHOD.

  " ======================================================================
  " TC1: Gửi mail PR Notification (Khớp với báo cáo: tuantvhe180495...)
  " ======================================================================
  METHOD test_send_mail_pr.
    DATA: lt_data    TYPE zcl_pr_sendmail=>gtt_filedata,
          ls_data    TYPE zcl_pr_sendmail=>gts_filedata,
          lv_sent    TYPE abap_bool,
          lv_message TYPE string.

    " Giả lập data để hệ thống tự render bảng HTML và sinh file Excel
    ls_data-prno   = '10000001'.
    ls_data-status = 'PR Released'.
    ls_data-purchaserequisitionprice = '500'.
    ls_data-purreqnitemcurrency = 'USD'.
    APPEND ls_data TO lt_data.

    mo_cut->send_mail_pr(
      EXPORTING
        iv_filename = 'Test_Upload.csv'
        it_data     = lt_data
        iv_receiver = 'tuantvhe180495@fpt.edu.vn' " Email thật từ file test của nhóm
        iv_user     = 'TuanTV'
        iv_subject  = 'PR Notification'
      IMPORTING
        ev_sent     = lv_sent
        ev_message  = lv_message
    ).

    " Hệ thống phải tạo mail thành công và không bị dump
    cl_abap_unit_assert=>assert_equals(
      act = lv_sent
      exp = abap_true
      msg = |Gửi mail thất bại. Lỗi: { lv_message }| ).
  ENDMETHOD.

  " ======================================================================
  " TC2: Gửi mail Release (Test logic sinh URL Convert PR to PO)
  " ======================================================================
  METHOD test_send_mail_release.
    DATA: lt_data    TYPE zcl_pr_sendmail=>gtt_filedata,
          ls_data    TYPE zcl_pr_sendmail=>gts_filedata,
          lv_sent    TYPE abap_bool,
          lv_message TYPE string.

    ls_data-prno   = '10000002'.
    APPEND ls_data TO lt_data.

    mo_cut->send_mail_pr_release(
      EXPORTING
        iv_filename = 'Release_List.csv'
        it_data     = lt_data
        iv_receiver = 'tuantvhe180495@fpt.edu.vn'
        iv_user     = 'TuanTV'
        iv_role     = 'S_PRC'  " Ép role này để hệ thống gen ra link Fiori Convert
      IMPORTING
        ev_sent     = lv_sent
        ev_message  = lv_message
    ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_sent
      exp = abap_true
      msg = 'Gửi mail Release thất bại' ).
  ENDMETHOD.

  " ======================================================================
  " TC3: Gửi mail Reject (Test logic in lý do từ chối)
  " ======================================================================
  METHOD test_send_mail_reject.
    DATA: lt_data    TYPE zcl_pr_sendmail=>gtt_filedata,
          ls_data    TYPE zcl_pr_sendmail=>gts_filedata,
          lv_sent    TYPE abap_bool,
          lv_message TYPE string.

    ls_data-prno         = '10000003'.
    ls_data-rejectreason = 'Vượt quá ngân sách dự kiến'.
    APPEND ls_data TO lt_data.

    mo_cut->send_mail_pr_reject(
      EXPORTING
        iv_filename = 'Reject_List.csv'
        it_data     = lt_data
        iv_receiver = 'tuantvhe180495@fpt.edu.vn'
        iv_user     = 'TuanTV'
      IMPORTING
        ev_sent     = lv_sent
        ev_message  = lv_message
    ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_sent
      exp = abap_true
      msg = 'Gửi mail Reject thất bại' ).
  ENDMETHOD.

  " ======================================================================
  " TC4: Exception Handling (Test luồng lỗi khi email không hợp lệ)
  " ======================================================================
  METHOD test_send_mail_error.
    DATA: lt_data    TYPE zcl_pr_sendmail=>gtt_filedata,
          lv_sent    TYPE abap_bool,
          lv_message TYPE string.

    " Cố tình truyền một địa chỉ email rỗng/sai định dạng
    " để class cl_cam_address_bcs ném ra lỗi cx_bcs
    mo_cut->send_mail_pr(
      EXPORTING
        iv_filename = 'Error.csv'
        it_data     = lt_data
        iv_receiver = ' '
        iv_user     = 'TuanTV'
      IMPORTING
        ev_sent     = lv_sent
        ev_message  = lv_message
    ).

    " Kết quả mong đợi: Hàm bắt được CATCH cx_bcs và trả về False
    cl_abap_unit_assert=>assert_equals(
      act = lv_sent
      exp = abap_false
      msg = 'Hệ thống không bắt được lỗi khi địa chỉ email sai' ).

    cl_abap_unit_assert=>assert_not_initial(
      act = lv_message
      msg = 'Hệ thống không trả về thông báo lỗi chi tiết' ).
  ENDMETHOD.

ENDCLASS.
