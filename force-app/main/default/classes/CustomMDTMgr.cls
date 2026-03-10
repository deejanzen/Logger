/*
CustomMDTMgr.builder()
    .addMetadata('mdtName.mdtRecord', new Map<String, Object>{'is_active__c' => true})
    .build()
    .deploy();
*/
public with sharing class CustomMDTMgr {
    public Metadata.DeployContainer container { get; set; }
    public Metadata.DeployCallback callback { get; set; }

    public CustomMDTMgr(Metadata.DeployContainer container, Metadata.DeployCallback callback) {
        this.container = container;
        this.callback = callback;
    }

    public void deploy() {
        Metadata.Operations.enqueueDeployment(container, callback);
    }

    public static Builder builder() {
        return new Builder();
    }

    public class Builder {
        private CustomMDTMgr customMdtMgr;

        public Builder() {
           this.customMdtMgr = new CustomMDTMgr(new Metadata.DeployContainer(), null);
        }

        public Builder addMetadata(String fullname, Map<String, Object> fields) {
            Metadata.CustomMetadata record = new Metadata.CustomMetadata();
        
            record.fullName = fullname;
            record.values = new List<Metadata.CustomMetadataValue>();

            for (String fieldName : fields.keySet()) {
                Metadata.CustomMetadataValue val = new Metadata.CustomMetadataValue();
                val.field = fieldName;
                val.value = fields.get(fieldName);
                record.values.add(val);
            }
            
            this.customMdtMgr.container.addMetadata(record);

            return this;
        }

        public Builder addCallback(Metadata.DeployCallback callback) {
            this.customMdtMgr.callback = callback;
            return this;
        }

        public CustomMDTMgr build() {
            return this.customMdtMgr;
        }
    }
}