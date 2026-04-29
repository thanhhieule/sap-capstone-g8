REPORT yg8_form_po NO STANDARD PAGE HEADING.

*---------------------------------------------------------------------*
* TYPES
*---------------------------------------------------------------------*
TYPES: BEGIN OF ts_po_header,
         po_number    TYPE ekko-ebeln,
         company_code TYPE ekko-bukrs,
         company_name TYPE t001-butxt,
         vendor_id    TYPE ekko-lifnr,
         vendor_name  TYPE lfa1-name1,
         pur_org      TYPE ekko-ekorg,
         pur_group    TYPE ekko-ekgrp,
         currency     TYPE ekko-waers,
         created_date TYPE ekko-bedat,
         vendor_grade TYPE elbk-gesbu,
         bank_key     TYPE lfbk-bankl,
         bank_acc     TYPE lfbk-bankn,
         bank_holder  TYPE lfbk-koinh,
         price_score  TYPE elbp-beurt, " gia ca
         qual_score   TYPE elbp-beurt, "chat luong
         deliv_score  TYPE elbp-beurt, " giao hang
         serv_score   TYPE elbp-beurt, " dich vu
         zterm        TYPE lfb1-zterm,

       END OF ts_po_header.

TYPES: tt_po_header TYPE STANDARD TABLE OF ts_po_header
       WITH NON-UNIQUE KEY po_number.

TYPES: BEGIN OF ts_po_item,
         po_number   TYPE ekpo-ebeln,
         line_item   TYPE ekpo-ebelp,
         material    TYPE ekpo-matnr,
         description TYPE makt-maktx,
         plant       TYPE ekpo-werks,
         quantity    TYPE ekpo-menge,
         uom         TYPE ekpo-meins,
         price       TYPE ekpo-netpr,
         currency    TYPE ekko-waers,
         delivery    TYPE eket-eindt,
         plant_name  TYPE t001w-name1,
         street      TYPE adrc-street,
         city        TYPE adrc-city1,
         phone       TYPE adrc-tel_number,
         fax         TYPE adrc-fax_number,

       END OF ts_po_item.

TYPES: tt_po_item TYPE STANDARD TABLE OF ts_po_item
       WITH NON-UNIQUE KEY po_number line_item.

TYPES: BEGIN OF ts_eket,
         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         eindt TYPE eket-eindt,
       END OF ts_eket.


*---------------------------------------------------------------------*
* DATA
*---------------------------------------------------------------------*
DATA: gt_header TYPE tt_po_header,
      gt_items  TYPE tt_po_item.

DATA: gs_current_header TYPE ts_po_header.

DATA: gv_form TYPE char1.

*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*
SELECT-OPTIONS:
  s_ponum FOR gs_current_header-po_number.

PARAMETERS:
  p_bukrs TYPE bukrs DEFAULT 'PH06' OBLIGATORY.


*---------------------------------------------------------------------*
* EVENTS
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_po_header.
  PERFORM get_po_items.
  PERFORM display_report.

*AT LINE-SELECTION.
*
*  PERFORM show_form.

AT LINE-SELECTION.

  IF sy-lisel CS 'INTERNAL'.
    PERFORM print_all_pos USING 'INT'.
  ELSEIF sy-lisel CS 'PURCHASE ORDER FORM'.
    PERFORM print_all_pos USING 'EXT'.
  ELSEIF sy-lisel CS 'VENDOR'.
    PERFORM print_all_pos USING 'VEND'.
  ENDIF.

