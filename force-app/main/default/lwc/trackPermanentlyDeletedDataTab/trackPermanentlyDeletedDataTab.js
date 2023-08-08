import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from "lightning/confirm";
import LightningAlert from 'lightning/alert';
import getAllObjectName from '@salesforce/apex/trackPermanentDalateDataController.getAllObjectName';
import saveTrackingObject from '@salesforce/apex/trackPermanentDalateDataController.saveTrackingObject';
import fetchAllRecords from '@salesforce/apex/trackPermanentDalateDataController.fetchAllRecords';
import deleteObject from '@salesforce/apex/trackPermanentDalateDataController.deleteObject';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {
    
    @track getAllObjectList=[];
    @track objectRecordList=[];
    @track deleteRecordIds ;
    @track newObjectList=[];
    @track getAllRecords;
    isSaveBtnVisible;
    recordExist=false;
    isLoading = true;
    
    
    

    connectedCallback(){
        console.log('In connected callback');
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
    wireAllRecords(result){
        this.getAllRecords=result;
        if(result.data){
            this.objectRecordList = this.getAllRecords.data;
            console.log('Data-'+JSON.stringify(result.data));
            this.error = undefined;
            this.isLoading=false;
        }else if(result.error){
            console.log('Error-'+error);
            this.records = undefined;
            this.isLoading=false;
        }
    }

   async handleChange(event){
    this.isSaveBtnVisible=true;
        console.log('in handle change',event.detail.value);
        var selectedValue =event.detail.value;
        var key = event.currentTarget.dataset.id;
       //debugger;
       const  objValue = this.newObjectList.findIndex((obj => obj.Id == key));

       this.newObjectList[objValue].Name=selectedValue;
        
    }

    //the function to be called on add button click used to add new row into a datatble
    addRow(){
        this.isSaveBtnVisible=true;
        let randomId = Math.random() * 16;
        let myNewElement = {Id :randomId, Name:null};
        this.objectRecordList = [...this.objectRecordList, myNewElement];
        this.newObjectList.push({Id :randomId, Name:null});
        console.log('Object list -'+JSON.stringify(this.objectRecordList));
        
    }

    //the function to be called on save button click used to save custom setting records
    async onsaveclickHandler(event){
        
       this.isLoading=true;
        console.log('Object List'+JSON.stringify(this.newObjectList));
          saveTrackingObject({ objNameList : this.newObjectList })
        .then(async(result)=>{
            console.log('Save Result-'+result);
            refreshApex(this.wireAllRecords);
            this.dispatchEvent(new RefreshEvent());
            this.isLoading=false;
          await LightningAlert.open({
                message: 'Record Saved successfully!',
                theme: 'success', // a red theme intended for error states
                label: 'Success!', // this is the header text
            });

           
            this.newObjectList=[];
            return refreshApex( this.getAllRecords);
            
            refreshApex(this.objectRecordList);
            this.wireAllRecords();
        })
        .catch(async(error)=>{
            this.isLoading=false;
            console.log('Error result-'+JSON.stringify(error));
            if(error){
                await LightningAlert.open({
                    message: JSON.stringify(error),
                    theme: 'error', // a red theme intended for error states
                    label: 'Error!', // this is the header text
                });
            }
            
            this.isLoading=false;
        })
        this.isSaveBtnVisible=false;
    
    }
    
   async handleActionDelete(event){
    
    console.log('Record Id-',event.target.dataset.id);
    this.deleteRecordIds=event.target.dataset.id;
    const result = await LightningConfirm.open({
            message: 'Are you sure to delete this record?',
            theme: 'warning', 
            variant: 'header',
            label: 'Delete a record',
            
        });
       if(result){
        this.isLoading=true;
        if(!isNaN(this.deleteRecordIds)){
            console.log('Index Value -'+this.objectRecordList.findIndex(row => row.Name === null));
            this.objectRecordList.splice( this.objectRecordList.findIndex(row => row.Name === null), 1);
            this.newObjectList.splice( this.newObjectList.findIndex(row => row.Name === null), 1);
            this.isSaveBtnVisible=false;
            this.isLoading=false;
            return refreshApex(this.getAllRecords);
        }else{
        deleteObject({removeObjectIds : this.deleteRecordIds})
        .then(async(res)=>{
            console.log('Result on delete-',res);
            //refreshApex(this.wireAllRecords);
            //this.dispatchEvent(new RefreshEvent());
            this.isLoading=false;
          await  LightningAlert.open({
                message: 'Record Deleted successfully!',
                theme: 'success', 
                label: 'Record Deleted', // this is the header text
            });
            //this.objectRecordList.splice( this.objectRecordList.findIndex(row => row.Id === this.deleteRecordIds), 1);
            return refreshApex(this.getAllRecords);
            
        })
        .catch((error)=>{
            console.log('error on delete-',error);
        })
    }
       }else{
        
       }
       this.isSaveBtnVisible=false;
}
updateRecordView() {
    setTimeout(() => {
         eval("$A.get('e.force:refreshView').fire();");
    }, 3000); 
 }
}