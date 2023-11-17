import { LightningElement, api, track, wire } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/noHeader';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
import showPreviewPage from '@salesforce/apex/permanentDeletedRecordPreviewController.showPreviewPage';
import restoreRecord from '@salesforce/apex/permanentDeletedRecordPreviewController.restoreRecord';

export default class PermanentlyDeletedRecordPreview extends NavigationMixin(LightningElement) {


   // recordIdFroPreview;
    error;
    @track recordForPreview;
    @api recId;
    objName;
    recName;
    isLoading;
    baseURL;

    connectedCallback(){
        console.log('RecId>>'+this.recId);
        Promise.all([loadStyle(this, HideLightningHeader)])
        .then(() => {
            // CSS loaded
        }).catch(error => {
            this.error = error;
            this.showLoading = false;
            console.log('error-->', error);
            this.showToast("Something Went Wrong in Loading 'noHeader' .",error,'error','dismissable');
        });
        this.recordPreview();
      
}

recordPreview(){
    
    showPreviewPage({recordId:this.recId})
    .then((result)=>{
        console.log('recordForPreview>> '+JSON.stringify(result.lstWrpData));
        this.recordForPreview=result.lstWrpData;
        this.objName=result.objectName;
        this.recName=result.recordName;

    }).catch((error)=>{
        console.log('Error-->'+JSON.stringify(error));
    })
}

cancelHandler(){
     window.location.assign('/lightning/n/rbin__Recycle_Bin_Manager');
     
}

restoreHandler(){
    console.log('In restore Handler');
    restoreRecord({recordId:this.recId})
    .then(async(result)=>{
        console.log('Result id- '+result.recordId);
        if(result.recordId != null){
            window.location.assign('/'+result.recordId);
        }else {
            await  LightningAlert.open({
                message: result.errorMessage,
                theme: 'error', 
                label: 'Error', 
            });
        }
        
    }).catch(async(error)=>{
        await  LightningAlert.open({
            message: 'Failed to restore a record!!',
            theme: 'error', 
            label: 'Error', 
        });
        console.log('Error- '+JSON.stringify(error));
    })
}

}