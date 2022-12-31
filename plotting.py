from botorch.models.gpytorch import GPyTorchModel
from botorch.utils.multi_objective.box_decompositions.dominated import (
    DominatedPartitioning,
)
import torch
import matplotlib.pyplot as plt
def plot_model(model: GPyTorchModel,x0,x1, steps=100):
    # convert x0,x1 to torch tensors
    x0=torch.tensor(x0)
    x1=torch.tensor(x1)

    coeffs=torch.linspace(0,1,steps).tolist()
    x=torch.stack([x0*(1-coeff)+coeff*x1 for coeff in coeffs])
    #print(x)
    p=model.posterior(x)
    y_mean=p.mean
    y_var=p.variance
    y_mean=y_mean.detach().numpy()
    y_var=y_var.detach().numpy()
    fig,ax=plt.subplots(1,2)
    for i in range(2):
        ax[i].plot(coeffs,y_mean[:,i])
        ax[i].errorbar(coeffs,y_mean[:,i],yerr=y_var[:,i])

def plot_population(Y):
    # scatter Y with axis labels
    fig,ax=plt.subplots()
    ax.scatter(Y[:,0],Y[:,1])
    ax.set_xlabel('Y1')
    ax.set_ylabel('Y2')

def plot_hypervolume_over_iteration(Y):
    # Y is of shape (n_iterations, n_objectives)
    hypervolumes=[]
    for i in range(Y.shape[0]):
        bd = DominatedPartitioning(ref_point=torch.tensor([-1,-2]), Y=Y[0:i,:])
        hv=bd.compute_hypervolume().item()
        hypervolumes.append(hv)

    fig,ax=plt.subplots()
    ax.plot(hypervolumes)
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Hypervolume')
