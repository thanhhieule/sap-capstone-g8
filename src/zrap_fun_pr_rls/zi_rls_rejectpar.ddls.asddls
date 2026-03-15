 @EndUserText.label: 'Reject Booking Parameters'
define root abstract entity ZI_RLS_RejectPar {
  @EndUserText.label: 'Reject reason'
  @Consumption.valueHelpDefinition: [
    { entity: { name: 'ZI_RLS_VH_RejectPar', element: 'CancelReasonCode' }, useForValidation: true }
  ]
  CancelReasonCode : abap.char(2);
}
