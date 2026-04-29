
*SELECT SINGLE BUTXT FROM T001
*  INTO @GD_COMPANY_NAME
*  WHERE BUKRS = @IM_PO_HEAD-BUKRS.

* get company name
PERFORM GET_COMPANY_NAME using IM_PO_HEAD-BUKRS
                         changing GD_COMPANY_NAME.
PERFORM GET_COMPANY_STREET using IM_PO_HEAD-BUKRS
                         changing GD_COMPANY_STREET.
PERFORM GET_COMPANY_CITY using IM_PO_HEAD-BUKRS
                         changing GD_COMPANY_CITY.
PERFORM GET_COMPANY_PHONE using IM_PO_HEAD-BUKRS
                         changing GD_COMPANY_PHONE.
PERFORM GET_COMPANY_FAX  using IM_PO_HEAD-BUKRS
                         changing GD_COMPANY_FAX.

PERFORM GET_VENDOR_NAME  USING IM_PO_HEAD-LIFNR
                          CHANGING GD_VENDOR_NAME.

PERFORM get_vendor_street USING im_po_head-lifnr CHANGING gd_vendor_street.
PERFORM get_vendor_city   USING im_po_head-lifnr CHANGING gd_vendor_city.
PERFORM get_vendor_phone  USING im_po_head-lifnr CHANGING gd_vendor_phone.
PERFORM get_vendor_fax    USING im_po_head-lifnr CHANGING gd_vendor_fax.

