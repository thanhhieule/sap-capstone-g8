 CLASS zcl_create_po DEFINITION
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
       gcf_normal              TYPE zi_rldhead_g8-status VALUE 'Success',
       gcf_error               TYPE zi_rldhead_g8-status VALUE 'Error'.

     TYPES: BEGIN OF gts_job_log_message,
              severity TYPE if_bali_item_setter=>ty_severity,
              message  TYPE cl_bali_free_text_setter=>ty_text.
     TYPES: END OF gts_job_log_message.
     TYPES: gtt_job_log_message TYPE TABLE OF gts_job_log_message WITH EMPTY KEY.

     TYPES: BEGIN OF gts_item_data,
              pritem                      TYPE zi_rlditem_g8-PrItem,
              purchaserequisitionitemtext TYPE zi_rlditem_g8-PurchaseRequisitionItemText,
              material                    TYPE zi_rlditem_g8-Material,
              materialgroup               TYPE zi_rlditem_g8-MaterialGroup,

              QuantityReq                 TYPE zi_rlditem_g8-QuantityReq,
              unit                        TYPE zi_rlditem_g8-Unit,

              netpr                       TYPE zi_rlditem_g8-Netpr,
              PurReqnItemCurrency         TYPE zi_rlditem_g8-PurReqnItemCurrency,

              plant                       TYPE zi_rlditem_g8-Plant,
              purchasinggroup             TYPE zi_rlditem_g8-PurchasingGroup,
              purchasingorganization      TYPE zi_rlditem_g8-PurchasingOrganization,

              accountassignmentcategory   TYPE zi_rlditem_g8-AccountAssignmentCategory,
              deliverydate                TYPE zi_rlditem_g8-DeliveryDate,
            END OF gts_item_data.

     TYPES gtt_item_data TYPE STANDARD TABLE OF gts_item_data WITH EMPTY KEY.

     TYPES: BEGIN OF gts_group_data,
              prno                    TYPE zi_rldhead_g8-PrNo,

              lifnr                   TYPE zi_rldhead_g8-Lifnr,
              purchaserequisitiontype TYPE zi_rldhead_g8-PurchaseRequisitionType,

              " Item list
              item_data               TYPE gtt_item_data,
            END OF gts_group_data.
     TYPES gtt_group_data TYPE STANDARD TABLE OF gts_group_data WITH EMPTY KEY.

     TYPES: gtt_release_g8 TYPE TABLE OF zi_rldhead_g8 WITH DEFAULT KEY,
            gtt_message    TYPE TABLE OF string.

     TYPES: BEGIN OF gts_parallel_input,
              pr_data TYPE gts_group_data.
     TYPES: END OF gts_parallel_input.

     TYPES: BEGIN OF gts_parallel_output,
              PR_number   TYPE zi_rldhead_g8-PrNo,
              PO_number   TYPE zi_rldhead_g8-PoNo,
              Criticality TYPE zi_rldhead_g8-Criticality,
              message     TYPE zi_rldhead_g8-MessageStandardtable,
            END OF gts_parallel_output.

     METHODS execute_parallel
       IMPORTING is_input        TYPE gts_parallel_input-pr_data
       RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

     METHODS do REDEFINITION.

     METHODS main_process
       IMPORTING is_input        TYPE gts_group_data
       RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

     METHODS create_po
       IMPORTING is_input    TYPE gts_parallel_input-pr_data
       EXPORTING ef_pono     TYPE zi_rldhead_g8-PoNo
                 ef_success  TYPE abap_boolean
                 ef_message  TYPE string
                 ef_severity TYPE if_abap_behv_message=>t_severity.

   PROTECTED SECTION.
   PRIVATE SECTION.
 ENDCLASS.



 CLASS zcl_create_po IMPLEMENTATION.


   METHOD execute_parallel.
     DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
           ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
           lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
           lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

     DATA: lds_input  TYPE gts_parallel_input-pr_data,
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
     DATA: lds_input  TYPE gts_parallel_input-pr_data,
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
       ldf_pono        TYPE zi_rldhead_g8-PoNo,
       ldf_message     TYPE string,
       ldf_criticality TYPE i,
       lds_output      TYPE gts_parallel_output.

     CHECK is_input IS NOT INITIAL.
     "ヘッダーユニットの条件
     CLEAR:
       ldf_message,
       ldf_criticality.

     DATA:
       ldf_release_fail  TYPE abap_boolean,
       ldf_boif_success  TYPE abap_boolean,
       ldf_status        TYPE zi_rldhead_g8-status,
       ldf_boif_severity TYPE  if_abap_behv_message=>t_severity.


     "スケール更新データなし→BOインターフェースで更新
     me->create_po(
       EXPORTING
         is_input          = is_input
       IMPORTING
         ef_pono           = ldf_pono
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
        PR_number   = is_input-prno
        PO_number   = ldf_pono
        criticality = ldf_criticality
        message     = ldf_message
     ).

   ENDMETHOD.



   METHOD create_po.
     DATA:
       ls_poheader  TYPE bapimepoheader,
       ls_poheaderx TYPE bapimepoheaderx,
       lt_poitems   TYPE TABLE OF bapimepoitem,
       lt_poitemsx  TYPE TABLE OF bapimepoitemx,
       lt_schedule  TYPE TABLE OF bapimeposchedule,
       lt_schedulex TYPE TABLE OF bapimeposchedulx,
       lt_return    TYPE TABLE OF bapiret2,
       ls_return    TYPE bapiret2,
       lv_po_item   TYPE ebelp VALUE '00010',
       lv_po_number TYPE ebeln,
       lv_bapi_suc  TYPE abap_boolean.
     DATA:
       ldt_messages TYPE TABLE OF string.

     " 1. Lấy thông tin PR đầu tiên để tạo PO Header
     IF is_input IS INITIAL.
       ef_success  = abap_false.
       ef_message  = 'Input data is empty.'.
       ef_severity = if_abap_behv_message=>severity-error.
       RETURN.
     ENDIF.


     READ TABLE is_input-item_data INTO DATA(ls_first_pr) INDEX 1.

     ls_poheader-doc_type   = 'NB'.
     ls_poheader-comp_code  = 'PH06'.
     ls_poheader-creat_date = sy-datum.
     ls_poheader-created_by = sy-uname.
     ls_poheader-vendor     = is_input-lifnr.
     ls_poheader-purch_org  = ls_first_pr-purchasingorganization.
     ls_poheader-pur_group  = ls_first_pr-purchasinggroup.
     ls_poheader-currency   = ls_first_pr-purreqnitemcurrency.

     ls_poheaderx-doc_type   = 'X'.
     ls_poheaderx-comp_code  = 'X'.
     ls_poheaderx-creat_date = 'X'.
     ls_poheaderx-created_by = 'X'.
     ls_poheaderx-vendor     = 'X'.
     ls_poheaderx-purch_org  = 'X'.
     ls_poheaderx-pur_group  = 'X'.
     ls_poheaderx-currency   = 'X'.

     LOOP AT is_input-item_data INTO DATA(ls_pr).

     DATA(lv_updated_price) = zcl_com_conv=>amount_out(
             if_amountin  = ls_pr-netpr
             if_currency  = ls_pr-purreqnitemcurrency ).


       APPEND VALUE bapimepoitem(
         po_item    = lv_po_item
         material   = ls_pr-material
         matl_group = ls_pr-materialgroup
         plant      = ls_pr-plant
         quantity   = ls_pr-quantityreq
         po_unit    = ls_pr-unit
         preq_no    = is_input-prno
         preq_item  = ls_pr-pritem
         net_price  = lv_updated_price
       ) TO lt_poitems.

       APPEND VALUE bapimepoitemx(
         po_item    = lv_po_item
         po_itemx   = 'X'
         material   = 'X'
         matl_group = 'X'
         plant      = 'X'
         stge_loc   = 'X'
         quantity   = 'X'
         po_unit    = 'X'
         preq_no    = 'X'
         preq_item  = 'X'
         net_price  = 'X'
       ) TO lt_poitemsx.

       APPEND VALUE bapimeposchedule(
         po_item       = lv_po_item
         sched_line    = 1
         delivery_date = ls_pr-deliverydate
         quantity      = ls_pr-quantityreq
       ) TO lt_schedule.

       APPEND VALUE bapimeposchedulx(
         po_item       = lv_po_item
         sched_line    = 1
         delivery_date = 'X'
         quantity      = 'X'
       ) TO lt_schedulex.
       lv_po_item += 10.
     ENDLOOP.

     ef_success = abap_true.
     ef_severity = if_abap_behv_message=>severity-success.

     CALL FUNCTION 'BAPI_PO_CREATE1'
       EXPORTING
         poheader         = ls_poheader
         poheaderx        = ls_poheaderx
       IMPORTING
         exppurchaseorder = lv_po_number
       TABLES
         poitem           = lt_poitems
         poitemx          = lt_poitemsx
         poschedule       = lt_schedule
         poschedulex      = lt_schedulex
         return           = lt_return.
     DATA(lv_msg_text) = ''.

     LOOP AT lt_return INTO ls_return.

       READ TABLE ldt_messages
            WITH TABLE KEY table_line = ls_return-message
            TRANSPORTING NO FIELDS.

       IF sy-subrc <> 0.
         APPEND ls_return-message TO ldt_messages.
       ENDIF.

       IF ls_return-type = 'E' OR ls_return-type = 'A'.
         ef_success  = abap_false.
         ef_severity = if_abap_behv_message=>severity-error.
         lv_bapi_suc = abap_false.
       ENDIF.

     ENDLOOP.



     " 成功時にコミット (Commit nếu thành công cho Code này)
     IF ef_success = abap_true OR lv_bapi_suc = abap_true.
       CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
         EXPORTING
           wait = 'X'.
       ef_pono = lv_po_number.
     ENDIF.

     " ---------------------------------------------------------
     " 4. メッセージ整理 (Format lại message đầu ra)
     " ---------------------------------------------------------
     IF ldt_messages IS INITIAL.
       APPEND 'Purchase order created successfully' TO ldt_messages.
     ENDIF.

     SORT ldt_messages.
     DELETE ADJACENT DUPLICATES FROM ldt_messages COMPARING ALL FIELDS.
     ef_message = xco_cp=>strings( ldt_messages )->join( | / | )->value.
   ENDMETHOD.

 ENDCLASS.
