#!/usr/bin/python

from pymongo import MongoClient
import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn.neighbors import KNeighborsClassifier
import turicreate as tc
import pickle
from bson.binary import Binary
import json
import numpy as np

import cv2
import os
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.decomposition import PCA

class PrintHandlers(BaseHandler):
    def get(self):
        '''Write out to screen the handlers used
        This is a nice debugging example!
        '''
        self.set_header("Content-Type", "application/json")
        self.write(self.application.handlers_string.replace('),','),\n'))

class RequestNewDatasetId(BaseHandler):
    def get(self):
        '''Get a new dataset ID for building a new dataset
        '''
        a = self.db.labeledinstances.find_one(sort=[("dsid", -1)])
        if a == None:
            newSessionId = 1
        else:
            newSessionId = float(a['dsid'])+1
        self.write_json({"dsid":newSessionId})

class UpdateModelForDatasetId(BaseHandler):
    def get(self):
        '''Train a new model (or update) for given dataset ID
        '''
        dsid = self.get_int_arg("dsid",default=0)
        
        # create feature vectors from database
        f=[];
        for a in self.db.labeledinstances.find({"dsid":dsid}):
            f.append([float(val) for val in a['feature']])
            
            # create label vector from database
        l=[];
        for a in self.db.labeledinstances.find({"dsid":dsid}):
            l.append(a['label'])
            
            # fit the model to the data
        c1 = KNeighborsClassifier(n_neighbors=1);
        acc = -1;
        if l:
            c1.fit(f,l) # training
            lstar = c1.predict(f)
            self.clf = c1
            acc = sum(lstar==l)/float(len(l))
            bytes = pickle.dumps(c1)
            self.db.models.update({"dsid":dsid},
                                  {  "$set": {"model":Binary(bytes)}  },
                                  upsert=True)

# send back the resubstitution accuracy
    # if training takes a while, we are blocking tornado!! No!!
        self.write_json({"resubAccuracy":acc})

class PredictOneFromDatasetId(BaseHandler):
    def post(self):
        '''Predict the class of a sent feature vector
        '''
        data = json.loads(self.request.body.decode("utf-8"))
        
        vals = data['feature'];
        fvals = [float(val) for val in vals];
        fvals = np.array(fvals).reshape(1, -1)
        dsid  = data['dsid']
        
        # load the model from the database (using pickle)
        # we are blocking tornado!! no!!
        if(self.clf == []):
            print('Loading Model From DB')
            tmp = self.db.models.find_one({"dsid":dsid})
            self.clf = pickle.loads(tmp['model'])
        predLabel = self.clf.predict(fvals);
        self.write_json({"prediction":str(predLabel)})

# ----------------  lab 5 -----------------

class uploadImage(BaseHandler):
    def post(self):
        data = json.loads(self.request.body.decode("utf-8"))
        feature = data['feature']
        label = data['label']
        head = self.request.headers
        mh = head.get('Cookie',None)

        if mh == options.cookie:
            self.db.images.insert({
                              'label': label,
                              'feature': feature
                              })
            self.write_json({'code':0,'msg':'add image success'})
        
        else:
            self.write({'code':99,'msg':'Auth failed'})

        

class AuthUser(BaseHandler):
    def post(self):
        
        data = json.loads(self.request.body.decode("utf-8"))
        head = self.request.headers
        mh = head.get('Cookie',None)
        print('head值：',mh)
        
        if mh == options.cookie:
            self.write({'code':0,'msg':'Auth success'})
        
        else:
            self.write({'code':99,'msg':'Auth failed'})


class LoginHandle(BaseHandler):
    
    def post(self):
        
        data = json.loads(self.request.body.decode("utf-8"))
        head = self.request.headers
        mh = head.get('Cookie',None)
        
        if data['username'] == 'admin' and data['password'] == 'admin':
            
            self.write({'code':0,'msg':'load success','TOKEN':options.cookie})
        
        else:
            #
            self.write({'code':1,'msg':'load failed'})


# check if there is enough labeled features to train the model
class GetModelData(BaseHandler):
    def post(self):
    
        check_list = {}
        # counts how many images for each label
        for i in self.db.images.find():
            print(i['label'])
            if i['label'] not in check_list:
                check_list[i['label']] = 1
            else:
                check_list[i['label']] += 1
                
        self.write_json({'code':0,'data':json.dumps(check_list)})
       

