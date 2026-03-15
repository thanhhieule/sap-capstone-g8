@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLHEAD_PO'
define root view entity  ZC_RLHEAD_PO
  provider contract transactional_query
  as projection on ZI_RLHEAD_PO
{
  key Ebeln,
  DefineKey,
  Status,
  Bukrs,
  Lifnr,
  Ekorg,
  Ekgrp,
  Waers,
  Erdat,
  MessageStandardtable,
  Criticality,
  Url,
  CreatedBy,
  CreatedAt,
  LastChangedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  _Item : redirected to composition child ZC_RLITEM_PO
  
}
