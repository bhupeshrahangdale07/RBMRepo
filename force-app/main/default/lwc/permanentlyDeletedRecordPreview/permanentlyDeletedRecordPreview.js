/**
 * @description This component is used preview of the record.
 * Version#     Date                   Author                 Description
 * 1.0         24/8/2023          Kandisa Technologies     Initial Version 1.0
 */

import {LightningElement, api, track} from "lwc";
import HideLightningHeader from "@salesforce/resourceUrl/noHeader";
import LightningAlert from "lightning/alert";
import {loadStyle} from "lightning/platformResourceLoader";
import {NavigationMixin} from "lightning/navigation";
import restoreRecord from
    "@salesforce/apex/permanentDeletedRecordPreviewController.restoreRecord";
import showPreviewPage from
    "@salesforce/apex/permanentDeletedRecordPreviewController.showPreviewPage";

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
        }).
            catch((error) => {

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

    recordPreview () {

        this.isLoading = true;
        showPreviewPage({"recordId": this.recId}).then((result) => {

            this.recordForPreview = result.lstWrpData;
            this.objName = result.objectName;
            this.recName = result.recordName;
            this.isLoading = false;

        }).
            catch(async (error) => {

                await LightningAlert.open({
                    "label": "Error",
                    "message": "Failed to load a record -" + error,
                    "theme": "error"
                });

            });

    }

    // This function get called on restore click, it will restore a record
    restoreHandler () {

        restoreRecord({"recordId": this.recId}).then(async (result) => {

            this.isLoading = true;
            if (result != null) {

                window.location.assign("/" + result);

            } else {

                await LightningAlert.open({
                    "label": "Error",
                    "message": "Failed to restore a record",
                    "theme": "error"
                });

            }
            this.isLoading = false;

        }).
            catch(async (error) => {

                this.isLoading = true;
                await LightningAlert.open({
                    "label": "Error",
                    "message": error.body.message,
                    "theme": "error"
                });
                this.isLoading = false;

            });

    }

}
