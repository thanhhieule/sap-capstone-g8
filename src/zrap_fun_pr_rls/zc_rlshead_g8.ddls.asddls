  @AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLHEAD_G8'
define root view entity ZC_RLSHEAD_G8
  provider contract transactional_query
  as projection on ZI_RLSHEAD_G8
{
  key PrNo,
  DefineKey,
  Status,
  Purchaserequisitiontype,
  Plant,
  PurchasingGroup,
  Purchasingorganization,
  CancelReasonCode,
  CancelNote,
  MessageStandardtable,
  Criticality,
  Url,
  CreatedBy,
  CreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt,
  _Item : redirected to composition child ZC_RLSITEM_G8 
  
}
