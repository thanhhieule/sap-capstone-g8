 @AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_RLSITEM_G8
  as projection on ZI_RLSITEM_G8
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
  Purreqnitemcurrency,
  Materialgroup,
  Plant,
  PurchasingGroup,
  Purchasingorganization,
  DeliveryDate,
  Url,
  _Header : redirected to parent ZC_RLSHEAD_G8
 
}
