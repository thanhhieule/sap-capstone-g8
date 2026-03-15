CLASS  ztest_xxx DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun. " Để test trên ADT (Eclipse)
    METHODS call_report.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS ztest_xxx IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " Gọi method để test
    me->call_report( ).
    out->write( 'Đã gọi xong report.' ).
  ENDMETHOD.

  METHOD call_report.

    SUBMIT ZPG_MAIL_01.
  ENDMETHOD.

ENDCLASS.
