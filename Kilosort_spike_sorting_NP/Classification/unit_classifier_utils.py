"""
@author: heet
"""
from utils import extract
from sklearn.metrics import confusion_matrix
import numpy as np
from sklearn.linear_model import LogisticRegression

def gen_model(**kwargs):
    """Train model with parameters given as keyword arguments. Kwargs passed to
    sklearn.linear_model.LogisticRegression()
    If no kwargs are given, assumes two defaults:
        solver = liblinear
        random_state = 0
    
    Returns trained model object
    """
    solver = kwargs.pop('solver', 'liblinear')
    random_state = kwargs.pop('random_state', 0)
    return LogisticRegression(solver=solver, random_state=random_state, **kwargs)


def data_splitter(df, train_filters, test_filters, feat_cols, label_col):
    """Extract data from DataFrame for training and testing set using filters
    
    Args:
        df (Dataframe):         Dataframe containing unit metrics
        train_filters (dict):   key = column headers, val = filter values at key
        test_filters (dict):    key = column headers, val = filter values at key
        feat_cols (list-like):  feature column indices to extract for classifier
        label_col: (list-like): column index for ground truth labels
    
    Returns filtered train x, train y, test x, test y
    """
    test_df = extract(df, **test_filters) if test_filters else df.copy()
    train_df = extract(df, **train_filters) if train_filters else df.copy()

    train_x = train_df.iloc[:, feat_cols].to_numpy()
    train_y = train_df.iloc[:, label_col].to_numpy()

    test_x = test_df.iloc[:, feat_cols].to_numpy()
    test_y = test_df.iloc[:, label_col].to_numpy()
    
    return train_x, train_y, test_x, test_y

def fit_and_test(model, train_x, train_y, test_x):
    """Fit model on train set and test on test set
        
    Args:
        model (obj):        sklearn model object
        train_x (ndarray):  training dataset with dims samples x features
        train_y (1d-array): training truth labels
        
    Returns predictions made on train_y
    """
    model.fit(train_x, train_y)
    predictions = model.predict(test_x)
    
    return predictions

def get_model_assessment(predictions, truth_labels, **kwargs):
    """Compute confusion and accuracy of predictions
    
    Args:
        predictions (1d-array):     predicted values
        truth_labels (1d-array):    truth values
        kwargs:                     passed to sklearn confusion_matrix()
    
    Returns confusion matrix and accuracy
    """
    confusion = confusion_matrix(truth_labels, predictions, **kwargs)
    accuracy = np.where(predictions==truth_labels)[0].size / predictions.size
    
    return confusion, accuracy