CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS updateItemPrice2 FOR DETERMINE ON MODIFY
      IMPORTING keys FOR item~updateItemPrice2.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR item RESULT result.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD updateItemPrice2.
    DATA: lt_update_item TYPE TABLE FOR UPDATE zi_rldhead_g8\\item.

    " 1. Đọc item vừa được trigger để lấy giá trị Netpr mới nhất
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY item
      FIELDS ( Netpr )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_changed_items).

    IF lt_changed_items IS INITIAL.
      RETURN.
    ENDIF.

    " Lấy giá trị net price mới (giả định xử lý theo item đầu tiên)
    DATA(lv_new_price) = lt_changed_items[ 1 ]-Netpr.

    " 2. Tìm Header của (các) item này bằng cách đọc qua association trỏ ngược lên Header
    " Lưu ý: Thay '\_Header' bằng tên association của bạn (ví dụ: \_Prhead, \_PurchaseRequisition,...)
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY item BY \_Header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    IF lt_headers IS INITIAL.
      RETURN.
    ENDIF.

    " 3. Từ Header tìm được, đọc TẤT CẢ các items thuộc PR đó qua association \_Item
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header BY \_Item
      ALL FIELDS
      WITH CORRESPONDING #( lt_headers )
      RESULT DATA(lt_all_items).

    " 4. Quét toàn bộ items của PR và gán giá mới
    LOOP AT lt_all_items INTO DATA(ls_item).
      " BƯỚC QUAN TRỌNG: Chỉ thêm vào bảng update nếu giá trị đang khác với giá mới.
      " Việc này giúp NGĂN CHẶN LỖI VÒNG LẶP VÔ HẠN (Infinite Loop) khi entity liên tục bị modify.
      IF ls_item-Netpr <> lv_new_price.
        APPEND VALUE #(
          %tky  = ls_item-%tky
          Netpr = lv_new_price
        ) TO lt_update_item.
      ENDIF.
    ENDLOOP.

    " 5. Thực thi lệnh MODIFY để cập nhật đồng loạt các item
    IF lt_update_item IS NOT INITIAL.
      MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
        ENTITY item
        UPDATE
        FIELDS ( Netpr )
        WITH lt_update_item
        REPORTED DATA(lt_reported_item)
        FAILED   DATA(lt_failed_item).
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(ldt_data).

    result = VALUE #(
      FOR lds_data IN ldt_data
        ( %tky = lds_data-%tky

          %features = VALUE #(

            %field-PRItem                          = if_abap_behv=>fc-f-read_only
            %field-Purchaserequisitiontype         = if_abap_behv=>fc-f-read_only
            %field-Purreqndescription              = if_abap_behv=>fc-f-read_only
            %field-Material                        = if_abap_behv=>fc-f-read_only
            %field-QuantityReq                     = if_abap_behv=>fc-f-read_only
            %field-Unit                            = if_abap_behv=>fc-f-read_only
            %field-Purchaserequisitionitemtext     = if_abap_behv=>fc-f-read_only
            %field-Accountassignmentcategory       = if_abap_behv=>fc-f-read_only
            %field-Purchaserequisitionprice        = if_abap_behv=>fc-f-read_only
            %field-Purreqnitemcurrency             = if_abap_behv=>fc-f-read_only
            %field-Materialgroup                   = if_abap_behv=>fc-f-read_only
            %field-Plant                           = if_abap_behv=>fc-f-read_only
            %field-PurchasingGroup                 = if_abap_behv=>fc-f-read_only
            %field-Purchasingorganization          = if_abap_behv=>fc-f-read_only
            %field-DeliveryDate                    = if_abap_behv=>fc-f-read_only
            %field-Url                             = if_abap_behv=>fc-f-read_only

          )
        )
    ).

  ENDMETHOD.

ENDCLASS.

CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR header
        RESULT result,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR header RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR header RESULT result.
    METHODS autovendor FOR MODIFY
      IMPORTING keys FOR ACTION header~autovendor RESULT result.

    METHODS converttopo FOR MODIFY
      IMPORTING keys FOR ACTION header~converttopo RESULT result.
    METHODS updateitemprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR header~updateitemprice.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
    ENTITY header
      FIELDS ( Status Lifnr )
      WITH CORRESPONDING #( keys )
    RESULT DATA(ldt_pr).

    result = VALUE #(
    FOR lds_pr IN ldt_pr
      ( %tky = lds_pr-%tky

        %features-%action-convertToPO = COND #(
          WHEN lds_pr-Status = 'PR Released'
           AND lds_pr-Lifnr IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

        %features-%action-Edit = COND #(
          WHEN lds_pr-Status = 'PR Released'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled )

      ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.

  ENDMETHOD.

  METHOD autoVendor.

    DATA: lt_update_item  TYPE TABLE FOR UPDATE zi_rldhead_g8\\item,
          lds_update_item LIKE LINE OF lt_update_item.
    " 1. Read PR header
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_head_data).

    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      BY \_Item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item_data).

    READ TABLE lt_head_data INTO DATA(lds_head) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(lt_item_dummy) = lt_item_data.

    SORT lt_item_dummy BY PurchasingOrganization Plant Material.
    DELETE ADJACENT DUPLICATES FROM lt_item_dummy
      COMPARING PurchasingOrganization Plant Material.
    " 3. Select Supplier + Net Price từ PIR
    SELECT PurchasingOrganization,
           Supplier,
           Material,
           NetPriceAmount
      FROM I_PurgInfoRecdOrgPlntDataTP
      FOR ALL ENTRIES IN @lt_item_dummy
      WHERE PurchasingOrganization  =  @lt_item_dummy-PurchasingOrganization
        AND Plant                   =  @lt_item_dummy-Plant
        AND Material                =  @lt_item_dummy-Material
        AND NetPriceAmount          <= @lt_item_dummy-Purchaserequisitionprice
      INTO TABLE @DATA(lt_info).

    IF sy-subrc <> 0.
      MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
        ENTITY header
        UPDATE
        FIELDS ( MessageStandardtable )
        WITH VALUE #(
          ( %tky            = keys[ 1 ]-%tky
            MessageStandardtable           = 'No suitable vendor found'
          )
        )
        REPORTED DATA(lt_rp_novendor)
        FAILED   DATA(lt_fail_novendor).
      READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
       ENTITY header
       ALL FIELDS WITH CORRESPONDING #( keys )
       RESULT DATA(lt_updated_data).

      LOOP AT lt_updated_data INTO DATA(lds_updated).
        INSERT VALUE #(
            %tky   = lds_updated-%tky
            %param = lds_updated
        ) INTO TABLE result.
      ENDLOOP.
      RETURN.
    ENDIF.

    DATA(lt_info_dummy) = lt_info.
    SORT lt_info_dummy BY PurchasingOrganization Supplier.
    DELETE ADJACENT DUPLICATES FROM lt_info_dummy COMPARING PurchasingOrganization Supplier Material.

    SELECT
           ekorg,
           lifnr,
           gesbu
    FROM elbk
    FOR ALL ENTRIES IN @lt_info_dummy
     WHERE ekorg = @lt_info_dummy-PurchasingOrganization
       AND lifnr = @lt_info_dummy-Supplier
    INTO TABLE @DATA(lt_best_supplier).

    SORT lt_best_supplier BY gesbu DESCENDING.

    " 4. Update lại PR bằng MODIFY ENTITIES
    MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      UPDATE
      FIELDS ( Lifnr )
      WITH VALUE #(
        ( %tky            = keys[ 1 ]-%tky
          Lifnr           = lt_best_supplier[ 1 ]-lifnr
        )
      )
      REPORTED DATA(lt_reported_head)
      FAILED   DATA(lt_failed_head).


    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_data1).

    LOOP AT lt_updated_data1 INTO DATA(lds_updated1).
      INSERT VALUE #(
          %tky   = lds_updated1-%tky
          %param = lds_updated1
      ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD convertToPO.

    DATA: lo_pr_release TYPE REF TO zcl_create_po,
          lds_output    TYPE zcl_create_po=>gts_parallel_output.

    DATA: ldt_senmail        TYPE zcl_po_sendmail=>gtt_po_data,
          lds_senmail        TYPE zcl_po_sendmail=>gts_po_data,
          lds_sendmail_input TYPE zcl_po_sendmail=>gts_parallel_input.

    DATA lds_parallel_input TYPE zcl_create_po=>gts_parallel_input.

    "---- Read header ----
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_head_data).

    "---- Read all items ----
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      BY \_Item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item_data).

    lo_pr_release = NEW zcl_create_po( ).

    SORT lt_head_data BY PrNo.

    LOOP AT lt_head_data INTO DATA(lds_head).

      CLEAR lds_parallel_input.

      "Header → PO input
      MOVE-CORRESPONDING lds_head TO lds_parallel_input-pr_data.

      "Items of this header only
      LOOP AT lt_item_data INTO DATA(lds_item)
        WHERE PrNo = lds_head-PrNo.

        DATA(lds_po_item) = VALUE zcl_create_po=>gts_item_data( ).
        MOVE-CORRESPONDING lds_item TO lds_po_item.
        APPEND lds_po_item TO lds_parallel_input-pr_data-item_data.

      ENDLOOP.

      "Execute PO creation
      lds_output = lo_pr_release->execute_parallel(
                    is_input = lds_parallel_input-pr_data ).

      "Status text
      DATA(lv_status_text) =
        COND zi_rldhead_g8-status(
          WHEN lds_output-criticality = 3 OR lds_output-criticality = 2
            THEN 'PO Created'
          WHEN lds_output-criticality = 1
            THEN 'Create PO failed'
        ).

      READ TABLE lt_head_data INTO DATA(lds_head_data)
          WITH KEY prno = lds_output-pr_number
                   BINARY SEARCH.
      IF sy-subrc = 0.

        "メッセージおよびステータスを更新
        MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
            ENTITY header
            UPDATE FIELDS ( status messagestandardtable criticality )
            WITH VALUE #(
                ( %tky                 = lds_head_data-%tky
                  Status               = lv_status_text
                  Criticality          = lds_output-criticality
                  MessageStandardtable = lds_output-message ) ).
      ENDIF.

      DATA lv_url TYPE string.

      IF lds_output-criticality <> 1.
        lds_senmail-bsart = 'NB'.
        lds_senmail-bukrs = 'PH06'.
        lds_senmail-ebeln = lds_output-po_number.
        lds_senmail-ekgrp = lds_head-PurchasingGroup.
        lds_senmail-ekorg = lds_head-Purchasingorganization.
        lds_senmail-erdat = sy-datum.
        lds_senmail-lifnr = lds_head-Lifnr.
        lds_senmail-waers = lds_item-Purreqnitemcurrency.
        APPEND lds_senmail TO ldt_senmail.
        DATA(lv_po) = lds_output-po_number.

        lv_url =
          |https://s35lp1.ucc.cit.tum.de:8100/sap/bc/ui2/flp#PurchaseOrder-manage|
          && |&/C_PurchaseOrderTP(|
          && |PurchaseOrder='{ lv_po }',|
          && |DraftUUID=guid'00000000-0000-0000-0000-000000000000',|
          && |IsActiveEntity=true)|.

        "Update current header only
        MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
          ENTITY header
          UPDATE
          FIELDS ( Status PoNo Criticality MessageStandardtable Url )
          WITH VALUE #(
            ( %tky                 = lds_head-%tky
              Status               = lv_status_text
              PoNo                 = lds_output-po_number
              Criticality          = lds_output-criticality
              Url                  = lv_url
              MessageStandardtable = lds_output-message ) ).



        MODIFY ENTITIES OF zi_rlshead_po_g8
          ENTITY header
            CREATE
            FIELDS (
               ebeln
               bukrs
               ekgrp
               ekorg
               erdat
               lifnr
               waers
               DefineKey
               Status
               Url
            )
            WITH VALUE #(
              (
                %cid      = |HEAD_| && sy-tabix
                ebeln     = lds_output-po_number
                bukrs     = 'PH06'
                ekgrp     = lds_head-PurchasingGroup
                ekorg     = lds_head-Purchasingorganization
                erdat     = sy-datum
                lifnr     = lds_head-Lifnr
                waers     = lds_item-Purreqnitemcurrency
                DefineKey = lds_head-DefineKey
                Status    = 'Not release'
                Url       = lv_url
              )
            )

          ENTITY header
          CREATE BY \_Item
            FIELDS (
              Ebelp
              banfn
              bnfpo
              matnr
              werks
              menge
              meins
              netpr
              waers
              eindt
              Url
              UrlPR
            )
            AUTO FILL CID WITH VALUE #(
              (
                %cid_ref = |HEAD_| && sy-tabix
                %target  = VALUE #(
                  FOR lds_item_crt IN lt_item_data WHERE ( PrNo = lds_head-PrNo )
                  (
                    Ebelp = lds_item_crt-PrItem
                    banfn = lds_item_crt-PrNo
                    bnfpo = lds_item_crt-PrItem
                    matnr = lds_item_crt-Material
                    werks = lds_item_crt-Plant
                    menge = lds_item_crt-QuantityReq
                    meins = lds_item_crt-Unit
                    netpr = lds_item_crt-Netpr
                    waers = lds_item_crt-Purreqnitemcurrency
                    eindt = lds_item_crt-DeliveryDate
                    Url   = lv_url
                    UrlPR = lds_item-Url
                  )
                )
              )
            )


          REPORTED DATA(ldt_reported_create)
          FAILED   DATA(ldt_failed_create)
          MAPPED   DATA(ldt_mapped_create).

      ENDIF.
    ENDLOOP.

    DATA(lo_parallel) = NEW zcl_po_sendmail( ).
    DATA lds_input TYPE zcl_po_sendmail=>gts_parallel_input.

    lds_input-iv_define_key = lds_head-DefineKey.
    lds_input-it_data       = ldt_senmail.
    lds_input-iv_receiver   = 'datnb258@gmail.com'.
    lds_input-iv_subject    = 'PO Created List'.

    lo_parallel->execute_parallel( lds_input ).


    "---- Return updated result ----
    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_data).

    LOOP AT lt_updated_data INTO DATA(lds_updated).
      INSERT VALUE #(
        %tky   = lds_updated-%tky
        %param = lds_updated
      ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD updateItemPrice.
    DATA: lt_update_item  TYPE TABLE FOR UPDATE zi_rldhead_g8\\item,
          lds_update_item LIKE LINE OF lt_update_item.

    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_head_data).

    READ ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
      ENTITY header
      BY \_Item
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item_data).
    DATA(lt_item_dummy) = lt_item_data.

    SORT lt_item_dummy BY PurchasingOrganization Plant Material.
    DELETE ADJACENT DUPLICATES FROM lt_item_dummy
      COMPARING PurchasingOrganization Plant Material.
    " 3. Select Supplier + Net Price từ PIR
    SELECT PurchasingOrganization,
           Supplier,
           Material,
           NetPriceAmount
      FROM I_PurgInfoRecdOrgPlntDataTP
      FOR ALL ENTRIES IN @lt_item_dummy
      WHERE PurchasingOrganization  =  @lt_item_dummy-PurchasingOrganization
        AND Plant                   =  @lt_item_dummy-Plant
        AND Material                =  @lt_item_dummy-Material
      INTO TABLE @DATA(lt_info).

    SORT lt_info BY PurchasingOrganization Supplier Material.
    LOOP AT lt_item_data ASSIGNING FIELD-SYMBOL(<lds_item_data>).
      READ TABLE lt_info INTO DATA(lds_info)
        WITH KEY PurchasingOrganization = <lds_item_data>-Purchasingorganization
                 Supplier               = lt_head_data[ 1 ]-Lifnr
                 Material               = <lds_item_data>-Material
        BINARY SEARCH.
      lds_update_item-%tky  =  <lds_item_data>-%tky.
      lds_update_item-Netpr =  lds_info-NetPriceAmount.
      APPEND lds_update_item TO lt_update_item.
    ENDLOOP.

    MODIFY ENTITIES OF zi_rldhead_g8 IN LOCAL MODE
       ENTITY item
       UPDATE
       FIELDS ( Netpr )
       WITH lt_update_item
       REPORTED DATA(lt_reported_item)
       FAILED   DATA(lt_failed_item).
  ENDMETHOD.

ENDCLASS.
