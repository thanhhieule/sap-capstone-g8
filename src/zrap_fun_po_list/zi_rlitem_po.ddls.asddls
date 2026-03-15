@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Item release'
@Metadata.ignorePropagatedAnnotations: true
define view  entity ZI_RLITEM_PO
  as select from zpo_item_g8 as item
  association to  parent ZI_RLHEAD_PO as _Header
    on $projection.Ebeln = _Header.Ebeln
{
  key ebeln as Ebeln,
  key ebelp as Ebelp,
  banfn as Banfn,
  bnfpo as Bnfpo,
  matnr as Matnr,
  werks as Werks,
  @Semantics.quantity.unitOfMeasure: 'Meins'
  menge as Menge,
  meins as Meins,
  @Semantics.amount.currencyCode: 'Waers'
  netpr as Netpr,
  waers as Waers,
  eindt as Eindt,
  url   as Url,
  _Header
}
