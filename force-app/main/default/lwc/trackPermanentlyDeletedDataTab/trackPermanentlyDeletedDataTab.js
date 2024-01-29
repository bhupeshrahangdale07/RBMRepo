
/**
 * @description This component is used for Track Permanently Deleted Data Tab.
 * Version#     Date                   Author                 Description
 * 1.0         7/18/2023          Kandisa Technologies     Initial Version 1.0
 */
import AddNewButton from "@salesforce/label/c.AddNewButton";
import deleteObject from
    "@salesforce/apex/trackPermanentDeletedDataCtrl.deleteObject";
import fetchAllRecords from
    "@salesforce/apex/trackPermanentDeletedDataCtrl.fetchAllRecords";
import getAllObjectName from
    "@salesforce/apex/trackPermanentDeletedDataCtrl.getAllObjectName";
import LightningAlert from "lightning/alert";
import LightningConfirm from "lightning/confirm";
import {LightningElement, track, wire} from "lwc";
import {RefreshEvent} from "lightning/refresh";
import {refreshApex} from "@salesforce/apex";
import saveRbin from "@salesforce/label/c.Save_rbin";
import saveTrackingObject from
    "@salesforce/apex/trackPermanentDeletedDataCtrl.saveTrackingObject";

export default class TrackPermanentlyDeletedDataTab extends LightningElement {

    @track getAllObjectList = [];

    @track allObjectListForIndex = [];

    @track objectRecordList = [];

    @track deleteRecordIds;

    @track newObjectList = [];

    @track getAllRecords;

    selectedopvalue = "";

    isSaveBtnVisible;

    isAddNewdisabled = false;

    isLoading = false;

    @track AlloptionArry2 = [];

    @track isValid;

    label = {
        AddNewButton,
        saveRbin
    };

    // Fetch all the existing records
    @wire(fetchAllRecords)
    wireAllRecords (result) {

        this.isLoading = true;
        this.getAllRecords = result;
        if (result.data) {

            const arr = [...this.getAllRecords.data],
                mainArr = [];
            arr.forEach((element) => {

                const myNewElement = {

                    "Id": element.Id,
                    "Name": element.Name,
                    "option1Array": [...this.getAllObjectList],
                    "rbin__Label__c": element.rbin__Label__c,
                    "selectedValue": element.Name
                };

                mainArr.push(myNewElement);

            });

            this.objectRecordList = [...mainArr];
            this.error = undefined;
            this.isLoading = false;

        } else if (result.error) {

            this.records = undefined;
            this.isLoading = false;

        }

    }

    // Fetch all the options for selection
    @wire(getAllObjectName)
    wireObjectNames (result) {

        if (result.data) {

            for (let key in result.data) {

                this.AlloptionArry2.push({
                    "label": result.data[key],
                    "value": key
                });
                if (!this.objectRecordList.some(obj => {

                    obj.Name === key;

                })) {

                    this.getAllObjectList.push({
                        "label": result.data[key],
                        "value": key
                    });

                }
                this.allObjectListForIndex.push({
                    "label": key,
                    "value": key
                });

            }
            this.getAllObjectList.sort((val1, val2) => {
                // Use localeCompare for case-insensitive sorting
                return val1.label.localeCompare(val2.label);

            });
            this.isLoading = false;

        } else if (result.error) {

            this.isLoading = false;

        }

    }

    // A function to be called on option change
    handleChange (event) {

        const keyId = event.currentTarget.dataset.id,
            selectedValue = event.detail.value;
        this.isSaveBtnVisible = true;
        this.selectedopvalue = selectedValue;
        const currtArry = this.objectRecordList.find((ele) => ele.Id == keyId),
            oldValue = currtArry.selectedValue,
        currentRecOption = currtArry.option1Array.find((ele) => ele.value == oldValue);
            currtArry.selectedValue = event.detail.value;
        this.objectRecordList.forEach((element) => {

            const newArr = [];
            if (element.Id != keyId) {

                element.option1Array.forEach((ele) => {

                    if (ele.value !== event.detail.value) {

                        newArr.push({
                            "label": ele.label,
                            "value": ele.value
                        });
                    }

                });
                if (oldValue != "") {

                    newArr.push({
                        "label": currentRecOption.label,
                        "value": currentRecOption.value
                    });
                }

                newArr.sort((val1, val2) => {

                    // Use localeCompare for case-insensitive sorting
                    return val1.label.localeCompare(val2.label);

                });

                element.option1Array = newArr;  
            }

        });

        const objValue = this.newObjectList.findIndex((obj => {obj.Id == keyId; }));
        this.newObjectList[objValue].Name = selectedValue;
        this.customValidityCheck();
        this.isAddNewdisabled = false;

    }

    // The function to be called on add button click used to add new row into a datatable
    async addRow () {

        const num10 = 10,
            num16 = 16,
            numMinus1 = -1;
        if (this.objectRecordList.length < num10) {

            this.isSaveBtnVisible = true;
            const randomId = Math.random() * num16,
                valueArr = [],
                myNewElement = {

                    "Id": randomId,
                    "Name": null,
                    "option1Array": [],
                    "rbin__Label__c": null,
                    "selectedValue": ""
                },
                newOptionsArr = [];
            if (this.objectRecordList) {

                this.objectRecordList.forEach((element) => {

                    valueArr.push(element.selectedValue);

                });

            }
            this.getAllObjectList.forEach((element) => {

                if (element.value !== this.selectedopvalue && (valueArr.indexOf(element.value) === numMinus1)) {

                    newOptionsArr.push({"label": element.label,
                        "value": element.value});
                }

            });
            myNewElement.option1Array = newOptionsArr;
            this.objectRecordList = [...this.objectRecordList, myNewElement];
            this.newObjectList.push({"Id": randomId,
                        "Name": null});

            this.isAddNewdisabled = true;
        } 
        else {

            await LightningAlert.open({

                "message": 'You can select only up to 10 records',
                "theme": 'warning', // A red theme intended for error states
                "label": 'Warning!' // This is the header text

            });

        }

    }

