FORM get_company_name USING    U_COMPANY_CODE TYPE T001-BUKRS
                      CHANGING C_COMPANY_NAME TYPE T001-BUTXT.

  SELECT SINGLE BUTXT
    FROM T001
    INTO @C_COMPANY_NAME
    WHERE BUKRS = @U_COMPANY_CODE.

  IF sy-subrc <> 0.
    C_COMPANY_NAME = 'Unknown'.
  ENDIF.

ENDFORM.

FORM get_company_street USING    u_company_code TYPE t001-bukrs
                       CHANGING c_company_street TYPE adrc-street.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM t001
    WHERE bukrs = u_company_code.

  SELECT SINGLE street
    INTO c_company_street
    FROM adrc
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_company_street = 'Unknown'.
  ENDIF.

ENDFORM.

FORM get_company_city USING    u_bukrs TYPE t001-bukrs
                     CHANGING c_city TYPE adrc-city1.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM t001
    WHERE bukrs = u_bukrs.

  SELECT SINGLE city1
    INTO c_city
    FROM adrc
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_city = 'Unknown'.
  ENDIF.

ENDFORM.

FORM get_company_phone USING    u_bukrs TYPE t001-bukrs
                      CHANGING c_phone TYPE adr2-tel_number.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM t001
    WHERE bukrs = u_bukrs.

  SELECT SINGLE tel_number
    INTO c_phone
    FROM adr2
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_phone = 'N/A'.
  ENDIF.

ENDFORM.

FORM get_company_fax USING    u_bukrs TYPE t001-bukrs
                    CHANGING c_fax TYPE adr3-fax_number.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM t001
    WHERE bukrs = u_bukrs.

  SELECT SINGLE fax_number
    INTO c_fax
    FROM adr3
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_fax = 'N/A'.
  ENDIF.

ENDFORM.


FORM GET_VENDOR_NAME
USING    U_VENDOR_ID TYPE LFA1-LIFNR
CHANGING C_VENDOR_NAME TYPE LFA1-NAME1.

  SELECT SINGLE NAME1
    FROM LFA1
    INTO C_VENDOR_NAME
    WHERE LIFNR = U_VENDOR_ID.

  IF sy-subrc <> 0.
    C_VENDOR_NAME = 'Unknown Vendor'.
  ENDIF.

ENDFORM.

FORM get_vendor_street USING    u_lifnr TYPE lfa1-lifnr
                      CHANGING c_street TYPE adrc-street.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE street
    INTO c_street
    FROM adrc
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_street = 'Unknown'.
  ENDIF.

ENDFORM.

FORM get_vendor_city USING    u_lifnr TYPE lfa1-lifnr
                    CHANGING c_city TYPE adrc-city1.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE city1
    INTO c_city
    FROM adrc
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_city = 'Unknown'.
  ENDIF.

ENDFORM.

FORM get_vendor_phone USING    u_lifnr TYPE lfa1-lifnr
                     CHANGING c_phone TYPE adr2-tel_number.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE tel_number
    INTO c_phone
    FROM adr2
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_phone = 'N/A'.
  ENDIF.

ENDFORM.

FORM get_vendor_fax USING    u_lifnr TYPE lfa1-lifnr
                   CHANGING c_fax TYPE adr3-fax_number.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE fax_number
    INTO c_fax
    FROM adr3
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0.
    c_fax = 'N/A'.
  ENDIF.

ENDFORM.


FORM get_vendor_postal USING    u_lifnr TYPE lfa1-lifnr
                       CHANGING c_postal TYPE adrc-post_code1.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE post_code1
    INTO c_postal
    FROM adrc
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0 OR c_postal IS INITIAL.
    c_postal = 'N/A'.
  ENDIF.

ENDFORM.

FORM get_vendor_email USING    u_lifnr TYPE lfa1-lifnr
                      CHANGING c_email TYPE adr6-smtp_addr.

  DATA: lv_addr TYPE adrc-addrnumber.

  SELECT SINGLE adrnr
    INTO lv_addr
    FROM lfa1
    WHERE lifnr = u_lifnr.

  SELECT SINGLE smtp_addr
    INTO c_email
    FROM adr6
    WHERE addrnumber = lv_addr.

  IF sy-subrc <> 0 OR c_email IS INITIAL.
    c_email = 'N/A'.
  ENDIF.

ENDFORM.

FORM get_vendor_tax_code USING    u_lifnr TYPE lfa1-lifnr
                         CHANGING c_tax   TYPE lfa1-stenr.

  SELECT SINGLE stenr
    INTO c_tax
    FROM lfa1
    WHERE lifnr = u_lifnr.

  IF sy-subrc <> 0 OR c_tax IS INITIAL.
    c_tax = 'N/A'.
  ENDIF.

ENDFORM.
