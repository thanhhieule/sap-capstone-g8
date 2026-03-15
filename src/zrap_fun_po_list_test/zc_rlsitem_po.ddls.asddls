@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLITEM_PO'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_RLSITEM_PO
  as projection on ZI_RLSITEM_PO
{
  key  Ebeln,
  key Ebelp,
  Banfn,
  Bnfpo,
  Matnr,
  Werks,
  @Semantics.quantity.unitOfMeasure: 'Meins'
  Menge,
  Meins,
  @Semantics.amount.currencyCode: 'Waers'
  Netpr,
  Waers,
  Eindt,
  Url,
  _Header : redirected to parent ZC_RLSHEAD_PO_TEST
  
}
