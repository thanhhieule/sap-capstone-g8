@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLITEM_PO'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_RLSITEM_PO_G8
  as projection on ZI_RLSITEM_PO_G8
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
  UrlPR,
  _Header : redirected to parent ZC_RLSHEAD_PO_G8
  
}
