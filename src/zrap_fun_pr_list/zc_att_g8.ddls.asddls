@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZI_ATT_G8'
define root view entity ZC_ATT_G8
  provider contract  transactional_query
  as projection on ZI_ATT_G8
{
key AttachmentUUID,
      @Semantics.largeObject: {
            mimeType: 'Mimetype',
            fileName: 'FileName',
            acceptableMimeTypes : ['text/csv'],
            contentDispositionPreference: #ATTACHMENT
          }
      Attachment,
      @Semantics.mimeType: true
      Mimetype,
      FileName,
      TotalCount,
      SuccessCount,
      WarningCount,
      ErrorCount,
      @ObjectModel.text.element: [ 'CreatedByDescription' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessUserVH', element: 'UserID'} }]
      CreatedBy,
      @Consumption.filter.selectionType: #INTERVAL
      CreatedAt,
      @Consumption.filter.selectionType: #INTERVAL
      LocalCreateAt,
      @ObjectModel.text.element: [ 'LastUpdatedByDescription' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessUserVH', element: 'UserID'} }]
      LastUpdatedBy,
      @Consumption.filter.selectionType: #INTERVAL
      LastUpdatedAt,
      @Consumption.filter.selectionType: #INTERVAL
      LocalLastUpdatedAt,
      @UI.hidden: true
      @Consumption.filter.hidden: true
      _UserCreatedBy.UserDescription as CreatedByDescription,
      @UI.hidden: true
      @Consumption.filter.hidden: true
      _UserUpdatedBy.UserDescription as LastUpdatedByDescription,
     _Item : redirected to composition child ZC_LIST_G8
  
  
}
