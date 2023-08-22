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
import AddNewButton from '@salesforce/label/c.AddNewButton';
import Save_rbin from '@salesforce/label/c.Save_rbin';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {
    
    @track getAllObjectList=[];
    @track allObjectListForIndex=[];
    @track objectRecordList=[];
    @track deleteRecordIds ;
    @track newObjectList=[];
    @track getAllRecords;
    isSaveBtnVisible;
    recordExist=false;
    isLoading = true;
    
    label={
        AddNewButton,
        Save_rbin,
    };
    
    

    // connectedCallback(){
    //     console.log('In connected callback');
    //     getAllObjectName()
    //     .then((result)=>{
    //         console.log('List of existing-',JSON.stringify(this.objectRecordList));
    //         for(let key in result){
    //            // this.getAllObjectList.push({label : key ,value : key});
    //         //    if (!this.objectRecordList.some(obj => obj.Name === key)) {
    //         //     this.getAllObjectList.push({ label: key, value: key });
    //         // }
    //         }
    //     })
    //     .catch((error)=>{
    //         console.log('Error found for Object List-'+error);
    //     })
        
    // }
    @wire(fetchAllRecords)
    wireAllRecords(result){
        console.log('In wire 1');
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

    @wire(getAllObjectName)
    wireObjectNames({error, data}){
        console.log('In wire 2');
        if(data){
            
        for(let key in data){
            // this.getAllObjectList.push({label : key ,value : key});
            if (!this.objectRecordList.some(obj => obj.Name === key)) {
             this.getAllObjectList.push({ label: key, value: key });
         }
         this.allObjectListForIndex.push({label: key, value: key});
         }
         this.isLoading=false;
        }else if(error){
            console.log('Error-'+error);
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
    
       console.log('All object List-',JSON.stringify(this.getAllObjectList));
       console.log('New selected object List-',JSON.stringify(this.newObjectList));
       //this.getAllObjectList.splice( this.getAllObjectList.findIndex(row => row.Name === selectedValue), 1);
       const idxValue=this.getAllObjectList.findIndex((objct => objct.value === selectedValue));
       this.getAllObjectList.splice(idxValue,1);
    }

    //the function to be called on add button click used to add new row into a datatble
    addRow(){
        this.isSaveBtnVisible=true;
        let randomId = Math.random() * 16;
        let myNewElement = {Id :randomId, Name:null};
        this.objectRecordList = [...this.objectRecordList, myNewElement];
        this.newObjectList.push({Id :randomId, Name:null});
        console.log('Object list -'+JSON.stringify(this.objectRecordList));
        console.log('New Arr after adding row-'+JSON.stringify(this.newObjectList));
        
    }

    //the function to be called on save button click used to save custom setting records
    async onsaveclickHandler(){
        
       this.isLoading=true;
        console.log('Object List'+JSON.stringify(this.newObjectList));
          saveTrackingObject({ objNameList : this.newObjectList })
        .then(async(result)=>{
            console.log('Save Result-'+result);
            refreshApex(this.wireAllRecords);
            this.dispatchEvent(new RefreshEvent());
            this.isLoading=false;
          await LightningAlert.open({
                message: result,
                theme: 'success', // a red theme intended for error states
                label: 'Success!', // this is the header text
            });
            this.newObjectList=[];
            this.wireObjectNames;
            return refreshApex( this.getAllRecords);
            
           // refreshApex(this.objectRecordList);
            //this.wireAllRecords();
        })
        .catch(async(error)=>{
            this.isLoading=false;
            console.log('Error result-'+JSON.stringify(error.body.message));
            if(error){
                const errorMessage =JSON.stringify(error.body.message);
                const startIndex = errorMessage.indexOf("first error");
                const extractedErrorMessage = errorMessage.substring(startIndex);
                const message =extractedErrorMessage.replace("first error: FIELD_INTEGRITY_EXCEPTION, ", "");
                console.log('Error result-'+message);
                await LightningAlert.open({
                    message: message,
                    theme: 'error', // a red theme intended for error states
                    label: 'Error!', // this is the header text
                });
            }
            
            this.isLoading=false;
        })
        this.isSaveBtnVisible=false;
    
    }
    
   async handleActionDelete(event){
    //var selectedValue =event.detail.value;
    //const idxValue=this.getAllObjectList.findIndex((objct => objct.value == selectedValue));
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
            console.log('Index Value -'+this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds));
            //debugger;
            this.objectRecordList.splice( this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds), 1);
            
            
            console.log('New Object Value-'+JSON.stringify(this.newObjectList));
            //if(this.newObjectList[this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds)].Name!=null){
                var foundObject = this.newObjectList.find(obj => obj.Id == this.deleteRecordIds);
                if (foundObject && foundObject.Name !== null) {
                    var nameValue = foundObject.Name;
                    console.log('Name value:', nameValue);
                }
            //var newDeletedValue=this.newObjectList[this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds)].Name;
            var indexValueforDeleteObj=this.allObjectListForIndex.findIndex(idx => idx.value == nameValue);
            if(nameValue!=null){
            this.getAllObjectList.splice(indexValueforDeleteObj,0,{label:nameValue, value:nameValue});
            console.log('All object option-'+ JSON.stringify(this.getAllObjectList));
        }
   // }
    console.log('Idx Value for new arr-'+this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds));
    this.newObjectList.splice( this.newObjectList.findIndex(row => row.Id == this.deleteRecordIds), 1);
    
            //this.newObjectList.splice( this.newObjectList.findIndex(row => row.Name == newDeletedValue), 1);
            //this.getAllObjectList.push({label:deletedValue, value:deletedValue});
            //console.log('New object List-',JSON.stringify(this.getAllObjectList));
           // this.isSaveBtnVisible=false;
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
                message: res,
                theme: 'success', 
                label: 'Record Deleted', // this is the header text
            });
            console.log('Deleted Value-'+this.objectRecordList[this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds)].Name);
            debugger;
            var deletedValue=this.objectRecordList[this.objectRecordList.findIndex(row => row.Id == this.deleteRecordIds)].Name;
            var indexValueforDeleteObj=this.allObjectListForIndex.findIndex(idx => idx.value == deletedValue);
            this.getAllObjectList.splice(indexValueforDeleteObj,0,{label:deletedValue, value:deletedValue});
            //this.getAllObjectList.push({label:deletedValue, value:deletedValue});
            console.log('New object List-',JSON.stringify(this.getAllObjectList));
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