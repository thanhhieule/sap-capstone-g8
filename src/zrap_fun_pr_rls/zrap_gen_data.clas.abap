 CLASS zrap_gen_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS zrap_gen_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA: lt_reasons  TYPE STANDARD TABLE OF zpr_rejres_g8,
          ls_reason  TYPE zpr_rejres_g8.

    DELETE FROM zpr_att_g8.
    DELETE FROM zpr_list_g8.
    COMMIT WORK.

    out->write(
      |Inserted { lines( lt_reasons ) } PR approval reject reasons|
    ).

  ENDMETHOD.

ENDCLASS.

