"""
@author: ZHGZYANG, Biplab
"""

from __future__ import print_function, division

import random

import pickle
import cv2
import numpy as np
from PIL import Image
import torch
import io

import os

class CPU_Unpickler(pickle.Unpickler):
    def find_class(self, module, name):
        if module == 'torch.storage' and name == '_load_from_bytes':
            return lambda b: torch.load(io.BytesIO(b), map_location='cpu')
        else: return super().find_class(module, name)
        
def get_intermediate_features_2(models, layers, input_image):
    intermediate_features_list = []
    
    for model, layer in zip(models, layers):
        model.cpu()
        features = []
        def hook(module, input, output):
            features.append(output)
        handle = layer.register_forward_hook(hook)

        with torch.no_grad():
            model_input = input_image.unsqueeze(0)
            model(model_input)

        handle.remove()
        intermediate_features_list.append(features[0].flatten())
    
    temp_features = [element for innerList in intermediate_features_list for element in innerList]
    intermediate_features_list = [temp_features]
    
    return intermediate_features_list

def model_predict(image_path):
    with open('water_model.pkl', 'rb') as f:
        model, transform, models_1, layers_1 = CPU_Unpickler(f).load()
        with open(image_path, "rb") as file:
            img = Image.open(file)
            img_tensor = transform(img)
            features = get_intermediate_features_2(models_1, layers_1, img_tensor)
            prediction = model.predict(features)

            if prediction < 0:
                prediction = 0.000
            else:
                prediction = np.around(prediction, decimals=2)

            label = str(np.squeeze(prediction))            
            return label

