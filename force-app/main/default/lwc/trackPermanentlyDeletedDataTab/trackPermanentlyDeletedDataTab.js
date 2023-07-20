import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";
import getAllObjectName from '@salesforce/apex/fetchAllObjects.getAllObjectName';
import saveTrackingObject from '@salesforce/apex/fetchAllObjects.saveTrackingObject';

export default class TrackPermanentlyDeletedDataTab extends LightningElement {
    
    @track objectList=[];
    isSaveBtnVisible;
    selectedObject;
    data=[
        {Id :1, objectName:'Account'},
        {Id :2, objectName:'Contact'}
    ];
    connectedCallback(){
        getAllObjectName()
        .then((result)=>{

            for(let key in result){
                this.objectList.push({label : key ,value : key});
            }
        })
        .catch((error)=>{
            console.log('Error found for Object List-'+error);
        })

    }
    handleChange(event){
        this.selectedObject=event.detail.value;
    }
    onsaveclickHandler(){
        saveTrackingObject({ objName : this.selectedObject })
        .then((result)=>{
           
            const evt = new ShowToastEvent({
                title: 'Success!',
                message: result,
                variant: 'Success',
            });
            this.dispatchEvent(evt);
        })
        .catch((error)=>{
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: error,
                variant: 'Error',
            });
            this.dispatchEvent(evt);
        })
        this.isSaveBtnVisible=false;
    }
    addRow(){
        this.isSaveBtnVisible=true;
        let randomId = Math.random() * 16;
        let myNewElement = {id: randomId.toString(36),objectName:"",Id :randomId };
        this.data = [...this.data, myNewElement];
    }
}