@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Detail CDS file report'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define  view entity ZC_LIST_G8
  as projection on ZI_LIST_G8
{
  key AttachmentUuid,
  key RecNumber,
  key ItemUuid,

      Status,

      PrNo,
      PrItem,
      PurchaseRequisitionType,
      PurReqnDescription,

      Material,
      @Semantics.quantity.unitOfMeasure : 'Unit'
      QuantityReq,
      Unit,

      PurchaseRequisitionItemText,
      AccountAssignmentCategory,

      @Semantics.amount.currencyCode : 'PurReqnItemCurrency'
      PurchaseRequisitionPrice,
      PurReqnItemCurrency,

      MaterialGroup,

      Plant,
      PurchasingGroup,
      PurchasingOrganization,

      DeliveryDate,

      MessageStandardtable,
      Criticality,
      Url,

      _Header : redirected to parent ZC_ATT_G8
}
