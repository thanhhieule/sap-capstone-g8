CLASS lsc_zi_att_g8 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zi_att_g8 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS vldData FOR DETERMINE ON MODIFY
      IMPORTING keys FOR item~vldData.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Item RESULT result.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD vldData.

    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
      ENTITY Item
      FIELDS ( QuantityReq
               Unit
               PurReqnItemCurrency
               DeliveryDate
               PurchaseRequisitionPrice )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    CHECK lt_item IS NOT INITIAL.

    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
      ENTITY Item BY \_Header
      FROM CORRESPONDING #( keys )
      LINK DATA(lt_header_link).

    LOOP AT lt_item INTO DATA(ls_item).
      APPEND VALUE #( %tky        = ls_item-%tky
                  %state_area = 'VALIDATE_DATA' )
                TO reported-item.

*--------------------------------------------------
* Quantity > 0
*--------------------------------------------------
      IF ls_item-QuantityReq <= 0.

        APPEND VALUE #( %tky        = ls_item-%tky
                %state_area = 'VALIDATE_DATA' )
              TO reported-item.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %element-QuantityReq = if_abap_behv=>mk-on
          %state_area            = 'VALIDATE_DATA'
          %path                  = VALUE #( header-%tky = lt_header_link[ KEY id  source-%tky = ls_item-%tky ]-target-%tky )
          %msg = new_message(
                    id       = 'ZRAP_COM_99'
                    number   = '001'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-item.

      ENDIF.


*--------------------------------------------------
* Unit tồn tại trong T006
*--------------------------------------------------
      SELECT SINGLE @abap_true
        FROM t006
        WHERE msehi = @ls_item-Unit
        INTO @DATA(lv_unit).

      IF sy-subrc <> 0.

        APPEND VALUE #( %tky        = ls_item-%tky
                %state_area = 'VALIDATE_DATA' )
              TO reported-item.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %element-Unit = if_abap_behv=>mk-on
          %state_area            = 'VALIDATE_DATA'
          %path                  = VALUE #( header-%tky = lt_header_link[ KEY id  source-%tky = ls_item-%tky ]-target-%tky )
          %msg = new_message(
                    id       = 'ZRAP_COM_99'
                    number   = '002'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-item.

      ENDIF.


*--------------------------------------------------
* Currency tồn tại trong TCURC
*--------------------------------------------------
      SELECT SINGLE @abap_true
        FROM tcurc
        WHERE waers = @ls_item-PurReqnItemCurrency
        INTO @DATA(lv_curr).

      IF sy-subrc <> 0.

        APPEND VALUE #( %tky        = ls_item-%tky
                %state_area = 'VALIDATE_DATA' )
              TO reported-item.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %element-PurReqnItemCurrency = if_abap_behv=>mk-on
          %state_area            = 'VALIDATE_DATA'
          %path                  = VALUE #( header-%tky = lt_header_link[ KEY id  source-%tky = ls_item-%tky ]-target-%tky )
          %msg = new_message(
                    id       = 'ZRAP_COM_99'
                    number   = '003'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-item.

      ENDIF.


*--------------------------------------------------
* Date >= Today
*--------------------------------------------------
      IF ls_item-DeliveryDate IS NOT INITIAL
         AND ls_item-DeliveryDate < sy-datum.

        APPEND VALUE #( %tky        = ls_item-%tky
                %state_area = 'VALIDATE_DATA' )
              TO reported-item.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %element-DeliveryDate = if_abap_behv=>mk-on
          %state_area            = 'VALIDATE_DATA'
          %path                  = VALUE #( header-%tky = lt_header_link[ KEY id  source-%tky = ls_item-%tky ]-target-%tky )
          %msg = new_message(
                    id       = 'ZRAP_COM_99'
                    number   = '004'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-item.

      ENDIF.

*--------------------------------------------------
* Price validate
*--------------------------------------------------
      IF ls_item-PurchaseRequisitionPrice IS INITIAL
      OR ls_item-PurchaseRequisitionPrice <= 0.

        APPEND VALUE #( %tky        = ls_item-%tky
                %state_area = 'VALIDATE_DATA' )
              TO reported-item.

        APPEND VALUE #(
          %tky = ls_item-%tky
          %element-PurchaseRequisitionPrice = if_abap_behv=>mk-on
          %state_area            = 'VALIDATE_DATA'
          %path                  = VALUE #( header-%tky = lt_header_link[ KEY id  source-%tky = ls_item-%tky ]-target-%tky )
          %msg = new_message(
                    id       = 'ZRAP_COM_99'
                    number   = '005'
                    severity = if_abap_behv_message=>severity-error )
        ) TO reported-item.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
  ENTITY item
     ALL FIELDS
    WITH CORRESPONDING #( keys )
  RESULT DATA(ldt_file).

    result = VALUE #(
      FOR lds_file IN ldt_file
        ( %tky = lds_file-%tky

          %features-%field-PrNo = if_abap_behv=>fc-f-read_only
          %features-%field-PrItem = if_abap_behv=>fc-f-read_only
          %features-%field-MessageStandardtable = if_abap_behv=>fc-f-read_only
          %features-%field-Status = if_abap_behv=>fc-f-read_only
    ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    DATA:
      "カウント用変数
      gdf_count_total   TYPE i VALUE 0,
      gdf_count_success TYPE i VALUE 0,
      gdf_count_warning TYPE i VALUE 0,
      gdf_count_error   TYPE i VALUE 0.

    "クリティカリティ
    CONSTANTS:
      gcf_criticality_error   TYPE i VALUE 1,
      gcf_criticality_warning TYPE i VALUE 2,
      gcf_criticality_success TYPE i VALUE 3.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR header RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR header RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR header RESULT result.

    "生データのCSVファイルを取得し、インポート用の明細ファイルに変換する
    METHODS getdatafile FOR DETERMINE ON MODIFY
      IMPORTING keys FOR header~getdatafile.

    "ビジネスオブジェクトを実行：製造指図作業の追加・更新
    METHODS updatebusinessobject FOR DETERMINE ON SAVE
      IMPORTING keys FOR header~updatebusinessobject.

    "削除前チェック
    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE header.

    "保存前の検証
    METHODS vldbeforesave FOR VALIDATE ON SAVE
      IMPORTING keys FOR header~vldbeforesave.

    METHODS testrun FOR MODIFY
      IMPORTING keys FOR ACTION header~testrun RESULT result.
    METHODS validatesavedata1 FOR VALIDATE ON SAVE
      IMPORTING keys FOR header~validatesavedata1.

    METHODS downloaderror
      IMPORTING it_error_data TYPE zcl_pr_sendmail=>gtt_filedata
                if_uuid       TYPE zi_att_g8-AttachmentUUID.

ENDCLASS.

CLASS lhc_header IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
  ENTITY header
     ALL FIELDS
    WITH CORRESPONDING #( keys )
  RESULT DATA(ldt_file).

    result = VALUE #(
      FOR lds_file IN ldt_file
        ( %tky = lds_file-%tky

          %features-%action-edit =  if_abap_behv=>fc-o-disabled

        )
    ).
  ENDMETHOD.


  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD getdatafile.

    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc = 0 AND ls_key-%is_draft = if_abap_behv=>mk-off.
      RETURN.
    ENDIF.

    DATA: ldt_filedata    TYPE TABLE OF zcl_pr_import=>gts_filedata,
          ldt_item_create TYPE TABLE FOR CREATE zi_att_g8\_item,
          lds_item_create LIKE LINE OF ldt_item_create,
          lds_reported    LIKE LINE OF reported-header VALUE IS INITIAL.

    "------------------------------------------------------------------
    " 1. Header 読み込み
    "------------------------------------------------------------------
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(ldt_file_header)
        FAILED DATA(lds_header_failed).

    CHECK ldt_file_header IS NOT INITIAL.
    DATA(lds_files) = ldt_file_header[ 1 ].

    "------------------------------------------------------------------
    " 2. 添付ファイル解析（CSV）
    "------------------------------------------------------------------
    IF lds_files-attachment IS NOT INITIAL
       AND lds_files-mimetype IS NOT INITIAL.

      TRY.
          zcl_com_file_upload=>get_from_upload_data(
            EXPORTING
              if_mimetype  = lds_files-mimetype
              if_data      = lds_files-attachment
              iv_start_row = 2
            CHANGING
              ct_rows      = ldt_filedata
          ).
        CATCH cx_root INTO DATA(ldo_root).
          DATA(ldf_etext) = ldo_root->get_longtext( ) .
          MOVE-CORRESPONDING lds_files TO lds_reported.
          lds_reported-%msg = new_message( severity = ms-error
                                                  id       = 'ZRAP_COM_00'
                                                  number   = '000'
                                                  v1       = ldf_etext
                                                  ).
          APPEND lds_reported TO reported-header.
          RETURN.
      ENDTRY.
    ENDIF.

    "------------------------------------------------------------------
    " 3. 既存明細削除（洗い替え）
    "------------------------------------------------------------------
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY header BY \_item
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(ldt_file_item)
        FAILED DATA(lds_failed).

    DATA: ldt_item_delete TYPE TABLE FOR DELETE zi_att_g8\\item.
    MOVE-CORRESPONDING ldt_file_item TO ldt_item_delete.

    IF ldt_item_delete IS NOT INITIAL.
      MODIFY ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY item
        DELETE FROM ldt_item_delete.
    ENDIF.

    "------------------------------------------------------------------
    " 4. ファイル → 明細変換
    "------------------------------------------------------------------
    LOOP AT ldt_filedata INTO DATA(lds_filedata).

      DATA(lds_conv) =
        zcl_pr_import=>convert_data_file(
          is_file_data = lds_filedata ).

      APPEND INITIAL LINE TO lds_item_create-%target
        ASSIGNING FIELD-SYMBOL(<l_s_item>).

      MOVE-CORRESPONDING lds_conv TO <l_s_item>.
      <l_s_item>-%key-attachmentuuid          = lds_files-attachmentuuid.
      <l_s_item>-%is_draft             = lds_files-%is_draft.
      <l_s_item>-recnumber             = sy-tabix.


    ENDLOOP.

    "------------------------------------------------------------------
    " 5. 明細作成
    "------------------------------------------------------------------
    IF ldt_filedata IS NOT INITIAL.

      lds_item_create-%is_draft       = lds_files-%is_draft.
      lds_item_create-attachmentuuid  = lds_files-attachmentuuid.
      APPEND lds_item_create TO ldt_item_create.

      MODIFY ENTITIES OF zi_att_g8 IN LOCAL MODE
  ENTITY header
  CREATE BY \_item
  FIELDS (
     PrNo
     PrItem
     RecNumber
     PurchaseRequisitionType
     PurReqnDescription
     PurchaseRequisitionItemText
     Material
     MaterialGroup
     QuantityReq
     Unit
     Plant
     PurchaseRequisitionPrice
     PurReqnItemCurrency
     PurchasingGroup
     PurchasingOrganization
     AccountAssignmentCategory
     DeliveryDate
     Url
  )
  AUTO FILL CID WITH ldt_item_create
  REPORTED DATA(ldt_reported_create)
  FAILED   DATA(ldt_failed_create)
  MAPPED   DATA(ldt_mapped_create).


    ENDIF.

  ENDMETHOD.


  METHOD updatebusinessobject.
    "アイテムのデータファイルデータを取得
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY header
        BY \_item
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(ldt_file_item)
        FAILED DATA(lds_read_failed).

    DATA: ldt_data_for_item_upd TYPE TABLE FOR UPDATE zi_att_g8\\item,
          ldt_release_head      TYPE TABLE FOR CREATE zi_rlshead_g8,
          lds_release_head      LIKE LINE OF ldt_release_head,
          ldt_release_item      TYPE TABLE FOR CREATE zi_rlshead_g8\_Item,
          lds_release_item      LIKE LINE OF ldt_release_item.
    DATA: ldt_parallel_input TYPE zcl_pr_import=>gtt_group_data.
    DATA: ldf_check TYPE i.
    DATA: ldt_senmail        TYPE zcl_pr_sendmail=>gtt_filedata,
          lds_senmail        TYPE zcl_pr_sendmail=>gts_filedata,
          lds_sendmail_input TYPE zcl_pr_sendmail=>gts_parallel_input.
    DATA: ldt_error_data TYPE zcl_pr_sendmail=>gtt_filedata,
          lds_error_data TYPE zcl_pr_sendmail=>gts_filedata.

    CLEAR: gdf_count_total, gdf_count_success, gdf_count_error, gdf_count_warning.

    "データが空でないことを確認
    IF ldt_file_item IS INITIAL.
      RETURN.
    ENDIF.

    "並列処理のインスタンスを作成
    DATA(lo_process_parallel) = NEW zcl_pr_import( ).
    SORT ldt_file_item BY PrNo.

    "データ入力パラメータを移動
    LOOP AT ldt_file_item INTO DATA(lds_file_item)
     GROUP BY ( PrNo = lds_file_item-PrNo )
     ASSIGNING FIELD-SYMBOL(<lds_group>).

      APPEND INITIAL LINE TO ldt_parallel_input ASSIGNING FIELD-SYMBOL(<lds_data>).
      CLEAR ldf_check.
      LOOP AT GROUP <lds_group> INTO DATA(lds_item).
        ldf_check += 1.
        IF ldf_check = 1.
          MOVE-CORRESPONDING lds_item TO <lds_data>.
        ENDIF.
        APPEND INITIAL LINE TO <lds_data>-item_data ASSIGNING FIELD-SYMBOL(<lds_item>).
        MOVE-CORRESPONDING lds_item TO <lds_item>.
      ENDLOOP.
    ENDLOOP.

    "実行して結果を取得
    SORT ldt_file_item BY attachmentuuid itemuuid.

    DATA(ldf_line) = 1.

    LOOP AT ldt_parallel_input INTO DATA(lds_parallel_input).
      DATA(lds_output) = lo_process_parallel->execute_parallel( lds_parallel_input ).

      "重要度、メッセージの値を更新
      LOOP AT lds_output-file_item_upd INTO DATA(lds_file_item_upd).
        READ TABLE ldt_file_item INTO lds_file_item
            WITH KEY attachmentuuid = lds_file_item_upd-attachmentuuid
                     itemuuid = lds_file_item_upd-itemuuid
                     BINARY SEARCH.
        IF sy-subrc = 0.
          APPEND VALUE #(
              %tky = lds_file_item-%tky
              PrNo                 = lds_file_item_upd-PrNo
              PrItem               = lds_file_item_upd-PrItem
              status               = lds_file_item_upd-status
              messagestandardtable = lds_file_item_upd-messagestandardtable
              criticality          = lds_file_item_upd-criticality
          ) TO ldt_data_for_item_upd.
        ENDIF.

        IF lds_file_item_upd-criticality <> gcf_criticality_error.
          MOVE-CORRESPONDING lds_file_item_upd TO lds_senmail.
          APPEND lds_senmail TO ldt_senmail.
        ENDIF.

        IF lds_file_item_upd-criticality = gcf_criticality_error.
          " Lấy dữ liệu item nguyên bản để có đủ các thông tin (Material, Quantity, Unit...)
          MOVE-CORRESPONDING lds_file_item TO lds_error_data.

          " Cập nhật thêm các trường có thể đã bị thay đổi trong quá trình xử lý nếu cần
          lds_error_data-PrNo   = ldf_line.

          APPEND lds_error_data TO ldt_error_data.
          CLEAR lds_error_data.
        ENDIF.

        "各レコードのステータスを集計する
        gdf_count_total += 1.

        CASE lds_file_item_upd-criticality.
          WHEN gcf_criticality_success.
            gdf_count_success += 1.
          WHEN gcf_criticality_error.
            gdf_count_error += 1.
          WHEN gcf_criticality_warning.
            gdf_count_warning += 1.
        ENDCASE.
      ENDLOOP.

      ldf_line += 1.
    ENDLOOP.

    LOOP AT ldt_data_for_item_upd ASSIGNING FIELD-SYMBOL(<lfs_item_url>).
      DATA(lv_url) = ''.

      <lfs_item_url>-Url = |https://s35lp1.ucc.cit.tum.de:8100/sap/bc/ui2/flp#PurchaseRequisition-displayFactSheet|
           && |?PurchaseRequisition={ <lfs_item_url>-PrNo }|
           && |&PurchaseRequisitionItem={ <lfs_item_url>-PrItem }|.
    ENDLOOP.

    "メッセージおよびステータスを更新
    MODIFY ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY item
        UPDATE FIELDS ( status messagestandardtable criticality PrNo PrItem Url )
        WITH ldt_data_for_item_upd
        REPORTED DATA(ldt_update_item_reported).

    "ヘッダーのカウントフィールドを更新
    MODIFY ENTITIES OF zi_att_g8 IN LOCAL MODE
        ENTITY header
        UPDATE FIELDS ( totalcount successcount warningcount errorcount )
        WITH VALUE #( (
            %is_draft = keys[ 1 ]-%is_draft
            %key = keys[ 1 ]-%key
            totalcount = gdf_count_total
            successcount = gdf_count_success
            warningcount = gdf_count_warning
            errorcount = gdf_count_error
        ) )
        REPORTED DATA(lds_update_header_reported).

    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
       ENTITY header
       FIELDS ( Filename )
       WITH CORRESPONDING #( keys )
       RESULT DATA(ldt_header_info).

    LOOP AT ldt_senmail ASSIGNING FIELD-SYMBOL(<lfs_item_url1>).
      <lfs_item_url1>-url = |https://s35lp1.ucc.cit.tum.de:8100/sap/bc/ui2/flp#PurchaseRequisition-displayFactSheet|
           && |?PurchaseRequisition={ <lfs_item_url1>-PrNo }|
           && |&PurchaseRequisitionItem={ <lfs_item_url1>-PrItem }|.
    ENDLOOP.

    DATA: ldf_check1 TYPE i.

    IF ldt_senmail IS NOT INITIAL.
      LOOP AT ldt_senmail INTO DATA(ls_senmail)
       GROUP BY ( PRNo = ls_senmail-prno ) INTO DATA(ls_group).

        ldf_check1 += 1.

        LOOP AT GROUP ls_group INTO DATA(lds_head).
          EXIT.
        ENDLOOP.

        MODIFY ENTITIES OF zi_rlshead_g8
        ENTITY header
          CREATE
          FIELDS (
            PRNo
            Definekey
            PurchaseRequisitionType
            Plant
            PurchasingOrganization
            PurchasingGroup
            Status
          )
          WITH VALUE #(
            (
              %cid                    = |HEAD_| && ldf_check1
              PRNo                    = lds_head-PRNo
              Definekey               = ldt_file_item[ 1 ]-attachmentuuid
              PurchaseRequisitionType = lds_head-PurchaseRequisitionType
              Plant                   = lds_head-Plant
              PurchasingOrganization  = lds_head-PurchasingOrganization
              PurchasingGroup         = lds_head-PurchasingGroup
              Status                  = 'Not release'
            )
          )

        ENTITY header
        CREATE BY \_Item
          FIELDS (
            PRItem
            Purchaserequisitiontype
            Purreqndescription
            Material
            QuantityReq
            Unit
            Purchaserequisitionitemtext
            Accountassignmentcategory
            Purchaserequisitionprice
            Purreqnitemcurrency
            Materialgroup
            Plant
            PurchasingGroup
            Purchasingorganization
            DeliveryDate
            Url
          )
          AUTO FILL CID WITH VALUE #(
            (
              %cid_ref = |HEAD_| && ldf_check1
              %target  = VALUE #(
                FOR ls_item IN GROUP ls_group
                (
                  PRItem                      = ls_item-PRItem
                  Purchaserequisitiontype     = ls_item-Purchaserequisitiontype
                  Purreqndescription          = ls_item-Purreqndescription
                  Material                    = ls_item-Material
                  QuantityReq                 = ls_item-QuantityReq
                  Unit                        = ls_item-Unit
                  Purchaserequisitionitemtext = ls_item-Purchaserequisitionitemtext
                  Accountassignmentcategory   = ls_item-Accountassignmentcategory
                  Purchaserequisitionprice    = ls_item-Purchaserequisitionprice
                  Purreqnitemcurrency         = ls_item-Purreqnitemcurrency
                  Materialgroup               = ls_item-Materialgroup
                  Plant                       = ls_item-Plant
                  PurchasingGroup             = ls_item-PurchasingGroup
                  Purchasingorganization      = ls_item-Purchasingorganization
                  DeliveryDate                = ls_item-DeliveryDate
                  Url                         = ls_item-Url
                )
              )
            )
          )


        REPORTED DATA(ldt_reported_create)
        FAILED   DATA(ldt_failed_create)
        MAPPED   DATA(ldt_mapped_create).

      ENDLOOP.

      LOOP AT ldt_senmail ASSIGNING FIELD-SYMBOL(<lds_sendmail>).
        <lds_sendmail>-purchaserequisitionprice =
         zcl_com_conv=>amount_out(
           if_amountin  = <lds_sendmail>-purchaserequisitionprice
           if_currency  = <lds_sendmail>-PurReqnItemCurrency ).
      ENDLOOP.

      lds_sendmail_input-iv_filename = ldt_file_item[ 1 ]-attachmentuuid.
      lds_sendmail_input-it_data = ldt_senmail.
      lds_sendmail_input-iv_subject = 'PR List'.
      DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
      lo_process_sendmail->execute_parallel( lds_sendmail_input ).
    ENDIF.

    IF ldt_error_data IS NOT INITIAL.
      downloaderror(
        it_error_data = ldt_error_data
        if_uuid       = keys[ 1 ]-AttachmentUUID
      ).
    ENDIF.
    reported = CORRESPONDING #( DEEP lds_update_header_reported ).

  ENDMETHOD.

  METHOD precheck_delete.

    DATA: lds_reported LIKE LINE OF reported-header.

    LOOP AT keys INTO DATA(lds_key).

      IF lds_key-%is_draft = '00'.
        CLEAR lds_reported.
        lds_reported-%tky = lds_key-%tky.
        lds_reported-%msg = new_message(
                            id       = 'ZRAP_COM_99'
                            number   = '006'
                            severity = if_abap_behv_message=>severity-error
                            ).
        APPEND lds_reported TO reported-header.
        APPEND VALUE #( %tky = lds_key-%tky ) TO failed-header.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD vldbeforesave.

    " 明細データの取得
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
      ENTITY header
      BY \_item
      FIELDS ( itemuuid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(ldt_items).

    IF ldt_items IS INITIAL.
      " 明細なしエラー設定
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-header.

      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message( id       = 'ZRAP_COM_99'
                            number   = '007'
                            severity = if_abap_behv_message=>severity-error )
      ) TO reported-header.
    ENDIF.

  ENDMETHOD.


  METHOD testRun.

  ENDMETHOD.

  METHOD downloaderror.

    IF it_error_data IS INITIAL. RETURN. ENDIF.

    " 1. TẠO HEADER CHO FILE CSV GIỐNG VỚI FORMAT UPLOAD
    DATA: lv_csv_string TYPE string.
    lv_csv_string =
    |PrNo,PrItem,PurchasingRequisitionType,PurReqnDescription,PurReqnDescription Item,Material,MaterialGroup,QuantityReq,Unit,PurchasingRequisitionPrice,Currency,Plant,PurchasingGroup,PurchasingOrganization,AccountAssignmentCategory,DeliveryDate| &&
                    cl_abap_char_utilities=>cr_lf.

    " 2. LOOP QUA BẢNG DỮ LIỆU LỖI VÀ ĐƯA VÀO CHUỖI
    LOOP AT it_error_data INTO DATA(ls_item).

      " --- Xử lý Format Số lượng (QuantityReq) ---
      DATA: lv_quan_export TYPE c LENGTH 30.
      WRITE ls_item-QuantityReq TO lv_quan_export UNIT ls_item-Unit NO-GROUPING LEFT-JUSTIFIED.
      CONDENSE lv_quan_export NO-GAPS.

      " --- Xử lý Format Tiền tệ (PurchasingRequisitionPrice) ---
      DATA: lv_price_export TYPE c LENGTH 30.
      WRITE ls_item-PurchaseRequisitionPrice TO lv_price_export CURRENCY ls_item-PurReqnItemCurrency NO-GROUPING LEFT-JUSTIFIED.
      CONDENSE lv_price_export NO-GAPS.

      " >>> THÊM MỚI: XỬ LÝ CẮT BỎ KHOẢNG TRẮNG (TRIM) CÁC TRƯỜNG TEXT <<<
      " Ép kiểu về string và dùng CONDENSE để xóa khoảng trắng thừa ở 2 đầu
      DATA(lv_pr_type) = CONV string( ls_item-PurchaseRequisitionType ). CONDENSE lv_pr_type.
      DATA(lv_mat_grp) = CONV string( ls_item-MaterialGroup ).           CONDENSE lv_mat_grp.
      DATA(lv_unit)    = CONV string( ls_item-Unit ).                    CONDENSE lv_unit.
      DATA(lv_curr)    = CONV string( ls_item-PurReqnItemCurrency ).     CONDENSE lv_curr.
      DATA(lv_plant)   = CONV string( ls_item-Plant ).                   CONDENSE lv_plant.
      DATA(lv_pur_grp) = CONV string( ls_item-PurchasingGroup ).         CONDENSE lv_pur_grp.
      DATA(lv_pur_org) = CONV string( ls_item-PurchasingOrganization ).  CONDENSE lv_pur_org.
      DATA(lv_acc_cat) = CONV string( ls_item-AccountAssignmentCategory ). CONDENSE lv_acc_cat.

      " --- Xử lý khoảng trắng và an toàn dấu ngoặc kép cho Description & Text ---
      DATA(lv_desc) = CONV string( ls_item-PurReqnDescription ).
      CONDENSE lv_desc. " Xóa khoảng trắng 2 đầu
      REPLACE ALL OCCURRENCES OF `"` IN lv_desc WITH `""`.

      DATA(lv_text) = CONV string( ls_item-PurchaseRequisitionItemText ).
      CONDENSE lv_text. " Xóa khoảng trắng 2 đầu
      REPLACE ALL OCCURRENCES OF `"` IN lv_text WITH `""`.

      " --- Xử lý PR No & Material (Vừa Condense vừa Alpha Out loại bỏ số 0 ở đầu) ---
      DATA(lv_pr_no) = |{ ls_item-PrNo ALPHA = OUT }|.
      CONDENSE lv_pr_no.

      DATA(lv_mat) = |{ ls_item-Material ALPHA = OUT }|.
      CONDENSE lv_mat.

      " --- Xử lý PR Item (Nếu rỗng hoặc 00000 thì để trắng) ---
      DATA(lv_pr_item) = COND string( WHEN ls_item-PrItem = '00000' OR ls_item-PrItem IS INITIAL
                                      THEN '' ELSE |{ ls_item-PrItem ALPHA = OUT }| ).
      CONDENSE lv_pr_item.

      " --- Ghép chuỗi CSV theo đúng thứ tự file Upload ---
      lv_csv_string = lv_csv_string &&
                      |{ lv_pr_no },| &&
                      |{ lv_pr_item },| &&
                      |{ lv_pr_type },| &&
                      |"{ lv_desc }",| &&
                      |"{ lv_text }",| &&
                      |{ lv_mat },| &&
                      |{ lv_mat_grp },| &&
                      |{ lv_quan_export },| &&
                      |{ lv_unit },| &&
                      |{ lv_price_export },| &&
                      |{ lv_curr },| &&
                      |{ lv_plant },| &&
                      |{ lv_pur_grp },| &&
                      |{ lv_pur_org },| &&
                      |{ lv_acc_cat },| &&
                      |{ ls_item-DeliveryDate }| &&
                      cl_abap_char_utilities=>cr_lf.
    ENDLOOP.

    " 3. CHUYỂN STRING THÀNH XSTRING VÀ GẮN BOM UTF-8
    DATA(lv_xstring_content) = xco_cp=>string( lv_csv_string )->as_xstring( xco_cp_character=>code_page->utf_8 )->value.
    DATA(lv_bom)             = cl_abap_char_utilities=>byte_order_mark_utf8.
    DATA(lv_xstring_file)    = lv_bom && lv_xstring_content.

    " 4. UPDATE ENTITY ĐỂ GHI FILE TRẢ VỀ CHO USER
    MODIFY ENTITIES OF zi_att_g8 IN LOCAL MODE
      ENTITY Header
      UPDATE FIELDS ( Attachment FileName Mimetype )
      WITH VALUE #( ( %key-AttachmentUUID = if_uuid
                      Attachment = lv_xstring_file
                      FileName   = 'Error_List_Export.csv'
                      Mimetype    = 'text/csv'  ) )
      FAILED DATA(failed)
      REPORTED DATA(reported).

  ENDMETHOD.