class TrainModel(BaseHandler):
    def post(self):
    
        train_data = self.getTrainData()

         # logistic regression
        logistic_model = tc.logistic_classifier.create(train_data, target='target', verbose=0)
        logistic_yhat = logistic_model.predict(train_data)
        logistic_count = sum(logistic_yhat == train_data['target'])/float(len(train_data))

        # boosted decision tree
        boosted_model = tc.boosted_trees_classifier.create(train_data, target='target', verbose=0)
        boosted_yhat = boosted_model.predict(train_data)
        boosted_count = sum(boosted_yhat == train_data['target'])/float(len(train_data))

        print('logistic_model accuracy:', logistic_count)
        print('boosted_model accuracy:', boosted_count)
        
        logistic_model.save('../models/turi_%s' % ('logistic_model'))
        boosted_model.save('../models/turi_%s' % ('boosted_model'))
        # export to coreml models
        logistic_model.export_coreml('../models/%s.mlmodel' % ('logistic_model'))
        boosted_model.export_coreml('../models/%s.mlmodel' % ('boosted_model'))
        
        self.write_json({'code':0,'msg':'train success'})

    def getTrainData(self):
        # convert data into sframe data
        features=[]
        labels=[]
        for a in self.db.images.find():
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])
        data = {'target':labels, 'sequence':np.array(features)}
        return tc.SFrame(data=data)

class PredictLabel(BaseHandler):
    def post(self):
        data = json.loads(self.request.body.decode("utf-8"))
        model_name = ''
        feature = self.get_sframe_feature(data['feature'])
        try:
           model_name = data['modelName']
        except Exception as e:
           # return None if the model does not exist
           self.write_json({'code':1,'msg': 'model does not exist'})
           return
        print('{} making the prediction'.format(model_name))
        # load model from previously saved location
        model = tc.load_model('../models/turi_%s' % (model_name))
        pred = model.predict(feature)
        
        self.write_json({'code':0,'data': pred[0]})

    def get_sframe_feature(self, feature):
        # convert the feature array to sframe data
        tmp = np.array(feature)
        tmp = tmp.reshape((1, -1))
        data = {'sequence': tmp}
        return tc.SFrame(data=data)


from sklearn.model_selection import train_test_split
# similar to train model but the comparing model requires more data and has test data set so that we could have a more reasonable accuracy to compare
class TrainAndCompareModel(BaseHandler):
    def post(self):
        train_data, test_data = self.getTrainData()

        # logistic regression
        logistic_model = tc.logistic_classifier.create(train_data, target='target', verbose=0)
        # predict the test data
        logistic_yhat = logistic_model.predict(test_data)
        logistic_acc = sum(logistic_yhat == test_data['target'])/float(len(test_data))

        # boosted decision tree
        boosted_model = tc.boosted_trees_classifier.create(train_data, target='target', verbose=0)
        boosted_yhat = boosted_model.predict(test_data)
        boosted_acc = sum(boosted_yhat == test_data['target'])/float(len(test_data))

        print('logistic accuracy:', logistic_acc)
        print('boostedTree accuracy:', boosted_acc)
        # save and export the newly trained model
        logistic_model.save('../models/turi_%s' % ('logistic_model'))
        boosted_model.save('../models/turi_%s' % ('boosted_model'))
        # export to coreml models
        logistic_model.export_coreml('../models/%s.mlmodel' % ('logistic_model'))
        boosted_model.export_coreml('../models/%s.mlmodel' % ('boosted_model'))

        # convert the accuracy to string so that they can be printed out on UI easily
        logistic_acc = '{:.2f}%'.format(logistic_acc*100)
        boosted_acc = '{:.2f}%'.format(boosted_acc*100)
        print(logistic_acc, boosted_acc)
        # write the json object and send back to server
        self.write_json({'code':0,'data':{'logistic_acc':str(logistic_acc),'boosted_acc':str(boosted_acc)}})

    def getTrainData(self):
        features=[]
        labels=[]
        for a in self.db.images.find():
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])

        # 80:20 split based on label stratification. we will use the accuracy on predicting the test data set to compare two models
        X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size = .2, random_state = 1, stratify = labels)
        # convert data into sframe data
        train_data = {'target':y_train, 'sequence':np.array(X_train)}
        test_data = {'target':y_test, 'sequence':np.array(X_test)}
        return tc.SFrame(data=train_data), tc.SFrame(data=test_data)

