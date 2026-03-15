@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Head release'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RLSHEAD_PO
  as select from zpo_head_g8_test as header
  composition [0..*] of ZI_RLSITEM_PO  as _Item
{
  key ebeln  as Ebeln,
  define_key as DefineKey,
  status as Status,
  bukrs as Bukrs,
  lifnr as Lifnr,
  ekorg as Ekorg,
  ekgrp as Ekgrp,
  waers as Waers,
  erdat as Erdat,
  message_standardtable as MessageStandardtable,
  criticality as Criticality,
  url    as Url,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _Item
}
