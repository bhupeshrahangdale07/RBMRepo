import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from "lightning/confirm";
import getAllObjectName from '@salesforce/apex/fetchAllObjects.getAllObjectName';
import saveTrackingObject from '@salesforce/apex/fetchAllObjects.saveTrackingObject';
import fetchAllRecords from '@salesforce/apex/fetchAllObjects.fetchAllRecords';
import deleteObject from '@salesforce/apex/fetchAllObjects.deleteObject';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {
    
    @track getAllObjectList=[];
    @track objectRecordList=[];
    @track deleteRecordIds = '';
    isSaveBtnVisible;
    
    

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

    //the function to be called on add button click used to add new row into a datatble
    addRow(){
        this.isSaveBtnVisible=true;
        let randomId = Math.random() * 16;
        let myNewElement = {Id :randomId, Name:null};
        this.objectRecordList = [...this.objectRecordList, myNewElement];
    }

    //the function to be called on save button click used to save custom setting records
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
    
   async handleActionDelete(event){
    
    console.log('Record Id-',event.target.dataset.id);
        
    const result = await LightningConfirm.open({
            message: 'Are you sure to delete this record?',
            theme: 'warning', 
            variant: 'header',
            label: 'Delete a record',
            
        });
       if(result){

        // if(isNaN(event.target.dataset.id)){
        //     this.deleteRecordIds = event.target.dataset.id; /*+ ',' + event.target.dataset.id;*/
        // }
        deleteObject({removeObjectIds : this.deleteRecordIds})
        .then((res)=>{
            console.log('Result on delete-',res);
        })
        .catch((error)=>{
            console.log('error on delete-',error);
        })
        this.objectRecordList.splice( this.objectRecordList.findIndex(row => row.Id === event.target.dataset.id), 1);
        
        // if(this.deleteRecordIds !== ''){
        //     this.deleteRecordIds = this.deleteRecordIds.substring(1);
        // }
        
        refreshApex(this.objectRecordList);
            
       }else{

       }
       this.isSaveBtnVisible=false;
}
}