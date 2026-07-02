"""
@author: Biplab, Congyu(Sam)
"""

import torch
from torchvision import transforms
from PIL import Image
import numpy as np
import io
import torchvision.models as models


# Model Definitions
class SimpleRegressionModel(torch.nn.Module):
    def __init__(self, input_size):
        super().__init__()
        self.flatten = torch.nn.Flatten()
        self.fc1 = torch.nn.Linear(input_size, 512)
        self.fc2 = torch.nn.Linear(512, 256)
        self.fc3 = torch.nn.Linear(256, 1)
        self.relu = torch.nn.ReLU()
        self.dropout = torch.nn.Dropout(0.1)

    def forward(self, x):
        x = self.flatten(x)
        x = self.relu(self.fc1(x))
        x = self.dropout(x)
        x = self.relu(self.fc2(x))
        x = self.dropout(x)
        return self.fc3(x)


# Global variables
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
feature_extractor = None
regression_model = None
bins = None
quantiles = None
features_list = []

model_loaded = False


def load_models():
    global feature_extractor, regression_model, bins, quantiles

    # Initialize and load MobileNetV3
    feature_extractor = models.mobilenet_v3_large(pretrained=True)
    feature_extractor.to(device)
    feature_extractor.eval()

    # Initialize regression model
    model_path = 'model/mobilenetv3_02_02_HUBER_E4000_conformal_COMBINED_trained.pth'
    regression_model = SimpleRegressionModel(input_size=47040)  # MobileNetV3 feature size
    regression_model.load_state_dict(torch.load(model_path, map_location=device))
    regression_model.to(device)
    regression_model.eval()

    """
    commentted out because conformal won't load, beside, we don't need upper/lower bounds for Oilix anyway
    # Load conformal parameters as numpy arrays
    conformal_path = 'model/02_02_HUBER_COMBINED_E4000_conformal_params_mobilenetv3.pt'
    conf_data = torch.load(conformal_path, map_location='cpu')
    bins = conf_data['bins'].cpu().numpy() if isinstance(conf_data['bins'], torch.Tensor) else conf_data['bins']
    quantiles = conf_data['quantiles'].cpu().numpy() if isinstance(conf_data['quantiles'], torch.Tensor) else conf_data[
        'quantiles']
    """


def extract_features(image_tensor):
    global features_list
    features_list = []

    def hook_fn(module, input, output):
        features_list.append(output)

    # Register hook to the last feature layer
    hook = feature_extractor.features[-1].register_forward_hook(hook_fn)

    # Forward pass
    with torch.no_grad():
        _ = feature_extractor(image_tensor.unsqueeze(0).to(device))

    # Remove hook
    hook.remove()

    return features_list[0]


def min_max_normalize(features):
    min_val = torch.min(features)
    max_val = torch.max(features)
    return (features - min_val) / (max_val - min_val)


def predict_with_confidence(image_tensor):
    with torch.no_grad():
        # Extract features using MobileNetV3
        features = extract_features(image_tensor)

        # Process features
        features = features.view(-1)  # Flatten features
        features = min_max_normalize(features)
        features = features.unsqueeze(0)  # Add batch dimension

        # Get prediction from regression model
        output = regression_model(features)
        mean_pred = torch.clamp(output.squeeze(), min=0).cpu().numpy()
        """
        # Calculate confidence intervals
        bin_indices = np.digitize(mean_pred, bins) - 1
        bin_indices = np.clip(bin_indices, 0, len(quantiles) - 1)
        prediction_quantiles = quantiles[bin_indices]

        lower_bound = np.maximum(mean_pred - prediction_quantiles, 0)
        upper_bound = mean_pred + prediction_quantiles
        """
        return {
            'prediction': float(mean_pred)#,
            #'lower_bound': float(lower_bound),
            #'upper_bound': float(upper_bound)
        }

def model_predict(image_path):
    if model_loaded == False:
        load_models()
        model_loaded == True
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Resize((224, 224)),
    ])
    with open(image_path, "rb") as file:
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        image_tensor = transform(image)
        prediction2 = predict_with_confidence(image_tensor)
        prediction=prediction2["prediction"]
        if prediction < 0:
            prediction = 0.000
        else:
            prediction = np.around(prediction, decimals=2)

        label = str(np.squeeze(prediction))
        return label