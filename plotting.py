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
    fig,ax=plt.subplots(1,2,figsize=(12, 7))
    for i in range(2):
        ax[i].plot(coeffs,y_mean[:,i])
        ax[i].errorbar(coeffs,y_mean[:,i],yerr=y_var[:,i])
        ax[i].set_xlabel(r'$\lambda$')
        ax[i].set_ylabel(f'Y{i+1}')

def plot_population(Y:torch.Tensor, algorithm_population_count=0):
    # scatter Y with axis labels
    fig,ax=plt.subplots()
    last_random=Y.shape[0]-algorithm_population_count
    ax.scatter(Y[:last_random,0],Y[:last_random,1], c='blue')
    ax.set_xlabel('Y1')
    ax.set_ylabel('Y2')
    if algorithm_population_count > 0:
        ax.scatter(Y[last_random:,0],Y[last_random:,1], c='red')
        ax.legend(('random','optimizer'))

def hypervolume(Y,ref_point=torch.tensor([-1,-2])):
    # compute hypervolume of Y
    bd = DominatedPartitioning(ref_point=ref_point, Y=Y)
    hv=bd.compute_hypervolume().item()
    return hv

def plot_hypervolume_over_iteration(Y,ref_point=torch.tensor([-1,-2])):
    # Y is of shape (n_iterations, n_objectives)
    hypervolumes=[]
    for i in range(Y.shape[0]):
        hypervolumes.append(hypervolume(Y[0:i,:],ref_point=ref_point))

    fig,ax=plt.subplots()
    ax.plot(hypervolumes)
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Hypervolume')
