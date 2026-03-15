 @AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_RLDITEM_G8
  as projection on ZI_RLDITEM_G8
{
  key PrNo,
  key PrItem,
  Purchaserequisitiontype,
  Purreqndescription,
  Material,
  @Semantics.quantity.unitOfMeasure: 'Unit'
  QuantityReq,
  Unit,
  Purchaserequisitionitemtext,
  Accountassignmentcategory,
  @Semantics.amount.currencyCode: 'Purreqnitemcurrency'
  Purchaserequisitionprice,
  @Semantics.amount.currencyCode: 'Purreqnitemcurrency'
  Netpr,
  Purreqnitemcurrency,
  Materialgroup,
  Plant,
  PurchasingGroup,
  Purchasingorganization,
  DeliveryDate,
  Url,
  _Header : redirected to parent ZC_RLDHEAD_G8
 
}
