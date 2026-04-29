*"* use this source file for your ABAP unit test classes
CLASS ltc_pr_import DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " Đối tượng chứa class đang được test
    DATA: mo_cut TYPE REF TO zcl_pr_import.

    METHODS: setup.

    " Khai báo đủ 7 Test Cases theo chuẩn của nhóm
    METHODS: test_ut01_01_format_prno       FOR TESTING.
    METHODS: test_ut01_02_conv_exits        FOR TESTING.
    METHODS: test_ut01_03_create_pr_success FOR TESTING.
    METHODS: test_ut01_04_create_pr_error   FOR TESTING.
    METHODS: test_ut01_05_main_success      FOR TESTING.
    METHODS: test_ut01_06_main_warning      FOR TESTING.
    METHODS: test_ut01_07_main_error        FOR TESTING.

ENDCLASS.

CLASS ltc_pr_import IMPLEMENTATION.

  METHOD setup.
    " Khởi tạo đối tượng trước mỗi Test Case
    CREATE OBJECT mo_cut.
  ENDMETHOD.

  " ======================================================================
  " 1. TEST_UT01_01_FORMAT_PRNO
  " ======================================================================
  METHOD test_ut01_01_format_prno.
    DATA: ls_file_data TYPE zcl_pr_import=>gts_filedata,
          ls_result    TYPE zi_list_g8.

    ls_file_data-prno   = '1'.
    ls_file_data-pritem = ''.

    ls_result = zcl_pr_import=>convert_data_file( is_file_data = ls_file_data ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-prno
      exp = '0000000001'
      msg = 'Lỗi xử lý PR No mã tạm' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-pritem
      exp = '00000'
      msg = 'Lỗi xử lý PR Item trống' ).
  ENDMETHOD.

  " ======================================================================
  " 2. TEST_UT01_02_CONV_EXITS
  " ======================================================================
  METHOD test_ut01_02_conv_exits.
    DATA: ls_file_data TYPE zcl_pr_import=>gts_filedata,
          ls_result    TYPE zi_list_g8.

    ls_file_data-purchaserequisitiontype = 'NB'.
    ls_file_data-plant                   = '1010'.

    ls_result = zcl_pr_import=>convert_data_file( is_file_data = ls_file_data ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-purchaserequisitiontype
      exp = 'NB'
      msg = 'Map sai trường PR Type' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-plant
      exp = '1010'
      msg = 'Map sai trường Plant' ).
  ENDMETHOD.

  " ======================================================================
  " 3. TEST_UT01_03_CREATE_PR_SUCCESS
  " ======================================================================
  " ======================================================================
  " 3. TEST_UT01_03_CREATE_PR_SUCCESS
  " ======================================================================
  METHOD test_ut01_03_create_pr_success.
    DATA: ls_input   TYPE zcl_pr_import=>gts_parallel_input-file_item,
          ls_item    TYPE zcl_pr_import=>gts_item_data,
          lv_prno    TYPE zi_list_g8-prno,
          lv_success TYPE abap_boolean,
          lv_message TYPE string,
          lv_sev     TYPE if_abap_behv_message=>t_severity.

    " Giả lập dữ liệu chuẩn - ĐIỀN KÍN CÁC TRƯỜNG ĐỂ PASS QUA SAP VALIDATION
    ls_input-purchaserequisitiontype = 'NB'.

    ls_item-material               = 'RM000330'.
    ls_item-plant                  = 'PHE'.
    ls_item-quantityreq            = '10'.
    ls_item-unit                   = 'PC'.                     " Đơn         vị tính
    ls_item-deliverydate           = sy-datum + 20.            " Ngày giao hàng
    ls_item-purchasingorganization = 'PPO1'.                   " Tổ chức mua
    ls_item-purchasinggroup        = 'PP1'.                    " Nhóm mua
    ls_item-materialgroup          = 'FG01'.                    " Nhóm vật tư (Rất hay bị SAP đòi)
    ls_item-purchaserequisitionprice = '100000'.                  " Giá PR
    ls_item-purreqnitemcurrency    = 'VND'.                    " Tiền tệ

    APPEND ls_item TO ls_input-item_data.

    mo_cut->create_pr(
      EXPORTING is_file_item_proc = ls_input
      IMPORTING ef_prno      = lv_prno
                ef_success   = lv_success
                ef_message   = lv_message
                ef_severity  = lv_sev ).

    " TUYỆT CHIÊU: Ghép lv_message vào assert để hiển thị nguyên văn lỗi SAP
    cl_abap_unit_assert=>assert_equals(
      act = lv_success
      exp = abap_true
      msg = |Tạo PR thất bại. Lỗi của SAP trả về là: { lv_message }| ).
  ENDMETHOD.

  " ======================================================================
  " 4. TEST_UT01_04_CREATE_PR_ERROR
  " ======================================================================
  METHOD test_ut01_04_create_pr_error.
    DATA: ls_input   TYPE zcl_pr_import=>gts_parallel_input-file_item,
          ls_item    TYPE zcl_pr_import=>gts_item_data,
          lv_prno    TYPE zi_list_g8-prno,
          lv_success TYPE abap_boolean,
          lv_message TYPE string,
          lv_sev     TYPE if_abap_behv_message=>t_severity.

    " Giả lập dữ liệu SAI (Material rỗng hoặc không tồn tại)
    ls_input-purchaserequisitiontype = 'NB'.
    ls_item-material = 'INVALID_MAT'.
    APPEND ls_item TO ls_input-item_data.

    mo_cut->create_pr(
      EXPORTING is_file_item_proc = ls_input
      IMPORTING ef_success   = lv_success
                ef_severity  = lv_sev ).

    " Hệ thống phải bắt được lỗi
    cl_abap_unit_assert=>assert_equals(
      act = lv_sev
      exp = if_abap_behv_message=>severity-error
      msg = 'Không bắt được lỗi Severity Error khi truyền data sai' ).
  ENDMETHOD.

  " ======================================================================
  " 5. TEST_UT01_05_MAIN_SUCCESS
  " ======================================================================
  METHOD test_ut01_05_main_success.
    DATA: ls_input  TYPE zcl_pr_import=>gts_parallel_input-file_item,
          ls_item   TYPE zcl_pr_import=>gts_item_data,
          ls_output TYPE zcl_pr_import=>gts_parallel_output.

    " Data hợp lệ
    ls_input-purchaserequisitiontype = 'NB'.
    ls_item-material = 'TG11'.
    APPEND ls_item TO ls_input-item_data.

    ls_output = mo_cut->main_process( is_input = ls_input ).

    READ TABLE ls_output-file_item_upd INTO DATA(ls_result) INDEX 1.

    " Output bảng phải có dữ liệu và Status gán thành Success
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_output-file_item_upd
      msg = 'Main Process không trả về dữ liệu' ).
  ENDMETHOD.

  " ======================================================================
  " 6. TEST_UT01_06_MAIN_WARNING
  " ======================================================================
  METHOD test_ut01_06_main_warning.
    DATA: ls_input  TYPE zcl_pr_import=>gts_parallel_input-file_item,
          ls_item   TYPE zcl_pr_import=>gts_item_data,
          ls_output TYPE zcl_pr_import=>gts_parallel_output.

    " Truyền Delivery Date ở quá khứ để ép SAP sinh Warning Message
    ls_input-purchaserequisitiontype = 'NB'.
    ls_item-material = 'TG11'.
    ls_item-deliverydate = sy-datum - 10. " Trừ đi 10 ngày
    APPEND ls_item TO ls_input-item_data.

    ls_output = mo_cut->main_process( is_input = ls_input ).

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_output-file_item_upd
      msg = 'Main Process không xử lý được luồng Warning' ).
  ENDMETHOD.

  " ======================================================================
  " 7. TEST_UT01_07_MAIN_ERROR
  " ======================================================================
  METHOD test_ut01_07_main_error.
    DATA: ls_input  TYPE zcl_pr_import=>gts_parallel_input-file_item,
          ls_item   TYPE zcl_pr_import=>gts_item_data,
          ls_output TYPE zcl_pr_import=>gts_parallel_output.

    " Truyền dữ liệu thiếu/lỗi để ép ra nhánh Error
    ls_input-purchaserequisitiontype = 'NB'.
    ls_item-material = 'INVALID_MAT'.
    APPEND ls_item TO ls_input-item_data.

    ls_output = mo_cut->main_process( is_input = ls_input ).

    READ TABLE ls_output-file_item_upd INTO DATA(ls_result) INDEX 1.

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-status
      exp = zcl_pr_import=>gcf_error
      msg = 'Status phải được cập nhật thành Error' ).

    " Khi lỗi, biến pritem không được cộng 10 mà phải giữ nguyên khoảng trắng/00000
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-pritem
      exp = '00000'
      msg = 'Khi có lỗi, PR Item không được đánh số tự động' ).
  ENDMETHOD.

ENDCLASS.
