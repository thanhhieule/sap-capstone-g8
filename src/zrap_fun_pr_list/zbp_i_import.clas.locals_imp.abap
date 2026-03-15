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
     GROUP BY ( productionorder = lds_file_item-PrNo )
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

      IF ldt_failed_create IS INITIAL.
        LOOP AT ldt_senmail ASSIGNING FIELD-SYMBOL(<lds_sendmail>).
          <lds_sendmail>-purchaserequisitionprice =
           zcl_com_conv=>amount_out(
             if_amountin  = <lds_sendmail>-purchaserequisitionprice
             if_currency  = <lds_sendmail>-PurReqnItemCurrency ).
        ENDLOOP.

        lds_sendmail_input-iv_filename = ldt_file_item[ 1 ]-attachmentuuid.
        lds_sendmail_input-it_data = ldt_senmail.
        lds_sendmail_input-iv_receiver = 'datnb258@gmail.com'.
        lds_sendmail_input-iv_subject = 'PR List'.
        DATA(lo_process_sendmail) = NEW zcl_pr_sendmail( ).
        lo_process_sendmail->execute_parallel( lds_sendmail_input ).
      ENDIF.
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

ENDCLASS.
