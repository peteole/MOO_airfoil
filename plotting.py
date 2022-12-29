from botorch.models.gpytorch import GPyTorchModel
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