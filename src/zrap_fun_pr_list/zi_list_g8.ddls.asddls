@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Detail CDS file import'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_LIST_G8
  as select from  zpr_list_g8
  association to parent ZI_ATT_G8 as _Header
    on $projection.AttachmentUuid = _Header.AttachmentUUID
{
  key attachment_uuid               as AttachmentUuid,
  key rec_number                    as RecNumber,
  key item_uuid                     as ItemUuid,

      status                         as Status,

      pr_no                          as PrNo,
      pr_item                        as PrItem,
      purchaserequisitiontype        as PurchaseRequisitionType,
      purreqndescription             as PurReqnDescription,

      material                       as Material,
      @Semantics.quantity.unitOfMeasure : 'Unit'
      quantity_req                   as QuantityReq,
      unit                           as Unit,

      purchaserequisitionitemtext    as PurchaseRequisitionItemText,
      accountassignmentcategory      as AccountAssignmentCategory,

      @Semantics.amount.currencyCode : 'PurReqnItemCurrency'
      purchaserequisitionprice       as PurchaseRequisitionPrice,
      purreqnitemcurrency            as PurReqnItemCurrency,

      materialgroup                  as MaterialGroup,

      plant                          as Plant,
      purchasing_group               as PurchasingGroup,
      purchasingorganization         as PurchasingOrganization,

      delivery_date                  as DeliveryDate,

      message_standardtable          as MessageStandardtable,
      criticality                    as Criticality,
      url                            as Url,

      _Header
}
