#!/usr/bin/python

from pymongo import MongoClient
import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn.neighbors import KNeighborsClassifier
import pickle
from bson.binary import Binary
import json
import numpy as np
import turicreate as tc

class PrintHandlers(BaseHandler):
    def get(self):
        '''Write out to screen the handlers used
        This is a nice debugging example!
        '''
        self.set_header("Content-Type", "application/json")
        self.write(self.application.handlers_string.replace('),','),\n'))

class UploadLabeledDatapointHandler(BaseHandler):
    def post(self):
        '''Save data point and class label to database
        '''
        data = json.loads(self.request.body.decode("utf-8"))
        
        vals = data['feature']
        fvals = [float(val) for val in vals]
        label = data['label']
        sess  = data['dsid']
        
        dbid = self.db.labeledinstances.insert({"feature":fvals,"label":label,"dsid":sess});
        
        self.write_json({"dsid":str(sess),
                        "feature":[str(len(fvals))+" Points Received","min of: " +str(min(fvals)),
                                   "max of: " +str(max(fvals))],"label":label})

class RequestNewDatasetId(BaseHandler):
    def get(self):
        '''Get a new dataset ID for building a new dataset
        '''
        dsidList = []
        dataArray = []
        for i in self.db.labeledinstances.find():
            if i['dsid'] not in dsidList:
                dsidList.append(i['dsid'])
                dataArray.append({'dsid':i['dsid'],'label':i['label']})
        
        self.write_json({"data":dataArray})

class UpdateModelForDatasetId(BaseHandler):
    def get(self):
        '''Train a new model (or update) for given dataset ID
        '''
        dsid = self.get_int_arg("dsid",default=0)
        data = getDataFromSFrame(self.db,dsid)
        acc = -1
        
        if len(data)>0:
            
            # training
            model = tc.classifier.create(data,target='classes',verbose=0)
            # Add a pair of id and model to the dict if id not exist,If it exists it will just update the model
            self.clf[dsid] = model
            acc = sum(model.predict(data)==data['classes'])/float(len(data))
            # save model for use later, if desired
            model.save('../models/model_dsid%s'%(dsid))
        
        self.write_json({"resubAccuracy":acc})


class PredictOneFromDatasetId(BaseHandler):
    def post(self):
        '''Predict the class of a sent feature vector
        '''
        data = json.loads(self.request.body.decode("utf-8"))
        
        np_data = np.array(data['feature']).reshape((1,-1))
        
        fvals = tc.SFrame(data={'items':np_data})
        dsid  = data['dsid']
        data = getDataFromSFrame(self.db,dsid)
        
        # load the model from the database (using pickle)
        # If that key does not exist, print a message and return
        if dsid not in self.clf:
            self.write("Model does not exist in clf, saving new dsid\n")
            model = tc.classifier.create(data,target='classes',verbose=0)# training
            self.clf[dsid] = model
            acc = sum(model.predict(data)==data['classes'])/float(len(data))
            # save model for use later, if desired
            model.save('../models/model_dsid%s'%(dsid))
        
        predLabel = self.clf[dsid].predict(fvals);   # If exist, use that model to do the predict
        self.write_json({"prediction":str(predLabel)})


def getDataFromSFrame(db,dsid):
    # create feature vectors from database
    f=[]
    l=[]
    for a in db.labeledinstances.find({"dsid":dsid}):
        f.append([float(val) for val in a['feature']])
        l.append(a['label'])
        
        # convert to dictionary for tc
    data = {'classes':l, 'items':np.array(f)}
        
        # send back the SFrame of the data
    return tc.SFrame(data=data)
