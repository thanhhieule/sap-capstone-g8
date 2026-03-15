CLASS LCL_HANDLER DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR header
        RESULT result,
      get_instance_features FOR INSTANCE FEATURES
            IMPORTING keys REQUEST requested_features FOR header RESULT result.

          METHODS releasePO FOR MODIFY
            IMPORTING keys FOR ACTION header~releasePO RESULT result.

          METHODS unreleasePO FOR MODIFY
            IMPORTING keys FOR ACTION header~unreleasePO RESULT result.
ENDCLASS.

CLASS LCL_HANDLER IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD get_instance_features.
  ENDMETHOD.

  METHOD releasePO.
  ENDMETHOD.

  METHOD unreleasePO.
  ENDMETHOD.

ENDCLASS.
