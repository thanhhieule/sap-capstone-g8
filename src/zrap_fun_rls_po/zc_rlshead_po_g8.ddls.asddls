@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLHEAD_PO'
define root view entity  ZC_RLSHEAD_PO_G8
  provider contract transactional_query
  as projection on ZI_RLSHEAD_PO_G8
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
  CancelReasonCode,
  CancelNote,
  MessageStandardtable,
  Criticality,
  Url,
  CreatedBy,
  CreatedAt,
  LastChangedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  _Item : redirected to composition child ZC_RLSITEM_PO_G8
  
}
