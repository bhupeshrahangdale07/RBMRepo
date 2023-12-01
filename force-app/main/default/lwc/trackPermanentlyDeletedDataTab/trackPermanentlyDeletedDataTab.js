/*
// --------------------------------------------------------------------------------------------------------------

// This component is used for Track Permanently Deleted Data Tab.
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         7/18/2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from "lightning/confirm";
import LightningAlert from 'lightning/alert';
import getAllObjectName from '@salesforce/apex/trackPermanentDeletedDataCtrl.getAllObjectName';
import saveTrackingObject from '@salesforce/apex/trackPermanentDeletedDataCtrl.saveTrackingObject';
import fetchAllRecords from '@salesforce/apex/trackPermanentDeletedDataCtrl.fetchAllRecords';
import deleteObject from '@salesforce/apex/trackPermanentDeletedDataCtrl.deleteObject';
import AddNewButton from '@salesforce/label/c.AddNewButton';
import Save_rbin from '@salesforce/label/c.Save_rbin';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {

    @track getAllObjectList = [];
    @track allObjectListForIndex = [];
    @track objectRecordList = [];
    @track deleteRecordIds;
    @track newObjectList = [];
    @track getAllRecords;
    isSaveBtnVisible;
    recordExist = false;
    isLoading = false;

    label = {
        AddNewButton,
        Save_rbin,
    };

    // fetch all the exsisting records 
    @wire(fetchAllRecords)
    wireAllRecords(result) {
        this.isLoading = true;
        this.getAllRecords = result;
        if (result.data) {
            this.objectRecordList = this.getAllRecords.data;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.log('Error-' + error);
            this.records = undefined;
            this.isLoading = false;
        }
    }

    // fetch all the options for selection
    @wire(getAllObjectName)
    wireObjectNames(result) {
        if (result.data) {
            this.getAllObjectList = [];
            this.allObjectListForIndex = [];
            for (let key in result.data) {
                if (!this.objectRecordList.some(obj => obj.Name === key)) {
                    this.getAllObjectList.push({ label : result.data[key], value : key });
                }
                this.allObjectListForIndex.push({ label : key, value: key });
            }
            this.isLoading = false;
        } else if (result.error) {
            console.log('Error-' + error);
            this.isLoading = false;
        }
    }

    // a function to be called on option change 
    async handleChange(event) {
        this.isSaveBtnVisible = true;
        var selectedValue = event.detail.value;
        var key = event.currentTarget.dataset.id;

        const objValue = this.newObjectList.findIndex((obj => obj.Id == key));

        this.newObjectList[objValue].Name = selectedValue;

        console.log('New selected object List-', JSON.stringify(this.newObjectList));
        const idxValue = this.getAllObjectList.findIndex((objct => objct.value === selectedValue));
        this.getAllObjectList.splice(idxValue, 1);
    }

    //the function to be called on add button click used to add new row into a datatble
    addRow() {
        this.isSaveBtnVisible = true;
        let randomId = Math.random() * 16;
        let myNewElement = { Id: randomId, Name: null };
        this.objectRecordList = [...this.objectRecordList, myNewElement];
        this.newObjectList.push({ Id: randomId, Name: null });
        console.log('Object list -' + JSON.stringify(this.objectRecordList));
        console.log('New Arr after adding row-' + JSON.stringify(this.newObjectList));

    }

    //the function to be called on save button click used to save custom setting records
    async onsaveclickHandler() {

        this.isLoading = true;
        saveTrackingObject({ objNameList : this.newObjectList })
            .then(async (result) => {
                refreshApex(this.wireAllRecords);
                this.dispatchEvent(new RefreshEvent());
                this.isLoading = false;
                await LightningAlert.open({
                    message: result,
                    theme: 'success', // a green theme intended for success states
                    label: 'Success!', // this is the header text
                });
                this.newObjectList = [];
                this.wireObjectNames;
                this.isSaveBtnVisible = false;
                return refreshApex(this.getAllRecords);

            })
            .catch(async (error) => {
                this.isLoading = false;
                if (error) {
                    const errorMessage = JSON.stringify(error.body.message);
                    const startIndex = errorMessage.indexOf("first error");
                    const extractedErrorMessage = errorMessage.substring(startIndex);
                    const message = extractedErrorMessage.replace("first error: FIELD_INTEGRITY_EXCEPTION, ", "");// it will show the message only
                    console.log('Error result-' + message);
                    await LightningAlert.open({
                        message: message,
                        theme: 'error', // a red theme intended for error states
                        label: 'Error!', // this is the header text
                    });
                }
                this.isLoading = false;
            })


    }

    // the will be called on the delete button click
    async handleActionDelete(event) {
        this.deleteRecordIds = event.target.dataset.id;

        // it will pop up an conformation box for user whether he want to delete a record or not
        const result = await LightningConfirm.open({
            message: 'Are you sure to delete this record?',
            theme: 'warning',
            variant: 'header',
            label: 'Delete a record',

        });
        // if he want to delete a record
        if (result) {
            this.isLoading = true;
            if (!isNaN(this.deleteRecordIds)) {
                this.objectRecordList.splice(this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds), 1);
                var foundObject = this.newObjectList.find(obj => obj.Id == this.deleteRecordIds);
                if (foundObject && foundObject.Name !== null) {
                    var nameValue = foundObject.Name;
                    console.log('Name value:', nameValue);
                }
                var indexValueforDeleteObj = this.allObjectListForIndex.findIndex(idx => idx.value == nameValue);
                if (nameValue != null) {
                    this.getAllObjectList.splice(indexValueforDeleteObj, 0, { label: nameValue, value: nameValue });
                }
                this.newObjectList.splice(this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds), 1);

                this.isLoading = false;
                return refreshApex(this.getAllRecords);
            } else {
                deleteObject({ removeObjectIds: this.deleteRecordIds })
                    .then(async (res) => {
                        this.isLoading = false;
                        await LightningAlert.open({
                            message: res,
                            theme: 'success',
                            label: 'Record Deleted', // this is the header text
                        });
                        var deletedValue = this.objectRecordList[this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds)].Name;
                        var indexValueforDeleteObj = this.allObjectListForIndex.findIndex(idx => idx.value == deletedValue);
                        this.getAllObjectList.splice(indexValueforDeleteObj, 0, { label: deletedValue, value: deletedValue });
                        return refreshApex(this.getAllRecords);

                    })
                    .catch((error) => {
                        console.log('error on delete-', error);
                    })
            }
        } else {

        }
        this.isSaveBtnVisible = false;
    }
    updateRecordView() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 3000);
    }
}