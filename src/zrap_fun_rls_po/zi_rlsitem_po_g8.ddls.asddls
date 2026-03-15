@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Item release'
@Metadata.ignorePropagatedAnnotations: true
define view  entity ZI_RLSITEM_PO_G8
  as select from zpo_rlsitem_g8 as item
  association to  parent ZI_RLSHEAD_PO_G8 as _Header
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
  url_pr as UrlPR,
  _Header
}
