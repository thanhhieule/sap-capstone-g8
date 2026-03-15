 @AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: '##GENERATED #'
define view entity ZI_RLSITEM_G8
  as select from zpr_rlsitem_g8 as item
  association to parent ZI_RLSHEAD_G8 as _Header
    on $projection.PrNo = _Header.PrNo
{
  key pr_no as PrNo,
  key pr_item as PrItem,
  purchaserequisitiontype as Purchaserequisitiontype,
  purreqndescription as Purreqndescription,
  material as Material,
  @Semantics.quantity.unitOfMeasure: 'Unit'
  quantity_req as QuantityReq,
  unit as Unit,
  purchaserequisitionitemtext as Purchaserequisitionitemtext,
  accountassignmentcategory as Accountassignmentcategory,
  @Semantics.amount.currencyCode: 'Purreqnitemcurrency'
  purchaserequisitionprice as Purchaserequisitionprice,
  @Semantics.amount.currencyCode: 'Purreqnitemcurrency'
  netpr as Netpr,
  purreqnitemcurrency as Purreqnitemcurrency,
  materialgroup as Materialgroup,
  plant as Plant,
  purchasing_group as PurchasingGroup,
  purchasingorganization as Purchasingorganization,
  delivery_date as DeliveryDate,
  url  as Url,
  _Header
}
