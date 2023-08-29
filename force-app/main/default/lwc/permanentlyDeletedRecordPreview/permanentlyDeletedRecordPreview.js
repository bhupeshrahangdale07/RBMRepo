import { LightningElement, api, track, wire } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/noHeader';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import showPreviewPage from '@salesforce/apex/permanentDeletedRecordPreviewController.showPreviewPage';

export default class PermanentlyDeletedRecordPreview extends NavigationMixin(LightningElement) {


   // recordIdFroPreview;
    error;
    @track recordForPreview;
    @api recId;
    objName;
    recName;

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
        console.log('recordForPreview>>'+JSON.stringify(result.lstWrpData));
        this.recordForPreview=result.lstWrpData;
        this.objName=result.objectName;
        this.recName=result.recordName;

    }).catch((error)=>{
        console.log('Error-->'+JSON.stringify(error));
    })
}

cancelHandler(){
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/apex/rbin__Recycle_Bin_Manager'
        }
    });

}

restoreHandler(){
    
}

}