    // The function to be called on save button click used to save custom setting records
    async onsaveclickHandler () {

        this.customValidityCheck();
        if (this.isValid) {

            this.newObjectList = this.newObjectList.filter(item => item.Name !== null);
            this.isLoading = true;
            saveTrackingObject({ objNameList: this.newObjectList })
                .then(async (result) => {

                    refreshApex(this.wireAllRecords);
                    this.dispatchEvent(new RefreshEvent());
                    this.isLoading = false;
                    await LightningAlert.open({

                        message: result,
                        theme: 'success', // a green theme intended for success states
                        label: 'Success!', // this is the header text

                    });
                    for (let key of this.newObjectList) {

                        this.getAllObjectList = this.getAllObjectList.filter(itm => itm.value !== key.Name);

                    }
                    this.newObjectList = [];

                    this.isSaveBtnVisible = false;
                    refreshApex(this.getAllRecords);

                })
                .catch(async (error) => {

                    this.isLoading = false;
                    if (error) {

                        const errorMessage = JSON.stringify(error.body.message);
                        const startIndex = errorMessage.indexOf("first error");
                        const extractedErrorMessage = errorMessage.substring(startIndex);
                        const message = extractedErrorMessage.replace("first error: FIELD_INTEGRITY_EXCEPTION, ", "");// it will show the message only
                        await LightningAlert.open({
                            message: message,
                            theme: 'error', // a red theme intended for error states
                            label: 'Error!', // this is the header text
                        });

                    }
                    this.isLoading = false;
                })

        } else {

            console.log('In else block');

        }

    }

    // the will be called on the delete button click
    async handleActionDelete (event) {

        this.deleteRecordIds = event.target.dataset.id;

        // it will pop up a confirmation box for the user whether he wants to delete a record or not
        const result = await LightningConfirm.open({
            message: 'Are you sure, you want to delete this record?',
            theme: 'warning',
            variant: 'header',
            label: 'Delete confirmation!',
        });
        // if he wants to delete a record
        if (result) {

            this.isLoading = true;
            if (!isNaN(this.deleteRecordIds)) {

                this.selectedopvalue = "";
                const currentRecArr = this.objectRecordList.find((ele) => ele.Id == this.deleteRecordIds);
                const currentValue = currentRecArr.selectedValue;
                if (currentValue != "") {

                    this.objectRecordList.forEach((element) => {

                        if (element.Id != currentRecArr.Id) {

                            if (element.selectedValue != currentValue) {

                                const currntValueIndx = element.option1Array.findIndex((opt) => opt.value == currentValue);
                                if (currntValueIndx == -1) {

                                    const optArr = this.getAllObjectList.find((ele) => ele.value == currentValue);
                                    element.option1Array.push({ label: optArr.label, value: optArr.value });
                                    element.option1Array.sort((a, b) => {

                                        // Use localeCompare for case-insensitive sorting
                                        return a.label.localeCompare(b.label);

                                    });

                                }

                            }

                        }

                    })

                }
                this.objectRecordList.splice(this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds), 1);

                this.newObjectList.splice(this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds), 1);

                this.isAddNewdisabled = false;
                this.customValidityCheck();
                if (this.newObjectList.length == 0) {

                    this.isSaveBtnVisible = false;
                    this.isAddNewdisabled = false;

                }
                this.isLoading = false;
                refreshApex(this.getAllRecords);
            } else {

                deleteObject({ removeObjectIds: this.deleteRecordIds })
                    .then(async (res) => {

                        this.isLoading = false;
                        await LightningAlert.open({
                            message: res,
                            theme: 'success',
                            label: 'Success!', // this is the header text

                        });
                        var deletedValue = this.objectRecordList[this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds)].Name;
                        var indexValueforDeleteObj = this.allObjectListForIndex.findIndex(idx => idx.value == deletedValue);
                        const currOptArr = this.AlloptionArry2.find((ele) => ele.value == deletedValue);
                        this.getAllObjectList.splice(indexValueforDeleteObj, 0, { label: currOptArr.label, value: currOptArr.value });
                        refreshApex(this.getAllRecords);
                        this.newObjectList = [];
                        this.isSaveBtnVisible = false;
                    })
                    .catch((error) => {

                        console.log('error on delete-', JSON.stringify(error));

                    })
                this.isAddNewdisabled = false;
            }
        } else {

        }
        if (this.objectRecordList.length == 0) {

            this.isSaveBtnVisible = false;
            this.isAddNewdisabled = false;

        }

    }
    updateRecordView () {

        setTimeout(() => {

            eval("$A.get('e.force:refreshView').fire();");

        }, 3000);

    }
    customValidityCheck () {

        this.isValid = true;

        var selectElements = this.template.querySelectorAll('lightning-select');

        selectElements.forEach((selectElement) => {

            // Check if the value is null or empty
            if (selectElement.value == '') {

                this.isValid = false;

                // Set a custom validity message
                selectElement.setCustomValidity('Please select a value.');
                this.isAddNewdisabled = true;

            } else {

                selectElement.setCustomValidity('');

            }
            // Report validity to show the error message
            selectElement.reportValidity();
        });
        return this.isValid;

    }

}
