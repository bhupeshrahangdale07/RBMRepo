import { LightningElement, api, track, wire } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/noHeader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
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
    console.log('In cancel click Handler');
    // this[NavigationMixin.GenerateUrl]({
    //     type: 'standard__webPage',
    //     attributes: {
    //         url: '/apex/Recycle_Bin_Manager'
    //     }
    // });
    this.isLoading=true;
    window.location.assign('/apex/Recycle_Bin_Manager');
    this.isLoading=false;

}

restoreHandler(){
console.log('In restore Handler');
    restoreRecord({restoreData:this.recordForPreview, objName:this.objName})
    .then((result)=>{
        console.log('Result- '+result);
        window.location.assign('/'+result);
    }).catch((error)=>{
        console.log('Error- '+JSON.stringify(error));
    })
}

}