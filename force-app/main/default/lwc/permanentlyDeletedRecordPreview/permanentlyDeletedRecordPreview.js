/**
 * @description This component is used preview of the record.
 * Version#     Date                   Author                 Description
 * 1.0         24/8/2023          Kandisa Technologies     Initial Version 1.0
 */

import {LightningElement, api, track} from "lwc";
import HideLightningHeader from "@salesforce/resourceUrl/noHeader";
import {loadStyle} from "lightning/platformResourceLoader";
import {NavigationMixin} from "lightning/navigation";
import LightningAlert from "lightning/alert";
import showPreviewPage from
    "@salesforce/apex/permanentDeletedRecordPreviewController.showPreviewPage";
import restoreRecord from
    "@salesforce/apex/permanentDeletedRecordPreviewController.restoreRecord";

export default class PermanentlyDeletedRecordPreview extends NavigationMixin(LightningElement) {

    // RecordIdFroPreview;
    error;

    @track recordForPreview;

    @api recId;

    objName;

    recName;

    isLoading = false;

    baseURL;

    connectedCallback () {

        Promise.all([loadStyle(this, HideLightningHeader)]).then(() => {
            // CSS loaded
        }).catch((error) => {

            this.error = error;
            this.showLoading = false;
            this.showToast(
                "Something Went Wrong in Loading 'noHeader' .",
                error,
                "error",
                "dismissable");
                
        });
        this.recordPreview();

    }
// This function get called for record preview
recordPreview(){
    this.isLoading = true;
    showPreviewPage({recordId:this.recId})
    .then((result)=>{
        this.recordForPreview=result.lstWrpData;
        this.objName=result.objectName;
        this.recName=result.recordName;
        this.isLoading = false;
    }).catch((error)=>{
        console.log('Error-->'+JSON.stringify(error));
    })
}

// A function to be called on cancel button click 
// cancelHandler(){
//     this.isLoading = true;
//      window.location.assign('/lightning/n/rbin__Recycle_Bin_Manager');
//      this.isLoading = false;
// }

// this function get called on restore click, it will restore a record
restoreHandler(){
    restoreRecord({recordId:this.recId})
    .then(async(result)=>{
        this.isLoading = true;
        if(result != null){

            console.log('Result id-- '+result);
            window.location.assign('/'+result);
        }else {
            await  LightningAlert.open({
                message: 'Failed to restore a record',
                theme: 'error', 
                label: 'Error', 
            });
        }
            this.isLoading = false;
    }).catch(async(error)=>{
        this.isLoading = true;
        await  LightningAlert.open({
            message: error.body.message,
            theme: 'error', 
            label: 'Error', 
        });
        this.isLoading = false;
        console.log('Error- '+JSON.stringify(error));
    })
}

}