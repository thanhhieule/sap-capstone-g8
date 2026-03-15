  @AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_RLHEAD_G8'
define root view entity ZC_RLDHEAD_G8
  provider contract transactional_query
  as projection on ZI_RLDHEAD_G8
{
  key PrNo,
  DefineKey,
  Status,
  PoNo,
  Lifnr,
  Purchaserequisitiontype,
  Plant,
  PurchasingGroup,
  Purchasingorganization,
  MessageStandardtable,
  Criticality,
  Url,
  CreatedBy,
  CreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt,
  _Item : redirected to composition child ZC_RLDITEM_G8 
  
}