*---------------------------------------------------------------------*
* GET HEADER
*---------------------------------------------------------------------*
FORM get_po_header.


  SELECT a~ebeln AS po_number,
         a~bukrs AS company_code,
         b~butxt AS company_name,
         a~lifnr AS vendor_id,
         c~name1 AS vendor_name,
         a~ekorg AS pur_org,
         a~ekgrp AS pur_group,
         a~waers AS currency,
         a~bedat AS created_date,
         d~gesbu AS vendor_grade,
         e~bankl AS bank_key,    " Bank Key
       e~bankn AS bank_acc,    " Bank Account
       e~koinh AS bank_holder  "  Account Holder
    FROM ekko AS a
    LEFT JOIN t001 AS b
      ON a~bukrs = b~bukrs
    LEFT JOIN lfa1 AS c
      ON a~lifnr = c~lifnr
    LEFT JOIN elbk AS d              " <-- Join grade vendor
      ON a~lifnr = d~lifnr           " Khop mã Vendor
     AND a~ekorg = d~ekorg           " Khop Purchasing Org
    LEFT JOIN lfbk AS e ON a~lifnr = e~lifnr AND e~bvtyp = '001'
    WHERE a~ebeln IN @s_ponum
  AND a~bukrs = @p_bukrs

    INTO TABLE @gt_header.

  IF gt_header IS NOT INITIAL.
    LOOP AT gt_header ASSIGNING FIELD-SYMBOL(<fs_head>).

      SELECT SINGLE zterm FROM lfb1 INTO @<fs_head>-zterm
        WHERE lifnr = @<fs_head>-vendor_id
          AND bukrs = @<fs_head>-company_code.

      " 20 price
      SELECT SINGLE beurt FROM elbp INTO @<fs_head>-price_score
        WHERE lifnr = @<fs_head>-vendor_id
          AND ekorg = @<fs_head>-pur_org
          AND hkrit = '20'.

      " Mã 21 score
      SELECT SINGLE beurt FROM elbp INTO @<fs_head>-qual_score
        WHERE lifnr = @<fs_head>-vendor_id
          AND ekorg = @<fs_head>-pur_org
          AND hkrit = '21'.

      "  (Mã 22)  delivery
      SELECT SINGLE beurt FROM elbp INTO @<fs_head>-deliv_score
        WHERE lifnr = @<fs_head>-vendor_id
          AND ekorg = @<fs_head>-pur_org
          AND hkrit = '22'.

      " (Mã 23)  service
      SELECT SINGLE beurt FROM elbp INTO @<fs_head>-serv_score
        WHERE lifnr = @<fs_head>-vendor_id
          AND ekorg = @<fs_head>-pur_org
          AND hkrit = '23'.

    ENDLOOP.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* GET ITEMS
*---------------------------------------------------------------------*
FORM get_po_items.

  IF gt_header IS INITIAL.
    RETURN.
  ENDIF.

  SELECT a~ebeln AS po_number,
       a~ebelp AS line_item,
       a~matnr AS material,
       f~maktx AS description,
       a~werks AS plant,
       a~menge AS quantity,
       a~meins AS uom,
       a~netpr AS price,
       c~waers AS currency,
       b~eindt AS delivery,

       d~name1 AS plant_name,
       e~street,
       e~city1,
       e~tel_number,
       e~fax_number

  FROM ekpo AS a
  LEFT JOIN eket AS b
    ON a~ebeln = b~ebeln
   AND a~ebelp = b~ebelp
  LEFT JOIN ekko AS c
    ON a~ebeln = c~ebeln

  LEFT JOIN t001w AS d
    ON a~werks = d~werks

  LEFT JOIN adrc AS e
    ON d~adrnr = e~addrnumber

  LEFT JOIN makt AS f ON a~matnr = f~matnr AND f~spras = @sy-langu

  FOR ALL ENTRIES IN @gt_header
  WHERE a~ebeln = @gt_header-po_number

  INTO TABLE @gt_items.


ENDFORM.


*---------------------------------------------------------------------*
* DISPLAY REPORT
*---------------------------------------------------------------------*

FORM display_report.

  WRITE: / 'Choose form type to print all purchase order:'.
  ULINE.

  FORMAT COLOR COL_POSITIVE.
  WRITE: / '[ PRINT INTERNAL PURCHASE ORDER FORM ]' HOTSPOT ON.
  FORMAT COLOR COL_HEADING.
  WRITE: / '[ PRINT EXTERNAL PURCHASE ORDER FORM ]' HOTSPOT ON.
  FORMAT COLOR COL_TOTAL.
  WRITE: / '[ PRINT VENDOR SELECTION APPROVAL ]' HOTSPOT ON.
  FORMAT COLOR OFF.

*  SKIP 1.
  ULINE.
  WRITE: / 'List of selected purchase order (Scroll down to see more):'.
  ULINE.


  SET BLANK LINES ON. " keep blank line

  LOOP AT GT_HEADER INTO GS_CURRENT_HEADER.
    WRITE: / '- PO Number:', GS_CURRENT_HEADER-PO_NUMBER.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* SHOW SMARTFORM
*---------------------------------------------------------------------*
*FORM show_form.
FORM show_form USING is_control TYPE ssfctrlop.

  DATA: ls_head TYPE ysg8form_po_head,
        lt_item TYPE yttg8_form_po_item,
        ls_item TYPE ysg8_form_po_item.
  REFRESH lt_item.

