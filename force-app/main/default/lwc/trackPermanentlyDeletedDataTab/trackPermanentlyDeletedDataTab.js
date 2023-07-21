import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from "lightning/confirm";
import getAllObjectName from '@salesforce/apex/fetchAllObjects.getAllObjectName';
import saveTrackingObject from '@salesforce/apex/fetchAllObjects.saveTrackingObject';
import fetchAllRecords from '@salesforce/apex/fetchAllObjects.fetchAllRecords';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {
    
    @track getAllObjectList=[];
    @track objectRecordList=[];
    isSaveBtnVisible;
    selectedObject;
    // data=[
    //     {Id :1, objectName:'Account'},
    //     {Id :2, objectName:'Contact'}
    // ];
    connectedCallback(){
        getAllObjectName()
        .then((result)=>{

            for(let key in result){
                this.getAllObjectList.push({label : key ,value : key});
            }
        })
        .catch((error)=>{
            console.log('Error found for Object List-'+error);
        })
    }
    @wire(fetchAllRecords)
    wireAllRecords({error , data}){
        if(data){
            this.objectRecordList = data;
            console.log('Data-'+JSON.stringify(data))
            this.error = undefined;
        }else if(error){
            console.log('Error-'+error);
            this.records = undefined;
        }
    }

    handleChange(event){
        console.log('in handle change',event.detail.value);
        var selectedValue =event.detail.value;
        //var selectedRow = event.currentTarget;
        var key = event.currentTarget.dataset.id;
        //var accountVar = this.objectRecordList[key];
        console.log('Id',key);

        let obj =this.objectRecordList.find((o, i) => {
            if (o.Id == key ) {
                this.objectRecordList[i] = { Name : selectedValue};
                return true; // stop searching
            }
        });
        // this.objectRecordList[key].Name = event.detail.value;
        // console.log('Value-',event.detail.value);
        console.log('BojectList new Value',JSON.stringify(this.objectRecordList));
    }
    addRow(){
        this.isSaveBtnVisible=true;
        let randomId = Math.random() * 16;
        let myNewElement = {Id :randomId, Name:''};
        this.objectRecordList = [...this.objectRecordList, myNewElement];
    }
    onsaveclickHandler(){
        console.log('Object List'+JSON.stringify(this.objectRecordList));
        saveTrackingObject({ objNameList : this.objectRecordList })
        .then((result)=>{
            console.log('Save Result-'+result);
            const evt = new ShowToastEvent({
                title: 'Success!',
                message: 'Record Saved Successfully',
                variant: 'Success'
            });
            this.dispatchEvent(evt);
        })
        .catch((error)=>{
            console.log('Error result-'+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: 'error',
                variant: 'Error'
            });
            this.dispatchEvent(evt);
        })
        this.isSaveBtnVisible=false;
    }
    
    handleActionDelete(){
        console.log('In delete Action');
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'error',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
}