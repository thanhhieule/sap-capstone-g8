@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Head release'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RLSHEAD_PO_G8
  as select from zpo_rlshead_g8 as header
  composition [0..*] of ZI_RLSITEM_PO_G8  as _Item
{
  key ebeln  as Ebeln,
  define_key as DefineKey,
  status as Status,
  bukrs as Bukrs,
  lifnr as Lifnr,
  ekorg as Ekorg,
  ekgrp as Ekgrp,
  waers as Waers,
  @Consumption.filter.selectionType: #INTERVAL
  erdat as Erdat,
  cancel_reason_code as CancelReasonCode,
  cancel_note as CancelNote,
  message_standardtable as MessageStandardtable,
  criticality as Criticality,
  url    as Url,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Consumption.filter.selectionType: #INTERVAL
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  @Consumption.filter.selectionType: #INTERVAL
  local_last_changed_at as LocalLastChangedAt,
  @Consumption.filter.selectionType: #INTERVAL
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _Item
}
