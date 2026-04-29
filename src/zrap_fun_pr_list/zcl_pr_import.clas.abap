CLASS  zcl_pr_import DEFINITION
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
      gcf_normal              TYPE zi_list_g8-status VALUE 'Success',
      gcf_warning             TYPE zi_list_g8-status VALUE 'Warning',
      gcf_error               TYPE zi_list_g8-status VALUE 'Error'.

    TYPES: BEGIN OF gts_filedata,
             prno                        TYPE zi_list_g8-PrNo,
             pritem                      TYPE zi_list_g8-PrItem,
             purchaserequisitiontype     TYPE zi_list_g8-PurchaseRequisitionType,
             purreqndescription          TYPE zi_list_g8-PurReqnDescription,
             purchaserequisitionitemtext TYPE zi_list_g8-PurchaseRequisitionItemText,
             material                    TYPE zi_list_g8-Material,
             materialgroup               TYPE zi_list_g8-MaterialGroup,
             quantityreq                 TYPE zi_list_g8-QuantityReq,
             unit                        TYPE zi_list_g8-Unit,
             purchaserequisitionprice    TYPE zi_list_g8-PurchaseRequisitionPrice,
             PurReqnItemCurrency         TYPE zi_list_g8-PurReqnItemCurrency,
             plant                       TYPE zi_list_g8-Plant,
             purchasinggroup             TYPE zi_list_g8-PurchasingGroup,
             purchasingorganization      TYPE zi_list_g8-PurchasingOrganization,
             accountassignmentcategory   TYPE zi_list_g8-AccountAssignmentCategory,
             deliverydate                TYPE zi_list_g8-DeliveryDate,
           END OF gts_filedata.

    TYPES gtt_filedata TYPE STANDARD TABLE OF gts_filedata WITH EMPTY KEY.
    TYPES: BEGIN OF gts_item_data,
             recnumber                   TYPE zi_list_g8-RecNumber,
             itemuuid                    TYPE zi_list_g8-ItemUuid,

             prno                        TYPE zi_list_g8-PrNo,
             pritem                      TYPE zi_list_g8-PrItem,
             purchaserequisitionitemtext TYPE zi_list_g8-PurchaseRequisitionItemText,
             material                    TYPE zi_list_g8-Material,
             materialgroup               TYPE zi_list_g8-MaterialGroup,

             QuantityReq                 TYPE zi_list_g8-QuantityReq,
             unit                        TYPE zi_list_g8-Unit,

             purchaserequisitionprice    TYPE zi_list_g8-PurchaseRequisitionPrice,
             PurReqnItemCurrency         TYPE zi_list_g8-PurReqnItemCurrency,

             plant                       TYPE zi_list_g8-Plant,
             purchasinggroup             TYPE zi_list_g8-PurchasingGroup,
             purchasingorganization      TYPE zi_list_g8-PurchasingOrganization,

             accountassignmentcategory   TYPE zi_list_g8-AccountAssignmentCategory,
             deliverydate                TYPE zi_list_g8-DeliveryDate,
           END OF gts_item_data.

    TYPES gtt_item_data TYPE STANDARD TABLE OF gts_item_data WITH EMPTY KEY.

    TYPES: BEGIN OF gts_group_data,
             attachmentuuid          TYPE zi_list_g8-AttachmentUuid,
             pr_no                   TYPE zi_list_g8-PrNo,

             purchaserequisitiontype TYPE zi_list_g8-PurchaseRequisitionType,
             purreqndescription      TYPE zi_list_g8-PurReqnDescription,

             " Item list
             item_data               TYPE gtt_item_data,
           END OF gts_group_data.
    TYPES gtt_group_data TYPE STANDARD TABLE OF gts_group_data WITH EMPTY KEY.

    TYPES: BEGIN OF gts_job_log_message,
             severity TYPE if_bali_item_setter=>ty_severity,
             message  TYPE cl_bali_free_text_setter=>ty_text.
    TYPES: END OF gts_job_log_message.
    TYPES: gtt_job_log_message TYPE TABLE OF gts_job_log_message WITH EMPTY KEY.

    TYPES: BEGIN OF gts_parallel_input,
             file_item TYPE gts_group_data.
    TYPES: END OF gts_parallel_input.

    TYPES: gtt_list_g8 TYPE TABLE OF zi_list_g8 WITH DEFAULT KEY,
           gtt_message TYPE TABLE OF string.

    TYPES: BEGIN OF gts_parallel_output,
             file_item_upd TYPE gtt_list_g8.
    TYPES: END OF gts_parallel_output.

    CLASS-METHODS convert_data_file
      IMPORTING is_file_data            TYPE zcl_pr_import=>gts_filedata
      RETURNING VALUE(rs_import_detail) TYPE zi_list_g8.

    METHODS execute_parallel
      IMPORTING is_input        TYPE gts_parallel_input-file_item
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS do REDEFINITION.

    METHODS main_process
      IMPORTING is_input        TYPE gts_parallel_input-file_item
      RETURNING VALUE(rs_ouput) TYPE gts_parallel_output.

    METHODS create_pr
      IMPORTING is_file_item_proc TYPE gts_parallel_input-file_item
      EXPORTING ef_prno           TYPE zi_list_g8-prno
                ef_success        TYPE abap_boolean
                ef_message        TYPE string
                ef_severity       TYPE if_abap_behv_message=>t_severity.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_pr_import IMPLEMENTATION.

  METHOD convert_data_file.

    "--------------------------------------------------
    " Basic mapping
    "--------------------------------------------------
    rs_import_detail-prno            = is_file_data-prno.
    rs_import_detail-pritem          = is_file_data-pritem.
    rs_import_detail-material        = is_file_data-material.
    rs_import_detail-quantityreq     = is_file_data-quantityreq.
    rs_import_detail-unit            = is_file_data-unit.
    rs_import_detail-deliverydate    = is_file_data-deliverydate.
    rs_import_detail-plant           = is_file_data-plant.
    rs_import_detail-purchasinggroup = is_file_data-purchasinggroup.

    rs_import_detail-purchaserequisitiontype     = is_file_data-purchaserequisitiontype.
    rs_import_detail-purreqndescription          = is_file_data-purreqndescription.
    rs_import_detail-purchaserequisitionitemtext = is_file_data-purchaserequisitionitemtext.
    rs_import_detail-materialgroup               = is_file_data-materialgroup.
    rs_import_detail-purchaserequisitionprice    = is_file_data-purchaserequisitionprice.
    rs_import_detail-PurReqnItemCurrency         = is_file_data-PurReqnItemCurrency.
    rs_import_detail-purchasingorganization      = is_file_data-purchasingorganization.
    rs_import_detail-accountassignmentcategory   = is_file_data-accountassignmentcategory.

    "--------------------------------------------------
    " Normalize PR number & item
    "--------------------------------------------------
    CONDENSE:
      rs_import_detail-prno   NO-GAPS,
      rs_import_detail-pritem NO-GAPS.

    rs_import_detail-prno   = |{ rs_import_detail-prno   ALPHA = IN }|.
    rs_import_detail-pritem = |{ rs_import_detail-pritem ALPHA = IN }|.

    "--------------------------------------------------
    " Conversion exits
    "--------------------------------------------------
    rs_import_detail-material =
      zcl_com_conv=>conv_matn1_in(
        if_input = is_file_data-material ).

    rs_import_detail-purchaserequisitionprice =
    zcl_com_conv=>amount_in(
      if_amountout = is_file_data-purchaserequisitionprice
      if_currency  = is_file_data-PurReqnItemCurrency ).

    rs_import_detail-unit =
      zcl_com_conv=>conv_cunit_in(
        if_input = is_file_data-unit ).

  ENDMETHOD.


  METHOD execute_parallel.
    DATA: ldt_xinput  TYPE cl_abap_parallel=>t_in_tab,
          ldt_xoutput TYPE cl_abap_parallel=>t_out_tab,
          lds_xinput  TYPE LINE OF cl_abap_parallel=>t_in_tab,
          lds_xoutput TYPE LINE OF cl_abap_parallel=>t_out_tab.

    DATA: lds_input  TYPE gts_parallel_input-file_item,
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
    DATA: lds_input  TYPE gts_parallel_input-file_item,
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
      lds_file_item TYPE gts_group_data.

    DATA:
      ldt_file_item_result TYPE gtt_list_g8,
      ldt_file_item_proc   TYPE gtt_list_g8.

    DATA:
      ldf_message     TYPE string,
      ldf_criticality TYPE i.

    lds_file_item = is_input.

    CHECK lds_file_item IS NOT INITIAL.
    "ヘッダーユニットの条件
    CLEAR:
      ldf_message,
      ldf_criticality.

    DATA:
      ldf_existed       TYPE abap_boolean,
      ldf_create_fail   TYPE abap_boolean,
      ldf_boif_success  TYPE abap_boolean,
      ldf_status        TYPE zi_list_g8-status,
      ldf_prno          TYPE zi_list_g8-prno,
      ldf_boif_severity TYPE  if_abap_behv_message=>t_severity.
    DATA:
      lds_file_item_proc TYPE zi_list_g8.

    CHECK lds_file_item IS NOT INITIAL.


    "スケール更新データなし→BOインターフェースで更新
    me->create_pr(
      EXPORTING
        is_file_item_proc = lds_file_item
      IMPORTING
        ef_prno           = ldf_prno
        ef_success        = ldf_boif_success
        ef_message        = ldf_message
        ef_severity       = ldf_boif_severity
    ).

    IF ldf_boif_success <> abap_true
    OR ldf_boif_severity = if_abap_behv_message=>severity-error.
      ldf_status      = gcf_error.
      ldf_criticality = gcf_criticality_error.
    ELSEIF ldf_boif_severity = if_abap_behv_message=>severity-warning.
      ldf_status      = gcf_warning.
      ldf_criticality = gcf_criticality_warning.
    ELSE.
      ldf_status      = gcf_normal.
      ldf_criticality = gcf_criticality_success.
    ENDIF.

    DATA: lv_item_increment TYPE n LENGTH 5.
    LOOP AT lds_file_item-item_data INTO DATA(lds_item).
      MOVE-CORRESPONDING lds_file_item TO lds_file_item_proc.
      MOVE-CORRESPONDING lds_item TO lds_file_item_proc.
      lds_file_item_proc-status               = ldf_status.
      IF ldf_status <> gcf_error.
        lv_item_increment = lv_item_increment + 10.
        lds_file_item_proc-pritem = lv_item_increment.
        lds_file_item_proc-prno = ldf_prno.
      ENDIF.
      lds_file_item_proc-messagestandardtable = ldf_message.
      lds_file_item_proc-criticality          = ldf_criticality.
      APPEND lds_file_item_proc TO ldt_file_item_proc.
    ENDLOOP.

    "処理済み行を結果に追加
    APPEND LINES OF ldt_file_item_proc TO ldt_file_item_result.
    CLEAR: ldt_file_item_proc.

    "出力の返却
    rs_ouput = VALUE #(
        file_item_upd = ldt_file_item_result
    ).

  ENDMETHOD.

  METHOD create_pr.

    " CID生成
    TRY.
        DATA(ldf_cid) = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.

    " 内部テーブル定義
    DATA:
      ldt_messages  TYPE TABLE OF string.