METHOD validateSaveData1.

    " 1. Đọc dữ liệu Item thông qua Association từ Header
    READ ENTITIES OF zi_att_g8 IN LOCAL MODE
      ENTITY header BY \_item
      FIELDS ( criticality )
      WITH CORRESPONDING #( keys )
      RESULT DATA(ldt_items)
      LINK DATA(ldt_links). " Dùng LINK để map chính xác Item với Header

    " 2. Duyệt qua từng Header (Best practice thay vì dùng keys[ 1 ])
    LOOP AT keys INTO DATA(ls_key).

      " Reset state area
      APPEND VALUE #( %tky        = ls_key-%tky
                      %state_area = 'VALIDATE_DATA' )
            TO reported-header.

      DATA(lv_has_error) = abap_false.

      " 3. Tìm các Item thuộc về Header hiện tại và kiểm tra Criticality
      LOOP AT ldt_links INTO DATA(ls_link) WHERE source-%tky = ls_key-%tky.

        " Lấy data chi tiết của Item tương ứng
        READ TABLE ldt_items INTO DATA(ls_item) WITH KEY %tky = ls_link-target-%tky.

        IF sy-subrc = 0 AND ls_item-criticality = 1. " 1 là Error (gcf_criticality_error)
          lv_has_error = abap_true.
          EXIT. " Đã thấy 1 dòng lỗi thì thoát vòng lặp ngay cho tối ưu
        ENDIF.

      ENDLOOP.

      " 4. Nếu có ít nhất 1 Item bị lỗi, mới xuất Message
      IF lv_has_error = abap_true.
        APPEND VALUE #(
          %tky        = ls_key-%tky
          %state_area = 'VALIDATE_DATA'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-warning
                          text     = 'Please check generated error file in Attachment!' )
        ) TO reported-header.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