* Header
  ls_head-ebeln = gs_current_header-po_number.
  ls_head-bukrs = gs_current_header-company_code.
  ls_head-lifnr = gs_current_header-vendor_id.
  ls_head-ekorg = gs_current_header-pur_org.
  ls_head-ekgrp = gs_current_header-pur_group.
  ls_head-waers = gs_current_header-currency.
  ls_head-erdat = gs_current_header-created_date.
  ls_head-gesbu = gs_current_header-vendor_grade.
  ls_head-price_score  = gs_current_header-price_score. "
  ls_head-qual_score   = gs_current_header-qual_score.
  ls_head-deliv_score  = gs_current_header-deliv_score.
  ls_head-serv_score   = gs_current_header-serv_score.
  ls_head-zterm        = gs_current_header-zterm.
  ls_head-bank_key     = gs_current_header-bank_key.
  ls_head-bank_acc     = gs_current_header-bank_acc.
  ls_head-bank_holder  = gs_current_header-bank_holder.


* Items
  LOOP AT gt_items INTO DATA(ls_src)
       WHERE po_number = gs_current_header-po_number.

    CLEAR ls_item.

    ls_item-ebeln = ls_src-po_number.
    ls_item-ebelp = ls_src-line_item.
    ls_item-matnr = ls_src-material.
    ls_item-maktx = ls_src-description.
    ls_item-werks = ls_src-plant.
    ls_item-menge = ls_src-quantity.
    ls_item-meins = ls_src-uom.
    ls_item-netpr = ls_src-price.
    ls_item-waers = ls_src-currency.
    ls_item-eindt = ls_src-delivery.

    APPEND ls_item TO lt_item.


  ENDLOOP.

  SORT lt_item BY ebelp.
  READ TABLE lt_item INTO DATA(ls_first_item) INDEX 1.
  IF sy-subrc = 0 AND ls_first_item-werks IS NOT INITIAL.
    ls_head-werks = ls_first_item-werks.
  ENDIF.

  DATA: lv_lines TYPE i.

  lv_lines = lines( lt_item ).

  IF lv_lines < 10.
    DO 10 - lv_lines TIMES.
      CLEAR ls_item.
      ls_item-matnr = ' '. " blank line
      APPEND ls_item TO lt_item.
    ENDDO.
  ENDIF.



  DATA: lv_fm_name TYPE rs38l_fnam,
        lv_form    TYPE tdsfname.

  CASE gv_form.

    WHEN 'A'.
      lv_form = 'YFG8_PO_FORM'.

    WHEN 'B'.
      lv_form = 'YFG8_PO_FORM2'.

    WHEN 'C'.
      lv_form = 'YFG8_PO_FORM3'.

  ENDCASE.



  DATA: ls_output_options TYPE ssfcompop.
  ls_output_options-tdnewid = 'X'. " Create a new spool to group purchase orders into one file.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = lv_form
    IMPORTING
      fm_name  = lv_fm_name.

  CALL FUNCTION lv_fm_name
    EXPORTING
      control_parameters = is_control        " get from form print_all_pos
      output_options     = ls_output_options " Configure printer output settings.
      im_po_head         = ls_head
    TABLES
      tab_items          = lt_item
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      others             = 5.

  IF sy-subrc <> 0.
    " err
  ENDIF.


ENDFORM.



FORM print_all_pos USING iv_type TYPE char4.
  DATA: ls_control TYPE ssfctrlop.
  DATA: lv_index   TYPE i,
        lv_total   TYPE i.

  lv_total = lines( gt_header ).
  lv_index = 0.

  LOOP AT gt_header INTO gs_current_header.
    lv_index = lv_index + 1.
    CLEAR ls_control.
    ls_control-no_dialog = 'X'.


    " ---
    IF lv_total = 1.
      " 1 po
      ls_control-no_open  = ' '.
      ls_control-no_close = ' '.
    ELSEIF lv_index = 1.
      " 1st po
      ls_control-no_open  = ' '.
      ls_control-no_close = 'X'.
    ELSEIF lv_index = lv_total.
      " last po
      ls_control-no_open  = 'X'.
      ls_control-no_close = ' '.
    ELSE.
      " mid po
      ls_control-no_open  = 'X'.
      ls_control-no_close = 'X'.
    ENDIF.
    " ------------------------------

    CASE iv_type.
      WHEN 'INT'.  gv_form = 'A'.
      WHEN 'EXT'.  gv_form = 'B'.
      WHEN 'VEND'. gv_form = 'C'.
    ENDCASE.

    PERFORM show_form USING ls_control.
  ENDLOOP.

  MESSAGE 'Complete!' TYPE 'S'.
ENDFORM.