* 製造指図作成
    MODIFY ENTITIES OF i_purchaserequisitiontp
      ENTITY PurchaseRequisition
        CREATE
        FIELDS (
          PurchaseRequisitionType
          PurReqnDescription
        )
        WITH VALUE #(
          (
            %cid                      = ldf_cid
            PurchaseRequisitionType   = is_file_item_proc-purchaserequisitiontype
            PurReqnDescription        = is_file_item_proc-purreqndescription
          )
        )

      CREATE BY \_purchaserequisitionitem
        FIELDS (
          PurchaseRequisitionItemText
          Material
          MaterialGroup
          RequestedQuantity
          BaseUnit
          PurchaseRequisitionPrice
          PurReqnItemCurrency
          Plant
          PurchasingGroup
          PurchasingOrganization
          AccountAssignmentCategory
          DeliveryDate
          RequisitionerName
        )
        AUTO FILL CID WITH VALUE #(
          (
            %cid_ref = ldf_cid
            %target  = VALUE #(
              FOR ls_item IN is_file_item_proc-item_data
              (
                %data-PurchaseRequisitionItemText = ls_item-purchaserequisitionitemtext
                %data-Material                    = ls_item-material
                %data-MaterialGroup               = ls_item-materialgroup
                %data-RequestedQuantity           = ls_item-quantityreq
                %data-BaseUnit                    = ls_item-unit
                %data-PurchaseRequisitionPrice    = ls_item-purchaserequisitionprice
                %data-PurReqnItemCurrency         = ls_item-purreqnitemcurrency
                %data-Plant                       = ls_item-plant
                %data-PurchasingGroup             = ls_item-purchasinggroup
                %data-PurchasingOrganization      = ls_item-purchasingorganization
                %data-AccountAssignmentCategory   = ls_item-accountassignmentcategory
                %data-DeliveryDate                = ls_item-deliverydate
                %data-RequisitionerName           = sy-uname
              )
            )
          )
        )

      FAILED   DATA(failed_create)
      REPORTED DATA(reported_create)
          MAPPED DATA(mapped).

    " 作成結果判定
    IF failed_create IS INITIAL.
      COMMIT ENTITIES BEGIN
        RESPONSE OF I_PurchaseRequisitionTP
          FAILED   DATA(lds_commit_failed_crt)
          REPORTED DATA(lds_commit_reported_crt).

      " オペレーション更新／作成
      IF lds_commit_failed_crt IS INITIAL.
        ef_success   = abap_true.
        CONVERT KEY OF I_PurchaseRequisitionTP
          FROM TEMPORARY VALUE #( %pid = mapped-purchaserequisition[ 1 ]-%pid
                                  %tmp = mapped-purchaserequisition[ 1 ]-%key )
          TO FINAL(lds_sodoc).
        ef_prno = lds_sodoc-PurchaseRequisition.
      ENDIF.

      "コミットメッセージの取得
      LOOP AT lds_commit_reported_crt-purchaserequisition INTO DATA(lds_com_pr).
        APPEND lds_com_pr-%msg->if_message~get_longtext( ) TO ldt_messages.
        ef_severity = lds_com_pr-%msg->m_severity.
      ENDLOOP.

      LOOP AT lds_commit_reported_crt-purchaserequisitionitem INTO DATA(lds_com_prit).
        APPEND lds_com_prit-%msg->if_message~get_longtext( ) TO ldt_messages.
        ef_severity = lds_com_prit-%msg->m_severity.
      ENDLOOP.

      COMMIT ENTITIES END.

    ELSE.
      " 作成エラー処理
      ef_severity = if_abap_behv_message=>severity-error.
      LOOP AT reported_create-purchaserequisition INTO DATA(lds_crt_pr).
        APPEND lds_crt_pr-%msg->if_message~get_longtext( ) TO ldt_messages.
      ENDLOOP.

      LOOP AT reported_create-purchaserequisitionitem INTO DATA(lds_crt_pritem).
        APPEND lds_crt_pritem-%msg->if_message~get_longtext( ) TO ldt_messages.
      ENDLOOP.
      IF ldt_messages IS INITIAL.
        IF line_exists( failed_create-purchaserequisition[ 1 ] ).
          APPEND failed_create-purchaserequisition[ 1 ]-%fail-cause TO ldt_messages.
        ELSEIF line_exists( failed_create-purchaserequisitionitem[ 1 ] ).
          APPEND failed_create-purchaserequisitionitem[ 1 ]-%fail-cause TO ldt_messages.
        ENDIF.
      ENDIF.
      ROLLBACK ENTITIES.
    ENDIF.

    " メッセージ整理
    SORT ldt_messages.
    DELETE ADJACENT DUPLICATES FROM ldt_messages COMPARING ALL FIELDS.
    ef_message = xco_cp=>strings( ldt_messages )->join( | / | )->value.

  ENDMETHOD.

ENDCLASS.

